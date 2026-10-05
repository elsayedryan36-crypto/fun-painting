import 'dart:math' as math; // ✅ NEW: needed for the uniform min() scale below
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fun_painting/app/app_pref.dart';
import 'package:fun_painting/presentation/common/services/sound_service.dart';
import 'package:lottie/lottie.dart';

import '../common/resources/assets_manager.dart';
import 'coloring_painter.dart';
import 'region.dart';

// class StarAnimation {
//   final int id;
//   final Offset position;

//   StarAnimation({required this.id, required this.position});
// }

// enum BrushMode { fill, magic, freehand, eraser, stamp }

// class ColoringCanvas extends StatefulWidget {
//   final List<Region> regions;
//   final BrushMode brushMode;
//   final Color selectedColor;
//   final StrokeStyle selectedStyle;
//   final Function(dynamic) onColoringAction;
//   final ui.Image? selectedWallpaper;
//   final String? selectedStampAsset;
//   final ValueChanged<String>? onStampSelected;
//   final double stampSize;
//   final VoidCallback? onPaintingStarted;
//   final VoidCallback? onPaintingEnded;
//   final VoidCallback? onClearRequested;
//   final String? selectedWallpaperAsset;

//   const ColoringCanvas({
//     super.key,
//     required this.regions,
//     required this.brushMode,
//     required this.selectedColor,
//     required this.selectedStyle,
//     required this.onColoringAction,
//     this.selectedWallpaper,
//     this.selectedWallpaperAsset,
//     this.selectedStampAsset,
//     this.onStampSelected,
//     required this.stampSize,
//     this.onPaintingStarted,
//     this.onPaintingEnded,
//     this.onClearRequested,
//   });

//   @override
//   State<ColoringCanvas> createState() => ColoringCanvasState();
// }

// class ColoringCanvasState extends State<ColoringCanvas> {
//   Rect? _bounds;
//   int? _activeRegionIndex;
//   // =========================
//   // Zoom & Pan
//   // =========================
//   double _zoom = 1.0;

//   Offset _pan = Offset.zero;

//   double _startZoom = 1.0;
//   Offset _startPan = Offset.zero;
//   Offset _startFocalPoint = Offset.zero;
//   Offset? _lastFocalPoint;
//   Stroke? _currentStroke;
//   ui.Picture? _selectedSvgPicture;
//   Size? _selectedSvgSize;
//   final Map<String, ui.Picture> _stampCache = {};
//   ui.Image? _glitterImage;
//   bool _isLoadingGlitter = false;
//   bool _isDisposed = false;
//   final List<StarAnimation> _animations = [];
//   int _animationId = 0;
//   Offset _lastTouchPosition = Offset.zero;

//   // Cache rasterized pictures of finished strokes to avoid re-drawing points
//   // every frame. Keyed by `stroke.hashCode`.
//   final Map<int, ui.Picture> _strokePictureCache = {};

//   // Throttle repainting during active drawing to reduce UI work.
//   DateTime _lastRepaintTime = DateTime.fromMillisecondsSinceEpoch(0);
//   static const Duration _minRepaintInterval = Duration(milliseconds: 30);

//   // Track last known canvas size (set during build) so we can rasterize
//   // strokes at the same scale used for painting.
//   Size? _lastCanvasSize;

//   // ADDED: Track which pictures we've already disposed
//   final Set<ui.Picture> _disposedPictures = {};

//   Future<ui.Image?> _loadGlitterImage() async {
//     if (_glitterImage != null) return _glitterImage;
//     if (_isLoadingGlitter) return null;

//     _isLoadingGlitter = true;
//     try {
//       final data = await rootBundle.load(ImageAssets.glitter);
//       final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
//       final frame = await codec.getNextFrame();
//       _glitterImage = frame.image;

//       if (mounted && !_isDisposed) {
//         setState(() {});
//       }

//       return _glitterImage;
//     } catch (e) {
//       debugPrint('Error loading glitter image: $e');
//       return null;
//     } finally {
//       _isLoadingGlitter = false;
//     }
//   }

//   @override
//   void initState() {
//     super.initState();

//     _computeBounds();
//     _loadGlitterImage();

//     if (widget.selectedStampAsset != null) {
//       _loadStamp(widget.selectedStampAsset!);
//     }

//     _restoreSavedStampPictures();
//   }

//   Future<void> _restoreSavedStampPictures() async {
//     for (final region in widget.regions) {
//       for (final stroke in region.strokes) {
//         if (stroke.stampAsset == null) continue;

//         try {
//           if (!_stampCache.containsKey(stroke.stampAsset)) {
//             final loader = SvgAssetLoader(stroke.stampAsset!);

//             final pictureInfo = await vg.loadPicture(loader, null);

//             _stampCache[stroke.stampAsset!] = pictureInfo.picture;
//           }

//           stroke.svgPicture = _stampCache[stroke.stampAsset!];
//         } catch (e) {
//           debugPrint("Cannot restore stamp: $e");
//         }
//       }
//     }

//     if (mounted) {
//       setState(() {});
//     }
//   }

//   void refresh() {
//     if (mounted && !_isDisposed) {
//       setState(() {});
//     }
//   }

//   // ADDED: Safe picture disposal method
//   void _safeDisposePicture(ui.Picture? picture) {
//     if (picture == null) return;

//     // Check if we've already disposed this picture
//     if (_disposedPictures.contains(picture)) {
//       return;
//     }

//     try {
//       picture.dispose();
//       _disposedPictures.add(picture);
//     } catch (e) {
//       debugPrint('Error disposing picture: $e');
//     }
//   }

//   // ADDED: Safe image disposal method
//   void _safeDisposeImage(ui.Image? image) {
//     if (image == null) return;

//     try {
//       image.dispose();
//     } catch (e) {
//       debugPrint('Error disposing image: $e');
//     }
//   }

//   @override
//   void dispose() {
//     if (_isDisposed) return;

//     _isDisposed = true;

//     // Clear current stroke reference
//     _currentStroke = null;

//     // Safe disposal of all cached pictures
//     _stampCache.forEach((key, picture) {
//       _safeDisposePicture(picture);
//     });
//     _stampCache.clear();

