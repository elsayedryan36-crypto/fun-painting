import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

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
import 'widgets/kid_dialogs.dart';
// ✅ NEW (kid-ui round 3): one button size for both rails.
import 'region.dart';
import 'svg_parser.dart';
import 'widgets/color_palette_widget.dart';
import 'widgets/kid_layout.dart';

import 'widgets/pattern_palette_widget.dart';
import 'widgets/stamp_palette_widget.dart';
import 'widgets/tool_palette_widget.dart';
// SoundService (the button click) still lives with the old action rail, and
// that file also keeps the original rails for reference.
import 'widgets/vertical_action_tools_widget.dart' show SoundService;
// ✅ NEW (kid-ui round 6 — Option C): the bubbles, pills and the colour fan.
import 'widgets/kid_paint_controls.dart';

/// ✅ NEW (kid-ui round 6 — Option C): what is covering the picture right now.
/// One value, so two open panels can never fight over the screen.
enum _KidPanel {
  /// Nothing — the picture is clean.
  none,

  /// The colours fanning out of the crayon bubble.
  colorFan,

  /// The tools fanning out of the tool bubble.
  toolFan,

  /// The grid sheet (all colours / stamps / patterns / tools) sliding up.
  grid,
}

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

  /// ✅ NEW (kid-ui round 6 — Option C): what is open on top of the picture.
  /// Exactly one thing at a time, and nothing is open by default.
  _KidPanel _panel = _KidPanel.none;

  /// ✅ NEW (round 6): the colours in the fan — one representative per family,
  /// taken from the same palette the app has always used, so the fan and the
  /// full grid never disagree.
  static List<Color> get _stripColors => groupedPalette
      .map((g) => g.colors.length > 1 ? g.colors[1] : g.colors.first)
      .take(KidLayout.fanColorCount)
      .toList();

  /// ✅ NEW (kid-ui): the brush thickness the child picked — S / M / L. It is
  /// a multiplier handed to ColoringCanvas, which stamps it onto every new
  /// stroke, so it never resizes a line that is already on the page.
  // The original UI has no size control, so this is fixed at the app's
  // original brush width (medium == 1.0). Make it non-final and add a control
  // to bring the S / M / L buttons back.
  final BrushSize _brushSize = BrushSize.medium;
  // ✅ CHANGED (round 6): the rails are gone; the picture is never covered.
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

    // ✅ CHANGED (round 6): the rails (and their slide animations) are gone —
    // the picture is never covered by a rail any more, so nothing slides.
    // ----- old version (kept for reference) -----
    // _verticalPaletteController = AnimationController(...);
    // _verticalPaletteAnimation = CurvedAnimation(...);
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

  /// ✅ CHANGED (round 6): there are no rails to slide away any more. When the
  /// child starts drawing, whatever panel is open simply closes.
  void _hideVerticalPalette() {
    if (_panel != _KidPanel.none || isSelectedColorOpen || isSelectedToolOpen) {
      _closeBothPalettes();
    }

    // ----- old version (kept for reference) -----
    // if (_isVerticalPaletteVisible && ...) { _verticalPaletteController.reverse(); }
    // if (_isLeftPaletteVisible && ...)     { _leftPaletteController.reverse(); }
  }

  void _handlePaintingEnded() {
    setState(() {
      // _isPainting = false;
    });
    // ✅ CHANGED (round 6): the bubbles never left, so there is nothing to
    // bring back.
    // ----- old version (kept for reference) -----
    // _showVerticalPalette();
  }

  void _closeBothPalettes() {
    setState(() {
      // ✅ NEW (round 6): the colour / tool fans close with everything else.
      _panel = _KidPanel.none;
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

  // ✅ CHANGED (round 6): nothing to slide back in — the bubbles never leave
  // the screen, so there is no "show the rail again" step.
  // ----- old version (kept for reference) -----
  // void _showVerticalPalette() {
  //   if (!_isVerticalPaletteVisible ...) { _verticalPaletteController.forward(); }
  //   if (!_isLeftPaletteVisible && ...) { _leftPaletteController.forward(); }
  // }

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

  /// ✅ CHANGED (round 6): opened from the tool fan's "fun" circle (or from the
  /// old rail, kept working for anything that still calls it).
  void _isSelectedToolOpen() {
    setState(() {
      isSelectedToolOpen = !isSelectedToolOpen;
      if (isSelectedToolOpen) _panel = _KidPanel.grid;
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

  /// ✅ CHANGED (round 6): opened from the colour fan's "＋" circle.
  void _isSelectedColorOpen() {
    setState(() {
      isSelectedColorOpen = !isSelectedColorOpen;
      if (isSelectedColorOpen) _panel = _KidPanel.grid;

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
        // ✅ NEW (kid-ui round 6 — Option C, the "Coloring Book" layout): the
        // picture is the whole screen and the controls are two bubbles.
        //
        //    picture = 100 % of the screen, never covered while choosing
        //    bottom right : crayon bubble  -> the colours fan out around it
        //    above it     : tool bubble    -> fill / brush / eraser / fun / clear
        //    bottom left  : undo (+ redo when there is something to redo)
        //    top left     : home          top right : save
        //
        // ----- old version (kept for reference) -----
        // body: Stack(fit: StackFit.expand, children: [
        //   canvas,
        //   Positioned colour panel (96 % x 83 %) when isSelectedColorOpen,
        //   Positioned(top:0,right:0) Row[ToolPaletteWidget, AnimatedVertical
        //     Palette(VerticalToolPaletteWidget)],        // the right rail
        //   Positioned(left:0,top:0) VerticalActionToolsWidget,  // the left rail
        // ]);
        body: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            final margin = KidLayout.fanMargin;
            final crayon = KidLayout.crayonBubbleSize;
            final bubble = KidLayout.bubbleSize;

            return Stack(
              fit: StackFit.expand,
              children: [
                // 1. The picture — the whole screen.
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
                    fit: ArtFit.fill,
                    brushScale: _brushSize.factor,
                    onPaintingStarted:
                        (_mode == BrushMode.freehand ||
                            _mode == BrushMode.eraser)
                        ? () {
                            // ✅ round 6: whatever is open closes as soon as a
                            // stroke begins, so the child draws on a clear
                            // picture.
                            _hideVerticalPalette();
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

                // 2. The colour fan: opens around the crayon bubble.
                KidFan(
                  open: _panel == _KidPanel.colorFan,
                  anchor: Alignment.bottomRight,
                  items: _buildColorFanItems(),
                ),

                // 3. The tool fan: opens around the tool bubble.
                KidFan(
                  open: _panel == _KidPanel.toolFan,
                  anchor: Alignment.bottomRight,
                  outerCount: 5,
                  items: _buildToolFanItems(),
                ),

                // 4. The full grid (78 colours / stamps / patterns / tools),
                //    as a sheet that slides up and closes on a pick.
                ?_buildGridSheet(size),

                // 5. The two bubbles a thumb rests on, bottom right.
                Positioned(
                  right: margin,
                  bottom: margin,
                  child: KidCrayonBubble(
                    color: _selectedColor,
                    open: _panel == _KidPanel.colorFan,
                    onTap: () {
                      SoundService.playClick();
                      setState(() {
                        _panel = _panel == _KidPanel.colorFan
                            ? _KidPanel.none
                            : _KidPanel.colorFan;
                      });
                    },
                  ),
                ),
                Positioned(
                  right: margin + (crayon - bubble) / 2,
                  bottom: margin + crayon + KidLayout.fanMargin * 0.6,
                  child: KidRoundBubble(
                    key: const Key('kid_tool_bubble'),
                    size: bubble,
                    selected: _panel == _KidPanel.toolFan,
                    tooltip: 'Tools',
                    faceColor: const Color(0xFFFFE082),
                    onTap: () {
                      SoundService.playClick();
                      setState(() {
                        _panel = _panel == _KidPanel.toolFan
                            ? _KidPanel.none
                            : _KidPanel.toolFan;
                      });
                    },
                    child: _currentToolIcon(),
                  ),
                ),

                // 6. Undo (and redo when there is something to redo), bottom
                //    left, where the other thumb rests.
                Positioned(
                  left: margin,
                  bottom: margin,
                  child: Row(
                    children: [
                      KidPill(
                        key: const Key('kid_undo_pill'),
                        label: 'Undo',
                        faceColor: const Color(0xFFFFD9B0),
                        enabled: _actionHistory.isNotEmpty,
                        onTap: () {
                          SoundService.playClick();
                          _undo();
                        },
                        icon: Image.asset(
                          ImageAssets.redo,
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(width: KidLayout.fanMargin * 0.6),
                      if (_redoStack.isNotEmpty)
                        KidPill(
                          key: const Key('kid_redo_pill'),
                          label: 'Redo',
                          onTap: () {
                            SoundService.playClick();
                            _redoAction();
                          },
                          icon: Transform.flip(
                            flipX: true,
                            child: Image.asset(
                              ImageAssets.redo,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // 7. Home and Save, small and out of the thumbs' way.
                Positioned(
                  left: margin,
                  top: margin,
                  child: Row(
                    children: [
                      KidRoundBubble(
                        key: const Key('kid_home_bubble'),
                        size: bubble * 0.86,
                        faceColor: const Color(0xFFDCE3E9),
                        tooltip: 'Leave the drawing',
                        onTap: () async {
                          await SoundService.playClick();
                          await _confirmClose();
                        },
                        child: Image.asset(
                          ImageAssets.close,
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(width: KidLayout.fanMargin * 0.6),
                      // ✅ NEW: clear-everything lives here, far from the
                      // eraser, and still asks "Erase everything?" first.
                      KidRoundBubble(
                        key: const Key('kid_clear_bubble'),
                        size: bubble * 0.86,
                        faceColor: const Color(0xFFFFCDD2),
                        tooltip: 'Erase everything',
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
                Positioned(
                  right: margin,
                  top: margin,
                  child: KidRoundBubble(
                    key: const Key('kid_save_bubble'),
                    size: bubble * 0.86,
                    faceColor: const Color(0xFFC8E6C9),
                    tooltip: 'Save to the phone',
                    onTap: () {
                      SoundService.playClick();
                      _saveToGallery();
                    },
                    child: Image.asset(ImageAssets.camera, fit: BoxFit.contain),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// The icon on the tool bubble: whatever the child is painting with.
  Widget _currentToolIcon() {
    switch (_mode) {
      case BrushMode.fill:
        return SvgPicture.asset(ImageAssets.fill1, fit: BoxFit.contain);
      case BrushMode.eraser:
        return Image.asset(ImageAssets.eraser, fit: BoxFit.contain);
      case BrushMode.magic:
        return Image.asset(ImageAssets.magic, fit: BoxFit.contain);
      case BrushMode.stamp:
        return SvgPicture.asset(ImageAssets.stamp, fit: BoxFit.contain);
      case BrushMode.freehand:
        return SvgPicture.asset(ImageAssets.pencil1, fit: BoxFit.contain);
    }
  }

  /// The colours in the fan: one big circle per colour family, in arc order,
  /// with a "＋" that opens the full 78-colour grid.
  List<KidFanItem> _buildColorFanItems() {
    final items = <KidFanItem>[
      for (final color in _stripColors)
        KidFanItem.color(
          color: color,
          selected: color == _selectedColor,
          onTap: () {
            SoundService.playClick();
            setState(() {
              _selectedColor = color;
              _lastColoringColor = color;
              _panel = _KidPanel.none;
            });
          },
        ),
    ];

    items.add(
      KidFanItem.action(
        label: 'More colours',
        onTap: () {
          SoundService.playClick();
          // Closes the fan and opens the full grid sheet.
          setState(() => _panel = _KidPanel.none);
          _isSelectedColorOpen();
        },
        child: Icon(
          Icons.add_rounded,
          color: ColorManager.darkPrimary,
          size: KidLayout.fanDotSize * 0.6,
        ),
      ),
    );

    return items;
  }

  /// The tools in the fan — the four a child uses plus clear.
  List<KidFanItem> _buildToolFanItems() {
    KidFanItem tool({
      required BrushMode mode,
      required StrokeStyle style,
      required ToolType type,
      required String label,
      required Widget icon,
      Color? face,
    }) {
      return KidFanItem.action(
        label: label,
        onTap: () {
          SoundService.playClick();
          _selectTool(SelectedTool(mode: mode, style: style, type: type));
          setState(() => _panel = _KidPanel.none);
        },
        child: icon,
      );
    }

    return [
      tool(
        mode: BrushMode.fill,
        style: StrokeStyle.solid,
        type: ToolType.fill,
        label: 'Fill a shape',
        icon: SvgPicture.asset(ImageAssets.fill1, fit: BoxFit.contain),
      ),
      tool(
        mode: BrushMode.freehand,
        style: StrokeStyle.solid,
        type: ToolType.freehand,
        label: 'Draw with a brush',
        icon: SvgPicture.asset(ImageAssets.pencil1, fit: BoxFit.contain),
      ),
      // The eraser is a mode, not a tool with a type (the same way the
      // original rail set it).
      KidFanItem.action(
        label: 'Eraser',
        onTap: () {
          SoundService.playClick();
          setState(() {
            _mode = BrushMode.eraser;
            _panel = _KidPanel.none;
          });
        },
        child: Image.asset(ImageAssets.eraser, fit: BoxFit.contain),
      ),
      KidFanItem.action(
        label: 'More fun',
        onTap: () {
          SoundService.playClick();
          // Closes the fan and opens the tool grid sheet.
          setState(() => _panel = _KidPanel.none);
          _isSelectedToolOpen();
        },
        child: const Icon(Icons.star_rounded, color: Color(0xFFF9A825)),
      ),
      KidFanItem.action(
        label: 'Erase everything',
        onTap: () {
          SoundService.playClick();
          _confirmClearAll();
        },
        child: SvgPicture.asset(ImageAssets.delete, fit: BoxFit.contain),
      ),
    ];
  }

  /// The grid sheet: the full colour grid, the stamps, the patterns or the
  /// whole tool grid — whichever the child asked for with "＋" or "fun".
  Widget? _buildGridSheet(Size size) {
    final showSheet =
        _panel == _KidPanel.grid && (isSelectedColorOpen || isSelectedToolOpen);
    if (!showSheet) return null;

    final content = isSelectedToolOpen
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

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Center(
        child: Container(
          width: math.min(
            KidLayout.swatchGridWidth + 2 * KidLayout.fanMargin,
            size.width * 0.78,
          ),
          height: math.min(
            size.height * 0.66,
            size.height - KidLayout.bubbleSize - 4 * KidLayout.fanMargin,
          ),
          margin: EdgeInsets.all(KidLayout.fanMargin * 0.5),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(KidLayout.buttonRadius * 1.4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.24),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              GestureDetector(
                onTap: _closeBothPalettes,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: KidLayout.fanMargin * 1.8,
                  alignment: Alignment.center,
                  child: Container(
                    width: KidLayout.fanMargin * 3,
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
