import 'dart:io';
import 'dart:ui' as ui;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
// ✅ NEW (kid-ui round 4): the floating bubbles over the full-screen canvas.
import 'widgets/kid_floating_controls.dart';
import 'widgets/kid_dialogs.dart';
// ✅ NEW (kid-ui round 3): one button size for both rails.
import 'region.dart';
import 'svg_parser.dart';
import 'widgets/color_palette_widget.dart';
import 'widgets/kid_layout.dart';
import 'widgets/pattern_palette_widget.dart';
import 'widgets/stamp_palette_widget.dart';
import 'widgets/tool_palette_widget.dart';
// SoundService (the button click) still lives with the old action rail.
import 'widgets/vertical_action_tools_widget.dart' show SoundService;

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

  /// ✅ NEW (kid-ui round 4): the bubbles fade while a stroke is drawn.
  bool _uiDimmed = false;

  /// ✅ NEW (kid-ui round 4): the painting fills the whole screen by default;
  /// the top bubble flips this to keep the artwork's own shape.
  ArtFit _artFit = ArtFit.fill;

  /// ✅ NEW (kid-ui round 4): one representative colour per palette family,
  /// for the always-visible strip along the bottom.
  static List<Color> get _stripColors => groupedPalette
      .map((g) => g.colors.length > 1 ? g.colors[1] : g.colors.first)
      .take(KidLayout.stripColors)
      .toList();

  /// ✅ NEW (kid-ui): the brush thickness the child picked — S / M / L. It is
  /// a multiplier handed to ColoringCanvas, which stamps it onto every new
  /// stroke, so it never resizes a line that is already on the page.
  BrushSize _brushSize = BrushSize.medium;
  // ✅ CHANGED (kid-ui round 4): the rails (and their slide animations) are
  // gone; the floating bubbles fade instead.
  // ----- old version (kept for reference) -----
  // late AnimationController _verticalPaletteController;
  // bool _isVerticalPaletteVisible = true;
  // late AnimationController _leftPaletteController;
  // bool _isLeftPaletteVisible = true;

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

    // ✅ CHANGED (kid-ui round 4): the rail slide animations are gone — the
    // floating bubbles fade instead (see _hideVerticalPalette).
    // ----- old version (kept for reference) -----
    // _verticalPaletteController = AnimationController(duration: ..., vsync: this);
    // _verticalPaletteAnimation = CurvedAnimation(parent: ..., curve: ...);
    // _leftPaletteController = AnimationController(...);
    // _leftPaletteAnimation = CurvedAnimation(...);
    // _verticalPaletteController.forward();
    // _leftPaletteController.forward();
  }

  @override
  void dispose() {
    // ----- old version (kept for reference) -----
    // _verticalPaletteController.dispose();
    // _leftPaletteController.dispose();
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

  /// ✅ CHANGED (kid-ui round 4): there are no rails to slide away any more —
  /// this now fades the floating bubbles out while the child is drawing.
  void _hideVerticalPalette() {
    setState(() {
      _uiDimmed = true;
    });

    // ----- old version (kept for reference) -----
    // if (_isVerticalPaletteVisible &&
    //     _verticalPaletteController.status != AnimationStatus.dismissed) {
    //   setState(() { _isVerticalPaletteVisible = false; });
    //   _verticalPaletteController.reverse();
    // }
    // if (_isLeftPaletteVisible &&
    //     _leftPaletteController.status != AnimationStatus.dismissed) {
    //   setState(() { _isLeftPaletteVisible = false; });
    //   _leftPaletteController.reverse();
    // }
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

  /// ✅ CHANGED (kid-ui round 4): brings the floating bubbles back (they were
  /// faded out by [_hideVerticalPalette] while the child drew).
  void _showVerticalPalette() {
    setState(() {
      _uiDimmed = false;
    });

    // ----- old version (kept for reference) -----
    // if (!_isVerticalPaletteVisible &&
    //     _verticalPaletteController.status != AnimationStatus.completed) {
    //   setState(() { _isVerticalPaletteVisible = true; });
    //   _verticalPaletteController.forward();
    // }
    // if (!_isLeftPaletteVisible && ...) { _leftPaletteController.forward(); }
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
                brushScale: _brushSize.factor,
                // ✅ NEW (kid-ui round 4): the painting fills the whole screen.
                fit: _artFit,
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
                    ? () {
                        _handlePaintingEnded();
                        if (_uiDimmed) setState(() => _uiDimmed = false);
                      }
                    : null,
              ),
            );

            final sheet = _buildSheet(screenW, screenH);

            // ✅ CHANGED (kid-ui round 4): NO rails and NO reserved strips. The
            // canvas is the whole screen and the controls float on top of it in
            // translucent bubbles, fading while the child draws. This is the
            // "the painting must fill the screen" layout.
            // ----- old version (kept for reference) -----
            // const railsAxis = Axis.vertical;   // docked side rails (round 3)
            // return SafeArea(child: KidRailMetrics(... Row[actionRail,
            //   Expanded(child: canvas), ?panel, toolRail] ...));
            final bubbles = AnimatedOpacity(
              opacity: _uiDimmed ? 0.22 : 1,
              duration: const Duration(milliseconds: 180),
              child: Stack(
                children: [
                  // Top-left bubble: leave, undo, redo, save, fill/fit, clear.
                  Positioned(
                    left: KidLayout.floatGap,
                    top: KidLayout.floatGap,
                    child: KidFloatCluster(
                      axis: Axis.horizontal,
                      children: [
                        KidFloatButton(
                          key: const Key('kid_close'),
                          label: 'Close',
                          faceColor: const Color(0xFFCFD8DC),
                          onTap: () async {
                            await SoundService.playClick();
                            await _confirmClose();
                          },
                          child: Image.asset(
                            ImageAssets.close,
                            fit: BoxFit.contain,
                          ),
                        ),
                        KidFloatButton(
                          key: const Key('kid_undo'),
                          label: 'Undo',
                          onTap: () {
                            SoundService.playClick();
                            _undo();
                          },
                          child: Image.asset(
                            ImageAssets.redo,
                            fit: BoxFit.contain,
                          ),
                        ),
                        KidFloatButton(
                          key: const Key('kid_redo'),
                          label: 'Redo',
                          onTap: () {
                            SoundService.playClick();
                            _redoAction();
                          },
                          child: Transform.flip(
                            flipX: true,
                            child: Image.asset(
                              ImageAssets.redo,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        KidFloatButton(
                          key: const Key('kid_save'),
                          label: 'Save',
                          faceColor: const Color(0xFFC8E6C9),
                          onTap: () {
                            SoundService.playClick();
                            _saveToGallery();
                          },
                          child: Image.asset(
                            ImageAssets.camera,
                            fit: BoxFit.contain,
                          ),
                        ),
                        // ✅ NEW: "fill the screen" / "keep the shape".
                        KidFloatButton(
                          key: const Key('kid_fit_toggle'),
                          label: _artFit == ArtFit.fill ? 'Fill' : 'Shape',
                          selected: _artFit == ArtFit.fill,
                          faceColor: const Color(0xFFFFE082),
                          tooltip: _artFit == ArtFit.fill
                              ? 'The painting fills the screen'
                              : 'The painting keeps its own shape',
                          onTap: () {
                            SoundService.playClick();
                            setState(() {
                              _artFit = _artFit == ArtFit.fill
                                  ? ArtFit.keepShape
                                  : ArtFit.fill;
                            });
                          },
                          child: Icon(
                            _artFit == ArtFit.fill
                                ? Icons.fullscreen_rounded
                                : Icons.aspect_ratio_rounded,
                            color: ColorManager.darkPrimary,
                          ),
                        ),
                        KidFloatButton(
                          key: const Key('kid_clear'),
                          label: 'Clear',
                          faceColor: const Color(0xFFFFCDD2),
                          onTap: () {
                            SoundService.playClick();
                            _confirmClearAll();
                          },
                          child: SvgPicture.asset(
                            ImageAssets.delete,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Right edge: the tools, with the S / M / L sizes under them.
                  Positioned(
                    right: KidLayout.floatGap,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: KidFloatCluster(
                        axis: Axis.vertical,
                        children: [
                          KidFloatButton(
                            key: const Key('kid_tool_brush'),
                            label: 'Brush',
                            selected: _selectedTool?.type == ToolType.freehand,
                            faceColor: const Color(0xFFFFE082),
                            onTap: () {
                              SoundService.playClick();
                              _selectTool(
                                SelectedTool(
                                  mode: BrushMode.freehand,
                                  style: StrokeStyle.solid,
                                  type: ToolType.freehand,
                                ),
                              );
                            },
                            child: SvgPicture.asset(
                              ImageAssets.pencil1,
                              fit: BoxFit.contain,
                            ),
                          ),
                          KidFloatButton(
                            key: const Key('kid_tool_fill'),
                            label: 'Fill',
                            selected:
                                _mode == BrushMode.fill &&
                                _selectedTool?.type == ToolType.fill,
                            faceColor: const Color(0xFFD9E9FF),
                            onTap: () {
                              SoundService.playClick();
                              _selectTool(
                                SelectedTool(
                                  mode: BrushMode.fill,
                                  style: StrokeStyle.solid,
                                  type: ToolType.fill,
                                ),
                              );
                            },
                            child: SvgPicture.asset(
                              ImageAssets.fill1,
                              fit: BoxFit.contain,
                            ),
                          ),
                          KidFloatButton(
                            key: const Key('kid_tool_magic'),
                            label: 'Magic',
                            selected: _mode == BrushMode.magic,
                            faceColor: const Color(0xFFEADCFB),
                            onTap: () {
                              SoundService.playClick();
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
                            child: Image.asset(
                              ImageAssets.magic,
                              fit: BoxFit.contain,
                            ),
                          ),
                          KidFloatButton(
                            key: const Key('kid_tool_eraser'),
                            label: 'Eraser',
                            selected: _mode == BrushMode.eraser,
                            faceColor: const Color(0xFFF8BBD0),
                            onTap: () {
                              SoundService.playClick();
                              setState(() => _mode = BrushMode.eraser);
                              _closeBothPalettes();
                            },
                            child: Image.asset(
                              ImageAssets.eraser,
                              fit: BoxFit.contain,
                            ),
                          ),
                          KidFloatButton(
                            key: const Key('kid_tool_stamp'),
                            label: 'Stamp',
                            selected: _mode == BrushMode.stamp,
                            faceColor: const Color(0xFFD7F0D0),
                            onTap: () {
                              SoundService.playClick();
                              _selectTool(
                                SelectedTool(
                                  mode: BrushMode.stamp,
                                  style: StrokeStyle.solid,
                                  type: ToolType.stamp,
                                ),
                              );
                              setState(() => isSelectedColorOpen = true);
                            },
                            child: SvgPicture.asset(
                              ImageAssets.stamp,
                              fit: BoxFit.contain,
                            ),
                          ),
                          KidFloatButton(
                            key: const Key('kid_tool_more'),
                            label: 'More',
                            selected: isSelectedToolOpen,
                            onTap: () {
                              SoundService.playClick();
                              _isSelectedToolOpen();
                            },
                            child: const Icon(Icons.more_horiz_rounded),
                          ),
                          KidSizeChips(
                            selected: _brushSize,
                            onChanged: (size) =>
                                setState(() => _brushSize = size),
                            previewColor: _selectedColor,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom: the always-visible colour strip.
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: KidLayout.floatGap,
                    child: Center(
                      child: KidColorStrip(
                        colors: _stripColors,
                        selectedColor: _selectedColor,
                        onColorSelected: (c) {
                          SoundService.playClick();
                          setState(() {
                            _selectedColor = c;
                            _lastColoringColor = c;
                          });
                        },
                        moreOpen: isSelectedColorOpen,
                        onMore: () {
                          SoundService.playClick();
                          _isSelectedColorOpen();
                        },
                      ),
                    ),
                  ),

                  // The full grid / stamps / patterns / tools, as a sheet.
                  ?sheet,
                ],
              ),
            );

            return SafeArea(
              // ✅ CHANGED (kid-ui round 4): the canvas IS the screen.
              minimum: EdgeInsets.zero,
              child: Stack(fit: StackFit.expand, children: [canvas, bubbles]),
            );
          },
        ),
      ),
    );
  }

  /// ✅ CHANGED (kid-ui round 4): the full colour grid / stamps / patterns /
  /// tools slide up as a **sheet over the bottom of the screen** instead of
  /// being docked beside the canvas — nothing is reserved while it is closed,
  /// and it hides itself the moment the child picks something.
  ///
  /// Returns null when no sheet is open.
  Widget? _buildSheet(double screenW, double screenH) {
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

    final isColorPalette =
        showPalette &&
        _mode != BrushMode.eraser &&
        _selectedTool?.type != ToolType.wallpaper &&
        _selectedTool?.type != ToolType.stamp;

    final width = isColorPalette
        ? math.min(
            KidLayout.swatchGridWidth + 2 * KidLayout.floatGap,
            screenW * 0.72,
          )
        : math.min(screenW * 0.6, 520.0);

    final height = math.min(
      isColorPalette ? screenH * 0.62 : screenH * 0.55,
      screenH - KidLayout.floatButtonSize - 3 * KidLayout.floatGap,
    );

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: IgnorePointer(
        ignoring: !(showToolPanel || showPalette),
        child: AnimatedSlide(
          offset: (showToolPanel || showPalette)
              ? Offset.zero
              : const Offset(0, 1.1),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: Center(
            child: Container(
              width: width,
              height: height,
              margin: EdgeInsets.all(KidLayout.floatGap * 0.6),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.97),
                borderRadius: BorderRadius.circular(
                  KidLayout.buttonRadius * 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Grab handle: tap it to close without picking anything.
                  GestureDetector(
                    onTap: _closeBothPalettes,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      height: KidLayout.floatGap * 1.6,
                      alignment: Alignment.center,
                      child: Container(
                        width: KidLayout.floatGap * 3,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  Expanded(child: content),
                ],
              ),
            ),
          ),
        ),
      ),
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