//     // Dispose stroke pictures
//     _strokePictureCache.forEach((key, picture) {
//       _safeDisposePicture(picture);
//     });
//     _strokePictureCache.clear();

//     // Safe disposal of selected SVG picture
//     _safeDisposePicture(_selectedSvgPicture);
//     _selectedSvgPicture = null;

//     // Safe disposal of glitter image
//     _safeDisposeImage(_glitterImage);
//     _glitterImage = null;

//     // Clear the disposed pictures set
//     _disposedPictures.clear();

//     super.dispose();
//   }

//   @override
//   void didUpdateWidget(ColoringCanvas oldWidget) {
//     super.didUpdateWidget(oldWidget);

//     if (_isDisposed) return;

//     if (widget.onClearRequested != oldWidget.onClearRequested &&
//         widget.onClearRequested != null) {
//       // clearGlobalStamps();
//     }

//     if (widget.selectedStampAsset != oldWidget.selectedStampAsset ||
//         (widget.brushMode == BrushMode.stamp &&
//             oldWidget.brushMode != BrushMode.stamp &&
//             widget.selectedStampAsset != null)) {
//       _loadStamp(widget.selectedStampAsset!);
//     }
//   }

//   Future<void> _loadStamp(String assetPath) async {
//     if (_isDisposed) return;

//     try {
//       // Check cache first
//       if (_stampCache.containsKey(assetPath)) {
//         setState(() {
//           _selectedSvgPicture = _stampCache[assetPath];
//         });
//         return;
//       }

//       final pictureInfo = await vg.loadPicture(SvgAssetLoader(assetPath), null);

//       if (_isDisposed) {
//         _safeDisposePicture(pictureInfo.picture);
//         return;
//       }

//       setState(() {
//         // Don't dispose the old picture here - let the dispose method handle it
//         _selectedSvgPicture = pictureInfo.picture;
//         _selectedSvgSize = pictureInfo.size;

//         // Cache the picture
//         _stampCache[assetPath] = pictureInfo.picture;
//       });
//     } catch (e, st) {
//       debugPrint('Error loading SVG stamp: $e\n$st');
//     }
//   }

//   // REMOVED: selectStampFromAsset method to avoid complex picture management

//   void _computeBounds() {
//     if (widget.regions.isEmpty) {
//       _bounds = Rect.fromLTWH(0, 0, 1, 1);
//       return;
//     }
//     Rect b = widget.regions.first.getBounds();
//     for (final r in widget.regions.skip(1)) {
//       b = b.expandToInclude(r.getBounds());
//     }
//     _bounds = b;
//   }

//   Map<String, double> _computeTransform(Size size) {
//     final bounds = _bounds ?? Rect.fromLTWH(0, 0, 1, 1);

//     final bw = bounds.width <= 0 ? 1.0 : bounds.width;
//     final bh = bounds.height <= 0 ? 1.0 : bounds.height;

//     // IMPORTANT:
//     // Use ONE scale to preserve aspect ratio.
//     final scale = math.min(size.width / bw, size.height / bh);

//     final drawnWidth = bw * scale;
//     final drawnHeight = bh * scale;

//     // Center the SVG inside the available canvas.
//     final offsetX = (size.width - drawnWidth) / 2;
//     final offsetY = (size.height - drawnHeight) / 2;

//     final tx = offsetX - bounds.left * scale;
//     final ty = offsetY - bounds.top * scale;

//     return {'scaleX': scale, 'scaleY': scale, 'tx': tx, 'ty': ty};
//   }

//   Offset _toPathSpace(Offset localPos, Size size) {
//     final t = _computeTransform(size);

//     final scale = t['scaleX']!;
//     final tx = t['tx']!;
//     final ty = t['ty']!;

//     // Reverse pan.
//     final panned = localPos - _pan;

//     // Reverse zoom around canvas center.
//     final center = Offset(size.width / 2, size.height / 2);

//     final unzoomed = center + (panned - center) / _zoom;

//     // Reverse base SVG transform.
//     return Offset((unzoomed.dx - tx) / scale, (unzoomed.dy - ty) / scale);
//   }

//   void _handleTapDown(TapDownDetails details, Size size) {
//     _lastTouchPosition = details.localPosition;
//     if (_isDisposed) return;

//     if (widget.brushMode == BrushMode.freehand ||
//         widget.brushMode == BrushMode.eraser ||
//         widget.brushMode == BrushMode.stamp) {
//       widget.onPaintingStarted?.call();
//     }

//     final p = _toPathSpace(details.localPosition, size);

//     if (widget.brushMode == BrushMode.stamp && _selectedSvgPicture != null) {
//       for (int i = 0; i < widget.regions.length; i++) {
//         final region = widget.regions[i];
//         if (region.path.contains(p)) {
//           BrushSoundService.instance.playOnce(_currentBrushSound());
//           final stamp = Stroke(
//             points: [p],
//             color: Colors.transparent,
//             style: StrokeStyle.stampSvg,
//             stampSize: widget.stampSize,
//             svgPicture: _selectedSvgPicture,
//             svgSize: _selectedSvgSize,
//             stampAsset: widget.selectedStampAsset,
//           );

//           region.strokes.add(stamp);

//           setState(() {
//             // Force rebuild after adding the stamp
//           });

//           widget.onColoringAction({
//             'type': 'stamp',
//             'regionIndex': i,
//             'stroke': stamp,
//           });

//           debugPrint('Stamp placed in region $i at: $p');
//           break;
//         }
//       }
//     }

//     for (int i = 0; i < widget.regions.length; i++) {
//       final region = widget.regions[i];
//       if (region.path.contains(p)) {
//         setState(() {
//           if (widget.brushMode == BrushMode.fill) {
//             BrushSoundService.instance.playOnce(_currentBrushSound());
//             final previousColor = region.currentFillColor;
//             final previousStyle = region.currentFillStyle;
//             final previousStrokes = region.strokes
//                 .map((s) => s.copyWith())
//                 .toList();

//             region.fill(widget.selectedColor, widget.selectedStyle);
//             region.strokes.clear();

