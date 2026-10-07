import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fun_painting/data/local%20data/painting_save_model.dart';

import '../../data/local data/coloring_save_model.dart';
import '../../data/local data/drawing_repository.dart';
import '../../data/local data/painting_repository.dart' show PaintingRepository;
import '../../data/services/interstitial_ad_service.dart';
import '../../data/services/thumbnail_service.dart';
import '../common/local_data/list.dart';
import '../common/resources/assets_manager.dart';
import '../common/resources/color_manager.dart';
import '../common/resources/font_manager.dart';
import '../common/resources/values_manager.dart';
import 'coloring_canvas.dart';
import 'models/tool_type.dart';
// ✅ NEW (kid-ui): the S / M / L brush presets.
import 'models/brush_size.dart';
// ✅ NEW (kid-ui): the kid-sized "erase everything?" dialog.
import 'widgets/kid_dialogs.dart';
// ✅ NEW (kid-ui round 3): one button size for both rails.
import 'region.dart';
import 'svg_parser.dart';
import 'widgets/color_palette_widget.dart';
import 'widgets/kid_layout.dart';
import 'widgets/kid_color_tray.dart';
// ✅ RESTORED: the original floating palettes animate in with this wrapper.
import 'widgets/animated_vertical_palette.dart';
import 'widgets/pattern_palette_widget.dart';
import 'widgets/stamp_palette_widget.dart';
import 'widgets/tool_palette_widget.dart';
import 'widgets/vertical_action_tools_widget.dart';
import 'widgets/vertical_tool_palette_widget.dart';

class PaintingPage extends StatefulWidget {
  const PaintingPage({super.key, required this.image});
  final String image;
  @override
  State<PaintingPage> createState() => _PaintingPageState();
}

