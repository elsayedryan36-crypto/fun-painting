import 'dart:ui';

import 'package:xml/xml.dart';

import '../../../data/local data/painting_save_model.dart';

class SvgModifier {
  static String modify({
    required String svg,
    required PaintingSave? save,
    required Color fillColor,
    double? strokeWidth,
  }) {
    final document = XmlDocument.parse(svg);

    int regionIndex = 0;

    final defaultColor = _toHex(fillColor);

    const supported = {
      'path',
      'circle',
      'ellipse',
      'rect',
      'polygon',
      'polyline',
      'line',
    };

    for (final node in document.descendants.whereType<XmlElement>()) {
      if (!supported.contains(node.name.local)) continue;

      final keep =
          (node.getAttribute('keepColor') ??
                  node.getAttribute('keepcolor') ??
                  '')
              .toLowerCase() ==
          'true';

      if (keep) continue;

      _processElement(
        element: node,
        defaultColor: defaultColor,
        index: regionIndex++,
        save: save,
        strokeWidth: strokeWidth,
      );
    }

    return document.toXmlString();
  }

  static void _processElement({
    required XmlElement element,
    required String defaultColor,
    required int index,
    required PaintingSave? save,
    required double? strokeWidth,
  }) {
    //-----------------------------------
    // Fill
    //-----------------------------------
    final fillAttr = element.getAttribute('fill');

    if (fillAttr != null && fillAttr.toLowerCase() != 'none') {
      String fill = defaultColor;

      if (save != null && index < save.regions.length) {
        fill = _toHex(Color(save.regions[index].fillColor));
      }

      element.setAttribute('fill', fill);
    }

    //-----------------------------------
    // Stroke
    //-----------------------------------
    if (element.getAttribute('stroke') != null) {
      element.setAttribute('stroke', '#000000');
    }

    //-----------------------------------
    // Stroke width
    //-----------------------------------
    if (strokeWidth != null &&
        element.getAttribute('stroke') != null) {
      element.setAttribute(
        'stroke-width',
        strokeWidth.toString(),
      );
    }

    //-----------------------------------
    // Style
    //-----------------------------------
    final style = element.getAttribute('style');

    if (style != null) {
      element.setAttribute(
        'style',
        _replaceStyle(
          style: style,
          defaultColor: defaultColor,
          strokeWidth: strokeWidth,
          index: index,
          save: save,
        ),
      );
    }
  }

  static String _replaceStyle({
    required String style,
    required String defaultColor,
    required int index,
    required PaintingSave? save,
    required double? strokeWidth,
  }) {
    final parts = style.split(';');

    String fill = defaultColor;

    if (save != null && index < save.regions.length) {
      fill = _toHex(
        Color(save.regions[index].fillColor),
      );
    }

    bool hasStroke = false;
    bool hasStrokeWidth = false;

    for (int i = 0; i < parts.length; i++) {
      final item = parts[i].trim();

      if (item.startsWith('fill:')) {
        if (!item.contains('none')) {
          parts[i] = 'fill:$fill';
        }
      } else if (item.startsWith('stroke:')) {
        parts[i] = 'stroke:#000000';
        hasStroke = true;
      } else if (item.startsWith('stroke-width:')) {
        hasStrokeWidth = true;

        if (strokeWidth != null) {
          parts[i] = 'stroke-width:$strokeWidth';
        }
      }
    }

    if (!hasStroke) {
      parts.add('stroke:#000000');
    }

    if (strokeWidth != null && !hasStrokeWidth) {
      parts.add('stroke-width:$strokeWidth');
    }

    return parts.join(';');
  }

  static String replaceStrokeWidth(
    String style,
    double width,
  ) {
    final values = style.split(';');

    bool found = false;

    for (int i = 0; i < values.length; i++) {
      if (values[i].trim().startsWith('stroke-width:')) {
        values[i] = 'stroke-width:$width';
        found = true;
      }
    }

    if (!found) {
      values.add('stroke-width:$width');
    }

    return values.join(';');
  }

  static String _toHex(Color color) {
    return '#'
        '${color.red.toRadixString(16).padLeft(2, '0')}'
        '${color.green.toRadixString(16).padLeft(2, '0')}'
        '${color.blue.toRadixString(16).padLeft(2, '0')}'
        .toUpperCase();
  }
}