//             widget.onColoringAction({
//               'type': 'fill',
//               'regionIndex': i,
//               'previousColor': previousColor,
//               'newColor': widget.selectedColor,
//               'previousStyle': previousStyle,
//               'newStyle': widget.selectedStyle,
//               'previousStrokes': previousStrokes,
//             });
//           } else if (widget.brushMode == BrushMode.magic) {
//             BrushSoundService.instance.playOnce(_currentBrushSound());
//             final previousColor = region.currentFillColor;
//             final previousStyle = region.currentFillStyle;
//             final previousStrokes = region.strokes
//                 .map((s) => s.copyWith())
//                 .toList();

//             region.resetToOriginal();
//             region.strokes.clear();

//             widget.onColoringAction({
//               'type': 'magic',
//               'regionIndex': i,
//               'previousColor': previousColor,
//               'previousStyle': previousStyle,
//               'previousStrokes': previousStrokes,
//             });
//           } else if (widget.brushMode == BrushMode.freehand ||
//               widget.brushMode == BrushMode.eraser) {
//             _activeRegionIndex = i;

//             _currentStroke = Stroke(
//               points: <Offset>[p],
//               color: widget.brushMode == BrushMode.eraser
//                   ? Colors.white
//                   : widget.selectedColor,
//               style: widget.brushMode == BrushMode.eraser
//                   ? StrokeStyle.solid
//                   : widget.selectedStyle,
//               wallpaperImage: widget.selectedWallpaper,
//               wallpaperAsset: widget.selectedWallpaperAsset,
//             );
//             region.strokes.add(_currentStroke!);

//             widget.onColoringAction({
//               'type': 'stroke',
//               'regionIndex': i,
//               'stroke': _currentStroke!,
//             });
//           }
//         });
//         break;
//       }
//     }
//   }

//   String _currentBrushSound() {
//     switch (widget.brushMode) {
//       case BrushMode.fill:
//         return "sounds/fill.mp3";

//       case BrushMode.eraser:
//         return "sounds/eraser.mp3";

//       case BrushMode.freehand:
//         return "sounds/pencil.mp3";

//       case BrushMode.stamp:
//         return "sounds/stamp.mp3";

//       case BrushMode.magic:
//         return "sounds/magic.mp3";

//       // default:
//       //   return "sounds/pencil.mp3";
//     }
//   }

//   void _handlePanStart(DragStartDetails details, Size size) {
//     if (_isDisposed) return;

//     if (!(widget.brushMode == BrushMode.freehand ||
//         widget.brushMode == BrushMode.eraser)) {
//       return;
//     }

//     widget.onPaintingStarted?.call();

//     if (_currentStroke != null) return;

//     final p = _toPathSpace(details.localPosition, size);

//     int? foundIndex;
//     for (int i = 0; i < widget.regions.length; i++) {
//       if (widget.regions[i].path.contains(p)) {
//         foundIndex = i;
//         break;
//       }
//     }

//     setState(() {
//       _activeRegionIndex = foundIndex;
//       if (_activeRegionIndex != null) {
//         _currentStroke = Stroke(
//           points: <Offset>[p],
//           color: widget.brushMode == BrushMode.eraser
//               ? Colors.white
//               : widget.selectedColor,
//           style: widget.brushMode == BrushMode.eraser
//               ? StrokeStyle.solid
//               : widget.selectedStyle,
//           wallpaperImage: widget.selectedWallpaper,
//           wallpaperAsset: widget.selectedWallpaperAsset,
//         );
//         //     _currentStroke = Stroke(
//         //       points: <Offset>[p],
//         //       color: widget.brushMode == BrushMode.eraser
//         //           ? Colors.white
//         //           : widget.selectedColor,
//         //       style: widget.brushMode == BrushMode.eraser
//         //           ? StrokeStyle.solid
//         //           : widget.selectedStyle,
//         //       wallpaperImage: widget.selectedWallpaper,
//         //       wallpaperAsset: widget.selectedStyle == StrokeStyle.wallpaper
//         // ? widget.selectedStampAsset
//         // : null,
//         //     );
//         widget.regions[_activeRegionIndex!].strokes.add(_currentStroke!);

//         widget.onColoringAction({
//           'type': 'stroke',
//           'regionIndex': _activeRegionIndex!,
//           'stroke': _currentStroke!,
//         });
//       } else {
//         _currentStroke = null;
//       }
//     });
//   }

//   void _handlePanUpdate(DragUpdateDetails details, Size size) {
//     _lastTouchPosition = details.localPosition;
//     if (_currentStroke == null || _isDisposed) return;
//     final p = _toPathSpace(details.localPosition, size);

//     if (_activeRegionIndex != null) {
//       final region = widget.regions[_activeRegionIndex!];
//       if (region.path.contains(p)) {
//         // Always update the model (points) but only repaint at most
//         // `_minRepaintInterval` to reduce UI work.
//         _currentStroke!.points.add(p);
//         final now = DateTime.now();
//         if (now.difference(_lastRepaintTime) >= _minRepaintInterval) {
//           _lastRepaintTime = now;
//           setState(() {});
//         }
//       }
//     }
//   }

//   void _startBrushSound() {
//     if (widget.brushMode == BrushMode.freehand ||
//         widget.brushMode == BrushMode.eraser) {
//       BrushSoundService.instance.playLoop(_currentBrushSound());
//     }
//   }

//   void _stopBrushSound() {
//     BrushSoundService.instance.stop();
//   }

//   void _showStarAnimation() {
//     final animation = StarAnimation(
//       id: _animationId++,
//       position: _lastTouchPosition,
//     );

//     setState(() {
//       _animations.add(animation);
//     });
//   }

//   // void _removeAnimation(int id) {
//   //   if (!mounted) return;

//   //   setState(() {
//   //     _animations.removeWhere((e) => e.id == id);
//   //   });
//   // }

//   void _handlePanEnd(DragEndDetails details) {
//     if (widget.brushMode == BrushMode.freehand ||
//         widget.brushMode == BrushMode.eraser) {
//       widget.onPaintingEnded?.call();
//     }

//     if (_activeRegionIndex != null && _currentStroke != null) {
//       widget.onColoringAction({
//         'type': 'strokeFinished',
//         'regionIndex': _activeRegionIndex!,
//         'stroke': _currentStroke!,
//       });
//     }

//     _activeRegionIndex = null;
//     _currentStroke = null;

//     _showStarAnimation();
//   }

