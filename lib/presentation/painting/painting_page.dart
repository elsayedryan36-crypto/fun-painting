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

// If the analyzer reports this one as unused, delete it.
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
import 'models/brush_size.dart';
import 'models/tool_type.dart';
import 'region.dart';
import 'svg_parser.dart';
import 'widgets/color_palette_widget.dart';
import 'widgets/kid_dialogs.dart';
import 'widgets/kid_layout.dart';
import 'widgets/kid_paint_controls.dart';
import 'widgets/pattern_palette_widget.dart';
import 'widgets/stamp_palette_widget.dart';
import 'widgets/vertical_action_tools_widget.dart' show SoundService;

/// What is covering the picture right now. One value, so two panels can never
/// be open (or disagree) at the same time.
enum _KidPanel {
  /// Nothing: the picture is clean.
  none,

  /// The tools fanning out of the tool bubble.
  toolFan,

  /// The sheet with all 78 colours (opened by the colour circle).
  colorGrid,

  /// The stamp picker (opened when the stamp tool is chosen).
  stampGrid,

  /// The pattern picker (opened when the wallpaper tool is chosen).
  patternGrid,
}

class PaintingPage extends StatefulWidget {
  const PaintingPage({super.key, required this.image});
  final String image;

  @override
  State<PaintingPage> createState() => _PaintingPageState();
}

class _PaintingPageState extends State<PaintingPage> {
  static const int _maxHistory = 100;

  /// Size of the tool bubble (the circle showing the current tool).
  /// 1.0 = as designed; 1.3 = 30% bigger.
  static const double _toolBubbleScale = .9;

  /// Size of the whole fan (icons, circles and spacing together).
  /// 1.0 = as designed; 1.2 = 20% bigger.
  static const double _fanScale = 1.2;

  /// Icon sizes. 1.0 = fill the circle exactly; raise to make icons bigger,
  /// lower if they start to touch the edge.
  static const double _fanIconScale = 2.2;

  /// Extra scale for icons that are PNGs with empty margins and look smaller
  /// than the others. Applied on top of _fanIconScale. 1.0 = no change.
  static const double _magicIconScale = 1.2;
  static const double _eraserIconScale = 1.1;

  /// Size of the background circle behind each fan tool, as a multiple of
  /// the slot the fan gives the icon (1.0 = exactly the slot). Scaling the
  /// slot (instead of using fixed pixels) keeps it visible on every screen.
  static const double _fanBgScale = 2.6;
  static const double _fanSelectedBgScale = 2.6;
  static const double _fanStrokeWidth = 1.6;
  static const double _fanSelectedStrokeWidth = 3.5;
  static const double _bubbleIconScale = 1.1;

  /// Popup backgrounds.
  static const Color _colorSheetBg = Color(0xFFFFF8E1);
  static const Color _stampSheetBg = Color(0xFFE3F2FD);
  static const Color _patternSheetBg = Color(0xFFF3E5F5);

  /// Tools that paint with the selected colour.
  static const Set<ToolType> _coloringTools = {
    ToolType.fill,
    ToolType.freehand,
    ToolType.pencil,
    ToolType.glitter,
  };

  final GlobalKey<ColoringCanvasState> _coloringCanvasKey =
      GlobalKey<ColoringCanvasState>();
  final GlobalKey _repaintKey = GlobalKey();

  final List<ColoringAction> _actionHistory = [];
  final List<ColoringAction> _redoStack = [];

  late final PaintingRepository _repository;

  List<Region> _regions = [];
  bool _loaded = false;
  bool _loadFailed = false;
  bool _isClosing = false;
  bool _isSaving = false;

  _KidPanel _panel = _KidPanel.none;

  BrushMode _mode = BrushMode.freehand;
  StrokeStyle _selectedStyle = StrokeStyle.solid;
  Color _selectedColor = Colors.red;

  SelectedTool _lastColoringTool = SelectedTool(
    mode: BrushMode.freehand,
    style: StrokeStyle.solid,
    type: ToolType.freehand,
  );
  late SelectedTool _selectedTool = _lastColoringTool;

  String _patternImage = PatternAssets.asset(1);
  ui.Image? _selectedWallpaper;

