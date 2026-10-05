// The rest of your _ColoringPainter class remains the same...
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:fun_painting/presentation/painting/region.dart';

/// Painter: applies translate/scale then draws regions & strokes.
class ColoringPainter extends CustomPainter {
  final List<Region> regions;
  final double scaleX;
  final double scaleY;
  final double tx;
  final double ty;
  final ui.Image? glitterImage;
  final Map<int, ui.Picture> strokePictureCache;
  final double zoom;
  final Offset pan;
  ColoringPainter({
    required this.regions,
    required this.scaleX,
    required this.scaleY,
    required this.tx,
    required this.ty,
    this.glitterImage,
    required this.strokePictureCache,
    this.zoom = 1.0,
    this.pan = Offset.zero,
  });

  // helper: a single "average" scale for stroke widths so pen/pencil/glitter
  // widths don't look stretched — use this in place of every old `scale`
  // inside stroke-width calculations below.
  double get _strokeScale => (scaleX + scaleY) / 2.0;

  // Create a smoothed path from raw points using quadratic beziers.
  Path _createSmoothedPath(List<Offset> pts) {
    final path = Path();
    if (pts.isEmpty) return path;
    if (pts.length == 1) {
      path.moveTo(pts.first.dx, pts.first.dy);
      return path;
    }

    path.moveTo(pts.first.dx, pts.first.dy);
    if (pts.length == 2) {
      path.lineTo(pts.last.dx, pts.last.dy);
      return path;
    }

    for (int i = 0; i < pts.length - 1; i++) {
      final p0 = pts[i];
      final p1 = pts[i + 1];
      final mid = Offset((p0.dx + p1.dx) / 2.0, (p0.dy + p1.dy) / 2.0);
      path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
    }
    // Ensure path reaches the last point
    path.lineTo(pts.last.dx, pts.last.dy);
    return path;
  }

  // Random generator removed (unused). Use local, seeded Random per-stroke where
  // deterministic behavior across repaints is desired.

