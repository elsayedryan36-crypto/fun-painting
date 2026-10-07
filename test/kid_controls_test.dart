// Tests for the kid-sized painting controls (commit 2 of the kid-ui round).
//
// The claims worth keeping honest:
//   * the colour palette really is 8 swatches per row and every swatch is big
//     enough for a small finger (>= KidLayout.minSwatch),
//   * the S / M / L buttons report the size that was tapped,
//   * the chosen size really changes how thick the line is painted, and it is
//     remembered per stroke (so an old line never changes size).

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fun_painting/presentation/painting/coloring_painter.dart';
import 'package:fun_painting/presentation/painting/models/brush_size.dart';
import 'package:fun_painting/presentation/painting/region.dart';
import 'package:fun_painting/presentation/painting/widgets/color_palette_widget.dart';
import 'package:fun_painting/presentation/painting/widgets/kid_controls.dart';
import 'package:fun_painting/presentation/painting/widgets/kid_layout.dart';

Widget _panel(Widget child, {double width = 0, double height = 320}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: width == 0 ? KidLayout.swatchGridWidth : width,
          height: height,
          child: child,
        ),
      ),
    ),
  );
}

ColorPaletteWidget _palette({
  Color selected = Colors.red,
  ValueChanged<Color>? onColorSelected,
}) {
  return ColorPaletteWidget(
    selectedColor: selected,
    onColorSelected: onColorSelected ?? (_) {},
    isColorChanged: () {},
  );
}

/// Number of visibly painted pixels after drawing [brushScale]'s stroke.
Future<int> _paintedPixels(double brushScale) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 120, 120));

  final region = Region(
    id: 'r0',
    path: Path()..addRect(const Rect.fromLTWH(0, 0, 120, 120)),
    strokeColor: Colors.black,
    strokeWidth: 1,
    originalFillColor: Colors.white,
  );

  final stroke = Stroke(
    points: const [Offset(20, 60), Offset(100, 60)],
    color: const Color(0xFF000000),
    brushScale: brushScale,
  );

  ColoringPainter(
    regions: [region],
    scaleX: 1,
    scaleY: 1,
    tx: 0,
    ty: 0,
    strokePictureCache: {},
  ).drawStyledStroke(canvas, stroke, region.path.getBounds());

  final image = await recorder.endRecording().toImage(120, 120);
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final bytes = data!.buffer.asUint8List();

  var painted = 0;
  for (var i = 3; i < bytes.length; i += 4) {
    if (bytes[i] > 0) painted++;
  }
  image.dispose();
  return painted;
}