  String? _selectedStampAsset;
  double _stampSize = 50.0;

  /// Fixed at the app's original brush width (medium == 1.0). Make it
  /// non-final and add a control to bring S / M / L back.
  final BrushSize _brushSize = BrushSize.medium;

  @override
  void initState() {
    super.initState();
    _repository = PaintingRepository(Hive.box<PaintingSave>("paintings"));
    _setDefaultStamp();
    _load();
    _loadInitialWallpaper();
    InterstitialAdService.instance.preload();
  }

  @override
  void dispose() {
    _selectedWallpaper?.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Loading / saving the painting
  // ---------------------------------------------------------------------------

  Future<void> _load() async {
    try {
      final svgString = await rootBundle.loadString(widget.image);
      final parsed = parseSvgToRegions(svgString);

      final saved = DrawingRepository.loadDrawing(widget.image);
      for (final region in parsed) {
        final colorValue = saved[region.id];
        if (colorValue != null) {
          region.currentFillColor = Color(colorValue);
        }
      }
      await _repository.loadPainting(imageId: widget.image, regions: parsed);

      if (!mounted) return;
      setState(() {
        _regions = parsed;
        _loaded = true;
        _loadFailed = false;
      });
    } catch (e, st) {
      debugPrint('Failed to load painting "${widget.image}": $e\n$st');
      if (!mounted) return;
      setState(() => _loadFailed = true);
    }
  }

  /// Fire-and-forget safe: errors are logged, never thrown.
  Future<void> _savePainting() async {
    try {
      await _repository.savePainting(imageId: widget.image, regions: _regions);
    } catch (e, st) {
      debugPrint('Save painting error: $e\n$st');
    }
  }

  // ---------------------------------------------------------------------------
  // Panels
  // ---------------------------------------------------------------------------

  void _closePanels() {
    if (_panel == _KidPanel.none) return;
    setState(() => _panel = _KidPanel.none);
  }

  void _togglePanel(_KidPanel panel) {
    setState(() => _panel = _panel == panel ? _KidPanel.none : panel);
  }

  // ---------------------------------------------------------------------------
  // Actions coming from the canvas, undo / redo, clear
  // ---------------------------------------------------------------------------

  void _pushAction(ColoringAction action) {
    _actionHistory.add(action);
    if (_actionHistory.length > _maxHistory) {
      _actionHistory.removeAt(0);
    }
    _redoStack.clear();
  }

  void _handleColoringAction(dynamic actionInfo) {
    if (actionInfo is! Map) return;

    var shouldSave = false;

    switch (actionInfo['type']) {
      case 'stroke':
      case 'stamp':
        // A stroke that has only just started has nothing worth saving yet;
        // the write happens on 'strokeFinished'.
        _pushAction(
          StrokeAction(
            regionIndex: actionInfo['regionIndex'] as int,
            stroke: actionInfo['stroke'] as Stroke,
          ),
        );
        break;

      case 'fill':
        _pushAction(
          FillAction(
            regionIndex: actionInfo['regionIndex'] as int,
            previousColor: actionInfo['previousColor'] as Color,
            newColor: actionInfo['newColor'] as Color,
            previousStyle: actionInfo['previousStyle'] as StrokeStyle,
            newStyle: actionInfo['newStyle'] as StrokeStyle,
            previousStrokes: (actionInfo['previousStrokes'] as List<Stroke>)
                .map((s) => s.copyWith())
                .toList(),
          ),
        );
        shouldSave = true;
        break;

      case 'strokeFinished':
        shouldSave = true;
        break;

      case 'magic':
        _pushAction(
          MagicAction(
            regionIndex: actionInfo['regionIndex'] as int,
            previousColor: actionInfo['previousColor'] as Color,
            previousStyle: actionInfo['previousStyle'] as StrokeStyle,
            previousStrokes: (actionInfo['previousStrokes'] as List<Stroke>)
                .map((s) => s.copyWith())
                .toList(),
          ),
        );
        shouldSave = true;
        break;
    }

    // One rebuild: closes any open panel and refreshes the undo / redo pills.
    setState(() => _panel = _KidPanel.none);
    if (shouldSave) _savePainting();
  }

  /// Rebuilds so the undo / redo pills reflect the latest history.
  void _handlePaintingEnded() => setState(() {});

  void _undo() {
    if (_actionHistory.isEmpty) return;

    final action = _actionHistory.removeLast();
    action.revert(_regions);
    _redoStack.add(action);

    setState(() {});
    _coloringCanvasKey.currentState?.refresh();
    _savePainting();
  }

  void _redo() {
    if (_redoStack.isEmpty) return;

    final action = _redoStack.removeLast();
    action.apply(_regions);
    _actionHistory.add(action);

    setState(() {});
    _coloringCanvasKey.currentState?.refresh();
    _savePainting();
  }

  Future<void> _confirmClearAll() async {
    final confirmed = await showClearAllDialog(context);
    if (!mounted || !confirmed) return;
    _clearAll();
  }

  void _clearAll() {
    // Pushed (and kept) so that clearing can be undone.
    _pushAction(
      ClearAction(
        _regions
            .map(
              (region) => RegionState(
                color: region.currentFillColor,
                style: region.currentFillStyle,
                strokes: List<Stroke>.from(region.strokes),
              ),
            )
            .toList(),
      ),
    );

    setState(() {
      for (final region in _regions) {
        region.currentFillColor = region.keepOriginalColor
            ? region.originalFillColor
            : Colors.white;
        region.currentFillStyle = StrokeStyle.solid;
        region.strokes.clear();
      }
      _panel = _KidPanel.none;
    });

    _coloringCanvasKey.currentState?.refresh();
    _savePainting();
  }

  // ---------------------------------------------------------------------------
  // Tools, colours, stamps, patterns
  // ---------------------------------------------------------------------------

  void _setDefaultStamp() {
    if (stamps.isNotEmpty) {
      _selectedStampAsset = stamps[0];
    }
  }

  void _selectTool(SelectedTool tool) {
    setState(() {
      _selectedTool = tool;
      _mode = tool.mode;
      _selectedStyle = tool.style;

      if (_coloringTools.contains(tool.type)) {
        _lastColoringTool = tool;
      }

      if (tool.type == ToolType.stamp && _selectedStampAsset == null) {
        _setDefaultStamp();
      }

      // Stamps and patterns have their own picker, which opens right away.
      switch (tool.type) {
        case ToolType.stamp:
          _panel = _KidPanel.stampGrid;
          break;
        case ToolType.wallpaper:
          _panel = _KidPanel.patternGrid;
          break;
        default:
          _panel = _KidPanel.none;
      }
    });
  }

  /// Choosing a colour means "paint with it", so leave the eraser / stamp /
  /// pattern and go back to the last painting tool. Call inside setState.
  void _restoreColoringTool() {
    final needsRestore =
        _mode == BrushMode.eraser ||
        _mode == BrushMode.stamp ||
        _selectedTool.type == ToolType.wallpaper;
    if (!needsRestore) return;

    _selectedTool = _lastColoringTool;
    _mode = _lastColoringTool.mode;
    _selectedStyle = _lastColoringTool.style;
  }

  void _pickColor(Color color) {
    setState(() {
      _restoreColoringTool();
      _selectedColor = color;
      _panel = _KidPanel.none;
    });
  }

  // Async on purpose: it works whether the palette expects a sync or an async
  // callback.
  Future<void> _selectStamp(String stampPath) async {
    setState(() {
      _selectedStampAsset = stampPath;
      _panel = _KidPanel.none;
    });
  }

  Future<void> _selectPattern(String path) async {
    try {
      final wallpaper = await _decodeImage(path);
      if (!mounted) {
        wallpaper.dispose();
        return;
      }
      _applyWallpaper(path, wallpaper);
      setState(() => _panel = _KidPanel.none);
    } catch (e, st) {
      debugPrint('Pattern load error: $e\n$st');
    }
  }

  Future<void> _loadInitialWallpaper() async {
    try {
      final wallpaper = await _decodeImage(_patternImage);
      if (!mounted) {
        wallpaper.dispose();
        return;
      }
      _applyWallpaper(_patternImage, wallpaper);
    } catch (e, st) {
      debugPrint('Wallpaper load error: $e\n$st');
    }
  }

  void _applyWallpaper(String path, ui.Image wallpaper) {
    final old = _selectedWallpaper;
    setState(() {
      _patternImage = path;
      _selectedWallpaper = wallpaper;
    });
    if (old != null) {
      // Disposed after the frame so the canvas never paints a dead image.
      WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
    }
  }

  Future<ui.Image> _decodeImage(String asset) async {
    final data = await rootBundle.load(asset);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  // ---------------------------------------------------------------------------
  // Save to gallery / thumbnail / close
  // ---------------------------------------------------------------------------

  Future<bool> _requestGalleryPermission() async {
    // The app only saves images it creates itself, so Android needs no
    // permission on API 29+.
    // TODO: if minSdk is below 29, request Permission.storage on API <= 28.
    if (Platform.isAndroid) return true;

    if (Platform.isIOS) {
      // Needs NSPhotoLibraryAddUsageDescription in Info.plist.
      final status = await Permission.photosAddOnly.request();
      debugPrint('Photos Add Only permission: $status');
      return status.isGranted || status.isLimited;
    }

    return false;
  }

  /// Captures the picture (without any overlay) as PNG bytes.
  Future<Uint8List?> _capturePng({required double pixelRatio}) async {
    // Never save a zoomed crop: reset the zoom, wait a frame, capture, then
    // put the view back.
    final canvas = _coloringCanvasKey.currentState;
    final zoom = canvas?.zoom ?? 1.0;
    final pan = canvas?.pan ?? Offset.zero;
    final wasZoomed = zoom != 1.0;
    if (wasZoomed) {
      canvas?.resetZoom();
      await WidgetsBinding.instance.endOfFrame;
    }

    try {
      final renderObject = _repaintKey.currentContext?.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) return null;

      final ui.Image image = await renderObject.toImage(pixelRatio: pixelRatio);
      try {
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        return byteData?.buffer.asUint8List();
      } finally {
        image.dispose();
      }
    } finally {
      if (wasZoomed && mounted) canvas?.setView(zoom, pan);
    }
  }

  Future<void> _saveToGallery() async {
    if (_isSaving) return;
    _isSaving = true;

    try {
      final hasPermission = await _requestGalleryPermission();
      if (!hasPermission) {
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

      final pngBytes = await _capturePng(pixelRatio: 2.0);
      if (pngBytes == null) {
        await _showSaveDialog(
          title: 'Oops!',
          message: 'Could not capture your coloring.',
          icon: Icons.error_outline,
        );
        return;
      }

      final result = await ImageGallerySaverPlus.saveImage(
        pngBytes,
        quality: 100,
        name: 'coloring_${DateTime.now().millisecondsSinceEpoch}',
      );
      debugPrint('Gallery save result: $result');

      final success = result is Map && result['isSuccess'] == true;

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
    } catch (e, st) {
      debugPrint('Save error: $e\n$st');
      await _showSaveDialog(
        title: 'Something Went Wrong',
        message: 'We couldn\'t save your coloring. Please try again.',
        icon: Icons.error_outline,
      );
    } finally {
      _isSaving = false;
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

    await showDialog<void>(
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
                  color: Colors.black.withValues(alpha: 0.15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/app_icon.png',
                  height: AppSizeHeight.s30,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: AppSizeHeight.s5),
                Container(
                  width: AppSizeHeight.s12,
                  height: AppSizeHeight.s12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (success ? Colors.green : Colors.orange).withValues(
                      alpha: 0.12,
                    ),
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
                if (showSettings) ...[
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
                  SizedBox(height: AppSizeHeight.s2),
                ],
                SizedBox(
                  width: double.infinity,
                  height: AppSizeHeight.s10,
                  child: TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
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
      final png = await _capturePng(pixelRatio: 1.5);
      if (png == null) return;
      await ThumbnailService().saveThumbnail(widget.image, png);
    } catch (e, st) {
      debugPrint('Thumbnail error: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  Future<void> _confirmClose() async {
    // Wired to both the close button and the back gesture; a quick second
    // trigger must not pop two routes.
    if (_isClosing) return;
    _isClosing = true;

    try {
      await _savePainting();
      await _saveThumbnail();
      await InterstitialAdService.instance.maybeShowOnColoringExit();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      _isClosing = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return _loadFailed
          ? _buildErrorScaffold()
          : const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        // Back closes an open panel first, then leaves the drawing.
        if (_panel != _KidPanel.none) {
          _closePanels();
          return;
        }
        await _confirmClose();
      },
      child: Scaffold(
        backgroundColor: ColorManager.lightPrimary,
        // Layout:
        //   picture      : the whole screen
        //   bottom right : the tool bubble (fan of tools opens around it)
        //   its top left : a circle showing the selected colour -> 78 colours
        //   bottom left  : undo (+ redo when there is something to redo)
        //   top left     : leave / erase everything      top right : save
        body: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            final margin = KidLayout.fanMargin;
            final crayon = KidLayout.crayonBubbleSize;
            final bubble = KidLayout.bubbleSize;
            final toolBubble = crayon * _toolBubbleScale; // <-- add this line

            final fanOpen = _panel == _KidPanel.toolFan;
            final fanItems = _buildToolFanItems();
            final dotSize = bubble * 0.7;
            // Centre of the colour circle, measured from the right / bottom
            // edge: on the top-left corner of the tool bubble, nudged inward.
            final dotCentre = margin + toolBubble * 0.88;
            return Stack(
              fit: StackFit.expand,
              children: [
                // 1. The picture.
                RepaintBoundary(
                  key: _repaintKey,
                  child: ColoringCanvas(
                    key: _coloringCanvasKey,
                    selectedWallpaperAsset: _patternImage,
                    selectedStampAsset:
                        _selectedStampAsset ??
                        (stamps.isNotEmpty ? stamps[0] : null),
                    regions: _regions,
                    brushMode: _mode,
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
                        ? _closePanels
                        : null,
                    onPaintingEnded:
                        (_mode == BrushMode.freehand ||
                            _mode == BrushMode.eraser ||
                            _mode == BrushMode.stamp)
                        ? _handlePaintingEnded
                        : null,
                  ),
                ),

                // 2. Scrim: while a panel is open, a tap outside only closes
                //    it. It never paints or fills by accident.
                if (_panel != _KidPanel.none)
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _closePanels,
                    ),
                  ),

                // 3. The tool fan, opening around the tool bubble.
                // 3. The tool fan, opening around the tool bubble.
                IgnorePointer(
                  ignoring: !fanOpen,
                  child: Transform.scale(
                    scale: _fanScale,
                    alignment: Alignment.topLeft,
                    // Grow from the centre of the tool bubble, so the fan stays attached
                    // to it instead of drifting toward the screen corner.
                    origin: Offset(
                      size.width - margin - crayon / 2,
                      size.height - margin - crayon / 2,
                    ),
                    child: KidFan(
                      open: fanOpen,
                      anchor: Alignment.bottomRight,
                      outerCount: math.min(5, fanItems.length),
                      items: fanItems,
                    ),
                  ),
                ),
                // 3b. While the fan is open, a tap anywhere outside it closes it.
                //     A Listener (not a GestureDetector) never competes with the fan
                //     items, so picking a tool still works. The tool stays selected;
                //     closing only changes _panel.
                if (fanOpen)
                  Positioned.fill(
                    child: Listener(
                      behavior: HitTestBehavior.translucent,
                      onPointerUp: (_) => _closePanels(),
                    ),
                  ),
                // 4. The sheet (colours / tools / stamps / patterns), sliding
                //    up from the bottom.
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      transitionBuilder: (child, animation) => SlideTransition(
                        position:
                            Tween<Offset>(
                              begin: const Offset(0, 1),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutCubic,
                              ),
                            ),
                        child: child,
                      ),
                      child:
                          _buildSheet(size) ??
                          const SizedBox.shrink(key: ValueKey('no_sheet')),
                    ),
                  ),
                ),

                // 5. The tool bubble: where a thumb rests.
                Positioned(
                  right: margin,
                  bottom: margin,
                  child: KidRoundBubble(
                    key: const Key('kid_tool_bubble'),
                    size: toolBubble,
                    selected: fanOpen,
                    tooltip: 'Tools',
                    faceColor: const Color(0xFFFFE082),
                    onTap: () {
                      SoundService.playClick();
                      _togglePanel(_KidPanel.toolFan);
                    },
                    child: _currentToolIcon(),
                  ),
                ),

                // 6. The colour circle, top left of the tool bubble. Hidden
                //    while the fan is open so it never sits on a fan item.
                Positioned(
                  right: dotCentre - dotSize / 3,
                  bottom: dotCentre - dotSize / 2,
                  child: IgnorePointer(
                    ignoring: fanOpen,
                    child: AnimatedOpacity(
                      opacity: fanOpen ? 0 : 1,
                      duration: const Duration(milliseconds: 150),
                      child: _buildColorDot(dotSize),
                    ),
                  ),
                ),

                // 7. Undo (and redo when there is something to redo).

                // 8. Leave and erase everything, top left.
                Positioned(
                  left: margin,
                  top: margin,
                  child: KidRoundBubble(
                    key: const Key('kid_home_bubble'),
                    size: bubble * 0.76,
                    faceColor: const Color(0xFFDCE3E9),
                    tooltip: 'Leave the drawing',
                    onTap: () {
                      SoundService.playClick();
                      _confirmClose();
                    },
                    child: Image.asset(ImageAssets.close, fit: BoxFit.contain),
                  ),
                ),

                // 9. Save, undo and redo, top right: all the same round bubble.
                Positioned(
                  right: margin,
                  top: margin,
                  child: Row(
                    children: [
                      // Undo: dimmed and untouchable while there is nothing to undo.

                      // Redo: only there when there is something to redo.
                      if (_redoStack.isNotEmpty) ...[
                        KidRoundBubble(
                          key: const Key('kid_redo_bubble'),
                          size: bubble * 0.75,
                          faceColor: const Color(0xFFFFD9B0),
                          tooltip: 'Redo',
                          onTap: () {
                            SoundService.playClick();
                            _redo();
                          },
                          child: Transform.flip(
                            flipX: true,
                            child: Image.asset(
                              ImageAssets.redo,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        SizedBox(width: margin * 0.6),
                      ],
                      IgnorePointer(
                        ignoring: _actionHistory.isEmpty,
                        child: Opacity(
                          opacity: _actionHistory.isEmpty ? 0.4 : 1,
                          child: KidRoundBubble(
                            key: const Key('kid_undo_bubble'),
                            size: bubble * 0.75,
                            faceColor: const Color(0xFFFFD9B0),
                            tooltip: 'Undo',
                            onTap: () {
                              SoundService.playClick();
                              _undo();
                            },
                            child: Image.asset(
                              ImageAssets.redo,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: margin * 0.6),
                      KidRoundBubble(
                        key: const Key('kid_save_bubble'),
                        size: bubble * 0.75,
                        faceColor: const Color(0xFFC8E6C9),
                        tooltip: 'Save to the phone',
                        onTap: () {
                          SoundService.playClick();
                          _saveToGallery();
                        },
                        child: Image.asset(
                          ImageAssets.camera,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorScaffold() {
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
                'Please try again or pick another drawing.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: FontSize.s15, color: Colors.black54),
              ),
              SizedBox(height: AppSizeHeight.s3),
              ElevatedButton(
                onPressed: () {
                  setState(() => _loadFailed = false);
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

  /// The circle showing the selected colour. Tap it to see all 78 colours.
  Widget _buildColorDot(double size) {
    final badge = size * 0.42;

    return Semantics(
      button: true,
      label: 'Choose a colour',
      child: Tooltip(
        message: 'Colours',
        child: GestureDetector(
          key: const Key('kid_color_dot'),
          behavior: HitTestBehavior.opaque,
          onTap: () {
            SoundService.playClick();
            _togglePanel(_KidPanel.colorGrid);
          },
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: _selectedColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                ),
                // A small badge so it reads as "tap for more colours", even
                // when the selected colour is white.
                Positioned(
                  left: -badge * 0.15,
                  top: -badge * 0.15,
                  child: Container(
                    width: badge,
                    height: badge,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.palette_rounded,
                      size: badge * 0.65,
                      color: ColorManager.darkPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The icon on the tool bubble: whatever the child is painting with.
  Widget _currentToolIcon() {
    final icon = _mode == BrushMode.eraser
        ? Transform.scale(
            scale: _eraserIconScale,
            child: Image.asset(ImageAssets.eraser, fit: BoxFit.contain),
          )
        : _toolIcon(_selectedTool.type);
    return Transform.scale(scale: _bubbleIconScale, child: icon);
  }

  /// One icon per tool, the same ones the old tool palette used. The layers
  /// that were tinted with the selected colour there are tinted here too.
  Widget _toolIcon(ToolType type) {
    Widget layer(String asset, {bool tint = false}) => SvgPicture.asset(
      asset,
      fit: BoxFit.contain,
      colorFilter: tint
          ? ColorFilter.mode(_selectedColor, BlendMode.srcIn)
          : null,
    );

    // FittedBox scales the layers to whatever room the parent gives them and
    // still works when that room is unbounded (StackFit.expand does not: it
    // throws, and a layout error inside the big Stack hides every control).
    Widget stacked(List<Widget> layers) => FittedBox(
      fit: BoxFit.contain,
      child: Stack(alignment: Alignment.center, children: layers),
    );

    switch (type) {
      case ToolType.fill:
        return stacked([
          layer(ImageAssets.fill1),
          layer(ImageAssets.fill2, tint: true),
        ]);
      case ToolType.glitter:
        return stacked([
          layer(ImageAssets.glitter1),
          layer(ImageAssets.glitter2),
          layer(ImageAssets.glitter3, tint: true),
        ]);
      case ToolType.freehand:
        return stacked([
          layer(ImageAssets.freeHand1),
          layer(ImageAssets.freeHand2, tint: true),
        ]);
      case ToolType.pencil:
        return stacked([
          layer(ImageAssets.pencil1, tint: true),
          layer(ImageAssets.pencil2),
        ]);
      case ToolType.wallpaper:
        return layer(ImageAssets.wallpaper);
      case ToolType.stamp:
        return layer(ImageAssets.stamp);
      case ToolType.magic:
        return Transform.scale(
          scale: _magicIconScale,
          child: Image.asset(ImageAssets.magic, fit: BoxFit.contain),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  /// True when [type] is the tool the child is painting with right now.
  /// The eraser is a mode, so while it is on no tool is highlighted.
  bool _isToolActive(ToolType type) =>
      _mode != BrushMode.eraser && _selectedTool.type == type;

  /// Wraps a fan icon so the selected tool stands out.
  /// Wraps a fan icon so the selected tool stands out.
  Widget _fanIcon(Widget icon, {required bool selected}) {
    // Every icon (SVG or PNG) is first fitted into the same 100x100 square,
    // then that square is fitted to the fan slot. Result: all backgrounds
    // are the same size, whatever the icon's own size or aspect ratio.
    final square = FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: 100,
        height: 100,
        child: FittedBox(fit: BoxFit.contain, child: icon),
      ),
    );

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: Transform.scale(
            scale: selected ? _fanSelectedBgScale : _fanBgScale,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? const Color(0xFFFFE082) : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? ColorManager.darkPrimary
                      : ColorManager.gold,
                  width: selected ? _fanSelectedStrokeWidth : _fanStrokeWidth,
                ),
              ),
            ),
          ),
        ),
        Transform.scale(scale: _fanIconScale, child: square),
      ],
    );
  }

  /// Every tool, straight in the fan. The selected one is highlighted.
  List<KidFanItem> _buildToolFanItems() {
    KidFanItem tool({
      required BrushMode mode,
      required StrokeStyle style,
      required ToolType type,
      required String label,
    }) {
      return KidFanItem.action(
        label: label,
        onTap: () {
          SoundService.playClick();
          _selectTool(SelectedTool(mode: mode, style: style, type: type));
        },
        child: _fanIcon(_toolIcon(type), selected: _isToolActive(type)),
      );
    }

    return [
      tool(
        mode: BrushMode.fill,
        style: StrokeStyle.solid,
        type: ToolType.fill,
        label: 'Fill a shape',
      ),
      tool(
        mode: BrushMode.freehand,
        style: StrokeStyle.glitter,
        type: ToolType.glitter,
        label: 'Glitter',
      ),
      tool(
        mode: BrushMode.freehand,
        style: StrokeStyle.solid,
        type: ToolType.freehand,
        label: 'Draw with a brush',
      ),
      tool(
        mode: BrushMode.freehand,
        style: StrokeStyle.neon,
        type: ToolType.pencil,
        label: 'Pencil',
      ),
      tool(
        mode: BrushMode.freehand,
        style: StrokeStyle.wallpaper,
        type: ToolType.wallpaper,
        label: 'Patterns',
      ),
      tool(
        mode: BrushMode.stamp,
        style: StrokeStyle.solid,
        type: ToolType.stamp,
        label: 'Stamps',
      ),
      tool(
        mode: BrushMode.magic,
        style: StrokeStyle.solid,
        type: ToolType.magic,
        label: 'Magic',
      ),
      // The eraser is a mode, not a tool with a type.
      KidFanItem.action(
        label: 'Eraser',
        onTap: () {
          SoundService.playClick();
          setState(() {
            _mode = BrushMode.eraser;
            _panel = _KidPanel.none;
          });
        },
        child: _fanIcon(
          Transform.scale(
            scale: _eraserIconScale,
            child: Image.asset(ImageAssets.eraser, fit: BoxFit.contain),
          ),
          selected: _mode == BrushMode.eraser,
        ),
      ),
      KidFanItem.action(
        label: 'Erase everything',
        onTap: () {
          SoundService.playClick();
          _confirmClearAll();
        },
        child: _fanIcon(
          SvgPicture.asset(ImageAssets.delete, fit: BoxFit.contain),
          selected: false,
        ),
      ),
    ];
  }

  Color get _sheetColor {
    switch (_panel) {
      case _KidPanel.colorGrid:
        return _colorSheetBg;
      case _KidPanel.stampGrid:
        return _stampSheetBg;
      case _KidPanel.patternGrid:
        return _patternSheetBg;
      default:
        return Colors.white;
    }
  }

  /// The sheet for the current panel, or null when none is showing.
  Widget? _buildSheet(Size size) {
    final Widget content;

    switch (_panel) {
      case _KidPanel.colorGrid:
        // Always the colours, whatever tool is selected.
        content = ColorPaletteWidget(
          isColorChanged: _closePanels,
          selectedColor: _selectedColor,
          onColorSelected: _pickColor,
          toolType: _lastColoringTool.type,
        );
        break;

      case _KidPanel.stampGrid:
        content = DefaultTextStyle.merge(
          style: const TextStyle(color: Colors.black), // your text colour
          child: StampPaletteWidget(
            selectedImage:
                _selectedStampAsset ?? (stamps.isNotEmpty ? stamps[0] : ''),
            onImageSelected: _selectStamp,
            isImageChanged: _closePanels,
            stampSize: _stampSize,
            onStampSizeChanged: (value) => setState(() => _stampSize = value),
            stamps: stamps,
          ),
        );
        break;

      case _KidPanel.patternGrid:
        content = PatternPaletteWidget(
          selectedImage: _patternImage,
          onImageSelected: _selectPattern,
          isImageChanged: _closePanels,
        );
        break;

      case _KidPanel.none:
      case _KidPanel.toolFan:
        return null;
    }

    final height = math.max(
      0.0,
      math.min(
        size.height * 0.66,
        size.height - KidLayout.bubbleSize - 4 * KidLayout.fanMargin,
      ),
    );

    return Container(
      key: ValueKey(_panel),
      width: math.min(
        KidLayout.swatchGridWidth + 2 * KidLayout.fanMargin,
        size.width * 0.78,
      ),
      height: height,
      margin: EdgeInsets.all(KidLayout.fanMargin * 0.5),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _sheetColor,
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
          // Drag-handle look; tapping it closes the sheet.
          GestureDetector(
            onTap: _closePanels,
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
    );
  }
}