  void _drawStampSvg(Canvas canvas, Stroke stroke) {
    if (stroke.svgPicture == null ||
        stroke.points.isEmpty ||
        stroke.stampSize <= 0) {
      return;
    }

    try {
      final svgSize =
          stroke.svgSize ?? Size(stroke.stampSize, stroke.stampSize);

      if (svgSize.width <= 0) return;

      final scale = stroke.stampSize / svgSize.width;

      for (final pos in stroke.points) {
        canvas.save();
        canvas.translate(
          pos.dx - stroke.stampSize / 2,
          pos.dy - stroke.stampSize / 2,
        );
        canvas.scale(scale, scale);

        try {
          canvas.drawPicture(stroke.svgPicture!);
        } catch (e) {
          debugPrint('Error drawing stamp picture: $e');
        }

        canvas.restore();
      }
    } catch (e) {
      debugPrint('Error in _drawStampSvg: $e');
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(tx, ty);
    canvas.scale(scaleX, scaleY);

    for (final region in regions) {
      final fillPaint = Paint()..style = PaintingStyle.fill;
      if (region.currentFillStyle case StrokeStyle.solid) {
        fillPaint.color = region.currentFillColor;
      } else if (region.currentFillStyle case StrokeStyle.glitter) {
        fillPaint.shader = ui.Gradient.linear(
          region.path.getBounds().topLeft,
          region.path.getBounds().bottomRight,
          [
            region.currentFillColor,
            region.currentFillColor.withOpacity(0.6),
            Colors.white,
          ],
          const [0.0, 0.6, 1.0],
        );
      } else if (region.currentFillStyle case StrokeStyle.rainbow) {
        fillPaint.shader = ui.Gradient.linear(
          region.path.getBounds().topLeft,
          region.path.getBounds().bottomRight,
          [
            Colors.red,
            Colors.orange,
            Colors.yellow,
            Colors.green,
            Colors.blue,
            Colors.purple,
          ],
        );
      } else if (region.currentFillStyle
          case StrokeStyle.patternStars || StrokeStyle.patternHearts) {
        fillPaint.color = region.currentFillColor.withOpacity(0.85);
      } else if (region.currentFillStyle case StrokeStyle.neon) {
        fillPaint.color = region.currentFillColor;
        fillPaint.maskFilter = const MaskFilter.blur(BlurStyle.outer, 8);
      }
      canvas.drawPath(region.path, fillPaint);

      if (region.currentFillStyle == StrokeStyle.patternStars ||
          region.currentFillStyle == StrokeStyle.patternHearts) {
        _paintPatternFill(canvas, region);
      }

      final effectiveStrokeWidth =
          region.strokeWidth / (_strokeScale <= 0 ? 1.0 : _strokeScale);
      final strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..color = region.strokeColor
        ..strokeWidth = effectiveStrokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(region.path, strokePaint);

      if (region.strokes.isNotEmpty) {
        canvas.save();
        canvas.clipPath(region.path);

        for (final stroke in region.strokes) {
          final pic = strokePictureCache[stroke.hashCode];
          if (pic != null) {
            try {
              canvas.drawPicture(pic);
            } catch (e) {
              // Fallback to drawing styled stroke if picture fails.
              drawStyledStroke(canvas, stroke, region.path.getBounds());
            }
          } else {
            drawStyledStroke(canvas, stroke, region.path.getBounds());
          }
        }

        canvas.restore();
      }
    }

    canvas.restore();
  }

  // Expose a way to rasterize a single stroke using painter's logic.
  // This method is used by the state to create a cached picture.
  ui.Picture rasterizeStrokeToPicture(Stroke stroke) {
    final recorder = ui.PictureRecorder();
    final c = Canvas(recorder);
    // Assume canvas already in path-space (no extra transforms needed).
    drawStyledStroke(c, stroke, Rect.largest);
    return recorder.endRecording();
  }

  void _paintPatternFill(Canvas canvas, Region region) {
    final bounds = region.path.getBounds();
    final emoji = region.currentFillStyle == StrokeStyle.patternStars
        ? '⭐'
        : '❤';
    final textPainter = TextPainter(
      text: TextSpan(
        text: emoji,
        style: TextStyle(fontSize: 18, color: region.currentFillColor),
      ),
      textDirection: TextDirection.ltr,
    );
    canvas.save();
    canvas.clipPath(region.path);
    for (double y = bounds.top; y < bounds.bottom; y += 24) {
      for (double x = bounds.left; x < bounds.right; x += 24) {
        textPainter.layout();
        textPainter.paint(canvas, Offset(x, y));
      }
    }
    canvas.restore();
  }

  void drawStyledStroke(Canvas canvas, Stroke stroke, Rect regionBounds) {
    if (stroke.points.isEmpty) return;

    switch (stroke.style) {
      case StrokeStyle.solid:
        _drawSolid(canvas, stroke);
        break;
      case StrokeStyle.glitter:
        drawKidsGlitter(canvas, stroke);
        break;
      case StrokeStyle.rainbow:
        _drawRainbow(canvas, stroke);
        break;
      case StrokeStyle.patternStars:
        _drawPatternAlongStroke(canvas, stroke, '⭐');
        break;
      case StrokeStyle.patternHearts:
        _drawPatternAlongStroke(canvas, stroke, '❤');
        break;
      case StrokeStyle.neon:
        _drawPencil(canvas, stroke);
        break;
      case StrokeStyle.crayon:
        _drawCrayon(canvas, stroke);
        break;
      case StrokeStyle.sticker:
        _drawStickers(canvas, stroke);
        break;
      case StrokeStyle.wallpaper:
        _drawWallpaperStroke(canvas, stroke);
        break;
      case StrokeStyle.stampSvg:
        _drawStampSvg(canvas, stroke);
        break;
    }
  }

  void _drawSolid(Canvas canvas, Stroke stroke) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = (15.0 / (_strokeScale <= 0 ? 1.0 : _strokeScale))
      ..color = stroke.color;
    if (stroke.points.length < 2) {
      canvas.drawCircle(stroke.points.first, paint.strokeWidth / 2.0, paint);
      return;
    }
    final path = Path()..moveTo(stroke.points.first.dx, stroke.points.first.dy);
    for (final p in stroke.points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, paint);
  }

  void drawKidsGlitter(Canvas canvas, Stroke stroke) {
    if (stroke.points.length < 2) return;

    final path = Path()..moveTo(stroke.points.first.dx, stroke.points.first.dy);
    for (final p in stroke.points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }

    final basePaint = Paint()
      ..color = stroke.color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 15.0 / (_strokeScale <= 0 ? 1.0 : _strokeScale)
      ..isAntiAlias = true;

    canvas.drawPath(path, basePaint);

    if (glitterImage != null) {
      const double glitterOpacity = 1;

      canvas.saveLayer(
        null,
        Paint()..color = Colors.white.withOpacity(glitterOpacity),
      );

      final glitterPaint = Paint()
        ..shader = ui.ImageShader(
          glitterImage!,
          TileMode.repeated,
          TileMode.repeated,
          Matrix4.diagonal3Values(.1, .1, 1).storage,
        )
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 15.0 / (_strokeScale <= 0 ? 1.0 : _strokeScale)
        ..blendMode = BlendMode.overlay
        ..isAntiAlias = true;

      canvas.drawPath(path, glitterPaint);

      canvas.restore();
    }
  }

