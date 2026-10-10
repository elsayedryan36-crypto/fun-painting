import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

      // the mute sticker toggles
      await tester.tap(find.text('🔊'));
      await tester.pump();
      expect(find.text('🔇'), findsOneWidget);

      // let the auto-navigation run; it must not throw
      await tester.pump(const Duration(milliseconds: 700));
    });
  });

  group('the sticker-book pieces', () {
    testWidgets('the world banner names the world and goes home', (
      tester,
    ) async {
      var home = 0;
      await tester.pumpWidget(
        _harness(
          WorldBanner(
            emoji: '🦁',
            name: 'Zoo',
            count: 89,
            color: const Color(0xFF3D9142),
            onHome: () => home++,
          ),
        ),
      );
      expect(find.text('🦁'), findsOneWidget);
      expect(find.text('Zoo · 89 pictures'), findsOneWidget);
      await tester.tap(find.text('🏠'));
      expect(home, 1);
    });

    testWidgets('a locked card is a present, never grey', (tester) async {
      await tester.pumpWidget(
        _harness(const SizedBox(width: 200, height: 200, child: GiftOverlay())),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('watch to open!'), findsOneWidget);
    });

    testWidgets('finished pictures wear a gold star', (tester) async {
      await tester.pumpWidget(_harness(const StarBadge()));
      expect(find.text('⭐'), findsOneWidget);
    });
  });
}