void main() {
  group('colour palette', () {
    testWidgets('lays the swatches out 8 to a row', (tester) async {
      await tester.pumpWidget(_panel(_palette()));

      double dyOf(int index) =>
          tester.getCenter(find.byKey(Key('kid_color_swatch_$index'))).dy;

      // The first eight share a row…
      for (var i = 1; i < KidLayout.colorColumns; i++) {
        expect(dyOf(i), dyOf(0), reason: 'swatch $i is not on the first row');
      }
      // …and the ninth starts the next one.
      expect(dyOf(KidLayout.colorColumns), greaterThan(dyOf(0)));

      // Every colour of every group is offered.
      expect(find.byKey(const Key('kid_color_swatch_0')), findsOneWidget);
      for (final swatch in ColorPaletteWidget.allSwatches) {
        expect(swatch.color, isNotNull);
      }
    });

    testWidgets('every swatch is big enough for a small finger', (
      tester,
    ) async {
      // The narrowest panel the page ever gives the palette.
      await tester.pumpWidget(
        _panel(_palette(), width: KidLayout.swatchGridWidth),
      );

      for (var i = 0; i < KidLayout.colorColumns; i++) {
        final size = tester.getSize(find.byKey(Key('kid_color_swatch_$i')));
        expect(
          size.width,
          greaterThanOrEqualTo(KidLayout.minSwatch),
          reason: 'swatch $i is ${size.width} dp wide',
        );
        expect(
          size.height,
          greaterThanOrEqualTo(KidLayout.minSwatch),
          reason: 'swatch $i is ${size.height} dp tall',
        );
      }
    });

    testWidgets('tapping a swatch reports that colour', (tester) async {
      Color? picked;
      await tester.pumpWidget(
        _panel(_palette(onColorSelected: (c) => picked = c)),
      );

      // A swatch from the first row, so it is always laid out and visible.
      final expected = ColorPaletteWidget.allSwatches[5].color;
      await tester.tap(find.byKey(const Key('kid_color_swatch_5')));
      await tester.pump();

      expect(picked, expected);
    });

    testWidgets('never squeezes the swatches on a wide bottom bar', (
      tester,
    ) async {
      // A 1920 dp wide panel (bottom-bar layout on a wide screen).
      await tester.pumpWidget(_panel(_palette(), width: 1920));

      final size = tester.getSize(find.byKey(const Key('kid_color_swatch_0')));
      expect(size.width, lessThanOrEqualTo(KidLayout.maxSwatch));
    });
  });

  group('brush size buttons', () {
    testWidgets('offers the three sizes and reports the one tapped', (
      tester,
    ) async {
      BrushSize? picked;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: KidBrushSizeControl(
                selected: BrushSize.medium,
                previewColor: Colors.pink,
                onChanged: (s) => picked = s,
              ),
            ),
          ),
        ),
      );

      for (final size in BrushSize.values) {
        expect(find.byKey(Key('kid_brush_size_${size.name}')), findsOneWidget);
      }

      await tester.tap(find.byKey(const Key('kid_brush_size_large')));
      await tester.pump();
      expect(picked, BrushSize.large);
    });

    testWidgets('every size button is a kid-sized touch target', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: KidBrushSizeControl(
                selected: BrushSize.small,
                previewColor: Colors.pink,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      for (final size in BrushSize.values) {
        final box = tester.getSize(
          find.byKey(Key('kid_brush_size_${size.name}')),
        );
        expect(box.width, greaterThanOrEqualTo(KidLayout.buttonSize));
      }
    });
  });

  group('the preset really changes the line', () {
    test('medium keeps the width the app always had', () {
      expect(BrushSize.medium.factor, 1.0);
      expect(BrushSize.small.factor, lessThan(1.0));
      expect(BrushSize.large.factor, greaterThan(1.0));
      // Ordered S < M < L so the buttons make visual sense.
      expect(
        BrushSize.small.dotDiameter,
        lessThan(BrushSize.medium.dotDiameter),
      );
      expect(
        BrushSize.medium.dotDiameter,
        lessThan(BrushSize.large.dotDiameter),
      );
    });

    test('a stroke remembers the size it was drawn with', () {
      final stroke = Stroke(points: const [Offset.zero], color: Colors.red);
      expect(stroke.brushScale, 1.0, reason: 'old strokes keep their width');

      final thick = stroke.copyWith(brushScale: BrushSize.large.factor);
      expect(thick.brushScale, BrushSize.large.factor);
      expect(
        stroke.brushScale,
        1.0,
        reason: 'copyWith must not mutate the original stroke',
      );
    });

    testWidgets('S really paints a thinner line than L', (tester) async {
      late int smallPixels;
      late int largePixels;

      await tester.runAsync(() async {
        smallPixels = await _paintedPixels(BrushSize.small.factor);
        largePixels = await _paintedPixels(BrushSize.large.factor);
      });

      expect(smallPixels, greaterThan(0));
      expect(
        largePixels,
        greaterThan(smallPixels * 1.5),
        reason:
            'L (${BrushSize.large.factor}x) painted $largePixels px, '
            'S (${BrushSize.small.factor}x) painted $smallPixels px',
      );
    });
  });
}
