// Tests for the kid-ui painting layout.
//
// The important claim to keep honest: docking the rails must never make the
// colouring area smaller than the alternative, and the decision between side
// rails and a bottom bar must follow the screen shape.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fun_painting/presentation/painting/widgets/kid_controls.dart';
import 'package:fun_painting/presentation/painting/widgets/kid_layout.dart';

void main() {
  group('art area maths', () {
    test('keeps the 16:9 artwork aspect ratio', () {
      // Fit 1920x1080 into a much wider box: height-limited.
      expect(KidLayout.artArea(2400, 1080), closeTo(1920 * 1080, 1));
      // Fit into a shorter box: width-limited.
      expect(KidLayout.artArea(1920, 900), closeTo(1600 * 900, 1));
    });

    test('returns 0 for degenerate boxes', () {
      expect(KidLayout.artArea(0, 100), 0);
      expect(KidLayout.artArea(100, 0), 0);
      expect(KidLayout.artArea(-5, 100), 0);
    });

    test('rails on the sides cost the child nothing on a wide phone', () {
      // 20:9 phone in landscape (the app locks landscape).
      const w = 2400.0;
      const h = 1080.0;

      expect(KidLayout.preferSideRails(w, h), isTrue);

      // With side rails the artwork still gets the FULL screen height,
      // because the rails sit in the empty bands beside a 16:9 drawing.
      final artWithRails = KidLayout.artArea(w - 2 * KidLayout.railThickness, h);
      expect(artWithRails, closeTo(1920 * 1080, 1));

      // …and that is more than a bottom bar would leave.
      final artWithBottomBar = KidLayout.artArea(w, h - KidLayout.railThickness);
      expect(artWithRails, greaterThan(artWithBottomBar));
    });

    test('a 16:9 screen prefers a bottom bar (there are no side bands)', () {
      expect(KidLayout.preferSideRails(1920, 1080), isFalse);
      expect(KidLayout.preferSideRails(1024, 768), isFalse); // 4:3 tablet
    });

    test('23:9 and wider still prefer side rails', () {
      expect(KidLayout.preferSideRails(2760, 1080), isTrue);
      expect(KidLayout.preferSideRails(3120, 1080), isTrue);
    });

    test('the chosen layout is never worse than the other one', () {
      const screens = <List<double>>[
        [2400, 1080],
        [2340, 1080],
        [2160, 1080],
        [1920, 1080],
        [2048, 1536],
        [1024, 768],
        [2760, 1080],
      ];

      for (final s in screens) {
        final w = s[0];
        final h = s[1];
        final side = KidLayout.artArea(w - 2 * KidLayout.railThickness, h);
        final bottom = KidLayout.artArea(w, h - KidLayout.railThickness);
        final chosen = KidLayout.preferSideRails(w, h) ? side : bottom;
        final other = KidLayout.preferSideRails(w, h) ? bottom : side;

        expect(
          chosen,
          greaterThanOrEqualTo(other),
          reason: 'on ${w.toInt()}x${h.toInt()} the chosen layout leaves '
              '${chosen.toInt()} px² but the other would leave '
              '${other.toInt()} px²',
        );

        // And it must always leave a usable canvas.
        expect(chosen, greaterThan(0));
      }
    });

    test('panels are bounded so they cannot swallow the canvas', () {
      expect(KidLayout.panelWidth(2400), lessThanOrEqualTo(360));
      expect(KidLayout.panelWidth(2400), lessThan(2400 * 0.5));
      expect(KidLayout.panelHeight(1080), lessThanOrEqualTo(230));
      expect(KidLayout.panelHeight(1080), lessThan(1080 * 0.5));
    });
  });

  group('kid controls', () {
    testWidgets('rail buttons are big enough for small fingers', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: KidRailButton(
                label: 'Brush',
                onTap: () {},
                child: const Icon(Icons.brush),
              ),
            ),
          ),
        ),
      );

      final size = tester.getSize(find.byType(KidRailButton));
      // 48 dp is the platform minimum; we ship 64 dp.
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
      // The widget box is the button face plus its 2 dp margin on each side.
      expect(size.width, greaterThanOrEqualTo(KidLayout.buttonSize));
      expect(size.width, KidLayout.buttonSize + 4);
    });

    testWidgets('rail buttons report taps and their label', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KidRailButton(
              label: 'Eraser',
              onTap: () => taps++,
              child: const Icon(Icons.cleaning_services),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(KidRailButton));
      expect(taps, 1);
      expect(find.bySemanticsLabel('Eraser'), findsWidgets);
    });

    testWidgets('a vertical rail stacks its buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                KidRail(
                  axis: Axis.vertical,
                  children: [
                    KidRailButton(onTap: () {}, child: const Icon(Icons.looks_one)),
                    KidRailButton(onTap: () {}, child: const Icon(Icons.looks_two)),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      final first = tester.getTopLeft(find.byIcon(Icons.looks_one));
      final second = tester.getTopLeft(find.byIcon(Icons.looks_two));
      expect(second.dy, greaterThan(first.dy));
      expect(second.dx, first.dx);
    });

    testWidgets('a horizontal rail places its buttons side by side',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                KidRail(
                  axis: Axis.horizontal,
                  children: [
                    KidRailButton(onTap: () {}, child: const Icon(Icons.looks_one)),
                    KidRailButton(onTap: () {}, child: const Icon(Icons.looks_two)),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      final first = tester.getTopLeft(find.byIcon(Icons.looks_one));
      final second = tester.getTopLeft(find.byIcon(Icons.looks_two));
      expect(second.dx, greaterThan(first.dx));
      expect(second.dy, first.dy);
    });
  });
}
