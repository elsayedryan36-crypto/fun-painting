import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:xml/xml.dart';

import 'region.dart';

List<Region> parseSvgToRegions(String svgContent) {
  final doc = XmlDocument.parse(svgContent);
  final regions = <Region>[];

  for (final node in doc.findAllElements('*')) {
    final tag = node.name.local.toLowerCase();
    Path? path;

    // ✅ NEW: geometry inside <defs>, <clipPath>, <mask>, <symbol>, <pattern>
    // or <marker> is never drawn by an SVG renderer, so it must not be drawn
    // (it used to be painted as an opaque white shape) and it must not accept
    // taps (it used to swallow the tap before the visible shape below it).
    // The region is still created, so saved painting indices stay valid.
    final bool hiddenGeometry = _isInsideHiddenContainer(node);
    // ----- old version (kept for reference) -----
    // final bool hiddenGeometry = false;

    if (tag == 'path') {
      final d = node.getAttribute('d');
      if (d == null) continue;
      path = parseSvgPathData(d);
    } else if (tag == 'rect') {
      final x = double.tryParse(node.getAttribute('x') ?? '0') ?? 0;
      final y = double.tryParse(node.getAttribute('y') ?? '0') ?? 0;
      final w = double.tryParse(node.getAttribute('width') ?? '0') ?? 0;
      final h = double.tryParse(node.getAttribute('height') ?? '0') ?? 0;
      final rx = double.tryParse(node.getAttribute('rx') ?? '0') ?? 0;
      final ry = double.tryParse(node.getAttribute('ry') ?? '0') ?? 0;
      path = Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, w, h),
            Radius.elliptical(rx, ry),
          ),
        );
    } else if (tag == 'circle') {
      final cx = double.tryParse(node.getAttribute('cx') ?? '0') ?? 0;
      final cy = double.tryParse(node.getAttribute('cy') ?? '0') ?? 0;
      final r = double.tryParse(node.getAttribute('r') ?? '0') ?? 0;
      path = Path()
        ..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    } else if (tag == 'ellipse') {
      final cx = double.tryParse(node.getAttribute('cx') ?? '0') ?? 0;
      final cy = double.tryParse(node.getAttribute('cy') ?? '0') ?? 0;
      final rx = double.tryParse(node.getAttribute('rx') ?? '0') ?? 0;
      final ry = double.tryParse(node.getAttribute('ry') ?? '0') ?? 0;
      path = Path()
        ..addOval(
          Rect.fromCenter(
            center: Offset(cx, cy),
            width: rx * 2,
            height: ry * 2,
          ),
        );
    } else if (tag == 'polygon' || tag == 'polyline') {
      final pointsAttr = node.getAttribute('points');
      if (pointsAttr != null) {
        final values = pointsAttr
            .trim()
            .split(RegExp(r'[\s,]+'))
            .map((s) => double.tryParse(s) ?? 0)
            .toList();
        if (values.length >= 4) {
          path = Path();
          path.moveTo(values[0], values[1]);
          for (int i = 2; i + 1 < values.length; i += 2) {
            path.lineTo(values[i], values[i + 1]);
          }
          if (tag == 'polygon') path.close();
        }
      }
    }

    if (path == null) continue;

    // --- read fill/stroke attributes ---
    String? fillAttr = node.getAttribute('fill');
    String? strokeAttr = node.getAttribute('stroke');
    String? strokeWidthAttr = node.getAttribute('stroke-width');
    final keepColorAttr = node.getAttribute('keepcolor');
    final keepColor = keepColorAttr?.toLowerCase() == 'true';

    final style = node.getAttribute('style');
    if (style != null) {
      for (final kv in style.split(';')) {
        if (!kv.contains(':')) continue;
        final parts = kv.split(':');
        final k = parts[0].trim();
        final v = parts.sublist(1).join(':').trim();
        if (k == 'fill') fillAttr = v;
        if (k == 'stroke') strokeAttr = v;
        if (k == 'stroke-width') strokeWidthAttr = v;
      }
    }

    // --- parse colors ---
    final bool hasFill =
        fillAttr != null && fillAttr.trim().toLowerCase() != 'none';
    final bool hasStroke =
        strokeAttr != null && strokeAttr.trim().toLowerCase() != 'none';

    // ✅ NEW: if the SVG paints nothing for this element (no fill AND no
    // stroke) it must not become a white paintable region here either.
    final bool hidden = hiddenGeometry || (!hasFill && !hasStroke);

    Color originalFill = const Color(0xFFFFFFFF);
    if (fillAttr != null && fillAttr.toLowerCase() != 'none') {
      try {
        originalFill = _parseColor(fillAttr);
      } catch (_) {}
    }

    Color strokeColor = const Color(0xFF000000);
    if (strokeAttr != null && strokeAttr.toLowerCase() != 'none') {
      try {
        strokeColor = _parseColor(strokeAttr);
      } catch (_) {}
    }

    double strokeWidth = 1.0;
    if (strokeWidthAttr != null) {
      try {
        final cleaned = strokeWidthAttr.replaceAll('px', '').trim();
        strokeWidth = double.tryParse(cleaned) ?? strokeWidth;
      } catch (_) {}
    }

    // ----------------------------------------------------
    // ⭐ NEW LOGIC: read custom "keepcolor" attribute
    // ----------------------------------------------------
    // final bool keepColor = node.getAttribute('keepcolor') == 'true';
    final regionId =
    node.getAttribute('id') ??
    '${tag}_${regions.length}';

    regions.add(
      Region(
          id: regionId,
        path: path,
        strokeColor: strokeColor,
        strokeWidth: strokeWidth,
        originalFillColor: originalFill, // ✅ always real SVG color
        keepOriginalColor: keepColor, // ✅ PASS FLAG
        hidden: hidden, // ✅ NEW: never painted, never tappable
        initialFillColor: keepColor
            ? originalFill
            : Colors.white, // ✅ visible start color
      ),
    );
    // ----- old version (kept for reference) -----
    // regions.add(
    //   Region(
    //       id: regionId,
    //     path: path,
    //     strokeColor: strokeColor,
    //     strokeWidth: strokeWidth,
    //     originalFillColor: originalFill, // ✅ always real SVG color
    //     keepOriginalColor: keepColor, // ✅ PASS FLAG
    //     initialFillColor: keepColor
    //         ? originalFill
    //         : Colors.white, // ✅ visible start color
    //   ),
    // );
  }

  return regions;
}

