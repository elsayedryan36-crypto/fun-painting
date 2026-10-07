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
import 'region.dart';
import 'svg_parser.dart';
import 'widgets/color_palette_widget.dart';
import 'widgets/kid_layout.dart';
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
  BrushSize _brushSize = BrushSize.medium;
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
        // ✅ CHANGED (kid-ui): the rails are DOCKED next to the canvas instead
        // of floating on top of it, so the drawing is never covered and every
        // shape stays tappable. The canvas gets all the space that is left,
        // and the screen shape decides whether the rails go down the sides
        // (wide screens — they sit in the empty bands beside a 16:9 artwork)
        // or into a single bottom bar (16:9 screens — no bands to use).
        body: LayoutBuilder(
          builder: (context, constraints) {
            final screenW = constraints.maxWidth;
            final screenH = constraints.maxHeight;

            final railsOnSides = KidLayout.preferSideRails(screenW, screenH);
            final railsAxis = railsOnSides ? Axis.vertical : Axis.horizontal;

            final canvas = RepaintBoundary(
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
                // ✅ NEW (kid-ui): the current S / M / L preset for new strokes.
                brushScale: _brushSize.factor,
                onPaintingStarted:
                    (_mode == BrushMode.freehand || _mode == BrushMode.eraser)
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
            );

            // ✅ CHANGED: SizeTransition instead of the old slide-and-fade
            // overlay — when a rail hides itself while the child draws, the
            // canvas really grows instead of leaving an empty gap.
            final actionRail = SizeTransition(
              axis: railsAxis,
              // Shrink towards the screen edge the rail is anchored to.
              alignment: railsOnSides
                  ? Alignment.topCenter
                  : Alignment.centerLeft,
              sizeFactor: _leftPaletteAnimation,
              child: VerticalActionToolsWidget(
                axis: railsAxis,
                onUndo: _undo,
                onSave: _saveToGallery,
                redo: _redoAction,
                animation: _leftPaletteAnimation,
                onClose: () async {
                  await _confirmClose();
                },
              ),
            );

            final toolRail = SizeTransition(
              axis: railsAxis,
              alignment: railsOnSides
                  ? Alignment.topCenter
                  : Alignment.centerRight,
              sizeFactor: _verticalPaletteAnimation,
              child: VerticalToolPaletteWidget(
                axis: railsAxis,
                selectedImage: selectedPatternImage,
                isColorOpen: _isSelectedColorOpen,
                isToolOpen: _isSelectedToolOpen,
                selectedColor: _selectedColor,
                selectedTool: _selectedTool,
                selectedStampAsset: _selectedStampAsset,
                brushMode: _mode,
                stamps: stamps,
                // ✅ NEW (kid-ui): S / M / L brush size buttons.
                brushSize: _brushSize,
                onBrushSizeChanged: (size) {
                  setState(() {
                    _brushSize = size;
                  });
                },
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
                onClearSelected: () {
                  _clearAllPaintingsAndStamps();
                },
              ),
            );

            final panel = _buildDockedPanel(railsAxis, screenW, screenH);

            return SafeArea(
              child: railsOnSides
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        actionRail,
                        Expanded(child: canvas),
                        ?panel,
                        toolRail,
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: canvas),
                        ?panel,
                        Row(children: [actionRail, const Spacer(), toolRail]),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }

  /// ✅ NEW: the tool grid / colour / stamp / pattern panel, docked as a
  /// sibling of the canvas so it shrinks the drawing area instead of covering
  /// it. Returns null when no panel is open.
  Widget? _buildDockedPanel(Axis railsAxis, double screenW, double screenH) {
    final showToolPanel = isSelectedToolOpen;
    final showPalette = isSelectedColorOpen;

    if (!showToolPanel && !showPalette) return null;

    final Widget content = showToolPanel
        ? ToolPaletteWidget(
            isToolOpen: _isSelectedToolOpen,
            mode: _mode,
            selectedColor: _selectedColor,
            selectedStyle: _selectedStyle,
            selectedTool: _selectedTool,
            onModeChanged: (mode) => setState(() => _mode = mode),
            onStyleChanged: (style) => setState(() => _selectedStyle = style),
            onToolSelected: _selectTool,
            selectedStampAsset: _selectedStampAsset,
            stamps: stamps,
          )
        : _buildPaletteForMode();

    final onSides = railsAxis == Axis.vertical;

    // ✅ NEW (kid-ui): the colour palette gets a panel wide enough for eight
    // kid-sized swatches per row; the other panels keep the slimmer one.
    final isColorPalette =
        showPalette &&
        _mode != BrushMode.eraser &&
        _selectedTool?.type != ToolType.wallpaper &&
        _selectedTool?.type != ToolType.stamp;
    // ----- old version (kept for reference) -----
    // width: onSides ? KidLayout.panelWidth(screenW) : null,
    final panelWidth = isColorPalette
        ? KidLayout.colorPanelWidth(screenW)
        : KidLayout.panelWidth(screenW);

    return Container(
      width: onSides ? panelWidth : null,
      height: onSides ? null : KidLayout.panelHeight(screenH),
      margin: const EdgeInsets.all(4),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: ColorManager.darkPrimary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: content,
    );
  }

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
}