//   ui.Picture _rasterizeStrokeToPicture(Stroke stroke, Rect regionBounds) {
//     double s = 1.0;
//     if (_lastCanvasSize != null) {
//       final t = _computeTransform(_lastCanvasSize!);
//       // use the smaller axis so stroke width doesn't look stretched
//       s = t['scaleX']! < t['scaleY']! ? t['scaleX']! : t['scaleY']!;
//     }

//     final painter = ColoringPainter(
//       regions: [],
//       scaleX: s,
//       scaleY: s,
//       tx: 0,
//       ty: 0,
//       glitterImage: _glitterImage,
//       strokePictureCache: {},
//     );

//     try {
//       final recorder = ui.PictureRecorder();
//       final canvas = Canvas(recorder);
//       painter.drawStyledStroke(canvas, stroke, regionBounds);
//       return recorder.endRecording();
//     } catch (e) {
//       debugPrint('Error rasterizing stroke: $e');
//       final r = ui.PictureRecorder();
//       return r.endRecording();
//     }
//   }

//   void _handleTapUp(TapUpDetails details, Size size) {
//     if (widget.brushMode == BrushMode.freehand ||
//         widget.brushMode == BrushMode.eraser
//     // ||
//     // widget.brushMode == BrushMode.stamp
//     ) {
//       widget.onPaintingEnded?.call();
//     }
//     _showStarAnimation();
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_isDisposed) {
//       return const SizedBox.shrink();
//     }

//     _computeBounds();

//     return LayoutBuilder(
//       builder: (context, constraints) {
//         final size = Size(constraints.maxWidth, constraints.maxHeight);

//         _lastCanvasSize = size;

//         final transform = _computeTransform(size);

//         final sx = transform['scaleX']!;
//         final sy = transform['scaleY']!;
//         final tx = transform['tx']!;
//         final ty = transform['ty']!;

//         return GestureDetector(
//           behavior: HitTestBehavior.opaque,

//           // =========================
//           // TAP
//           // Fill / Magic / Stamp
//           // =========================
//           onTapDown: (details) {
//             if (widget.brushMode == BrushMode.fill ||
//                 widget.brushMode == BrushMode.magic ||
//                 widget.brushMode == BrushMode.stamp) {
//               _handleTapDown(details, size);
//             }
//           },

//           // =========================
//           // SCALE
//           // 1 Finger = Drawing
//           // 2 Fingers = Zoom + Pan
//           // =========================
//           onScaleStart: (details) {
//             _startZoom = _zoom;
//             _startPan = _pan;
//             _startFocalPoint = details.focalPoint;

//             if (details.pointerCount == 1 &&
//                 (widget.brushMode == BrushMode.freehand ||
//                     widget.brushMode == BrushMode.eraser)) {
//               _handlePanStart(
//                 DragStartDetails(
//                   globalPosition: details.focalPoint,
//                   localPosition: details.localFocalPoint,
//                 ),
//                 size,
//               );

//               _startBrushSound();
//             }
//           },

//           onScaleUpdate: (details) {
//             // ==============================
//             // TWO FINGERS = ZOOM + PAN
//             // ==============================
//             if (details.pointerCount >= 2) {
//               if (_currentStroke != null) {
//                 _stopBrushSound();
//                 _currentStroke = null;
//                 _activeRegionIndex = null;
//               }

//               setState(() {
//                 _zoom = (_startZoom * details.scale).clamp(1.0, 4.0);

//                 final delta = details.focalPoint - _startFocalPoint;

//                 _pan = _startPan + delta;
//               });

//               return;
//             }

//             // ==============================
//             // ONE FINGER = DRAW
//             // ==============================
//             if (details.pointerCount == 1 &&
//                 (widget.brushMode == BrushMode.freehand ||
//                     widget.brushMode == BrushMode.eraser)) {
//               _handlePanUpdate(
//                 DragUpdateDetails(
//                   globalPosition: details.focalPoint,
//                   localPosition: details.localFocalPoint,
//                   delta: details.focalPointDelta,
//                 ),
//                 size,
//               );
//             }
//           },

//           onScaleEnd: (details) {
//             _stopBrushSound();

//             if (_currentStroke != null) {
//               _handlePanEnd(DragEndDetails(velocity: details.velocity));
//             }
//           },

//           child: CustomPaint(
//             size: size,
//             painter: ColoringPainter(
//               regions: widget.regions,
//               scaleX: sx,
//               scaleY: sy,
//               tx: tx,
//               ty: ty,
//               zoom: _zoom,
//               pan: _pan,
//               glitterImage: _glitterImage,
//               strokePictureCache: _strokePictureCache,
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

class StarAnimation {
  final int id;
  final Offset position;

  StarAnimation({required this.id, required this.position});
}

enum BrushMode { fill, magic, freehand, eraser, stamp }

class ColoringCanvas extends StatefulWidget {
  final List<Region> regions;
  final BrushMode brushMode;
  final Color selectedColor;
  final StrokeStyle selectedStyle;
  final Function(dynamic) onColoringAction;
  final ui.Image? selectedWallpaper;
  final String? selectedStampAsset;
  final ValueChanged<String>? onStampSelected;
  final double stampSize;
  final VoidCallback? onPaintingStarted;
  final VoidCallback? onPaintingEnded;
  final VoidCallback? onClearRequested;
  final String? selectedWallpaperAsset;

  const ColoringCanvas({
    super.key,
    required this.regions,
    required this.brushMode,
    required this.selectedColor,
    required this.selectedStyle,
    required this.onColoringAction,
    this.selectedWallpaper,
    this.selectedWallpaperAsset,
    this.selectedStampAsset,
    this.onStampSelected,
    required this.stampSize,
    this.onPaintingStarted,
    this.onPaintingEnded,
    this.onClearRequested,
  });

  @override
  State<ColoringCanvas> createState() => ColoringCanvasState();
}

class ColoringCanvasState extends State<ColoringCanvas> {
  Rect? _bounds;
  int? _activeRegionIndex;

  Stroke? _currentStroke;
  ui.Picture? _selectedSvgPicture;
  Size? _selectedSvgSize;
  final Map<String, ui.Picture> _stampCache = {};
  ui.Image? _glitterImage;
  bool _isLoadingGlitter = false;
  bool _isDisposed = false;
  final List<StarAnimation> _animations = [];
  int _animationId = 0;
  Offset _lastTouchPosition = Offset.zero;
  AppPreferences appPreferences = AppPreferences();
  /// ✅ CHANGED: keyed by the Stroke instance (identity) instead of its
  /// hashCode — a hashCode collision used to draw a different stroke's pixels.
  final Map<Stroke, ui.Picture> _strokePictureCache = {};
  // ----- old version (kept for reference) -----
  // final Map<int, ui.Picture> _strokePictureCache = {};

  /// ✅ NEW: bumped on every model mutation. ColoringPainter.shouldRepaint()
  /// compares it so a repaint no longer depends on being relaid out.
  int _revision = 0;

  DateTime _lastRepaintTime = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _minRepaintInterval = Duration(milliseconds: 30);

  Size? _lastCanvasSize;

  final Set<ui.Picture> _disposedPictures = {};

  Future<ui.Image?> _loadGlitterImage() async {
    if (_glitterImage != null) return _glitterImage;
    if (_isLoadingGlitter) return null;

    _isLoadingGlitter = true;
    try {
      final data = await rootBundle.load(ImageAssets.glitter);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      _glitterImage = frame.image;

      if (mounted && !_isDisposed) {
        setState(() {});
      }

      return _glitterImage;
    } catch (e) {
      debugPrint('Error loading glitter image: $e');
      return null;
    } finally {
      _isLoadingGlitter = false;
    }
  }

  @override
  void initState() {
    super.initState();

    _computeBounds();
    _loadGlitterImage();

    if (widget.selectedStampAsset != null) {
      _loadStamp(widget.selectedStampAsset!);
    }

    _restoreSavedStampPictures();
  }

  Future<void> _restoreSavedStampPictures() async {
    for (final region in widget.regions) {
      for (final stroke in region.strokes) {
        if (stroke.stampAsset == null) continue;

        try {
          if (!_stampCache.containsKey(stroke.stampAsset)) {
            final loader = SvgAssetLoader(stroke.stampAsset!);

            final pictureInfo = await vg.loadPicture(loader, null);

            _stampCache[stroke.stampAsset!] = pictureInfo.picture;
          }

          stroke.svgPicture = _stampCache[stroke.stampAsset!];
        } catch (e) {
          debugPrint("Cannot restore stamp: $e");
        }
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  void refresh() {
    if (mounted && !_isDisposed) {
      // ✅ NEW: drop rasterised pictures of strokes that no longer exist
      // (undo / redo / clear all) before repainting.
      _pruneStrokePictures();
      setState(() {
        _revision++; // ✅ NEW: tell the painter the model changed
      });
    }
  }

  /// ✅ NEW: keeps the stroke picture cache from growing without bound when
  /// strokes are removed by undo, redo or "clear all".
  void _pruneStrokePictures() {
    if (_strokePictureCache.isEmpty) return;

    final alive = <Stroke>{};
    for (final region in widget.regions) {
      alive.addAll(region.strokes);
    }

    final dead = _strokePictureCache.keys
        .where((stroke) => !alive.contains(stroke))
        .toList();

    for (final stroke in dead) {
      _safeDisposePicture(_strokePictureCache.remove(stroke));
    }
  }

  void _safeDisposePicture(ui.Picture? picture) {
    if (picture == null) return;

    if (_disposedPictures.contains(picture)) {
      return;
    }

    try {
      picture.dispose();
      _disposedPictures.add(picture);
    } catch (e) {
      debugPrint('Error disposing picture: $e');
    }
  }

  void _safeDisposeImage(ui.Image? image) {
    if (image == null) return;

    try {
      image.dispose();
    } catch (e) {
      debugPrint('Error disposing image: $e');
    }
  }

  @override
  void dispose() {
    if (_isDisposed) return;

    _isDisposed = true;

    // ✅ FIX: stop the pencil/eraser loop sound here too. It used to keep
    // looping if the page was left while a brush sound was playing.
    BrushSoundService.instance.stop();
    // ----- old version (kept for reference) -----
    // (nothing — dispose() did not touch the sound service)

    _currentStroke = null;

    _stampCache.forEach((key, picture) {
      _safeDisposePicture(picture);
    });
    _stampCache.clear();

    _strokePictureCache.forEach((key, picture) {
      _safeDisposePicture(picture);
    });
    _strokePictureCache.clear();

    _safeDisposePicture(_selectedSvgPicture);
    _selectedSvgPicture = null;

    _safeDisposeImage(_glitterImage);
    _glitterImage = null;

    _disposedPictures.clear();

    super.dispose();
  }

  @override
  void didUpdateWidget(ColoringCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_isDisposed) return;

    // ✅ NEW: the parent (undo/redo/clear all) may have mutated the regions
    // list without going through this state — make sure we repaint.
    _revision++;

    if (widget.onClearRequested != oldWidget.onClearRequested &&
        widget.onClearRequested != null) {}

    // ✅ FIX: the stamp asset can be cleared back to null; the old code did
    // `_loadStamp(widget.selectedStampAsset!)` and would crash on that null.
    final newStampAsset = widget.selectedStampAsset;
    if (newStampAsset != null &&
        (newStampAsset != oldWidget.selectedStampAsset ||
            (widget.brushMode == BrushMode.stamp &&
                oldWidget.brushMode != BrushMode.stamp))) {
      _loadStamp(newStampAsset);
    }
    // ----- old version (kept for reference) -----
    // if (widget.selectedStampAsset != oldWidget.selectedStampAsset ||
    //     (widget.brushMode == BrushMode.stamp &&
    //         oldWidget.brushMode != BrushMode.stamp &&
    //         widget.selectedStampAsset != null)) {
    //   _loadStamp(widget.selectedStampAsset!);
    // }
  }

  Future<void> _loadStamp(String assetPath) async {
    if (_isDisposed) return;

    try {
      if (_stampCache.containsKey(assetPath)) {
        setState(() {
          _selectedSvgPicture = _stampCache[assetPath];
        });
        return;
      }

      final pictureInfo = await vg.loadPicture(SvgAssetLoader(assetPath), null);

      if (_isDisposed) {
        _safeDisposePicture(pictureInfo.picture);
        return;
      }

      setState(() {
        _selectedSvgPicture = pictureInfo.picture;
        _selectedSvgSize = pictureInfo.size;

        _stampCache[assetPath] = pictureInfo.picture;
      });
    } catch (e, st) {
      debugPrint('Error loading SVG stamp: $e\n$st');
    }
  }

  void _computeBounds() {
    if (widget.regions.isEmpty) {
      _bounds = Rect.fromLTWH(0, 0, 1, 1);
      return;
    }
    Rect b = widget.regions.first.getBounds();
    for (final r in widget.regions.skip(1)) {
      b = b.expandToInclude(r.getBounds());
    }
    _bounds = b;
  }

  Map<String, double> _computeTransform(Size size) {
    final bounds = _bounds ?? Rect.fromLTWH(0, 0, 1, 1);
    final bw = bounds.width <= 0 ? 1.0 : bounds.width;
    final bh = bounds.height <= 0 ? 1.0 : bounds.height;

    // ✅ FIX: ONE scale for both axes, so the artwork keeps its own aspect
    // ratio instead of being stretched to fill the canvas (circles stayed
    // circles, and the same painting now looks the same on every screen).
    final scale = math.min(size.width / bw, size.height / bh);

    final drawnWidth = bw * scale;
    final drawnHeight = bh * scale;

    // Centre the drawing inside the available canvas.
    final offsetX = (size.width - drawnWidth) / 2;
    final offsetY = (size.height - drawnHeight) / 2;

    final tx = offsetX - bounds.left * scale;
    final ty = offsetY - bounds.top * scale;

    return {'scaleX': scale, 'scaleY': scale, 'tx': tx, 'ty': ty};

    // ----- old version (kept for reference) -----
    // final scaleX = size.width / bw;
    // final scaleY = size.height / bh;
    //
    // final tx = -bounds.left * scaleX;
    // final ty = -bounds.top * scaleY;
    //
    // return {'scaleX': scaleX, 'scaleY': scaleY, 'tx': tx, 'ty': ty};
  }

  Offset _toPathSpace(Offset localPos, Size size) {
    final t = _computeTransform(size);
    final sx = t['scaleX']!;
    final sy = t['scaleY']!;
    final tx = t['tx']!;
    final ty = t['ty']!;
    return Offset((localPos.dx - tx) / sx, (localPos.dy - ty) / sy);
  }

  void _handleTapDown(TapDownDetails details, Size size) {
    _lastTouchPosition = details.localPosition;
    if (_isDisposed) return;

    if (widget.brushMode == BrushMode.freehand ||
        widget.brushMode == BrushMode.eraser ||
        widget.brushMode == BrushMode.stamp) {
      widget.onPaintingStarted?.call();
    }

    final p = _toPathSpace(details.localPosition, size);

    if (widget.brushMode == BrushMode.stamp && _selectedSvgPicture != null) {
      // ✅ FIX: walk back to front (the last drawn shape is the one the child
      // sees) and ignore hidden geometry, which used to swallow the tap.
      // ----- old version (kept for reference) -----
      // for (int i = 0; i < widget.regions.length; i++) {
      //   final region = widget.regions[i];
      //   if (region.path.contains(p)) {
      for (int i = widget.regions.length - 1; i >= 0; i--) {
        final region = widget.regions[i];
        if (region.hidden) continue;
        if (region.path.contains(p)) {
          BrushSoundService.instance.playOnce(
            _currentBrushSound(),
            appPreferences.getKSoundVolum(),
          );
          final stamp = Stroke(
            points: [p],
            color: Colors.transparent,
            style: StrokeStyle.stampSvg,
            stampSize: widget.stampSize,
            svgPicture: _selectedSvgPicture,
            svgSize: _selectedSvgSize,
            stampAsset: widget.selectedStampAsset,
          );

          region.strokes.add(stamp);

          setState(() {});

          widget.onColoringAction({
            'type': 'stamp',
            'regionIndex': i,
            'stroke': stamp,
          });

          debugPrint('Stamp placed in region $i at: $p');
          break;
        }
      }
    }

    // ✅ FIX: same as above — topmost shape first, hidden geometry ignored.
    // ----- old version (kept for reference) -----
    // for (int i = 0; i < widget.regions.length; i++) {
    //   final region = widget.regions[i];
    //   if (region.path.contains(p)) {
    for (int i = widget.regions.length - 1; i >= 0; i--) {
      final region = widget.regions[i];
      if (region.hidden) continue;
      if (region.path.contains(p)) {
        setState(() {
          _revision++; // ✅ NEW: model changed -> repaint

          if (widget.brushMode == BrushMode.fill) {
            // ✅ FIX: a region whose colour is locked by the artwork
            // (keepcolor="true") ignores fills — it must not clear the
            // child's stamps either, nor record an undo step.
            if (region.keepOriginalColor) {
              return;
            }
            // ----- old version (kept for reference) -----
            // (nothing — the fill branch ran for locked regions too, wiping
            //  their strokes and pushing a no-op FillAction)
            BrushSoundService.instance.playOnce(
              _currentBrushSound(),
              appPreferences.getKSoundVolum(),
            );
            final previousColor = region.currentFillColor;
            final previousStyle = region.currentFillStyle;
            final previousStrokes = region.strokes
                .map((s) => s.copyWith())
                .toList();

            region.fill(widget.selectedColor, widget.selectedStyle);
            region.strokes.clear();

            widget.onColoringAction({
              'type': 'fill',
              'regionIndex': i,
              'previousColor': previousColor,
              'newColor': widget.selectedColor,
              'previousStyle': previousStyle,
              'newStyle': widget.selectedStyle,
              'previousStrokes': previousStrokes,
            });
          } else if (widget.brushMode == BrushMode.magic) {
            BrushSoundService.instance.playOnce(
              _currentBrushSound(),
              appPreferences.getKSoundVolum(),
            );
            final previousColor = region.currentFillColor;
            final previousStyle = region.currentFillStyle;
            final previousStrokes = region.strokes
                .map((s) => s.copyWith())
                .toList();

            region.resetToOriginal();
            region.strokes.clear();

            widget.onColoringAction({
              'type': 'magic',
              'regionIndex': i,
              'previousColor': previousColor,
              'previousStyle': previousStyle,
              'previousStrokes': previousStrokes,
            });
          } else if (widget.brushMode == BrushMode.freehand ||
              widget.brushMode == BrushMode.eraser) {
            _activeRegionIndex = i;

            _currentStroke = Stroke(
              points: <Offset>[p],
              color: widget.brushMode == BrushMode.eraser
                  ? Colors.white
                  : widget.selectedColor,
              style: widget.brushMode == BrushMode.eraser
                  ? StrokeStyle.solid
                  : widget.selectedStyle,
              wallpaperImage: widget.selectedWallpaper,
              wallpaperAsset: widget.selectedWallpaperAsset,
            );
            region.strokes.add(_currentStroke!);

            widget.onColoringAction({
              'type': 'stroke',
              'regionIndex': i,
              'stroke': _currentStroke!,
            });
          }
        });
        break;
      }
    }
  }

  String _currentBrushSound() {
    switch (widget.brushMode) {
      case BrushMode.fill:
        return "sounds/fill.mp3";

      case BrushMode.eraser:
        return "sounds/eraser.mp3";

      case BrushMode.freehand:
        return "sounds/pencil.mp3";

      case BrushMode.stamp:
        return "sounds/stamp.mp3";

      case BrushMode.magic:
        return "sounds/magic.mp3";
    }
  }

  void _handlePanStart(DragStartDetails details, Size size) {
    if (_isDisposed) return;

    if (!(widget.brushMode == BrushMode.freehand ||
        widget.brushMode == BrushMode.eraser)) {
      return;
    }

    widget.onPaintingStarted?.call();

    if (_currentStroke != null) return;

    final p = _toPathSpace(details.localPosition, size);

    int? foundIndex;
    // ✅ FIX: match the tap behaviour — topmost shape wins, hidden geometry
    // is not drawable.
    // ----- old version (kept for reference) -----
    // for (int i = 0; i < widget.regions.length; i++) {
    //   if (widget.regions[i].path.contains(p)) {
    //     foundIndex = i;
    //     break;
    //   }
    // }
    for (int i = widget.regions.length - 1; i >= 0; i--) {
      final region = widget.regions[i];
      if (region.hidden) continue;
      if (region.path.contains(p)) {
        foundIndex = i;
        break;
      }
    }

    setState(() {
      _activeRegionIndex = foundIndex;
      if (_activeRegionIndex != null) {
        _currentStroke = Stroke(
          points: <Offset>[p],
          color: widget.brushMode == BrushMode.eraser
              ? Colors.white
              : widget.selectedColor,
          style: widget.brushMode == BrushMode.eraser
              ? StrokeStyle.solid
              : widget.selectedStyle,
          wallpaperImage: widget.selectedWallpaper,
          wallpaperAsset: widget.selectedWallpaperAsset,
        );

        widget.regions[_activeRegionIndex!].strokes.add(_currentStroke!);

        widget.onColoringAction({
          'type': 'stroke',
          'regionIndex': _activeRegionIndex!,
          'stroke': _currentStroke!,
        });
      } else {
        _currentStroke = null;
      }
    });
  }

  void _handlePanUpdate(DragUpdateDetails details, Size size) {
    _lastTouchPosition = details.localPosition;
    if (_currentStroke == null || _isDisposed) return;
    final p = _toPathSpace(details.localPosition, size);

    if (_activeRegionIndex != null) {
      final region = widget.regions[_activeRegionIndex!];
      if (region.path.contains(p)) {
        _currentStroke!.points.add(p);
        final now = DateTime.now();
        if (now.difference(_lastRepaintTime) >= _minRepaintInterval) {
          _lastRepaintTime = now;
          setState(() {
            _revision++; // ✅ NEW: repaint the growing stroke
          });
        }
      }
    }
  }

  void _startBrushSound() {
    if (widget.brushMode == BrushMode.freehand ||
        widget.brushMode == BrushMode.eraser) {
      BrushSoundService.instance.playLoop(_currentBrushSound());
    }
  }

  void _stopBrushSound() {
    BrushSoundService.instance.stop();
  }

  void _showStarAnimation() {
    final animation = StarAnimation(
      id: _animationId++,
      position: _lastTouchPosition,
    );

    setState(() {
      _animations.add(animation);
      _revision++; // ✅ NEW: repaint with the new model state
    });

    // ✅ FIX: remove the confetti again after it has played. It used to stay
    // in the Stack forever, so every tap added another live Lottie widget —
    // unbounded memory/layout cost over a session.
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted || _isDisposed) return;
      setState(() {
        _animations.removeWhere((a) => a.id == animation.id);
      });
    });
    // ----- old version (kept for reference) -----
    // setState(() {
    //   _animations.add(animation);
    // });
  }

  void _handlePanEnd(DragEndDetails details) {
    if (widget.brushMode == BrushMode.freehand ||
        widget.brushMode == BrushMode.eraser) {
      widget.onPaintingEnded?.call();
    }

    if (_currentStroke != null && _activeRegionIndex != null) {
      try {
        final region = widget.regions[_activeRegionIndex!];
        final picture = _rasterizeStrokeToPicture(
          _currentStroke!,
          region.path.getBounds(),
        );

        // ✅ FIX: cache by the Stroke instance itself (identity), not by its
        // hashCode, so a hash collision can no longer paint another stroke.
        final stroke = _currentStroke!;
        if (_strokePictureCache.containsKey(stroke)) {
          _safeDisposePicture(_strokePictureCache[stroke]);
        }
        _strokePictureCache[stroke] = picture;
        // ----- old version (kept for reference) -----
        // final key = _currentStroke!.hashCode;
        // if (_strokePictureCache.containsKey(key)) {
        //   _safeDisposePicture(_strokePictureCache[key]);
        // }
        // _strokePictureCache[key] = picture;
      } catch (e) {
        debugPrint('Error caching stroke picture: $e');
      }
    }

    if (_activeRegionIndex != null && _currentStroke != null) {
      widget.onColoringAction({
        'type': 'strokeFinished',
        'regionIndex': _activeRegionIndex!,
        'stroke': _currentStroke!,
      });
    }
    _activeRegionIndex = null;
    _currentStroke = null;
    _revision++; // ✅ NEW: the stroke is now in the cache -> repaint

    _showStarAnimation();
  }

  ui.Picture _rasterizeStrokeToPicture(Stroke stroke, Rect regionBounds) {
    double s = 1.0;
    if (_lastCanvasSize != null) {
      final t = _computeTransform(_lastCanvasSize!);
      // ✅ FIX: use the SAME factor as ColoringPainter._strokeScale
      // ((scaleX + scaleY) / 2). The old code used min(scaleX, scaleY) here,
      // so every stroke got visibly thicker (up to 1.5x) the moment the
      // finger was lifted and the cached picture was used instead.
      s = (t['scaleX']! + t['scaleY']!) / 2.0;
      // ----- old version (kept for reference) -----
      // // use the smaller axis so stroke width doesn't look stretched
      // s = t['scaleX']! < t['scaleY']! ? t['scaleX']! : t['scaleY']!;
    }

    final painter = ColoringPainter(
      regions: [],
      scaleX: s,
      scaleY: s,
      tx: 0,
      ty: 0,
      glitterImage: _glitterImage,
      strokePictureCache: {},
    );

    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      painter.drawStyledStroke(canvas, stroke, regionBounds);
      return recorder.endRecording();
    } catch (e) {
      debugPrint('Error rasterizing stroke: $e');
      final r = ui.PictureRecorder();
      return r.endRecording();
    }
  }

  void _handleTapUp(TapUpDetails details, Size size) {
    if (widget.brushMode == BrushMode.freehand ||
        widget.brushMode == BrushMode.eraser) {
      widget.onPaintingEnded?.call();
    }

    // ✅ FIX: a tap in freehand/eraser mode starts a stroke on tap-down. That
    // stroke used to stay "open" forever, so the NEXT drag was appended to it
    // (because _handlePanStart() early-returns while _currentStroke != null):
    // the child saw a rubber-band line from the old tap point, clipped to the
    // old region. Close and flush it here instead.
    final finishedStroke = _currentStroke;
    final finishedRegion = _activeRegionIndex;

    if (finishedStroke != null && finishedRegion != null) {
      try {
        final region = widget.regions[finishedRegion];
        _strokePictureCache[finishedStroke] = _rasterizeStrokeToPicture(
          finishedStroke,
          region.path.getBounds(),
        );
      } catch (e) {
        debugPrint('Error caching tap stroke picture: $e');
      }

      // Let the page store the finished dot (and record it for undo).
      widget.onColoringAction({'type': 'strokeFinished'});
    }

    _activeRegionIndex = null;
    _currentStroke = null;
    // ----- old version (kept for reference) -----
    // (nothing was reset here, which is what caused the bug above)

    _showStarAnimation();
  }

  /// ✅ NEW: a cancelled drag (second finger, system gesture, arena
  /// re-resolution) used to leave the brush sound looping and _currentStroke
  /// alive, which blocked every following stroke until the page was reopened.
  void _handlePanCancel() {
    _stopBrushSound();

    final cancelledStroke = _currentStroke;
    final cancelledRegion = _activeRegionIndex;

    if (cancelledStroke != null && cancelledRegion != null) {
      // Keep what the child already drew, exactly like a normal stroke end.
      try {
        final region = widget.regions[cancelledRegion];
        _strokePictureCache[cancelledStroke] = _rasterizeStrokeToPicture(
          cancelledStroke,
          region.path.getBounds(),
        );
      } catch (e) {
        debugPrint('Error caching cancelled stroke picture: $e');
      }
      widget.onColoringAction({'type': 'strokeFinished'});
    }

    _activeRegionIndex = null;
    _currentStroke = null;
    _revision++;
    // No confetti for a cancelled gesture — just make sure we repaint.
    if (mounted && !_isDisposed) setState(() {});
  }

  /// ✅ NEW: silence the brush when a tap is cancelled, but stay out of the
  /// way when that "tap" is really the first 100 ms of a drag (Flutter fires
  /// onTapDown after kPressTimeout) — the pan handlers own the sound then.
  void _handleTapCancel() {
    if (_currentStroke == null) {
      _stopBrushSound();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDisposed) {
      return const SizedBox.shrink();
    }

    _computeBounds();

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        // ✅ FIX: this printed on every layout (hot path, production log spam)
        // ----- old version (kept for reference) -----
        // debugPrint('Canvas size: $size');
        _lastCanvasSize = size;

        final transform = _computeTransform(size);
        final sx = transform['scaleX']!;
        final sy = transform['scaleY']!;
        final tx = transform['tx']!;
        final ty = transform['ty']!;

        _lastCanvasSize = size;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) {
            _handleTapDown(d, size);
          },
          onTapUp: (d) {
            _handleTapUp(d, size);
          },
          // ✅ NEW: without these two handlers a cancelled gesture left the
          // brush sound looping and _currentStroke alive.
          onTapCancel: _handleTapCancel,
          onPanCancel: _handlePanCancel,
          onPanStart: (d) {
            _startBrushSound();
            _handlePanStart(d, size);
          },
          onPanUpdate: (d) => _handlePanUpdate(d, size),
          onPanEnd: (d) {
            _stopBrushSound();
            _handlePanEnd(d);
          },
          child: Stack(
            children: [
              CustomPaint(
                size: size,
                painter: ColoringPainter(
                  regions: widget.regions,
                  scaleX: sx,
                  scaleY: sy,
                  tx: tx,
                  ty: ty,
                  glitterImage: _glitterImage,
                  strokePictureCache: _strokePictureCache,
                  revision: _revision, // ✅ NEW: drives shouldRepaint()
                ),
              ),
              ..._animations.map((animation) {
                return Positioned(
                  // ✅ NEW: a stable key so removing one confetti does not
                  // recycle another one's Lottie state.
                  key: ValueKey(animation.id),
                  left: animation.position.dx - 45,
                  top: animation.position.dy - 45,
                  child: SizedBox(
                    width: 90,
                    height: 90,
                    child: IgnorePointer(
                      child: Lottie.asset(
                        "assets/json/Confetti.json",
                        repeat: false,
                        onLoaded: (_) {},
                        delegates: null,
                        frameRate: FrameRate.max,
                        animate: true,
                        fit: BoxFit.contain,
                        options: LottieOptions(enableMergePaths: true),
                        controller: null,
                        onWarning: (warning) {},
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