  void _drawRainbow(Canvas canvas, Stroke stroke) {
    if (stroke.points.length < 2) {
      _drawSolid(canvas, stroke);
      return;
    }
    final rainbow = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.purple,
    ];
    for (int i = 1; i < stroke.points.length; i++) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = (14.0 / (_strokeScale <= 0 ? 1.0 : _strokeScale))
        ..color = rainbow[i % rainbow.length];
      canvas.drawLine(stroke.points[i - 1], stroke.points[i], paint);
    }
  }

  void _drawPatternAlongStroke(Canvas canvas, Stroke stroke, String emoji) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: emoji,
        style: TextStyle(fontSize: 16, color: stroke.color),
      ),
      textDirection: TextDirection.ltr,
    );
    const spacing = 18.0;
    for (int i = 1; i < stroke.points.length; i++) {
      final a = stroke.points[i - 1];
      final b = stroke.points[i];
      final seg = (b - a);
      final segLen = seg.distance;
      if (segLen == 0) continue;
      int steps = (segLen / spacing).floor();
      for (int j = 0; j <= steps; j++) {
        final t = j / (steps == 0 ? 1 : steps);
        final pos = Offset(a.dx + seg.dx * t, a.dy + seg.dy * t);
        textPainter.layout();
        textPainter.paint(canvas, pos);
      }
    }
  }

  void _drawPencil(Canvas canvas, Stroke stroke) {
    if (stroke.points.length < 2) return;

    final baseColor = stroke.color;
    var width = 8.0 / (_strokeScale <= 0 ? 1.0 : _strokeScale);

    // Increase overall pencil size by 1.25 as requested.
    width *= 1.25;

    // Deterministic RNG per-stroke for stable speck placement

    // Create layered stroke paints for the pencil look.
    // middle width reduced, then increased by 50% previously. Now increase
    // by an additional 75% as requested.
    final baseMid = width * 0.20;
    final baseOuter = baseMid * 1.6;
    final midWidth = baseMid * 1.5 * 1.75; // previous 1.5, now *1.75
    final outerWidth = baseOuter * 1.5 * 1.75;

    final outerColor = Color.lerp(
      baseColor,
      Colors.white,
      0.45,
    )!.withOpacity(0.30);
    final midColor = baseColor.withOpacity(0.64);
    final coreColor = Color.lerp(
      baseColor,
      Colors.black,
      0.06,
    )!.withOpacity(0.50);

    // Re-add outer stroke; mid-line widths will be reduced by 50% below.

    final outerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true
      ..color = outerColor
      ..strokeWidth = outerWidth * 0.4
      ..strokeCap = StrokeCap.butt
      ..strokeJoin = StrokeJoin.bevel
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);

    // We'll draw the middle area as multiple thin lines for texture.
    final midLines = 4; // number of thin middle lines
    // reduce mid-line width by 50%
    final singleMidLineWidth = (midWidth / midLines) * 0.5;

    final corePaint = Paint()
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true
      ..color = coreColor
      ..strokeWidth = width * 0.09
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Build a smoothed path for efficiency and to avoid round blobs at joins
    final path = _createSmoothedPath(stroke.points);

    // Draw outer then multiple thin mid-lines then core.
    canvas.drawPath(path, outerPaint);

    // Build offset mid-paths by offsetting each point perpendicular to the
    // local tangent. This produces multiple thin parallel lines.
    if (stroke.points.length >= 2) {
      for (int lineIndex = 0; lineIndex < midLines; lineIndex++) {
        // offsets: centered around 0.0
        final midOffsetIndex = lineIndex - (midLines - 1) / 2.0;
        final offsetDistance = midOffsetIndex * (singleMidLineWidth * 0.9);

        final List<Offset> offPoints = [];
        for (int i = 0; i < stroke.points.length; i++) {
          final p = stroke.points[i];
          // determine tangent using neighbors
          Offset tangent;
          if (i == 0) {
            tangent = stroke.points[1] - stroke.points[0];
          } else if (i == stroke.points.length - 1) {
            tangent = stroke.points[i] - stroke.points[i - 1];
          } else {
            tangent = stroke.points[i + 1] - stroke.points[i - 1];
          }
          final tlen = tangent.distance;
          Offset normal = Offset.zero;
          if (tlen != 0) normal = Offset(-tangent.dy / tlen, tangent.dx / tlen);
          final op = p + normal * offsetDistance;
          offPoints.add(op);
        }
        final midPath = _createSmoothedPath(offPoints);

        final midPaintLine = Paint()
          ..style = PaintingStyle.stroke
          ..isAntiAlias = true
          ..color = midColor
          // reduce each mid-line stroke a bit to emphasize color over thickness
          ..strokeWidth = singleMidLineWidth * 0.8
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

        canvas.drawPath(midPath, midPaintLine);
      }
    }

    canvas.drawPath(path, corePaint);

    // Specks removed per user request to avoid circular artifacts.
  }

  void _drawCrayon(Canvas canvas, Stroke stroke) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = (12.0 / (_strokeScale <= 0 ? 1.0 : _strokeScale))
      ..color = stroke.color;
    // Use a per-stroke seed so jitter is consistent for the same stroke.
    final rnd = Random(stroke.hashCode ^ stroke.points.length);
    for (int i = 1; i < stroke.points.length; i++) {
      final jitter = Offset(
        (rnd.nextDouble() - 0.5) * 3,
        (rnd.nextDouble() - 0.5) * 3,
      );
      canvas.drawLine(
        stroke.points[i - 1] + jitter,
        stroke.points[i] + jitter,
        paint,
      );
    }
  }

  void _drawStickers(Canvas canvas, Stroke stroke) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: '🌟',
        style: TextStyle(fontSize: 40, color: stroke.color),
      ),
      textDirection: TextDirection.ltr,
    );
    // Layout once and center each emoji at the stroke point.
    textPainter.layout();
    final halfSize = Offset(
      textPainter.size.width / 2,
      textPainter.size.height / 2,
    );
    for (final pos in stroke.points) {
      textPainter.paint(canvas, pos - halfSize);
    }
  }

  void _drawWallpaperStroke(Canvas canvas, Stroke stroke) {
    debugPrint("Drawing wallpaper: ${stroke.wallpaperAsset}");
    if (stroke.wallpaperImage == null || stroke.points.length < 2) return;

    final path = Path()..moveTo(stroke.points.first.dx, stroke.points.first.dy);
    for (final p in stroke.points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }

    final paint = Paint()
      ..shader = ui.ImageShader(
        stroke.wallpaperImage!,
        TileMode.repeated,
        TileMode.repeated,
        Matrix4.identity().storage,
      )
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 15.0 / (_strokeScale <= 0 ? 1.0 : _strokeScale)
      ..isAntiAlias = true;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ColoringPainter old) =>
      old.regions != regions ||
      old.scaleX != scaleX ||
      old.scaleY != scaleY ||
      old.tx != tx ||
      old.ty != ty ||
      old.glitterImage != glitterImage;

  // void _drawStyledStroke(ui.Canvas canvas, Stroke stroke, ui.Rect regionBounds) {}
}

