import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fun_painting/presentation/galary/galary_page.dart'
    show galleryColumns, galleryPerPage;
import 'package:fun_painting/presentation/galary/widgets/kid_gallery_widgets.dart';
import 'package:fun_painting/presentation/splash/splash_view.dart';
import 'package:sizer/sizer.dart';

// The two rebuilt screens: splash ("the dragon says hello") and the
// category sticker-book pieces.

Widget _harness(Widget child) {
  return Sizer(
    builder: (_, __, ___) => MaterialApp(
      onGenerateRoute: (settings) => MaterialPageRoute(
        builder: (_) => const Scaffold(body: Text('next screen')),
      ),
      home: child,
    ),
  );
}

void main() {
  group('the splash', () {
    testWidgets('shows the dragon, a play button and a mute sticker', (
      tester,
    ) async {
      // flutter_tester has no Rive native runtime, so the dragon gets a
      // stand-in; on a real device SplashScreen plays dragon.riv instead.
      await tester.pumpWidget(
        _harness(const SplashScreen(dragonOverride: SizedBox())),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // the mute sticker is on stage and toggles
      expect(find.text('🔊'), findsOneWidget);

      // the paint splash shows the mascot card and a bubbly PLAY drop
      expect(find.text('▶  PLAY'), findsOneWidget);

      // the mute sticker toggles
      await tester.tap(find.text('🔊'));
      await tester.pump();
      expect(find.text('🔇'), findsOneWidget);

      // tapping PLAY bursts confetti and opens home without throwing
      await tester.tap(find.text('▶  PLAY'));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump(const Duration(milliseconds: 300));
    });
  });

  group('the calm & clean grid', () {
    test('six stickers per page on every screen', () {
      expect(galleryPerPage(const Size(800, 360)), 6); // landscape (the app)
      expect(galleryPerPage(const Size(360, 800)), 6); // upright, just in case
      expect(galleryPerPage(const Size(600, 600)), 6);
    });

    test('three columns in landscape, two upright', () {
      expect(galleryColumns(const Size(800, 360)), 3); // 3 × 2
      expect(galleryColumns(const Size(360, 800)), 2); // 2 × 3
    });
  });

  group('the sticker-book pieces', () {
    testWidgets('the top bar names the world and goes home', (tester) async {
      var home = 0;
      await tester.pumpWidget(
        _harness(
          GalleryTopBar(
            emoji: '🦁',
            name: 'Zoo',
            count: 12,
            color: const Color(0xFF3D9142),
            onHome: () => home++,
          ),
        ),
      );
      expect(find.text('🦁'), findsOneWidget);
      expect(find.text('Zoo'), findsOneWidget);
      expect(find.text('12 pictures'), findsOneWidget);
      await tester.tap(find.text('🏠'));
      expect(home, 1);
    });

    // OLD (sticker-book WorldBanner test, kept commented per the rule):
    // testWidgets('the world banner names the world and goes home', ...
    //   expect(find.text('Zoo · 89 pictures'), findsOneWidget); ...);

    testWidgets('a locked card is a present, never grey', (tester) async {
      await tester.pumpWidget(
        _harness(const SizedBox(width: 200, height: 200, child: GiftOverlay())),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Watch an ad to open'), findsOneWidget);
      expect(find.text('AD'), findsOneWidget);
    });

    testWidgets('finished pictures wear a gold star', (tester) async {
      await tester.pumpWidget(_harness(const StarBadge()));
      expect(find.text('⭐'), findsOneWidget);
    });
  });
}
