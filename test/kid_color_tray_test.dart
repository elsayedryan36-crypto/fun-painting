// Tests for Option B — "your app + a colour tray".
//
// The promises this layout makes, and what is checked here:
//   * the colours are ALWAYS on screen (nothing has to be opened first),
//   * the tray owns a strip of its own, so the picture is never covered by it,
//   * every target in the tray is a fingertip (>= 44 dp; buttons >= 48 dp),
//   * the rails — which are 98 % of the SCREEN tall — stay fully visible now
//     that the tray has taken 20 % of the height: they shrink to fit instead
//     of being clipped.
//
// The page itself is not mounted here (it loads artwork over the network); the
// tray is tested directly and the layout contract is tested on a harness that
// mirrors the page's build().

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fun_painting/presentation/common/resources/color_manager.dart';
import 'package:fun_painting/presentation/painting/widgets/color_palette_widget.dart';
import 'package:fun_painting/presentation/painting/widgets/kid_color_tray.dart';
import 'package:fun_painting/presentation/painting/widgets/kid_layout.dart';

/// A swatch that is really in the app's palette (used as "the colour in hand").
final Color _anySwatch = ColorPaletteWidget.allSwatches[2];

/// The two phones the proposals were drawn for.
const Size _smallPhone = Size(640, 360);
const Size _bigPhone = Size(915, 412);

/// The tray and a stand-in picture, arranged exactly like the page's
/// `body: Column(children: [Expanded(Stack(...)), KidColorTray(...)])`.
Widget _harness({
  Size size = _smallPhone,
  double railPercentOfScreen = 98,
  Widget? picture,
  ValueChanged<Color>? onColor,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: size.width,
        height: size.height,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    key: const Key('picture'),
                    color: Colors.white,
                    child: picture,
                  ),
                  // The right rail: 98 % of the screen tall, like the app's,
                  // pushed through the same shrink-to-fit wrapper the page uses.
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.topRight,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: SizedBox(
                          key: const Key('rail'),
                          width: KidLayout.pctH(22),
                          height: KidLayout.pctH(railPercentOfScreen),
                          child: Container(color: const Color(0x33344D67)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            KidColorTray(
              colors: ColorPaletteWidget.allSwatches,
              selectedColor: Colors.red,
              onColorSelected: onColor ?? (_) {},
              onMoreColors: () {},
              onTools: () {},
              onEraser: () {},
              onClear: () {},
            ),
          ],
        ),
      ),
    ),
  );
}