// The rest of your _ColoringPainter class remains the same...
// import 'dart:math';
// import 'dart:ui' as ui;

// import 'package:flutter/material.dart';
// import 'package:fun_painting/presentation/painting/region.dart';

// /// Painter: applies translate/scale then draws regions & strokes.
// class ColoringPainter extends CustomPainter {
//   final List<Region> regions;
//   final double scaleX;
//   final double scaleY;
//   final double tx;
//   final double ty;
//   final ui.Image? glitterImage;
//   final Map<int, ui.Picture> strokePictureCache;
//   final double zoom;
//   final Offset pan;
//   ColoringPainter({
//     required this.regions,
//     required this.scaleX,
//     required this.scaleY,
//     required this.tx,
//     required this.ty,
//     this.glitterImage,
//     required this.strokePictureCache,
//     this.zoom = 1.0,
//     this.pan = Offset.zero,
//   });

//   // helper: a single "average" scale for stroke widths so pen/pencil/glitter
//   // widths don't look stretched — use this in place of every old `scale`
//   // inside stroke-width calculations below.
//   double get _strokeScale => (scaleX + scaleY) / 2.0;

//   // Create a smoothed path from raw points using quadratic beziers.
//   Path _createSmoothedPath(List<Offset> pts) {
//     final path = Path();
//     if (pts.isEmpty) return path;
//     if (pts.length == 1) {
//       path.moveTo(pts.first.dx, pts.first.dy);
//       return path;
//     }

//     path.moveTo(pts.first.dx, pts.first.dy);
//     if (pts.length == 2) {
//       path.lineTo(pts.last.dx, pts.last.dy);
//       return path;
//     }

