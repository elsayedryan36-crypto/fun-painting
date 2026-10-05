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
import 'region.dart';
import 'svg_parser.dart';
import 'widgets/animated_vertical_palette.dart';
import 'widgets/color_palette_widget.dart';
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
  bool isWallPaper = false;
  String selectedPatternImage = PatternAssets.asset(1);
  late Box<ColoringSaveModel> paintingBox;
  late PaintingRepository _repository;

  SelectedTool? _selectedTool;
  ui.Image? _selectedWallpaper;
  String? _selectedStampAsset;
  double _stampSize = 50.0;
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

    switch (type) {
      case 'stroke':
      case 'stamp':
        _saveStrokeAction(
          actionInfo['regionIndex'] as int,
          actionInfo['stroke'] as Stroke,
        );
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
        break;
      case 'strokeFinished':
        _savePainting();
        break;

      case 'magic':
        _saveMagicAction(
          regionIndex: actionInfo['regionIndex'] as int,
          previousColor: actionInfo['previousColor'] as Color,
          previousStyle: actionInfo['previousStyle'] as StrokeStyle,
          previousStrokes: actionInfo['previousStrokes'] as List<Stroke>,
        );
        break;
    }
    _savePainting();
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

      _actionHistory.clear();
      _redoStack.clear();
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

    setState(() {
      _regions = parsed;
    });
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

    // Only save when user confirms Yes
    await _saveThumbnail();
    await InterstitialAdService.instance.maybeShowOnColoringExit();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_regions.isEmpty) {
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
        body: Stack(
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
                onPaintingStarted:
                    (_mode == BrushMode.freehand || _mode == BrushMode.eraser
                    // ||
                    // _mode == BrushMode.stamp
                    )
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
                        height: AppSizeHeight.s96,
                        width: AppSizeWidth.s83,
                        child: _buildPaletteForMode(),
                      ),
                    ),
                  )
                : Container(),
            Positioned(
              top: 0,
              right: 0,
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
                          onModeChanged: (mode) => setState(() => _mode = mode),
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
                      onClearSelected: () {
                        _clearAllPaintingsAndStamps();
                      },
                    ),
                  ),
                ],
              ),
            ),

            Positioned(
              left: 0,
              top: 0,
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
          ],
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
