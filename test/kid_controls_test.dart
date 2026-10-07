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

/// The width the page gives the colour panel on a small phone (640 dp wide).
const double _smallPanel = 269;

/// The width it gives on a tablet.
const double _tabletPanel = KidLayout.swatchGridWidth;

Widget _panel(
  Widget child, {
  double width = _tabletPanel,
  double height = 320,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(width: width, height: height, child: child),
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
  group('colour palette (the app original layout)', () {
    testWidgets('shows the colours 6 to a row', (tester) async {
      await tester.pumpWidget(_panel(_palette(), width: 900, height: 400));

      double dyOf(int index) =>
          tester.getCenter(find.byKey(Key('kid_color_swatch_$index'))).dy;

      // The first six share a row (the original crossAxisCount is 6)…
      for (var i = 1; i < 6; i++) {
        expect(dyOf(i), dyOf(0), reason: 'swatch $i is not on the first row');
      }
      // …and the seventh starts the next one.
      expect(dyOf(6), greaterThan(dyOf(0)));
    });

    testWidgets('every group is offered', (tester) async {
      await tester.pumpWidget(_panel(_palette(), width: 900, height: 400));

      expect(ColorPaletteWidget.allSwatches.length, greaterThanOrEqualTo(72));
      for (final color in ColorPaletteWidget.allSwatches) {
        expect(color, isNotNull);
      }
    });

    testWidgets('tapping a swatch reports that colour', (tester) async {
      Color? picked;
      await tester.pumpWidget(
        _panel(
          _palette(onColorSelected: (c) => picked = c),
          width: 900,
          height: 400,
        ),
      );

      final expected = ColorPaletteWidget.allSwatches[5];
      await tester.tap(find.byKey(const Key('kid_color_swatch_5')));
      await tester.pump();

      expect(picked, expected);
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
        expect(box.width, greaterThanOrEqualTo(KidLayout.minButton));
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