//     for (int i = 0; i < pts.length - 1; i++) {
//       final p0 = pts[i];
//       final p1 = pts[i + 1];
//       final mid = Offset((p0.dx + p1.dx) / 2.0, (p0.dy + p1.dy) / 2.0);
//       path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
//     }
//     // Ensure path reaches the last point
//     path.lineTo(pts.last.dx, pts.last.dy);
//     return path;
//   }

//   // Random generator removed (unused). Use local, seeded Random per-stroke where
//   // deterministic behavior across repaints is desired.

//   void _drawStampSvg(Canvas canvas, Stroke stroke) {
//     if (stroke.svgPicture == null ||
//         stroke.points.isEmpty ||
//         stroke.stampSize <= 0) {
//       return;
//     }

//     try {
//       final svgSize =
//           stroke.svgSize ?? Size(stroke.stampSize, stroke.stampSize);

//       if (svgSize.width <= 0) return;

//       final scale = stroke.stampSize / svgSize.width;

//       for (final pos in stroke.points) {
//         canvas.save();
//         canvas.translate(
//           pos.dx - stroke.stampSize / 2,
//           pos.dy - stroke.stampSize / 2,
//         );
//         canvas.scale(scale, scale);

//         try {
//           canvas.drawPicture(stroke.svgPicture!);
//         } catch (e) {
//           debugPrint('Error drawing stamp picture: $e');
//         }

//         canvas.restore();
//       }
//     } catch (e) {
//       debugPrint('Error in _drawStampSvg: $e');
//     }
//   }

//   @override
//   void paint(Canvas canvas, Size size) {
//     canvas.save();

//     final center = Offset(size.width / 2, size.height / 2);

//     // Zoom around center
//     canvas.translate(center.dx, center.dy);
//     canvas.scale(zoom);
//     canvas.translate(-center.dx, -center.dy);

//     // Pan
//     canvas.translate(pan.dx, pan.dy);

//     for (final region in regions) {
//       final fillPaint = Paint()..style = PaintingStyle.fill;
//       if (region.currentFillStyle case StrokeStyle.solid) {
//         fillPaint.color = region.currentFillColor;
//       } else if (region.currentFillStyle case StrokeStyle.glitter) {
//         fillPaint.shader = ui.Gradient.linear(
//           region.path.getBounds().topLeft,
//           region.path.getBounds().bottomRight,
//           [
//             region.currentFillColor,
//             region.currentFillColor.withOpacity(0.6),
//             Colors.white,
//           ],
//           const [0.0, 0.6, 1.0],
//         );
//       } else if (region.currentFillStyle case StrokeStyle.rainbow) {
//         fillPaint.shader = ui.Gradient.linear(
//           region.path.getBounds().topLeft,
//           region.path.getBounds().bottomRight,
//           [
//             Colors.red,
//             Colors.orange,
//             Colors.yellow,
//             Colors.green,
//             Colors.blue,
//             Colors.purple,
//           ],
//         );
//       } else if (region.currentFillStyle
//           case StrokeStyle.patternStars || StrokeStyle.patternHearts) {
//         fillPaint.color = region.currentFillColor.withOpacity(0.85);
//       } else if (region.currentFillStyle case StrokeStyle.neon) {
//         fillPaint.color = region.currentFillColor;
//         fillPaint.maskFilter = const MaskFilter.blur(BlurStyle.outer, 8);
//       }
//       canvas.drawPath(region.path, fillPaint);

//       if (region.currentFillStyle == StrokeStyle.patternStars ||
//           region.currentFillStyle == StrokeStyle.patternHearts) {
//         _paintPatternFill(canvas, region);
//       }

//       final effectiveStrokeWidth =
//           region.strokeWidth / (_strokeScale <= 0 ? 1.0 : _strokeScale);
//       final strokePaint = Paint()
//         ..style = PaintingStyle.stroke
//         ..color = region.strokeColor
//         ..strokeWidth = effectiveStrokeWidth
//         ..strokeCap = StrokeCap.round
//         ..strokeJoin = StrokeJoin.round;
//       canvas.drawPath(region.path, strokePaint);

//       if (region.strokes.isNotEmpty) {
//         canvas.save();
//         canvas.clipPath(region.path);

//         for (final stroke in region.strokes) {
//           final pic = strokePictureCache[stroke.hashCode];
//           if (pic != null) {
//             try {
//               canvas.drawPicture(pic);
//             } catch (e) {
//               // Fallback to drawing styled stroke if picture fails.
//               drawStyledStroke(canvas, stroke, region.path.getBounds());
//             }
//           } else {
//             drawStyledStroke(canvas, stroke, region.path.getBounds());
//           }
//         }

//         canvas.restore();
//       }
//     }

//     canvas.restore();
//   }