/// ✅ NEW: true when [node] sits inside a container that an SVG renderer
/// never paints directly. Those elements only exist to be referenced
/// (`defs`, `clipPath`, `mask`, `symbol`, `pattern`, `marker`), so treating
/// them as colouring regions adds invisible shapes that can steal taps.
bool _isInsideHiddenContainer(XmlElement node) {
  const hiddenTags = {
    'defs',
    'clippath',
    'mask',
    'symbol',
    'pattern',
    'marker',
  };

  for (XmlElement? parent = node.parentElement;
      parent != null;
      parent = parent.parentElement) {
    if (hiddenTags.contains(parent.name.local.toLowerCase())) return true;
  }

  return false;
}


Color _parseColor(String s) {
  final str = s.trim().toLowerCase();
  if (str.startsWith('#')) {
    var hex = str.substring(1);
    if (hex.length == 3) {
      hex = hex.split('').map((c) => c + c).join();
    }
    if (hex.length == 6) hex = 'ff$hex';
    if (hex.length == 8) {
      return Color(int.parse(hex, radix: 16));
    }
  }

  switch (str) {
    case 'black':
      return const Color(0xFF000000);
    case 'white':
      return const Color(0xFFFFFFFF);
    case 'red':
      return const Color(0xFFFF0000);
    case 'green':
      return const Color(0xFF00FF00);
    case 'blue':
      return const Color(0xFF0000FF);
    case 'yellow':
      return const Color(0xFFFFFF00);
    default:
      return const Color(0xFF000000);
  }
}