void main() {
  group('tray sizing (KidLayout, percent of the screen)', () {
    test('the tray is a real strip, never a sliver', () {
      expect(KidLayout.trayHeight, greaterThanOrEqualTo(KidLayout.minTray));
      expect(KidLayout.trayHeight, lessThanOrEqualTo(KidLayout.maxTray));
      // and it must leave the picture the bigger part of the screen
      expect(KidLayout.trayHeight, lessThan(KidLayout.screenH * 0.4));
    });

    test('tray buttons are the 48-56 dp the proposal asks for', () {
      expect(KidLayout.trayButtonSize, greaterThanOrEqualTo(48));
      expect(KidLayout.trayButtonSize, lessThanOrEqualTo(60));
      // a button always has to fit inside its own tray
      expect(KidLayout.trayButtonSize, lessThanOrEqualTo(KidLayout.trayHeight));
    });

    test('colour dots are fingertip sized: a child taps them directly', () {
      expect(KidLayout.trayDotSize, greaterThanOrEqualTo(44));
      expect(KidLayout.trayDotSize, lessThanOrEqualTo(KidLayout.trayHeight));
    });

    test('the cell around a dot is wider than the dot itself', () {
      expect(KidLayout.trayGap, greaterThanOrEqualTo(8));
      // so the tap target is the whole cell, not the circle
      expect(
        KidLayout.trayDotSize + KidLayout.trayGap,
        greaterThan(KidLayout.trayDotSize),
      );
    });

    test(
      'the full colour grid is capped by the picture area, not the screen',
      () {
        expect(
          KidLayout.floatingPanelMaxHeight,
          lessThanOrEqualTo(KidLayout.pctH(96)),
        );
        // it must fit above the tray...
        expect(
          KidLayout.floatingPanelMaxHeight,
          lessThanOrEqualTo(KidLayout.screenH - KidLayout.trayHeight),
        );
        // ...but not be squeezed into something unusable
        expect(KidLayout.floatingPanelMaxHeight, greaterThanOrEqualTo(120));
      },
    );
  });

  group('the tray (widget)', () {
    testWidgets('shows every colour the app has, plus its buttons', (
      tester,
    ) async {
      await tester.pumpWidget(_harness());

      expect(find.byKey(KidColorTray.trayKey), findsOneWidget);
      expect(find.byKey(KidColorTray.stripKey), findsOneWidget);
      expect(find.byKey(KidColorTray.moreKey), findsOneWidget);
      expect(find.byKey(KidColorTray.colorKey), findsOneWidget);
      expect(find.byKey(KidColorTray.toolsKey), findsOneWidget);
      expect(find.byKey(KidColorTray.eraserKey), findsOneWidget);
      expect(find.byKey(KidColorTray.clearKey), findsOneWidget);

      // Every colour of the app is in the strip — nothing is hidden behind an
      // "open the palette first" step.
      final strip = tester.widget<ListView>(find.byKey(KidColorTray.stripKey));
      final delegate = strip.childrenDelegate as SliverChildBuilderDelegate;
      expect(
        delegate.estimatedChildCount,
        ColorPaletteWidget.allSwatches.length,
      );
      expect(strip.scrollDirection, Axis.horizontal);
    });

    testWidgets('a tap on a dot hands back exactly that colour', (
      tester,
    ) async {
      Color? picked;
      await tester.pumpWidget(_harness(onColor: (c) => picked = c));

      const index = 5;
      await tester.tap(find.byKey(KidColorTray.swatchKey(index)));
      await tester.pump();

      expect(picked, ColorPaletteWidget.allSwatches[index]);
    });

    testWidgets('every button does its one job', (tester) async {
      var more = 0, tools = 0, eraser = 0, clear = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KidColorTray(
              colors: ColorPaletteWidget.allSwatches,
              selectedColor: Colors.red,
              onColorSelected: (_) {},
              onMoreColors: () => more++,
              onTools: () => tools++,
              onEraser: () => eraser++,
              onClear: () => clear++,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(KidColorTray.moreKey));
      await tester.tap(find.byKey(KidColorTray.colorKey));
      await tester.tap(find.byKey(KidColorTray.toolsKey));
      await tester.tap(find.byKey(KidColorTray.eraserKey));
      await tester.tap(find.byKey(KidColorTray.clearKey));
      await tester.pump();

      // ＋ and the colour preview both open the full grid, so it fired twice
      expect(more, 2);
      expect(tools, 1);
      expect(eraser, 1);
      expect(clear, 1);
    });

    testWidgets('every button is a fingertip, and the tray is its own strip', (
      tester,
    ) async {
      await tester.pumpWidget(_harness());

      for (final key in [
        KidColorTray.moreKey,
        KidColorTray.colorKey,
        KidColorTray.toolsKey,
        KidColorTray.eraserKey,
        KidColorTray.clearKey,
      ]) {
        final size = tester.getSize(
          find
              .descendant(
                of: find.byKey(key),
                matching: find.byType(GestureDetector),
              )
              .first,
        );
        expect(size.width, greaterThanOrEqualTo(48), reason: '$key is narrow');
        expect(size.height, greaterThanOrEqualTo(48), reason: '$key is short');
      }

      expect(
        tester.getSize(find.byKey(KidColorTray.trayKey)).height,
        closeTo(KidLayout.trayHeight, 0.5),
      );
    });

    testWidgets('a dot has a finger-wide cell even when the circle is small', (
      tester,
    ) async {
      await tester.pumpWidget(_harness());
      final cell = tester.getSize(find.byKey(KidColorTray.swatchKey(0)));
      expect(cell.width, greaterThanOrEqualTo(44));
      expect(cell.height, greaterThanOrEqualTo(44));
    });

    testWidgets('the colour in the child\'s hand is the one that is ringed', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KidColorTray(
              colors: ColorPaletteWidget.allSwatches,
              selectedColor: _anySwatch,
              onColorSelected: (_) {},
              onMoreColors: () {},
              onTools: () {},
              onEraser: () {},
              onClear: () {},
            ),
          ),
        ),
      );

      // The ring is drawn on the selected dot: gold border, 3 wide.
      const index = 2;
      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byKey(KidColorTray.swatchKey(index)),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
      expect((decoration.border as Border).top.color, ColorManager.gold);
      expect((decoration.border as Border).top.width, 3);
    });
  });

  group('the Option B layout contract', () {
    testWidgets('the tray never covers the picture: it sits below it', (
      tester,
    ) async {
      await tester.pumpWidget(_harness());

      final picture = tester.getRect(find.byKey(const Key('picture')));
      final tray = tester.getRect(find.byKey(KidColorTray.trayKey));

      // The picture stops exactly where the tray starts...
      expect(picture.bottom, closeTo(tray.top, 0.5));
      // ...so the two never overlap, and the tray reaches the bottom edge.
      expect(picture.bottom, lessThanOrEqualTo(tray.top));
      expect(tray.left, 0);
      expect(tray.right, 640);
      expect(tray.bottom, closeTo(360, 0.5));
    });

    testWidgets('a rail taller than the picture area shrinks to fit', (
      tester,
    ) async {
      await tester.pumpWidget(_harness(railPercentOfScreen: 98));

      final picture = tester.getRect(find.byKey(const Key('picture')));
      final rail = tester.getRect(find.byKey(const Key('rail')));

      // The rail wants 98 % of the SCREEN but only has the picture area:
      // without the shrink-to-fit wrapper it would be cut off at the bottom.
      expect(rail.bottom, lessThanOrEqualTo(picture.bottom + 0.5));
      expect(rail.top, greaterThanOrEqualTo(picture.top - 0.5));
      // and it did have to shrink — this is the bug the wrapper prevents
      expect(rail.height, lessThan(KidLayout.pctH(98)));
    });

    testWidgets('a rail that already fits is left exactly as it is', (
      tester,
    ) async {
      await tester.pumpWidget(_harness(railPercentOfScreen: 40));

      final rail = tester.getRect(find.byKey(const Key('rail')));
      expect(rail.height, closeTo(KidLayout.pctH(40), 0.5));
    });

    testWidgets('on a big phone the tray is deep and the picture keeps most of '
        'the screen', (tester) async {
      await tester.pumpWidget(_harness(size: _bigPhone));

      final picture = tester.getRect(find.byKey(const Key('picture')));
      final tray = tester.getRect(find.byKey(KidColorTray.trayKey));

      expect(picture.bottom, closeTo(tray.top, 0.5));
      // the picture keeps well over half the screen
      expect(picture.height / _bigPhone.height, greaterThan(0.75));
    });
  });
}