//   // Expose a way to rasterize a single stroke using painter's logic.
//   // This method is used by the state to create a cached picture.
//   ui.Picture rasterizeStrokeToPicture(Stroke stroke) {
//     final recorder = ui.PictureRecorder();
//     final c = Canvas(recorder);
//     // Assume canvas already in path-space (no extra transforms needed).
//     drawStyledStroke(c, stroke, Rect.largest);
//     return recorder.endRecording();
//   }

//   void _paintPatternFill(Canvas canvas, Region region) {
//     final bounds = region.path.getBounds();
//     final emoji = region.currentFillStyle == StrokeStyle.patternStars
//         ? '⭐'
//         : '❤';
//     final textPainter = TextPainter(
//       text: TextSpan(
//         text: emoji,
//         style: TextStyle(fontSize: 18, color: region.currentFillColor),
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     canvas.save();
//     canvas.clipPath(region.path);
//     for (double y = bounds.top; y < bounds.bottom; y += 24) {
//       for (double x = bounds.left; x < bounds.right; x += 24) {
//         textPainter.layout();
//         textPainter.paint(canvas, Offset(x, y));
//       }
//     }
//     canvas.restore();
//   }

//   void drawStyledStroke(Canvas canvas, Stroke stroke, Rect regionBounds) {
//     if (stroke.points.isEmpty) return;

//     switch (stroke.style) {
//       case StrokeStyle.solid:
//         _drawSolid(canvas, stroke);
//         break;
//       case StrokeStyle.glitter:
//         drawKidsGlitter(canvas, stroke);
//         break;
//       case StrokeStyle.rainbow:
//         _drawRainbow(canvas, stroke);
//         break;
//       case StrokeStyle.patternStars:
//         _drawPatternAlongStroke(canvas, stroke, '⭐');
//         break;
//       case StrokeStyle.patternHearts:
//         _drawPatternAlongStroke(canvas, stroke, '❤');
//         break;
//       case StrokeStyle.neon:
//         _drawPencil(canvas, stroke);
//         break;
//       case StrokeStyle.crayon:
//         _drawCrayon(canvas, stroke);
//         break;
//       case StrokeStyle.sticker:
//         _drawStickers(canvas, stroke);
//         break;
//       case StrokeStyle.wallpaper:
//         _drawWallpaperStroke(canvas, stroke);
//         break;
//       case StrokeStyle.stampSvg:
//         _drawStampSvg(canvas, stroke);
//         break;
//     }
//   }

//   void _drawSolid(Canvas canvas, Stroke stroke) {
//     final paint = Paint()
//       ..style = PaintingStyle.stroke
//       ..strokeCap = StrokeCap.round
//       ..strokeJoin = StrokeJoin.round
//       ..strokeWidth = (15.0 / (_strokeScale <= 0 ? 1.0 : _strokeScale))
//       ..color = stroke.color;
//     if (stroke.points.length < 2) {
//       canvas.drawCircle(stroke.points.first, paint.strokeWidth / 2.0, paint);
//       return;
//     }
//     final path = Path()..moveTo(stroke.points.first.dx, stroke.points.first.dy);
//     for (final p in stroke.points.skip(1)) {
//       path.lineTo(p.dx, p.dy);
//     }
//     canvas.drawPath(path, paint);
//   }

//   void drawKidsGlitter(Canvas canvas, Stroke stroke) {
//     if (stroke.points.length < 2) return;

//     final path = Path()..moveTo(stroke.points.first.dx, stroke.points.first.dy);
//     for (final p in stroke.points.skip(1)) {
//       path.lineTo(p.dx, p.dy);
//     }

//     final basePaint = Paint()
//       ..color = stroke.color
//       ..style = PaintingStyle.stroke
//       ..strokeCap = StrokeCap.round
//       ..strokeJoin = StrokeJoin.round
//       ..strokeWidth = 15.0 / (_strokeScale <= 0 ? 1.0 : _strokeScale)
//       ..isAntiAlias = true;

//     canvas.drawPath(path, basePaint);

//     if (glitterImage != null) {
//       const double glitterOpacity = 1;

//       canvas.saveLayer(
//         null,
//         Paint()..color = Colors.white.withOpacity(glitterOpacity),
//       );

//       final glitterPaint = Paint()
//         ..shader = ui.ImageShader(
//           glitterImage!,
//           TileMode.repeated,
//           TileMode.repeated,
//           Matrix4.diagonal3Values(.1, .1, 1).storage,
//         )
//         ..style = PaintingStyle.stroke
//         ..strokeCap = StrokeCap.round
//         ..strokeJoin = StrokeJoin.round
//         ..strokeWidth = 15.0 / (_strokeScale <= 0 ? 1.0 : _strokeScale)
//         ..blendMode = BlendMode.overlay
//         ..isAntiAlias = true;