class _PaintingPageState extends State<PaintingPage>
    with TickerProviderStateMixin<PaintingPage> {
  final GlobalKey<ColoringCanvasState> _coloringCanvasKey =
      GlobalKey<ColoringCanvasState>();

  List<Region> _regions = [];
  BrushMode _mode = BrushMode.freehand;
  StrokeStyle _selectedStyle = StrokeStyle.solid;
  Color _selectedColor = Colors.red;
  final GlobalKey _repaintKey = GlobalKey();
  final List<ColoringAction> _actionHistory = [];
  final List<ColoringAction> _redoStack = [];
  bool isSelectedToolOpen = false;
  bool isSelectedColorOpen = false;

  /// ✅ NEW: true when the artwork could not be loaded (missing/corrupt SVG).
  bool _loadFailed = false;

  /// ✅ NEW: guards against a double tap on close / back popping two routes.
  bool _isClosing = false;
  bool isWallPaper = false;
  String selectedPatternImage = PatternAssets.asset(1);
  late Box<ColoringSaveModel> paintingBox;
  late PaintingRepository _repository;

  SelectedTool? _selectedTool;
  ui.Image? _selectedWallpaper;
  String? _selectedStampAsset;
  double _stampSize = 50.0;

  /// ✅ NEW (kid-ui): the brush thickness the child picked — S / M / L. It is
  /// a multiplier handed to ColoringCanvas, which stamps it onto every new
  /// stroke, so it never resizes a line that is already on the page.
  // The original UI has no size control, so this is fixed at the app's
  // original brush width (medium == 1.0). Make it non-final and add a control
  // to bring the S / M / L buttons back.
  final BrushSize _brushSize = BrushSize.medium;
  late AnimationController _verticalPaletteController;
  late Animation<double> _verticalPaletteAnimation;
  bool _isVerticalPaletteVisible = true;
  late AnimationController _leftPaletteController;
  late Animation<double> _leftPaletteAnimation;
  bool _isLeftPaletteVisible = true;

  SelectedTool? _lastColoringTool;
  Color _lastColoringColor = Colors.red;
  // bool _isPainting = false;

  @override
  void initState() {
    super.initState();
    paintingBox = Hive.box<ColoringSaveModel>("painting_save");

    _repository = PaintingRepository(Hive.box<PaintingSave>("paintings"));

    _load();
    _loadWallpaper();
    _setDefaultStamp();
    InterstitialAdService.instance.preload();
    _lastColoringTool = SelectedTool(
      mode: BrushMode.freehand,
      style: StrokeStyle.solid,
      type: ToolType.freehand,
    );
    _selectedTool = _lastColoringTool;

    _verticalPaletteController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _verticalPaletteAnimation = CurvedAnimation(
      parent: _verticalPaletteController,
      curve: Curves.easeInOut,
    );

    _leftPaletteController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _leftPaletteAnimation = CurvedAnimation(
      parent: _leftPaletteController,
      curve: Curves.easeInOut,
    );

    _verticalPaletteController.forward();
    _leftPaletteController.forward();
  }

  @override
  void dispose() {
    _verticalPaletteController.dispose();
    _leftPaletteController.dispose();
    super.dispose();
  }

  // Future<bool> _requestGalleryPermission() async {
  //   final androidInfo = await DeviceInfoPlugin().androidInfo;
  //   final sdkInt = androidInfo.version.sdkInt;

  //   PermissionStatus status;
  //   if (sdkInt >= 33) {
  //     // Android 13+ uses granular media permission
  //     status = await Permission.photos.request();
  //   } else {
  //     // Android 12 and below
  //     status = await Permission.storage.request();
  //   }

  //   return status.isGranted;
  // }

  Future<void> savePainting() async {
    List<RegionSaveModel> saveRegions = [];

    for (final region in _regions) {
      List<StrokeSaveModel> saveStrokes = [];

      for (final stroke in region.strokes) {
        List<double> pts = [];

        for (final p in stroke.points) {
          pts.add(p.dx);
          pts.add(p.dy);
        }

        (saveStrokes.add(
          StrokeSaveModel(
            points: pts,
            color: stroke.color.value,
            style: stroke.style.index,
            stampAsset: stroke.stampAsset,
            stampSize: stroke.stampSize,
            wallpaperAsset: stroke.wallpaperAsset,
          ),
        ));
      }

      saveRegions.add(
        RegionSaveModel(
          fillColor: region.currentFillColor.value,
          fillStyle: region.currentFillStyle.index,
          strokes: saveStrokes,
        ),
      );
    }

    final save = ColoringSaveModel(imageId: widget.image, regions: saveRegions);

    await paintingBox.put(widget.image, save);
  }

  void _hideVerticalPalette() {
    if (_isVerticalPaletteVisible &&
        _verticalPaletteController.status != AnimationStatus.dismissed) {
      try {
        setState(() {
          _isVerticalPaletteVisible = false;
        });
        _verticalPaletteController.reverse();
      } catch (e) {
        debugPrint('Error hiding vertical palette: $e');
      }
    }

    // Also hide left palette
    if (_isLeftPaletteVisible &&
        _leftPaletteController.status != AnimationStatus.dismissed) {
      try {
        setState(() {
          _isLeftPaletteVisible = false;
        });
        _leftPaletteController.reverse();
      } catch (e) {
        debugPrint('Error hiding left palette: $e');
      }
    }
  }

  void _handlePaintingEnded() {
    setState(() {
      // _isPainting = false;
    });
    _showVerticalPalette();
  }

  void _closeBothPalettes() {
    setState(() {
      isSelectedColorOpen = false;
      isSelectedToolOpen = false;
    });
  }

  void _handleColoringAction(dynamic actionInfo) {
    if (actionInfo is! Map) return;

    final type = actionInfo['type'];

    _closeBothPalettes();

    // ✅ NEW: decide once, after the switch, whether this action is worth a
    // full Hive write of the whole painting.
    bool shouldSave = false;

    switch (type) {
      case 'stroke':
      case 'stamp':
        _saveStrokeAction(
          actionInfo['regionIndex'] as int,
          actionInfo['stroke'] as Stroke,
        );
        // ✅ FIX: a stroke that has only just started has no points worth
        // saving. This used to write the entire painting to Hive on every
        // pointer-down (and again on strokeFinished, and once more below).
        break;

      case 'fill':
        _saveFillAction(
          regionIndex: actionInfo['regionIndex'] as int,
          previousColor: actionInfo['previousColor'] as Color,
          newColor: actionInfo['newColor'] as Color,
          previousStyle: actionInfo['previousStyle'] as StrokeStyle,
          newStyle: actionInfo['newStyle'] as StrokeStyle,
          previousStrokes: actionInfo['previousStrokes'] as List<Stroke>,
        );
        shouldSave = true; // ✅ NEW
        break;
      case 'strokeFinished':
        shouldSave = true; // ✅ NEW
        // ----- old version (kept for reference) -----
        // _savePainting();
        break;

      case 'magic':
        _saveMagicAction(
          regionIndex: actionInfo['regionIndex'] as int,
          previousColor: actionInfo['previousColor'] as Color,
          previousStyle: actionInfo['previousStyle'] as StrokeStyle,
          previousStrokes: actionInfo['previousStrokes'] as List<Stroke>,
        );
        shouldSave = true; // ✅ NEW
        break;
    }

    if (shouldSave) {
      _savePainting();
    }
    // ----- old version (kept for reference) -----
    // _savePainting();
  }

  /// ✅ NEW (kid-ui): the clear button asks first. It used to wipe the page on
  /// the first touch, sitting right beside the eraser.
  Future<void> _confirmClearAll() async {
    final confirmed = await showClearAllDialog(context);
    if (!mounted || !confirmed) return;
    _clearAllPaintingsAndStamps();
  }

  void _clearAllPaintingsAndStamps() {
    _saveClearAction();

    setState(() {
      for (final region in _regions) {
        if (region.keepOriginalColor) {
          region.currentFillColor = region.originalFillColor;
        } else {
          region.currentFillColor = Colors.white;
        }

        region.currentFillStyle = StrokeStyle.solid;
        region.strokes.clear();
      }

      // ✅ FIX: the ClearAction pushed by _saveClearAction() must survive so
      // that clearing can be undone. Wiping the history here made ClearAction
      // dead code and the clear button irreversible.
      // ----- old version (kept for reference) -----
      // _actionHistory.clear();
      // _redoStack.clear();
      _coloringCanvasKey.currentState?.refresh(); // ✅ NEW: prune + repaint
    });

    _closeBothPalettes();
    _savePainting();
  }

  void _showVerticalPalette() {
    if (!_isVerticalPaletteVisible &&
        _verticalPaletteController.status != AnimationStatus.completed) {
      try {
        setState(() {
          _isVerticalPaletteVisible = true;
        });
        _verticalPaletteController.forward();
      } catch (e) {
        debugPrint('Error showing vertical palette: $e');
      }
    }

    // Also show left palette
    if (!_isLeftPaletteVisible &&
        _leftPaletteController.status != AnimationStatus.completed) {
      try {
        setState(() {
          _isLeftPaletteVisible = true;
        });
        _leftPaletteController.forward();
      } catch (e) {
        debugPrint('Error showing left palette: $e');
      }
    }
  }

  void _setDefaultStamp() {
    if (stamps.isNotEmpty) {
      _selectedStampAsset = stamps[0];
    }
  }

  void _updateStampSize(double newSize) {
    setState(() {
      _stampSize = newSize;
    });
  }

  Future<ui.Image> loadWallpaper(String asset) async {
    final data = await rootBundle.load(asset);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Future<bool> _requestGalleryPermission() async {
    // The app only saves images that it creates itself.
    // No Gallery/Photos permission is required on Android.
    if (Platform.isAndroid) {
      return true;
    }

    if (Platform.isIOS) {
      final status = await Permission.photosAddOnly.request();

      debugPrint('Photos Add Only permission: $status');

      return status.isGranted || status.isLimited;
    }

    return false;
  }

  Future<void> _saveToGallery() async {
    try {
      if (!mounted) return;

      final hasPermission = await _requestGalleryPermission();

      if (!hasPermission) {
        if (!mounted) return;

        await _showSaveDialog(
          title: 'Permission Required',
          message:
              'We need permission to save your beautiful coloring to your gallery.',
          icon: Icons.photo_library_outlined,
          showSettings: true,
        );

        return;
      }

      await WidgetsBinding.instance.endOfFrame;

      final renderObject = _repaintKey.currentContext?.findRenderObject();

      if (renderObject == null) {
        debugPrint('Save error: RepaintBoundary not found');

        if (mounted) {
          await _showSaveDialog(
            title: 'Oops!',
            message: 'Could not find your coloring.',
            icon: Icons.error_outline,
          );
        }

        return;
      }

      if (renderObject is! RenderRepaintBoundary) {
        debugPrint('Save error: RenderObject is not RenderRepaintBoundary');

        if (mounted) {
          await _showSaveDialog(
            title: 'Oops!',
            message: 'Could not capture your coloring.',
            icon: Icons.error_outline,
          );
        }

        return;
      }

      final boundary = renderObject;

      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);

      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        image.dispose();

        if (mounted) {
          await _showSaveDialog(
            title: 'Oops!',
            message: 'Could not create the image.',
            icon: Icons.image_not_supported_outlined,
          );
        }

        return;
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      final result = await ImageGallerySaverPlus.saveImage(
        pngBytes,
        quality: 100,
        name: 'coloring_${DateTime.now().millisecondsSinceEpoch}',
      );

      image.dispose();

      debugPrint('Gallery save result: $result');

      final success = result is Map && result['isSuccess'] == true;

      if (!mounted) return;

      if (success) {
        await _showSaveDialog(
          title: 'Saved! 🎨',
          message: 'Your beautiful coloring has been saved to your gallery!',
          icon: Icons.check_circle_outline,
          success: true,
        );
      } else {
        await _showSaveDialog(
          title: 'Couldn\'t Save',
          message: 'We couldn\'t save your coloring. Please try again.',
          icon: Icons.error_outline,
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Save error: $e');
      debugPrint('$stackTrace');

      if (!mounted) return;

      await _showSaveDialog(
        title: 'Something Went Wrong',
        message: 'We couldn\'t save your coloring. Please try again.',
        icon: Icons.error_outline,
      );
    }
  }

  Future<void> _showSaveDialog({
    required String title,
    required String message,
    required IconData icon,
    bool success = false,
    bool showSettings = false,
  }) async {
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,

          insetPadding: const EdgeInsets.symmetric(
            horizontal: 28,
            vertical: 24,
          ),

          child: Container(
            width: double.infinity,

            padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),

            decoration: BoxDecoration(
              color: Colors.white,

              borderRadius: BorderRadius.circular(28),

              boxShadow: [
                BoxShadow(
                  blurRadius: 25,
                  spreadRadius: 2,
                  offset: const Offset(0, 10),
                  color: Colors.black.withOpacity(0.15),
                ),
              ],
            ),

            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  child: Image.asset(
                    'assets/images/app_icon.png',
                    height: AppSizeHeight.s30,
                    fit: BoxFit.contain,
                  ),
                ),

                SizedBox(height: AppSizeHeight.s5),

                Container(
                  width: AppSizeHeight.s12,
                  height: AppSizeHeight.s12,

                  decoration: BoxDecoration(
                    shape: BoxShape.circle,

                    color: success
                        ? Colors.green.withOpacity(0.12)
                        : Colors.orange.withOpacity(0.12),
                  ),

                  child: Icon(
                    icon,
                    size: AppSizeHeight.s12,

                    color: success ? Colors.green : Colors.orange,
                  ),
                ),

                SizedBox(height: AppSizeHeight.s2),

                Text(
                  title,
                  textAlign: TextAlign.center,

                  style: TextStyle(
                    fontSize: FontSize.s18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),

                SizedBox(height: AppSizeHeight.s2),

                Text(
                  message,
                  textAlign: TextAlign.center,

                  style: TextStyle(
                    fontSize: FontSize.s15,
                    height: 1.4,
                    color: Colors.black54,
                  ),
                ),

                SizedBox(height: AppSizeHeight.s2),

                if (showSettings)
                  SizedBox(
                    width: double.infinity,
                    height: AppSizeHeight.s30,

                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.of(dialogContext).pop();

                        await Future.delayed(const Duration(milliseconds: 250));

                        await openAppSettings();
                      },

                      icon: const Icon(Icons.settings_outlined),

                      label: Text(
                        'Open Settings',

                        style: TextStyle(
                          fontSize: FontSize.s16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),

                if (showSettings) SizedBox(height: AppSizeHeight.s2),

                SizedBox(
                  width: double.infinity,
                  height: AppSizeHeight.s10,

                  child: TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },

                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),

                    child: Text(
                      showSettings ? 'Cancel' : 'OK',

                      style: TextStyle(
                        fontSize: FontSize.s18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveThumbnail() async {
    try {
      final boundary =
          _repaintKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;

      final image = await boundary.toImage(pixelRatio: 1.5);

      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) return;

      await ThumbnailService().saveThumbnail(
        widget.image,
        byteData.buffer.asUint8List(),
      );

      final file = await ThumbnailService().getThumbnail(widget.image);

      debugPrint("Saved file exists: ${file != null}");

      debugPrint("Thumbnail saved.");
    } catch (e, st) {
      debugPrint("Thumbnail error: $e");
      debugPrintStack(stackTrace: st);
    }
  }

  Future<void> _savePainting() async {
    await _repository.savePainting(imageId: widget.image, regions: _regions);
  }

  Future<void> _load() async {
    // ✅ FIX: this used to run unguarded. A missing or malformed SVG threw an
    // unhandled exception, _regions stayed empty and the page sat on a
    // spinner forever with no explanation.
    try {
      final svgString = await rootBundle.loadString(widget.image);

      final parsed = parseSvgToRegions(svgString);

      //----------------------------
      // Load saved drawing
      //----------------------------
      final saved = DrawingRepository.loadDrawing(widget.image);

      for (final region in parsed) {
        final colorValue = saved[region.id];

        if (colorValue != null) {
          region.currentFillColor = Color(colorValue);
        }
      }
      await _repository.loadPainting(imageId: widget.image, regions: parsed);

      // ✅ FIX: bail out if the page was closed while loading (the old code
      // called setState on a disposed State).
      if (!mounted) return;

      setState(() {
        _regions = parsed;
        _loadFailed = false;
      });
    } catch (e, st) {
      debugPrint('Failed to load painting "${widget.image}": $e\n$st');

      if (!mounted) return;

      setState(() {
        _loadFailed = true;
      });
    }
    // ----- old version (kept for reference) -----
    // final svgString = await rootBundle.loadString(widget.image);
    //
    // final parsed = parseSvgToRegions(svgString);
    //
    // final saved = DrawingRepository.loadDrawing(widget.image);
    //
    // for (final region in parsed) {
    //   final colorValue = saved[region.id];
    //
    //   if (colorValue != null) {
    //     region.currentFillColor = Color(colorValue);
    //   }
    // }
    // await _repository.loadPainting(imageId: widget.image, regions: parsed);
    //
    // setState(() {
    //   _regions = parsed;
    // });
  }

  void _saveFillAction({
    required int regionIndex,
    required Color previousColor,
    required Color newColor,
    required StrokeStyle previousStyle,
    required StrokeStyle newStyle,
    required List<Stroke> previousStrokes,
  }) {
    final action = FillAction(
      regionIndex: regionIndex,
      previousColor: previousColor,
      newColor: newColor,
      previousStyle: previousStyle,
      newStyle: newStyle,
      previousStrokes: previousStrokes.map((s) => s.copyWith()).toList(),
    );
    _actionHistory.add(action);
    _redoStack.clear();
  }

  void _saveStrokeAction(int regionIndex, Stroke stroke) {
    final action = StrokeAction(regionIndex: regionIndex, stroke: stroke);
    _actionHistory.add(action);
    _redoStack.clear();
  }

  void _saveMagicAction({
    required int regionIndex,
    required Color previousColor,
    required StrokeStyle previousStyle,
    required List<Stroke> previousStrokes,
  }) {
    final action = MagicAction(
      regionIndex: regionIndex,
      previousColor: previousColor,
      previousStyle: previousStyle,
      previousStrokes: previousStrokes.map((s) => s.copyWith()).toList(),
    );
    _actionHistory.add(action);
    _redoStack.clear();
  }

  void _saveClearAction() {
    final previousStates = _regions
        .map(
          (region) => RegionState(
            color: region.currentFillColor,
            style: region.currentFillStyle,
            strokes: List<Stroke>.from(region.strokes),
          ),
        )
        .toList();

    final action = ClearAction(previousStates);
    _actionHistory.add(action);
    _redoStack.clear();
  }

  void _undo() {
    if (_actionHistory.isEmpty) return;

    final action = _actionHistory.removeLast();
    action.revert(_regions);
    _redoStack.add(action);

    setState(() {});
    _coloringCanvasKey.currentState?.refresh();
    _savePainting();
  }

  void _redoAction() {
    if (_redoStack.isEmpty) return;

    final action = _redoStack.removeLast();
    action.apply(_regions);
    _actionHistory.add(action);

    setState(() {});
    _coloringCanvasKey.currentState?.refresh();
    _savePainting();
  }

  void _isSelectedToolOpen() {
    setState(() {
      isSelectedToolOpen = !isSelectedToolOpen;
      if (isSelectedToolOpen && (_mode == BrushMode.eraser)) {
        if (_lastColoringTool != null) {
          _selectedTool = _lastColoringTool;
          _mode = _lastColoringTool!.mode;
          _selectedStyle = _lastColoringTool!.style;
          _selectedColor = _lastColoringColor;
        }
      }

      // Close color palette when opening tool palette
      if (isSelectedToolOpen) {
        isSelectedColorOpen = false;
      }
    });
  }

  void _isSelectedColorOpen() {
    setState(() {
      isSelectedColorOpen = !isSelectedColorOpen;

      // Close tool palette when opening color palette
      if (isSelectedColorOpen) {
        isSelectedToolOpen = false;
      }

      if (isSelectedColorOpen && _mode == BrushMode.eraser) {
        if (_lastColoringTool != null) {
          _selectedTool = _lastColoringTool;
          _mode = _lastColoringTool!.mode;
          _selectedStyle = _lastColoringTool!.style;
          _selectedColor = _lastColoringColor;
        }
      }
    });
  }

  /// ✅ NEW (Option B): a colour tapped straight in the tray.
  ///
  /// Nothing opens or closes here — the tray is always on screen — so the
  /// child taps a dot and the next stroke is that colour. Picking a colour
  /// also brings the colouring tool back when the eraser was in hand, which is
  /// exactly what opening the palette used to do.
  void _pickColorFromTray(Color colour) {
    setState(() {
      _selectedColor = colour;
      _lastColoringColor = colour;
      if (_mode == BrushMode.eraser && _lastColoringTool != null) {
        _selectedTool = _lastColoringTool;
        _mode = _lastColoringTool!.mode;
        _selectedStyle = _lastColoringTool!.style;
      }
    });
    // A pick from the tray also closes the full grid if it happens to be open.
    _closeBothPalettes();
  }

  /// ✅ NEW (Option B): the tray's eraser button — the same thing the rail's
  /// eraser button does.
  void _selectEraserFromTray() {
    setState(() {
      _mode = BrushMode.eraser;
    });
    _closeBothPalettes();
  }

  void _selectTool(SelectedTool tool) {
    setState(() {
      _selectedTool = tool;
      _mode = tool.mode;
      _selectedStyle = tool.style;

      isWallPaper = (tool.type == ToolType.wallpaper);

      if (tool.type == ToolType.fill ||
          tool.type == ToolType.freehand ||
          tool.type == ToolType.pencil ||
          tool.type == ToolType.glitter) {
        _lastColoringTool = tool;
        _lastColoringColor = _selectedColor;
      }

      _closeBothPalettes();

      if (tool.type == ToolType.stamp && _selectedStampAsset == null) {
        _setDefaultStamp();
      }
    });
  }

  Future<void> _loadWallpaper() async {
    final wallpaper = await loadWallpaper(selectedPatternImage);
    setState(() {
      _selectedWallpaper = wallpaper;
    });
  }

  Future<void> _confirmClose() async {
    // final shouldClose = await showDialog<bool>(
    //   context: context,
    //   barrierDismissible: false,
    //   builder: (dialogContext) {
    //     return AlertDialog(
    //       backgroundColor: ColorManager.lightPrimary,
    //       content: Lottie.asset(
    //         'assets/json/close.json',
    //         width: AppSizeWidth.s25,
    //         height: AppSizeHeight.s25,
    //       ),
    //       actions: [
    //         Row(
    //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //           children: [
    //             ElevatedButton(
    //               onPressed: () {
    //                 Navigator.of(dialogContext).pop(false);
    //               },
    //               style: ElevatedButton.styleFrom(
    //                 backgroundColor: ColorManager.primary,
    //                 foregroundColor: ColorManager.white,
    //               ),
    //               child: Text(
    //                 'No',
    //                 style: TextStyle(
    //                   color: ColorManager.white,
    //                   fontSize: FontSize.s16,
    //                 ),
    //               ),
    //             ),
    //             ElevatedButton(
    //               onPressed: () {
    //                 Navigator.of(dialogContext).pop(true);
    //               },
    //               style: ElevatedButton.styleFrom(
    //                 backgroundColor: ColorManager.primary,
    //                 foregroundColor: ColorManager.white,
    //               ),
    //               child: Text(
    //                 'Yes',
    //                 style: TextStyle(
    //                   color: ColorManager.white,
    //                   fontSize: FontSize.s16,
    //                 ),
    //               ),
    //             ),
    //           ],
    //         ),
    //       ],
    //     );
    //   },
    // );

    // if (shouldClose != true || !mounted) {
    //   return;
    // }

    // ✅ FIX: _confirmClose() is wired to both the close button and the
    // system back gesture, and it awaits a thumbnail capture — a quick second
    // trigger used to run it twice and pop two routes (painting + gallery).
    if (_isClosing) return;
    _isClosing = true;

    try {
      // Only save when user confirms Yes
      await _saveThumbnail();
      await InterstitialAdService.instance.maybeShowOnColoringExit();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      _isClosing = false;
    }
    // ----- old version (kept for reference) -----
    // await _saveThumbnail();
    // await InterstitialAdService.instance.maybeShowOnColoringExit();
    // if (mounted) {
    //   Navigator.of(context).pop();
    // }
  }

  @override
  Widget build(BuildContext context) {
    if (_regions.isEmpty) {
      // ✅ NEW: a real error state with a retry, instead of a spinner that
      // never resolves when the artwork fails to load.
      if (_loadFailed) {
        return Scaffold(
          backgroundColor: ColorManager.lightPrimary,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.image_not_supported_outlined,
                    size: 64,
                    color: Colors.orange,
                  ),
                  SizedBox(height: AppSizeHeight.s3),
                  Text(
                    'Could not open this drawing',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: FontSize.s18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: AppSizeHeight.s2),
                  Text(
                    'Please check your connection or try another drawing.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: FontSize.s15,
                      color: Colors.black54,
                    ),
                  ),
                  SizedBox(height: AppSizeHeight.s3),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _loadFailed = false;
                      });
                      _load();
                    },
                    child: const Text('Try again'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: const Text('Back'),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        await _confirmClose();
      },
      child: Scaffold(
        backgroundColor: ColorManager.lightPrimary,
        // ✅ RESTORED (round 5): the app's ORIGINAL arrangement — the canvas
        // fills the screen and the palettes float on top of it, exactly the
        // way the app was first built. The drawing is stretched to fill the
        // screen (ArtFit.fill), which is what it always did.
        // ----- old version (kept for reference) -----
        // body: LayoutBuilder(builder: (context, constraints) {
        //   return SafeArea(child: Row([actionRail, Expanded(canvas),
        //     ?panel, toolRail])); })          // the round-3/4 docked layouts
        // ✅ CHANGED (Option B, round 7): the app's own arrangement is kept —
        // the canvas fills the picture area and the two rails float over it —
        // and exactly ONE thing moves: the colour panel. It is no longer a
        // panel that covers the drawing; the colours now live in a tray along
        // the bottom of the screen (its own strip, always visible).
        // ----- old version (kept for reference) -----
        // Round 5 had one Stack for the whole screen, with the palette
        // floating over the picture:
        //   body: Stack(fit: StackFit.expand,
        //     children: [canvas, colourPanel, rightRail, leftRail]),
        // The Option C "Coloring Book" build() is parked in full at the
        // bottom of this class.
        body: Column(
          children: [
            // The picture: the round-5 Stack, now bounded by the tray below
            // instead of by the bottom of the screen.
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  RepaintBoundary(
                    key: _repaintKey,
                    child: ColoringCanvas(
                      selectedWallpaperAsset: selectedPatternImage,
                      selectedStampAsset:
                          _selectedStampAsset ??
                          (stamps.isNotEmpty ? stamps[0] : null),
                      regions: _regions,
                      brushMode: _mode,
                      key: _coloringCanvasKey,
                      selectedColor: _selectedColor,
                      selectedStyle: _selectedStyle,
                      selectedWallpaper: _selectedWallpaper,
                      onColoringAction: _handleColoringAction,
                      stampSize: _stampSize,
                      // ✅ NEW: the painting fills the whole screen.
                      fit: ArtFit.fill,
                      // The S / M / L feature stays wired; medium == the original
                      // brush width, so nothing changes unless a control is added.
                      brushScale: _brushSize.factor,
                      onPaintingStarted:
                          (_mode == BrushMode.freehand ||
                              _mode == BrushMode.eraser)
                          ? () {
                              _hideVerticalPalette();
                              _closeBothPalettes();
                            }
                          : null,
                      onPaintingEnded:
                          (_mode == BrushMode.freehand ||
                              _mode == BrushMode.eraser ||
                              _mode == BrushMode.stamp)
                          ? _handlePaintingEnded
                          : null,
                    ),
                  ),

                  // The full colour grid, still floating over the drawing and
                  // still opened from the rails and from the tray's ＋ — but it can
                  // only ever cover the picture, never the tray below it.
                  isSelectedColorOpen
                      ? Positioned(
                          top: 0,
                          right: AppSizeWidth.s15,
                          left: AppSizeWidth.s10,
                          child: Center(
                            child: Container(
                              margin: EdgeInsets.symmetric(
                                vertical: AppSizeHeight.s2,
                                horizontal: AppSizeHeight.s1,
                              ),
                              decoration: BoxDecoration(
                                color: ColorManager.darkPrimary,
                                border: Border(
                                  top: BorderSide(
                                    color: ColorManager.darkPrimary,
                                    width: AppSizeHeight.s0_5,
                                  ),
                                  left: BorderSide(
                                    color: ColorManager.darkPrimary,
                                    width: AppSizeHeight.s0_5,
                                  ),
                                  bottom: BorderSide(
                                    color: ColorManager.darkPrimary,
                                    width: AppSizeHeight.s0_5,
                                  ),
                                ),
                                borderRadius: BorderRadius.all(
                                  Radius.circular(AppSizeWidth.s4),
                                ),
                              ),
                              // ✅ CHANGED (Option B): 96 % of the screen was
                              // fine while the panel had the whole screen; the
                              // tray now owns the bottom strip, so the panel is
                              // capped at what the picture area has left.
                              height: KidLayout.floatingPanelMaxHeight,
                              width: AppSizeWidth.s83,
                              child: _buildPaletteForMode(),
                            ),
                          ),
                        )
                      : Container(),

                  // The right tool rail, with the tool grid beside it.
                  // ✅ CHANGED (Option B): the tray has taken 20 % of the
                  // height, so this rail may shrink to the area it actually
                  // has instead of being clipped. On a screen where it already
                  // fits, nothing is scaled at all.
                  // ----- old version (kept for reference) -----
                  // Positioned(...original..., child: Row(),
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.topRight,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            isSelectedToolOpen
                                ? ToolPaletteWidget(
                                    isToolOpen: _isSelectedToolOpen,
                                    mode: _mode,
                                    selectedColor: _selectedColor,
                                    selectedStyle: _selectedStyle,
                                    selectedTool: _selectedTool,
                                    onModeChanged: (mode) =>
                                        setState(() => _mode = mode),
                                    onStyleChanged: (style) =>
                                        setState(() => _selectedStyle = style),
                                    onToolSelected: _selectTool,
                                    selectedStampAsset: _selectedStampAsset,
                                    stamps: stamps,
                                  )
                                : Container(),
                            AnimatedVerticalPalette(
                              animation: _verticalPaletteAnimation,
                              child: VerticalToolPaletteWidget(
                                selectedImage: selectedPatternImage,
                                isColorOpen: _isSelectedColorOpen,
                                isToolOpen: _isSelectedToolOpen,
                                selectedColor: _selectedColor,
                                selectedTool: _selectedTool,
                                selectedStampAsset: _selectedStampAsset,
                                brushMode: _mode,
                                stamps: stamps,
                                onEraserSelected: () {
                                  setState(() {
                                    _mode = BrushMode.eraser;
                                  });
                                  _closeBothPalettes();
                                },
                                onMagicSelected: () {
                                  setState(() {
                                    _mode = BrushMode.magic;

                                    _selectedTool = SelectedTool(
                                      mode: BrushMode.magic,
                                      style: StrokeStyle.solid,
                                      type: ToolType.magic,
                                    );
                                  });

                                  _closeBothPalettes();
                                },
                                // ✅ CHANGED (round 5): asks "Erase everything?" first —
                                // the only change to this rail.
                                onClearSelected: () {
                                  _confirmClearAll();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // The left action rail: close, undo, redo, save.
                  // ✅ CHANGED (Option B): the tray has taken 20 % of the
                  // height, so this rail may shrink to the area it actually
                  // has instead of being clipped. On a screen where it already
                  // fits, nothing is scaled at all.
                  // ----- old version (kept for reference) -----
                  // Positioned(...original..., child: VerticalActionToolsWidget(),
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: VerticalActionToolsWidget(
                          onUndo: _undo,
                          onSave: _saveToGallery,
                          redo: _redoAction,
                          animation: _leftPaletteAnimation,
                          onClose: () async {
                            await _confirmClose();
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ✅ NEW (Option B): the colour tray. It owns this strip, so
            // the drawing is never covered while a child picks a colour.
            KidColorTray(
              colors: ColorPaletteWidget.allSwatches,
              selectedColor: _selectedColor,
              onColorSelected: _pickColorFromTray,
              onMoreColors: _isSelectedColorOpen,
              onTools: _isSelectedToolOpen,
              onEraser: _selectEraserFromTray,
              onClear: _confirmClearAll,
              moreOpen: isSelectedColorOpen,
              toolsOpen: isSelectedToolOpen,
            ),
          ],
        ),
      ),
    );
  }

  // ----- the round-3 / round-4 docked layouts (kept for reference) -----
  // Round 4 replaced this with floating bubbles; round 5 went back to the
  // app's own original floating palettes in the build() above.
  //
  // Widget? _buildDockedPanel(Axis railsAxis, double screenW, double screenH) {
  //   ... a docked panel beside the canvas (round 3) ...
  // }
  // Widget? _buildSheet(double screenW, double screenH) {
  //   ... a bottom sheet holding the colour grid / stamps / tools (round 4) ...
  // }

  Widget _buildPaletteForMode() {
    if (_selectedTool?.type == ToolType.wallpaper) {
      return PatternPaletteWidget(
        selectedImage: selectedPatternImage,
        onImageSelected: (path) async {
          final wallpaper = await loadWallpaper(path);
          setState(() {
            selectedPatternImage = path;
            _selectedWallpaper = wallpaper;
            isSelectedColorOpen = false;
            isSelectedToolOpen = false;
          });
        },
        isImageChanged: _closeBothPalettes,
      );
    }

    if (_selectedTool?.type == ToolType.stamp) {
      final currentStamp =
          _selectedStampAsset ?? (stamps.isNotEmpty ? stamps[0] : null);
      return StampPaletteWidget(
        selectedImage: currentStamp ?? '',
        onImageSelected: (stampPath) async {
          setState(() {
            _selectedStampAsset = stampPath;
            isSelectedColorOpen = false;
            isSelectedToolOpen = false;
          });
        },
        isImageChanged: _closeBothPalettes,
        stampSize: _stampSize,
        onStampSizeChanged: _updateStampSize,
        stamps: stamps,
      );
    }

    if (_mode == BrushMode.eraser) {
      return const SizedBox.shrink();
    }

    if (_mode == BrushMode.magic) {
      return ColorPaletteWidget(
        isColorChanged: _closeBothPalettes,
        selectedColor: _lastColoringColor,
        onColorSelected: (c) {
          setState(() {
            _selectedColor = c;
            _lastColoringColor = c;
            isSelectedColorOpen = false;
            isSelectedToolOpen = false;
          });
        },
        toolType: _selectedTool?.type,
      );
    }

    return ColorPaletteWidget(
      isColorChanged: _closeBothPalettes,
      selectedColor: _lastColoringColor,
      onColorSelected: (c) {
        setState(() {
          _selectedColor = c;
          _lastColoringColor = c;
          isSelectedColorOpen = false;
          isSelectedToolOpen = false;
        });
      },
      toolType: _selectedTool?.type,
    );
  }
  // ===========================================================================
  // PARKED — Option C, "Coloring Book" (commit c9b754a; this was the live
  // layout on main until Option B replaced it). Kept here, commented, so this
  // one file can be switched back: un-comment this block, drop the Column and
  // the tray from build() above, and put back three imports —
  //   import 'dart:math' as math;
  //   import 'package:flutter_svg/flutter_svg.dart';
  //   import 'widgets/kid_paint_controls.dart';
  // The fan maths it uses (fanAnchor / fanDotOffset / fanArcFor /
  // fanDotSizeFor) is still in kid_layout.dart, and its widgets are still in
  // widgets/kid_paint_controls.dart with their own passing tests.
  // ===========================================================================

  // --- was a top-level declaration, just above the class ---
  // /// ✅ NEW (kid-ui round 6 — Option C): what is covering the picture right now.
  // /// One value, so two open panels can never fight over the screen.
  // enum _KidPanel {
  //   /// Nothing — the picture is clean.
  //   none,
  //
  //   /// The colours fanning out of the crayon bubble.
  //   colorFan,
  //
  //   /// The tools fanning out of the tool bubble.
  //   toolFan,
  //
  //   /// The grid sheet (all colours / stamps / patterns / tools) sliding up.
  //   grid,
  // }

  // --- was the live build() of the page ---
  //   Widget build(BuildContext context) {
  //     if (_regions.isEmpty) {
  //       // ✅ NEW: a real error state with a retry, instead of a spinner that
  //       // never resolves when the artwork fails to load.
  //       if (_loadFailed) {
  //         return Scaffold(
  //           backgroundColor: ColorManager.lightPrimary,
  //           body: Center(
  //             child: Padding(
  //               padding: const EdgeInsets.all(24),
  //               child: Column(
  //                 mainAxisSize: MainAxisSize.min,
  //                 children: [
  //                   const Icon(
  //                     Icons.image_not_supported_outlined,
  //                     size: 64,
  //                     color: Colors.orange,
  //                   ),
  //                   SizedBox(height: AppSizeHeight.s3),
  //                   Text(
  //                     'Could not open this drawing',
  //                     textAlign: TextAlign.center,
  //                     style: TextStyle(
  //                       fontSize: FontSize.s18,
  //                       fontWeight: FontWeight.w700,
  //                       color: Colors.black87,
  //                     ),
  //                   ),
  //                   SizedBox(height: AppSizeHeight.s2),
  //                   Text(
  //                     'Please check your connection or try another drawing.',
  //                     textAlign: TextAlign.center,
  //                     style: TextStyle(
  //                       fontSize: FontSize.s15,
  //                       color: Colors.black54,
  //                     ),
  //                   ),
  //                   SizedBox(height: AppSizeHeight.s3),
  //                   ElevatedButton(
  //                     onPressed: () {
  //                       setState(() {
  //                         _loadFailed = false;
  //                       });
  //                       _load();
  //                     },
  //                     child: const Text('Try again'),
  //                   ),
  //                   TextButton(
  //                     onPressed: () => Navigator.of(context).maybePop(),
  //                     child: const Text('Back'),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //         );
  //       }
  //
  //       return const Scaffold(body: Center(child: CircularProgressIndicator()));
  //     }
  //
  //     return PopScope(
  //       canPop: false,
  //       onPopInvokedWithResult: (didPop, result) async {
  //         if (didPop) return;
  //
  //         await _confirmClose();
  //       },
  //       child: Scaffold(
  //         backgroundColor: ColorManager.lightPrimary,
  //         // ✅ NEW (kid-ui round 6 — Option C, the "Coloring Book" layout): the
  //         // picture is the whole screen and the controls are two bubbles.
  //         //
  //         //    picture = 100 % of the screen, never covered while choosing
  //         //    bottom right : crayon bubble  -> the colours fan out around it
  //         //    above it     : tool bubble    -> fill / brush / eraser / fun / clear
  //         //    bottom left  : undo (+ redo when there is something to redo)
  //         //    top left     : home          top right : save
  //         //
  //         // ----- old version (kept for reference) -----
  //         // body: Stack(fit: StackFit.expand, children: [
  //         //   canvas,
  //         //   Positioned colour panel (96 % x 83 %) when isSelectedColorOpen,
  //         //   Positioned(top:0,right:0) Row[ToolPaletteWidget, AnimatedVertical
  //         //     Palette(VerticalToolPaletteWidget)],        // the right rail
  //         //   Positioned(left:0,top:0) VerticalActionToolsWidget,  // the left rail
  //         // ]);
  //         body: LayoutBuilder(
  //           builder: (context, constraints) {
  //             final size = Size(constraints.maxWidth, constraints.maxHeight);
  //             final margin = KidLayout.fanMargin;
  //             final crayon = KidLayout.crayonBubbleSize;
  //             final bubble = KidLayout.bubbleSize;
  //
  //             return Stack(
  //               fit: StackFit.expand,
  //               children: [
  //                 // 1. The picture — the whole screen.
  //                 RepaintBoundary(
  //                   key: _repaintKey,
  //                   child: ColoringCanvas(
  //                     selectedWallpaperAsset: selectedPatternImage,
  //                     selectedStampAsset:
  //                         _selectedStampAsset ??
  //                         (stamps.isNotEmpty ? stamps[0] : null),
  //                     regions: _regions,
  //                     brushMode: _mode,
  //                     key: _coloringCanvasKey,
  //                     selectedColor: _selectedColor,
  //                     selectedStyle: _selectedStyle,
  //                     selectedWallpaper: _selectedWallpaper,
  //                     onColoringAction: _handleColoringAction,
  //                     stampSize: _stampSize,
  //                     fit: ArtFit.fill,
  //                     brushScale: _brushSize.factor,
  //                     onPaintingStarted:
  //                         (_mode == BrushMode.freehand ||
  //                             _mode == BrushMode.eraser)
  //                         ? () {
  //                             // ✅ round 6: whatever is open closes as soon as a
  //                             // stroke begins, so the child draws on a clear
  //                             // picture.
  //                             _hideVerticalPalette();
  //                           }
  //                         : null,
  //                     onPaintingEnded:
  //                         (_mode == BrushMode.freehand ||
  //                             _mode == BrushMode.eraser ||
  //                             _mode == BrushMode.stamp)
  //                         ? _handlePaintingEnded
  //                         : null,
  //                   ),
  //                 ),
  //
  //                 // 2. The colour fan: opens around the crayon bubble.
  //                 KidFan(
  //                   open: _panel == _KidPanel.colorFan,
  //                   anchor: Alignment.bottomRight,
  //                   items: _buildColorFanItems(),
  //                 ),
  //
  //                 // 3. The tool fan: opens around the tool bubble.
  //                 KidFan(
  //                   open: _panel == _KidPanel.toolFan,
  //                   anchor: Alignment.bottomRight,
  //                   outerCount: 5,
  //                   items: _buildToolFanItems(),
  //                 ),
  //
  //                 // 4. The full grid (78 colours / stamps / patterns / tools),
  //                 //    as a sheet that slides up and closes on a pick.
  //                 ?_buildGridSheet(size),
  //
  //                 // 5. The two bubbles a thumb rests on, bottom right.
  //                 Positioned(
  //                   right: margin,
  //                   bottom: margin,
  //                   child: KidCrayonBubble(
  //                     color: _selectedColor,
  //                     open: _panel == _KidPanel.colorFan,
  //                     onTap: () {
  //                       SoundService.playClick();
  //                       setState(() {
  //                         _panel = _panel == _KidPanel.colorFan
  //                             ? _KidPanel.none
  //                             : _KidPanel.colorFan;
  //                       });
  //                     },
  //                   ),
  //                 ),
  //                 Positioned(
  //                   right: margin + (crayon - bubble) / 2,
  //                   bottom: margin + crayon + KidLayout.fanMargin * 0.6,
  //                   child: KidRoundBubble(
  //                     key: const Key('kid_tool_bubble'),
  //                     size: bubble,
  //                     selected: _panel == _KidPanel.toolFan,
  //                     tooltip: 'Tools',
  //                     faceColor: const Color(0xFFFFE082),
  //                     onTap: () {
  //                       SoundService.playClick();
  //                       setState(() {
  //                         _panel = _panel == _KidPanel.toolFan
  //                             ? _KidPanel.none
  //                             : _KidPanel.toolFan;
  //                       });
  //                     },
  //                     child: _currentToolIcon(),
  //                   ),
  //                 ),
  //
  //                 // 6. Undo (and redo when there is something to redo), bottom
  //                 //    left, where the other thumb rests.
  //                 Positioned(
  //                   left: margin,
  //                   bottom: margin,
  //                   child: Row(
  //                     children: [
  //                       KidPill(
  //                         key: const Key('kid_undo_pill'),
  //                         label: 'Undo',
  //                         faceColor: const Color(0xFFFFD9B0),
  //                         enabled: _actionHistory.isNotEmpty,
  //                         onTap: () {
  //                           SoundService.playClick();
  //                           _undo();
  //                         },
  //                         icon: Image.asset(
  //                           ImageAssets.redo,
  //                           fit: BoxFit.contain,
  //                         ),
  //                       ),
  //                       SizedBox(width: KidLayout.fanMargin * 0.6),
  //                       if (_redoStack.isNotEmpty)
  //                         KidPill(
  //                           key: const Key('kid_redo_pill'),
  //                           label: 'Redo',
  //                           onTap: () {
  //                             SoundService.playClick();
  //                             _redoAction();
  //                           },
  //                           icon: Transform.flip(
  //                             flipX: true,
  //                             child: Image.asset(
  //                               ImageAssets.redo,
  //                               fit: BoxFit.contain,
  //                             ),
  //                           ),
  //                         ),
  //                     ],
  //                   ),
  //                 ),
  //
  //                 // 7. Home and Save, small and out of the thumbs' way.
  //                 Positioned(
  //                   left: margin,
  //                   top: margin,
  //                   child: Row(
  //                     children: [
  //                       KidRoundBubble(
  //                         key: const Key('kid_home_bubble'),
  //                         size: bubble * 0.86,
  //                         faceColor: const Color(0xFFDCE3E9),
  //                         tooltip: 'Leave the drawing',
  //                         onTap: () async {
  //                           await SoundService.playClick();
  //                           await _confirmClose();
  //                         },
  //                         child: Image.asset(
  //                           ImageAssets.close,
  //                           fit: BoxFit.contain,
  //                         ),
  //                       ),
  //                       SizedBox(width: KidLayout.fanMargin * 0.6),
  //                       // ✅ NEW: clear-everything lives here, far from the
  //                       // eraser, and still asks "Erase everything?" first.
  //                       KidRoundBubble(
  //                         key: const Key('kid_clear_bubble'),
  //                         size: bubble * 0.86,
  //                         faceColor: const Color(0xFFFFCDD2),
  //                         tooltip: 'Erase everything',
  //                         onTap: () {
  //                           SoundService.playClick();
  //                           _confirmClearAll();
  //                         },
  //                         child: SvgPicture.asset(
  //                           ImageAssets.delete,
  //                           fit: BoxFit.contain,
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //                 Positioned(
  //                   right: margin,
  //                   top: margin,
  //                   child: KidRoundBubble(
  //                     key: const Key('kid_save_bubble'),
  //                     size: bubble * 0.86,
  //                     faceColor: const Color(0xFFC8E6C9),
  //                     tooltip: 'Save to the phone',
  //                     onTap: () {
  //                       SoundService.playClick();
  //                       _saveToGallery();
  //                     },
  //                     child: Image.asset(ImageAssets.camera, fit: BoxFit.contain),
  //                   ),
  //                 ),
  //               ],
  //             );
  //           },
  //         ),
  //       ),
  //     );
  //   }
  //
  //   /// The icon on the tool bubble: whatever the child is painting with.
  //   Widget _currentToolIcon() {
  //     switch (_mode) {
  //       case BrushMode.fill:
  //         return SvgPicture.asset(ImageAssets.fill1, fit: BoxFit.contain);
  //       case BrushMode.eraser:
  //         return Image.asset(ImageAssets.eraser, fit: BoxFit.contain);
  //       case BrushMode.magic:
  //         return Image.asset(ImageAssets.magic, fit: BoxFit.contain);
  //       case BrushMode.stamp:
  //         return SvgPicture.asset(ImageAssets.stamp, fit: BoxFit.contain);
  //       case BrushMode.freehand:
  //         return SvgPicture.asset(ImageAssets.pencil1, fit: BoxFit.contain);
  //     }
  //   }
  //
  //   /// The colours in the fan: one big circle per colour family, in arc order,
  //   /// with a "＋" that opens the full 78-colour grid.
  //   List<KidFanItem> _buildColorFanItems() {
  //     final items = <KidFanItem>[
  //       for (final color in _stripColors)
  //         KidFanItem.color(
  //           color: color,
  //           selected: color == _selectedColor,
  //           onTap: () {
  //             SoundService.playClick();
  //             setState(() {
  //               _selectedColor = color;
  //               _lastColoringColor = color;
  //               _panel = _KidPanel.none;
  //             });
  //           },
  //         ),
  //     ];
  //
  //     items.add(
  //       KidFanItem.action(
  //         label: 'More colours',
  //         onTap: () {
  //           SoundService.playClick();
  //           // Closes the fan and opens the full grid sheet.
  //           setState(() => _panel = _KidPanel.none);
  //           _isSelectedColorOpen();
  //         },
  //         child: Icon(
  //           Icons.add_rounded,
  //           color: ColorManager.darkPrimary,
  //           size: KidLayout.fanDotSize * 0.6,
  //         ),
  //       ),
  //     );
  //
  //     return items;
  //   }
  //
  //   /// The tools in the fan — the four a child uses plus clear.
  //   List<KidFanItem> _buildToolFanItems() {
  //     KidFanItem tool({
  //       required BrushMode mode,
  //       required StrokeStyle style,
  //       required ToolType type,
  //       required String label,
  //       required Widget icon,
  //       Color? face,
  //     }) {
  //       return KidFanItem.action(
  //         label: label,
  //         onTap: () {
  //           SoundService.playClick();
  //           _selectTool(SelectedTool(mode: mode, style: style, type: type));
  //           setState(() => _panel = _KidPanel.none);
  //         },
  //         child: icon,
  //       );
  //     }
  //
  //     return [
  //       tool(
  //         mode: BrushMode.fill,
  //         style: StrokeStyle.solid,
  //         type: ToolType.fill,
  //         label: 'Fill a shape',
  //         icon: SvgPicture.asset(ImageAssets.fill1, fit: BoxFit.contain),
  //       ),
  //       tool(
  //         mode: BrushMode.freehand,
  //         style: StrokeStyle.solid,
  //         type: ToolType.freehand,
  //         label: 'Draw with a brush',
  //         icon: SvgPicture.asset(ImageAssets.pencil1, fit: BoxFit.contain),
  //       ),
  //       // The eraser is a mode, not a tool with a type (the same way the
  //       // original rail set it).
  //       KidFanItem.action(
  //         label: 'Eraser',
  //         onTap: () {
  //           SoundService.playClick();
  //           setState(() {
  //             _mode = BrushMode.eraser;
  //             _panel = _KidPanel.none;
  //           });
  //         },
  //         child: Image.asset(ImageAssets.eraser, fit: BoxFit.contain),
  //       ),
  //       KidFanItem.action(
  //         label: 'More fun',
  //         onTap: () {
  //           SoundService.playClick();
  //           // Closes the fan and opens the tool grid sheet.
  //           setState(() => _panel = _KidPanel.none);
  //           _isSelectedToolOpen();
  //         },
  //         child: const Icon(Icons.star_rounded, color: Color(0xFFF9A825)),
  //       ),
  //       KidFanItem.action(
  //         label: 'Erase everything',
  //         onTap: () {
  //           SoundService.playClick();
  //           _confirmClearAll();
  //         },
  //         child: SvgPicture.asset(ImageAssets.delete, fit: BoxFit.contain),
  //       ),
  //     ];
  //   }
  //
  //   /// The grid sheet: the full colour grid, the stamps, the patterns or the
  //   /// whole tool grid — whichever the child asked for with "＋" or "fun".
  //   Widget? _buildGridSheet(Size size) {
  //     final showSheet =
  //         _panel == _KidPanel.grid && (isSelectedColorOpen || isSelectedToolOpen);
  //     if (!showSheet) return null;
  //
  //     final content = isSelectedToolOpen
  //         ? ToolPaletteWidget(
  //             isToolOpen: _isSelectedToolOpen,
  //             mode: _mode,
  //             selectedColor: _selectedColor,
  //             selectedStyle: _selectedStyle,
  //             selectedTool: _selectedTool,
  //             onModeChanged: (mode) => setState(() => _mode = mode),
  //             onStyleChanged: (style) => setState(() => _selectedStyle = style),
  //             onToolSelected: _selectTool,
  //             selectedStampAsset: _selectedStampAsset,
  //             stamps: stamps,
  //           )
  //         : _buildPaletteForMode();
  //
  //     return Positioned(
  //       left: 0,
  //       right: 0,
  //       bottom: 0,
  //       child: Center(
  //         child: Container(
  //           width: math.min(
  //             KidLayout.swatchGridWidth + 2 * KidLayout.fanMargin,
  //             size.width * 0.78,
  //           ),
  //           height: math.min(
  //             size.height * 0.66,
  //             size.height - KidLayout.bubbleSize - 4 * KidLayout.fanMargin,
  //           ),
  //           margin: EdgeInsets.all(KidLayout.fanMargin * 0.5),
  //           clipBehavior: Clip.antiAlias,
  //           decoration: BoxDecoration(
  //             color: Colors.white.withValues(alpha: 0.97),
  //             borderRadius: BorderRadius.circular(KidLayout.buttonRadius * 1.4),
  //             boxShadow: [
  //               BoxShadow(
  //                 color: Colors.black.withValues(alpha: 0.24),
  //                 blurRadius: 18,
  //                 offset: const Offset(0, 6),
  //               ),
  //             ],
  //           ),
  //           child: Column(
  //             children: [
  //               GestureDetector(
  //                 onTap: _closeBothPalettes,
  //                 behavior: HitTestBehavior.opaque,
  //                 child: Container(
  //                   height: KidLayout.fanMargin * 1.8,
  //                   alignment: Alignment.center,
  //                   child: Container(
  //                     width: KidLayout.fanMargin * 3,
  //                     height: 5,
  //                     decoration: BoxDecoration(
  //                       color: Colors.black26,
  //                       borderRadius: BorderRadius.circular(4),
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //               Expanded(child: content),
  //             ],
  //           ),
  //         ),
  //       ),
  //     );
  //   }
  //
}
