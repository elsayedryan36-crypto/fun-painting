// The painting page's tune button opens a small card with two items:
// Sound levels and How to paint. These tests check the card alone, and then
// the real painting page: tap the tune button, then How to paint.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import 'package:fun_painting/app/app_pref.dart';
import 'package:fun_painting/data/local data/hive.dart';
import 'package:fun_painting/data/local data/painting_save_model.dart';
import 'package:fun_painting/presentation/painting/painting_page.dart';
import 'package:fun_painting/presentation/painting/widgets/tools_menu.dart';

void main() {
  group('ToolsMenuCard', () {
    testWidgets('shows both items and calls the matching callback', (
      tester,
    ) async {
      var sound = 0;
      var help = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ToolsMenuCard(
                width: 300,
                rowHeight: 56,
                onSound: () => sound++,
                onHelp: () => help++,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Sound levels'), findsOneWidget);
      expect(find.text('How to paint'), findsOneWidget);

      await tester.tap(find.text('Sound levels'));
      await tester.pump();
      expect(sound, 1);
      expect(help, 0);

      await tester.tap(find.text('How to paint'));
      await tester.pump();
      expect(help, 1);
    });

    testWidgets('each row is a touch target of at least 44 dp', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ToolsMenuCard(
              width: 300,
              rowHeight: 44,
              onSound: () {},
              onHelp: () {},
            ),
          ),
        ),
      );
      final row = tester.getSize(find.byType(InkWell).first);
      expect(row.height, greaterThanOrEqualTo(44));
    });
  });

  group('painting page', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final dir = Directory.systemTemp.createTempSync('tools_menu_hive');
      Hive.init(dir.path);
      Hive.registerAdapter(PaintingSaveAdapter());
      Hive.registerAdapter(SavedStrokeAdapter());
      Hive.registerAdapter(SavedRegionAdapter());
      Hive.registerAdapter(DrawingModelAdapter());
      await Hive.openBox<PaintingSave>('paintings');
      await Hive.openBox<DrawingModel>('drawings');

      const codec = StandardMethodCodec();
      SharedPreferences.setMockInitialValues({});
      await AppPreferences().init();
      // Skip the first-visit tutorial so it does not cover the tune button.
      await AppPreferences().setPaintingTutorialSeen(true);
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMessageHandler(
        'plugins.flutter.io/path_provider',
        (message) async => codec.encodeSuccessEnvelope(dir.path),
      );
      for (final ch in [
        'plugins.flutter.io/google_mobile_ads',
        'com.ryanheise.audio_session',
        'xyz.luan/audioplayers',
        'xyz.luan/audioplayers.global',
      ]) {
        messenger.setMockMessageHandler(
          ch,
          (message) async => codec.encodeSuccessEnvelope(null),
        );
      }
    });

    testWidgets(
      'tune button opens the menu and How to paint starts the tutorial',
      (tester) async {
        tester.view.physicalSize = const Size(915, 412);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) =>
                MaterialApp(home: PaintingPage(image: 'assets/images/0.svg')),
          ),
        );
        for (var i = 0; i < 40; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)),
          );
          await tester.pump(const Duration(milliseconds: 100));
          if (find.byKey(const Key('kid_home_bubble')).evaluate().isNotEmpty) {
            break;
          }
        }
        expect(find.byKey(const Key('kid_home_bubble')), findsOneWidget);

        expect(find.text('How to paint'), findsNothing);
        await tester.tap(find.byKey(const Key('kid_tools_bubble')));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('How to paint'), findsOneWidget);
        expect(find.text('Sound levels'), findsOneWidget);

        await tester.tap(find.text('How to paint'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('How to paint'), findsNothing);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
        tester.takeException();
      },
    );
  });
}