//       canvas.drawPath(path, glitterPaint);

//       canvas.restore();
//     }
//   }

//   void _drawRainbow(Canvas canvas, Stroke stroke) {
//     if (stroke.points.length < 2) {
//       _drawSolid(canvas, stroke);
//       return;
//     }
//     final rainbow = [
//       Colors.red,
//       Colors.orange,
//       Colors.yellow,
//       Colors.green,
//       Colors.blue,
//       Colors.purple,
//     ];
//     for (int i = 1; i < stroke.points.length; i++) {
//       final paint = Paint()
//         ..style = PaintingStyle.stroke
//         ..strokeCap = StrokeCap.round
//         ..strokeWidth = (14.0 / (_strokeScale <= 0 ? 1.0 : _strokeScale))
//         ..color = rainbow[i % rainbow.length];
//       canvas.drawLine(stroke.points[i - 1], stroke.points[i], paint);
//     }
//   }

//   void _drawPatternAlongStroke(Canvas canvas, Stroke stroke, String emoji) {
//     final textPainter = TextPainter(
//       text: TextSpan(
//         text: emoji,
//         style: TextStyle(fontSize: 16, color: stroke.color),
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     const spacing = 18.0;
//     double acc = 0.0;
//     for (int i = 1; i < stroke.points.length; i++) {
//       final a = stroke.points[i - 1];
//       final b = stroke.points[i];
//       final seg = (b - a);
//       final segLen = seg.distance;
//       if (segLen == 0) continue;
//       int steps = (segLen / spacing).floor();
//       for (int j = 0; j <= steps; j++) {
//         final t = j / (steps == 0 ? 1 : steps);
//         final pos = Offset(a.dx + seg.dx * t, a.dy + seg.dy * t);
//         textPainter.layout();
//         textPainter.paint(canvas, pos);
//       }
//       acc += segLen;
//     }
//   }

//   void _drawPencil(Canvas canvas, Stroke stroke) {
//     if (stroke.points.length < 2) return;

//     final baseColor = stroke.color;
//     var width = 8.0 / (_strokeScale <= 0 ? 1.0 : _strokeScale);

//     // Increase overall pencil size by 1.25 as requested.
//     width *= 1.25;

//     // Deterministic RNG per-stroke for stable speck placement
//     final rand = Random(stroke.hashCode ^ stroke.points.length);

//     // Create layered stroke paints for the pencil look.
//     // middle width reduced, then increased by 50% previously. Now increase
//     // by an additional 75% as requested.
//     final baseMid = width * 0.20;
//     final baseOuter = baseMid * 1.6;
//     final midWidth = baseMid * 1.5 * 1.75; // previous 1.5, now *1.75
//     final outerWidth = baseOuter * 1.5 * 1.75;

//     final outerColor = Color.lerp(
//       baseColor,
//       Colors.white,
//       0.45,
//     )!.withOpacity(0.30);
//     final midColor = baseColor.withOpacity(0.64);
//     final coreColor = Color.lerp(
//       baseColor,
//       Colors.black,
//       0.06,
//     )!.withOpacity(0.50);

//     // Re-add outer stroke; mid-line widths will be reduced by 50% below.

//     final outerPaint = Paint()
//       ..style = PaintingStyle.stroke
//       ..isAntiAlias = true
//       ..color = outerColor
//       ..strokeWidth = outerWidth * 0.4
//       ..strokeCap = StrokeCap.butt
//       ..strokeJoin = StrokeJoin.bevel
//       ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);

//     // We'll draw the middle area as multiple thin lines for texture.
//     final midLines = 4; // number of thin middle lines
//     // reduce mid-line width by 50%
//     final singleMidLineWidth = (midWidth / midLines) * 0.5;

//     final corePaint = Paint()
//       ..style = PaintingStyle.stroke
//       ..isAntiAlias = true
//       ..color = coreColor
//       ..strokeWidth = width * 0.09
//       ..strokeCap = StrokeCap.round
//       ..strokeJoin = StrokeJoin.round;

//     // Build a smoothed path for efficiency and to avoid round blobs at joins
//     final path = _createSmoothedPath(stroke.points);

//     // Draw outer then multiple thin mid-lines then core.
//     canvas.drawPath(path, outerPaint);

