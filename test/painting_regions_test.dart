// Regression tests for the painting/gallery region fixes.
//
// Why these exist:
//  * save files store colours BY REGION INDEX, so svg_parser.dart (painting
//    page) and svg_modifier.dart (gallery previews) must number the elements
//    of an artwork identically. They disagreed by up to 16 regions, which
//    painted the wrong colours on the wrong shapes in the gallery.
//  * svg_parser.dart used to turn <defs>/<clipPath> geometry and unfilled
//    shapes into invisible white regions that could steal taps.
//
// Run with: flutter test test/painting_regions_test.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fun_painting/data/local%20data/painting_save_model.dart';
import 'package:fun_painting/presentation/galary/services/svg_modifier.dart';
import 'package:fun_painting/presentation/painting/svg_parser.dart';
import 'package:xml/xml.dart';

/// Artworks that contain keepcolor elements and/or hidden geometry.
const _artworks = <String>[
  'assets/images/zoo/1.svg',
  'assets/images/dragons/1.svg',
  'assets/images/fairy/1.svg',
  'assets/images/food/1.svg',
  'assets/images/circis/1.svg',
  'assets/images/sea/1.svg',
  'assets/images/space/1.svg',
  'assets/images/transportation/1.svg',
  'assets/images/letters/1.svg',
  'assets/images/numbers/1.svg',
  'assets/images/planet/1.svg',
];

/// Tags svg_parser.dart treats as colouring regions.
const _regionTags = {
  'path',
  'rect',
  'circle',
  'ellipse',
  'polygon',
  'polyline',
};

/// Supported region elements of [document], in document order — the order in
/// which svg_parser.dart numbers them.
List<XmlElement> _regionElements(XmlDocument document) => document.descendants
    .whereType<XmlElement>()
    .where((e) => _regionTags.contains(e.name.local.toLowerCase()))
    .toList();

/// Every fill value of [element]: the `fill` attribute plus any `fill:` entry
/// inside the `style` attribute (these Inkscape files use the latter).
List<String> _fillsOf(XmlElement element) {
  final fills = <String>[];

  final attr = element.getAttribute('fill');
  if (attr != null) fills.add(attr);

  final style = element.getAttribute('style');
  if (style != null) {
    for (final part in style.split(';')) {
      final trimmed = part.trim();
      if (trimmed.startsWith('fill:')) fills.add(trimmed.substring(5).trim());
    }
  }

  return fills;
}

/// The marker colour that encodes region [index]: 0xFF0F0000 | index, written
/// by svg_modifier.dart as '#0F' + 4 hex digits.
String _sentinelFor(int index) =>
    '#0F${index.toRadixString(16).padLeft(4, '0')}'.toUpperCase();

/// The region index this element was rewritten with, or null when it was not
/// rewritten at all (keepcolor keeps the artist's colour).
int? _sentinelIndexOf(Map<String, int> sentinels, XmlElement element) {
  for (final fill in _fillsOf(element)) {
    final hit = sentinels[fill.toUpperCase()];
    if (hit != null) return hit;
  }
  return null;
}

/// True when SvgModifier is expected to rewrite this element's fill.
bool _wouldRewrite(XmlElement element) {
  final keep = (element.getAttribute('keepcolor') ?? '').toLowerCase() == 'true';
  if (keep) return false;

  return _fillsOf(element).any((f) => f.toLowerCase() != 'none');
}

void main() {
  test('parser and gallery modifier agree on region numbering', () {
    for (final asset in _artworks) {
      final svg = File(asset).readAsStringSync();
      final regions = parseSvgToRegions(svg);

      expect(regions, isNotEmpty, reason: '$asset produced no regions');

      // Unique, index-encoded colour per region, so we can read back which
      // index the gallery assigned to which element.
      final sentinels = <String, int>{};
      final save = PaintingSave(<SavedRegion>[
        for (var i = 0; i < regions.length; i++)
          __region(sentinels, i),
      ]);

      final modifiedSvg = SvgModifier.modify(
        svg: svg,
        save: save,
        fillColor: const Color(0xFFFFFFFF),
      );

      final source = _regionElements(XmlDocument.parse(svg));
      final output = _regionElements(XmlDocument.parse(modifiedSvg));

      expect(
        source.length,
        regions.length,
        reason: '$asset: the parser must create one region per supported '
            'element (it numbers them in document order)',
      );
      expect(output.length, source.length);

      final expected =
          source.where(_wouldRewrite).length;

      var verified = 0;
      for (var i = 0; i < output.length; i++) {
        final index = _sentinelIndexOf(sentinels, output[i]);
        if (index == null) continue;

        verified++;

        expect(
          index,
          i,
          reason: '$asset: element #$i was given region $index\'s colour — '
              'saved colours would be painted on the wrong shapes.',
        );
      }

      expect(
        verified,
        expected,
        reason: '$asset: expected $expected rewritten elements, saw $verified',
      );

      // The original bug in one line: right after a keepcolor element the
      // gallery numbering used to lag one or more regions behind.
      for (var i = 0; i < source.length - 1; i++) {
        final isKeep =
            (source[i].getAttribute('keepcolor') ?? '').toLowerCase() == 'true';
        if (!isKeep) continue;

        for (var j = i + 1; j < output.length; j++) {
          final index = _sentinelIndexOf(sentinels, output[j]);
          if (index == null) continue;

          expect(
            index,
            j,
            reason: '$asset: element #$j follows a keepcolor element (#$i) and '
                'must still receive region $j.',
          );
          break;
        }
      }
    }
  });

  test('geometry the SVG never renders is marked hidden', () {
    // <clipPath> geometry: 359 elements in the circles artwork.
    final circis = parseSvgToRegions(
      File('assets/images/circis/1.svg').readAsStringSync(),
    );
    expect(
      circis.where((r) => r.hidden).length,
      greaterThan(300),
      reason: 'clipPath geometry must not become paintable white regions',
    );

    // Unfilled, unstroked shapes elsewhere in the artwork.
    final zoo = parseSvgToRegions(
      File('assets/images/zoo/1.svg').readAsStringSync(),
    );
    expect(zoo.where((r) => r.hidden).length, greaterThan(0));

    // The flower artwork has no hidden geometry at all.
    final planet = parseSvgToRegions(
      File('assets/images/planet/1.svg').readAsStringSync(),
    );
    expect(planet.where((r) => r.hidden), isEmpty);
    expect(planet.where((r) => !r.hidden).length, planet.length);
  });

  test('keepcolor regions keep their original fill and stay locked', () {
    final zoo = parseSvgToRegions(
      File('assets/images/zoo/1.svg').readAsStringSync(),
    );
    final locked = zoo.where((r) => r.keepOriginalColor).toList();

    expect(locked, isNotEmpty, reason: 'zoo/1.svg has keepcolor elements');

    for (final region in locked) {
      // Locked regions start at the artist's colour, not white.
      expect(region.currentFillColor, region.originalFillColor);

      // …and ignore fill requests.
      region.fill(const Color(0xFF00FF00), region.currentFillStyle);
      expect(region.currentFillColor, region.originalFillColor);
    }
  });
}

/// A saved region carrying the marker colour for [index].
SavedRegion __region(Map<String, int> sentinels, int index) {
  sentinels[_sentinelFor(index)] = index;
  return SavedRegion(
    fillColor: 0xFF0F0000 | index,
    fillStyle: 0,
    strokes: <SavedStroke>[],
  );
}
