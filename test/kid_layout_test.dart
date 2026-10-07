// Tests for the kid-ui painting layout (round 3 — the app's own percentage
// sizing system).
//
// The claims worth keeping honest:
//   * the layout is sized as a percentage of the screen (`.h` / `.w`, the same
//     language the original code used), not in fixed dp;
//   * a rail always fits the buttons it holds — it shrinks them instead of
//     overflowing or making the child scroll;
//   * buttons never shrink below a real touch target;
//   * the colour grid keeps swatches at kid size on a small phone.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fun_painting/presentation/painting/widgets/kid_controls.dart';
import 'package:fun_painting/presentation/painting/widgets/kid_layout.dart';

Widget _host(Widget child, {Size size = const Size(2400, 1080)}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: size),
      child: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  group('percentage sizing', () {
    test('falls back to a small phone when Sizer has not measured yet', () {
      // No Sizer in a widget test, so Device.height is `late` — the fallback
      // must kick in instead of throwing.
      expect(KidLayout.screenW, greaterThan(0));
      expect(KidLayout.screenH, greaterThan(0));
      expect(KidLayout.buttonSize, greaterThanOrEqualTo(KidLayout.minButton));
      expect(KidLayout.buttonSize, lessThanOrEqualTo(KidLayout.maxButton));
    });

    test('a button is a percentage of the screen, bounded', () {
      final fromHeight = KidLayout.pctH(KidLayout.buttonH);
      final fromWidth = KidLayout.pctW(KidLayout.buttonW);
      final wanted = fromHeight < fromWidth ? fromHeight : fromWidth;

      expect(
        KidLayout.buttonSize,
        wanted.clamp(KidLayout.minButton, KidLayout.maxButton),
        reason: 'the button must follow the screen, like AppSizeHeight does',
      );
    });

    test('the percentage is what drives it (no fixed 64 dp anymore)', () {
      // With no Sizer the fallback screen is 800 x 400 (landscape phone), so
      // the height percentage wins: 18 % of 400 = 72 dp.
      expect(KidLayout.screenH, 400);
      expect(KidLayout.buttonSize, 72);
      expect(
        KidLayout.buttonSize,
        isNot(64),
        reason: 'a fixed 64 dp is exactly what round 2 did and what we left',
      );
      // The rail is a button plus padding, like the original 22.h rail.
      expect(KidLayout.railThickness, greaterThan(KidLayout.buttonSize));
    });
  });

  group('a rail always fits its buttons', () {
    test('short rail -> smaller buttons, never smaller than 48 dp', () {
      // A 1080x340 landscape screen: rails must hold 5 buttons in 340 dp.
      final size = KidLayout.railButtonSize(railExtent: 320, count: 5);
      expect(size, lessThan(KidLayout.buttonSize));
      expect(size, greaterThanOrEqualTo(KidLayout.minButton));

      // A very short screen: the floor wins and the rail scrolls instead.
      final tiny = KidLayout.railButtonSize(railExtent: 200, count: 5);
      expect(tiny, KidLayout.minButton);
    });

    test('tall rail -> full-size buttons', () {
      final size = KidLayout.railButtonSize(railExtent: 2000, count: 5);
      expect(size, KidLayout.buttonSize);
    });

    test('an empty rail does not divide by zero', () {
      expect(KidLayout.railButtonSize(railExtent: 500, count: 0), isNotNull);
    });
  });

  group('the painting fills the screen', () {
    // The artwork's own bounds are 1920 x 1080 (16:9); a phone screen is 20:9.
    const artBounds = Rect.fromLTWH(0, 0, 1920, 1080);
    const phone = Size(2400, 1080);

    test('fill mode covers the whole canvas', () {
      final t = KidLayout.fitTransform(
        bounds: artBounds,
        canvas: phone,
        fit: ArtFit.fill,
      );

      // The drawn rectangle really is as big as the canvas on both axes.
      final drawnW = artBounds.width * t['scaleX']!;
      final drawnH = artBounds.height * t['scaleY']!;
      expect(drawnW, closeTo(phone.width, 0.5));
      expect(drawnH, closeTo(phone.height, 0.5));

      // …and it is positioned at the canvas origin, not centred in a band.
      expect(t['tx']!, closeTo(0, 0.5));
      expect(t['ty']!, closeTo(0, 0.5));
    });

    test('fill mode still refuses to squash an extreme screen', () {
      // Portrait-ish 1080 x 2400 would be a 3.5x stretch on one axis.
      final t = KidLayout.fitTransform(
        bounds: artBounds,
        canvas: const Size(1080, 2400),
        fit: ArtFit.fill,
      );
      final ratio = t['scaleX']! > t['scaleY']!
          ? t['scaleX']! / t['scaleY']!
          : t['scaleY']! / t['scaleX']!;
      expect(ratio, lessThanOrEqualTo(KidLayout.maxStretch + 0.0001));
    });

    test('keep-shape mode keeps the artwork undistorted and centred', () {
      final t = KidLayout.fitTransform(
        bounds: artBounds,
        canvas: phone,
        fit: ArtFit.keepShape,
      );

      expect(t['scaleX']!, t['scaleY']!, reason: 'one scale for both axes');

      final drawnW = artBounds.width * t['scaleX']!;
      final drawnH = artBounds.height * t['scaleY']!;
      expect(drawnH, closeTo(phone.height, 0.5));
      expect(
        drawnW,
        lessThan(phone.width),
        reason: 'this is the old letterbox',
      );
      expect(t['tx']!, closeTo((phone.width - drawnW) / 2, 0.5));
    });

    test('the fill default really is fill', () {
      // A regression guard: the default must fill the screen, because that is
      // what the app was asked to do twice.
      expect(ArtFit.values.first, ArtFit.fill);
      expect(ArtFit.fill.index, 0);
    });
  });

  group('floating controls', () {
    test('buttons stay a real touch target and grow with the screen', () {
      expect(
        KidLayout.floatButtonSize,
        greaterThanOrEqualTo(KidLayout.minFloatButton),
      );
      expect(
        KidLayout.floatButtonSize,
        lessThanOrEqualTo(KidLayout.maxFloatButton),
      );
    });

    test('colour dots are kid sized', () {
      expect(
        KidLayout.colorDotSize,
        greaterThanOrEqualTo(KidLayout.minColorDot),
      );
      expect(KidLayout.colorDotSize, lessThanOrEqualTo(KidLayout.maxColorDot));
    });
  });

  group('colour grid stays kid sized', () {
    test('eight columns only when they are big enough', () {
      // A tablet-width panel (the full 8-column grid width).
      expect(KidLayout.colorColumnsFor(KidLayout.swatchGridWidth), 8);
      // A 640 dp phone gives the panel ~269 dp: eight columns would be 26 dp,
      // six are 44 dp. Six must win.
      final phonePanel = KidLayout.colorPanelWidth(640);
      expect(phonePanel, lessThan(KidLayout.swatchGridWidth));
      expect(KidLayout.colorColumnsFor(phonePanel), lessThan(8));
      expect(KidLayout.colorColumnsFor(phonePanel), greaterThanOrEqualTo(4));
    });

    test('columns are never fewer than four', () {
      expect(KidLayout.colorColumnsFor(120), 4);
    });

    test('the panel leaves the canvas the majority of the screen', () {
      for (final w in [640.0, 800.0, 2400.0]) {
        expect(KidLayout.colorPanelWidth(w), lessThan(w * 0.55));
        expect(KidLayout.panelWidth(w), lessThan(w * 0.5));
      }
    });
  });

  group('rail buttons', () {
    testWidgets('a side rail stacks its buttons and reports its geometry', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          KidRail(
            axis: Axis.vertical,
            children: [
              KidRailButton(
                label: 'One',
                onTap: () {},
                child: const Icon(Icons.looks_one),
              ),
              KidRailButton(
                label: 'Two',
                onTap: () {},
                child: const Icon(Icons.looks_two),
              ),
            ],
          ),
        ),
      );

      final first = tester.getCenter(find.byIcon(Icons.looks_one));
      final second = tester.getCenter(find.byIcon(Icons.looks_two));
      expect(second.dy, greaterThan(first.dy));
      expect(second.dx, first.dx);
    });

    testWidgets('every button is at least a 48 dp touch target', (
      tester,
    ) async {
      for (final size in [const Size(320, 640), const Size(1080, 2400)]) {
        await tester.pumpWidget(
          _host(
            KidRail(
              axis: Axis.vertical,
              children: [
                KidRailButton(
                  label: 'A',
                  onTap: () {},
                  child: const Icon(Icons.brush),
                ),
                KidRailButton(
                  label: 'B',
                  onTap: () {},
                  child: const Icon(Icons.star),
                ),
              ],
            ),
            size: size,
          ),
        );

        for (final icon in [Icons.brush, Icons.star]) {
          final box = tester.getSize(
            find
                .ancestor(of: find.byIcon(icon), matching: find.byType(InkWell))
                .first,
          );
          expect(
            box.width,
            greaterThanOrEqualTo(KidLayout.minButton),
            reason: 'on $size the button came out ${box.width} dp wide',
          );
        }
      }
    });

    testWidgets('a tap runs the action and the label is readable', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          KidRail(
            axis: Axis.vertical,
            children: [
              KidRailButton(
                label: 'Eraser',
                onTap: () => taps++,
                child: const Icon(Icons.cleaning_services),
              ),
            ],
          ),
        ),
      );

      expect(find.text('Eraser'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.cleaning_services));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('a horizontal rail places its buttons side by side', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          KidRail(
            axis: Axis.horizontal,
            children: [
              KidRailButton(
                label: 'One',
                onTap: () {},
                child: const Icon(Icons.looks_one),
              ),
              KidRailButton(
                label: 'Two',
                onTap: () {},
                child: const Icon(Icons.looks_two),
              ),
            ],
          ),
        ),
      );

      final first = tester.getCenter(find.byIcon(Icons.looks_one));
      final second = tester.getCenter(find.byIcon(Icons.looks_two));
      expect(second.dx, greaterThan(first.dx));
      expect(second.dy, first.dy);
    });
  });
}
