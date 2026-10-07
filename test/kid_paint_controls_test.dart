// Tests for the "Coloring Book" controls (round 6 — Option C).
//
// The claims worth keeping honest:
//   * the fan really is a fan: its circles sit on an arc, at finger size, and
//     the whole fan fits inside the screen (nothing off the edge);
//   * tapping the crayon bubble opens the colours and tapping a colour picks
//     it and closes the fan;
//   * the two bubbles a thumb uses are big enough to find without looking.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fun_painting/presentation/painting/widgets/kid_layout.dart';
import 'package:fun_painting/presentation/painting/widgets/kid_paint_controls.dart';

const Size _phone = Size(915, 412); // a 20:9 landscape phone

Widget _host(Widget child, {Size size = _phone}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: size),
      child: Scaffold(
        body: SizedBox(
          width: size.width,
          height: size.height,
          child: Stack(children: [child]),
        ),
      ),
    ),
  );
}

void main() {
  group('the fan geometry', () {
    test('its circles really sit on the arc', () {
      final arc = KidLayout.fanArcFor(Alignment.bottomRight);
      const radius = 150.0;
      const count = 7;

      final offsets = [
        for (var i = 0; i < count; i++)
          KidLayout.fanDotOffset(
            index: i,
            count: count,
            radius: radius,
            arc: arc,
          ),
      ];

      for (final offset in offsets) {
        expect(
          offset.distance,
          closeTo(radius, 0.001),
          reason: 'every circle must be the same distance from the bubble',
        );
      }

      // The first is straight left of the bubble, the last is up and slightly
      // right — i.e. the fan opens away from the bottom-right corner.
      expect(offsets.first.dx, closeTo(-radius, 0.5));
      expect(offsets.first.dy, closeTo(0, 0.5));
      expect(offsets.last.dy, lessThan(0));
      expect(offsets.last.dx, greaterThan(-radius * 0.6));
    });

    test('a single circle does not divide by zero', () {
      final offset = KidLayout.fanDotOffset(
        index: 0,
        count: 1,
        radius: 120,
        arc: KidLayout.fanArcFor(Alignment.bottomRight),
      );
      expect(offset.distance, closeTo(120, 0.001));
    });

    test('a fan anchored to another corner opens away from that corner', () {
      final topLeft = KidLayout.fanArcFor(Alignment.topLeft);
      final offset = KidLayout.fanDotOffset(
        index: 0,
        count: 2,
        radius: 120,
        arc: topLeft,
      );
      // 0° is to the right, 120° is down-left: both have a positive x or a
      // positive y, so the fan opens into the screen from a top-left bubble.
      expect(offset.dx, greaterThan(0));
    });

    test('the whole fan stays on screen on a small phone', () {
      final size = _phone;
      final centre = KidLayout.fanAnchor(size, Alignment.bottomRight);

      final arc = KidLayout.fanArcFor(Alignment.bottomRight);
      // The real fan: five circles on the outer row, four on the inner one.
      final rows = {5: KidLayout.fanOuterRadius, 4: KidLayout.fanInnerRadius};

      rows.forEach((count, radius) {
        final dot = KidLayout.fanDotSizeFor(
          count: count,
          radius: radius,
          arc: arc,
        );
        for (var i = 0; i < count; i++) {
          final offset = KidLayout.fanDotOffset(
            index: i,
            count: count,
            radius: radius,
            arc: arc,
          );
          final centreOfDot = centre + offset;
          expect(
            centreOfDot.dx - dot / 2,
            greaterThanOrEqualTo(-1),
            reason: 'a circle hangs off the left edge',
          );
          expect(
            centreOfDot.dy - dot / 2,
            greaterThanOrEqualTo(-1),
            reason: 'a circle hangs off the top edge',
          );
          expect(centreOfDot.dx + dot / 2, lessThanOrEqualTo(size.width + 1));
          expect(centreOfDot.dy + dot / 2, lessThanOrEqualTo(size.height + 1));
        }
      });
    });

    test('the two arcs do not overlap each other', () {
      final gap = KidLayout.fanOuterRadius - KidLayout.fanInnerRadius;
      expect(
        gap,
        greaterThan(KidLayout.fanDotSize * 0.9),
        reason: 'inner circles would collide with outer ones',
      );
    });
  });

  group('thumb-sized controls', () {
    test('the crayon bubble is the biggest thing on screen', () {
      expect(KidLayout.crayonBubbleSize, greaterThanOrEqualTo(64));
      expect(KidLayout.crayonBubbleSize, greaterThan(KidLayout.bubbleSize));
    });

    test('the tool bubble and the undo pill are easy to hit', () {
      expect(KidLayout.bubbleSize, greaterThanOrEqualTo(50));
      expect(KidLayout.pillHeight, greaterThanOrEqualTo(44));
    });

    test('a fan circle is never smaller than a fingertip', () {
      expect(KidLayout.fanDotSize, greaterThanOrEqualTo(KidLayout.minFanDot));
    });

    test('every number follows the screen, not a fixed value', () {
      // 20:9 phone: 22 % of 412 dp is ~90 dp — bigger than the 64 minimum.
      expect(KidLayout.crayonBubbleSize, greaterThan(64));
      expect(
        KidLayout.crayonBubbleSize,
        closeTo(KidLayout.pctH(KidLayout.crayonBubbleH), 0.001),
        reason: 'the bubble must be the percentage of the screen it says',
      );
    });
  });

  group('the crayon bubble and its fan', () {
    testWidgets('tapping the bubble opens the colours', (tester) async {
      var opened = 0;
      await tester.pumpWidget(
        _host(
          Positioned(
            right: 10,
            bottom: 10,
            child: KidCrayonBubble(color: Colors.red, onTap: () => opened++),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('kid_crayon_bubble')));
      await tester.pump();
      expect(opened, 1);
    });

    testWidgets('the fan shows one circle per colour and reports a pick', (
      tester,
    ) async {
      Color? picked;
      final items = [
        for (final color in [Colors.red, Colors.green, Colors.blue])
          KidFanItem.color(color: color, onTap: () => picked = color),
        KidFanItem.action(
          label: 'More',
          onTap: () {},
          child: const Icon(Icons.add),
        ),
      ];

      await tester.pumpWidget(_host(KidFan(items: items, open: true)));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byKey(const ValueKey('kid_fan_item_0')), findsOneWidget);
      expect(find.byKey(const ValueKey('kid_fan_item_3')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('kid_fan_item_1')));
      await tester.pump();
      expect(picked, Colors.green);
    });

    testWidgets('a closed fan takes no taps', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          KidFan(
            open: false,
            items: [KidFanItem.color(color: Colors.red, onTap: () => taps++)],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Nothing at that spot should respond while the fan is closed.
      await tester.tapAt(const Offset(800, 350));
      await tester.pump();
      expect(taps, 0);
    });

    testWidgets('an open fan dims the picture behind it', (tester) async {
      await tester.pumpWidget(
        _host(
          KidFan(
            open: true,
            items: [KidFanItem.color(color: Colors.red, onTap: () {})],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // The scrim is the first child of the fan's stack.
      final scrim = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(KidFan),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = scrim.color;
      expect(decoration, isNotNull);
      expect(decoration!.a, greaterThan(0));
      expect(decoration.a, lessThan(1), reason: 'it must be see-through');
    });

    testWidgets('the fan circles are at least 44 dp', (tester) async {
      await tester.pumpWidget(
        _host(
          KidFan(
            open: true,
            items: [
              for (final color in [Colors.red, Colors.green, Colors.blue])
                KidFanItem.color(color: color, onTap: () {}),
            ],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));

      for (var i = 0; i < 3; i++) {
        final size = tester.getSize(find.byKey(ValueKey('kid_fan_item_$i')));
        expect(size.width, greaterThanOrEqualTo(KidLayout.minFanDot));
      }
    });
  });

  group('pills', () {
    testWidgets('an enabled pill runs its action, a disabled one does not', (
      tester,
    ) async {
      var undo = 0;
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              KidPill(
                label: 'Undo',
                icon: const Icon(Icons.undo),
                onTap: () => undo++,
              ),
              KidPill(
                key: const Key('kid_redo_disabled'),
                label: 'Redo',
                icon: const Icon(Icons.redo),
                enabled: false,
                onTap: () => undo += 100,
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.text('Undo'));
      await tester.pump();
      expect(undo, 1);

      await tester.tap(find.text('Redo'));
      await tester.pump();
      expect(undo, 1, reason: 'a disabled pill must ignore taps');
    });

    testWidgets('a pill is at least 44 dp tall', (tester) async {
      await tester.pumpWidget(
        _host(
          KidPill(label: 'Undo', icon: const Icon(Icons.undo), onTap: () {}),
        ),
      );
      final size = tester.getSize(find.text('Undo'));
      expect(size.height, greaterThan(0));
      final pill = tester.getSize(
        find.ancestor(of: find.text('Undo'), matching: find.byType(InkWell)),
      );
      expect(pill.height, greaterThanOrEqualTo(44));
    });
  });

  group('sanity', () {
    test('every circle of the real fan is still a fingertip', () {
      final arc = KidLayout.fanArcFor(Alignment.bottomRight);
      final rows = {5: KidLayout.fanOuterRadius, 4: KidLayout.fanInnerRadius};
      rows.forEach((count, radius) {
        expect(
          KidLayout.fanDotSizeFor(count: count, radius: radius, arc: arc),
          greaterThanOrEqualTo(KidLayout.minFanDot),
        );
      });
    });

    test('circles on the same row do not collide', () {
      final arc = KidLayout.fanArcFor(Alignment.bottomRight);
      final dot = KidLayout.fanDotSizeFor(
        count: 5,
        radius: KidLayout.fanOuterRadius,
        arc: arc,
      );
      final sweepRad = (arc.end - arc.start) * math.pi / 180;
      final spacing = KidLayout.fanOuterRadius * sweepRad / 4;
      expect(spacing, greaterThanOrEqualTo(dot - 0.001));
    });

    test('the arc helper is monotonic across its sweep', () {
      final arc = KidLayout.fanArcFor(Alignment.bottomRight);
      double last = -1e9;
      for (var i = 0; i < 8; i++) {
        final offset = KidLayout.fanDotOffset(
          index: i,
          count: 8,
          radius: 100,
          arc: arc,
        );
        // Sweeping 180 -> 270 degrees walks the dot from straight-left to
        // straight-up: dx rises monotonically and dy never goes below the
        // bubble (which would mean the fan covering the corner it opens from).
        expect(offset.dx, greaterThan(last - 1e-9));
        last = offset.dx;
        expect(offset.dy, lessThanOrEqualTo(1e-9));
      }
    });

    test('the sweep is a quarter turn or more', () {
      final arc = KidLayout.fanArcFor(Alignment.bottomRight);
      expect(arc.end - arc.start, greaterThanOrEqualTo(90));
      expect((arc.end - arc.start) * math.pi / 180, lessThan(math.pi));
    });
  });
}