//     // Build offset mid-paths by offsetting each point perpendicular to the
//     // local tangent. This produces multiple thin parallel lines.
//     if (stroke.points.length >= 2) {
//       for (int lineIndex = 0; lineIndex < midLines; lineIndex++) {
//         // offsets: centered around 0.0
//         final midOffsetIndex = lineIndex - (midLines - 1) / 2.0;
//         final offsetDistance = midOffsetIndex * (singleMidLineWidth * 0.9);

//         final List<Offset> offPoints = [];
//         for (int i = 0; i < stroke.points.length; i++) {
//           final p = stroke.points[i];
//           // determine tangent using neighbors
//           Offset tangent;
//           if (i == 0) {
//             tangent = stroke.points[1] - stroke.points[0];
//           } else if (i == stroke.points.length - 1) {
//             tangent = stroke.points[i] - stroke.points[i - 1];
//           } else {
//             tangent = stroke.points[i + 1] - stroke.points[i - 1];
//           }
//           final tlen = tangent.distance;
//           Offset normal = Offset.zero;
//           if (tlen != 0) normal = Offset(-tangent.dy / tlen, tangent.dx / tlen);
//           final op = p + normal * offsetDistance;
//           offPoints.add(op);
//         }
//         final midPath = _createSmoothedPath(offPoints);

//         final midPaintLine = Paint()
//           ..style = PaintingStyle.stroke
//           ..isAntiAlias = true
//           ..color = midColor
//           // reduce each mid-line stroke a bit to emphasize color over thickness
//           ..strokeWidth = singleMidLineWidth * 0.8
//           ..strokeCap = StrokeCap.round
//           ..strokeJoin = StrokeJoin.round;

//         canvas.drawPath(midPath, midPaintLine);
//       }
//     }

//     canvas.drawPath(path, corePaint);

//     // Specks removed per user request to avoid circular artifacts.
//   }

//   void _drawCrayon(Canvas canvas, Stroke stroke) {
//     final paint = Paint()
//       ..style = PaintingStyle.stroke
//       ..strokeCap = StrokeCap.round
//       ..strokeWidth = (12.0 / (_strokeScale <= 0 ? 1.0 : _strokeScale))
//       ..color = stroke.color;
//     // Use a per-stroke seed so jitter is consistent for the same stroke.
//     final rnd = Random(stroke.hashCode ^ stroke.points.length);
//     for (int i = 1; i < stroke.points.length; i++) {
//       final jitter = Offset(
//         (rnd.nextDouble() - 0.5) * 3,
//         (rnd.nextDouble() - 0.5) * 3,
//       );
//       canvas.drawLine(
//         stroke.points[i - 1] + jitter,
//         stroke.points[i] + jitter,
//         paint,
//       );
//     }
//   }

//   void _drawStickers(Canvas canvas, Stroke stroke) {
//     final textPainter = TextPainter(
//       text: TextSpan(
//         text: '🌟',
//         style: TextStyle(fontSize: 40, color: stroke.color),
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     // Layout once and center each emoji at the stroke point.
//     textPainter.layout();
//     final halfSize = Offset(
//       textPainter.size.width / 2,
//       textPainter.size.height / 2,
//     );
//     for (final pos in stroke.points) {
//       textPainter.paint(canvas, pos - halfSize);
//     }
//   }

//   void _drawWallpaperStroke(Canvas canvas, Stroke stroke) {
//     debugPrint("Drawing wallpaper: ${stroke.wallpaperAsset}");
//     if (stroke.wallpaperImage == null || stroke.points.length < 2) return;

//     final path = Path()..moveTo(stroke.points.first.dx, stroke.points.first.dy);
//     for (final p in stroke.points.skip(1)) {
//       path.lineTo(p.dx, p.dy);
//     }

//     final paint = Paint()
//       ..shader = ui.ImageShader(
//         stroke.wallpaperImage!,
//         TileMode.repeated,
//         TileMode.repeated,
//         Matrix4.identity().storage,
//       )
//       ..style = PaintingStyle.stroke
//       ..strokeCap = StrokeCap.round
//       ..strokeJoin = StrokeJoin.round
//       ..strokeWidth = 15.0 / (_strokeScale <= 0 ? 1.0 : _strokeScale)
//       ..isAntiAlias = true;

//     canvas.drawPath(path, paint);
//   }

//   @override
//   bool shouldRepaint(covariant ColoringPainter old) =>
//       old.regions != regions ||
//       old.scaleX != scaleX ||
//       old.scaleY != scaleY ||
//       old.tx != tx ||
//       old.ty != ty ||
//       old.glitterImage != glitterImage;

//   // void _drawStyledStroke(ui.Canvas canvas, Stroke stroke, ui.Rect regionBounds) {}
// }
