import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fun_painting/presentation/common/local_data/Class.dart';
import 'package:fun_painting/presentation/home/Widgets/kid_home_shelf.dart';
import 'package:sizer/sizer.dart';

// The "pick your world" storybook shelf.
//
// These tests never mount the videos (the video plugin only exists on a
// real device) — they pin down the shelf's promises: every world has a
// face, Free Draw is the hero, the pages hold three stickers, and a
// sticker card is a real fingertip target that opens its world.

void main() {
  group('the shelf data', () {
    test('eleven worlds, each with a name, an emoji and a colour', () {
      expect(kWorldMeta.length, 11);
      for (final m in kWorldMeta) {
        expect(m.name, isNotEmpty);
        expect(m.emoji, isNotEmpty);
      }
      expect(kWorldMeta.first.name, 'Zoo');
      expect(kWorldMeta.last.name, 'Numbers');
    });

    test('Free Draw is the hero at slot 1, worlds keep their order', () {
      final items = List.generate(
        12,
        (i) => Collections(imagePath: 'v$i', onTap: () async {}),
      );
      final slots = buildShelfSlots(items);
      expect(slots, hasLength(12));
      expect(slots.first.isHero, isTrue);
      expect(slots.first.item.imagePath, 'v11');
      expect(slots[1].meta?.name, 'Zoo');
      expect(slots.last.meta?.name, 'Numbers');
    });

    test('the shelf becomes four pages of three stickers', () {
      final items = List.generate(
        12,
        (i) => Collections(imagePath: 'v$i', onTap: () async {}),
      );
      final pages = chunkShelf(buildShelfSlots(items), 3);
      expect(pages, hasLength(4));
      for (final p in pages) {
        expect(p, hasLength(3));
      }
    });
  });

  group('the sticker card', () {
    Future<void> pumpCard(
      WidgetTester tester,
      ShelfSlot slot,
      VoidCallback onTap,
    ) async {
      await tester.pumpWidget(
        Sizer(
          builder: (_, __, ___) => MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 300,
                  height: 320,
                  child: WorldCard(
                    slot: slot,
                    thumb: Container(color: Colors.green),
                    onTap: onTap,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('shows its name plate and opens its world on tap', (
      tester,
    ) async {
      var taps = 0;
      final slot = ShelfSlot(
        Collections(imagePath: 'zoo', onTap: () async => taps++),
        kWorldMeta[0],
        -0.02,
      );
      await pumpCard(tester, slot, () => taps++);

      expect(find.text('Zoo'), findsOneWidget);
      expect(find.text('🦁'), findsWidgets);

      await tester.tap(find.byType(WorldCard));
      expect(taps, 1);
    });

    testWidgets('the hero card shouts FREE DRAW, twice', (tester) async {
      await pumpCard(
        tester,
        ShelfSlot(Collections(imagePath: 'wb', onTap: () async {}), null, 0.02),
        () {},
      );
      // once in the big overlay, once on the gold name plate
      expect(find.text('FREE DRAW!'), findsNWidgets(2));
    });

    testWidgets('the card fills its shelf cell: a fingertip target', (
      tester,
    ) async {
      await pumpCard(
        tester,
        ShelfSlot(
          Collections(imagePath: 'x', onTap: () async {}),
          kWorldMeta[1],
          0,
        ),
        () {},
      );
      final size = tester.getSize(find.byType(WorldCard));
      expect(size.width, greaterThanOrEqualTo(WorldCard.minTap));
      expect(size.height, greaterThanOrEqualTo(WorldCard.minTap));
    });
  });
}
