import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fun_painting/app/app_pref.dart';
import 'package:fun_painting/presentation/common/services/music_level.dart';
import 'package:fun_painting/presentation/common/services/sound_service.dart';
import 'package:fun_painting/presentation/galary/widgets/kid_gallery_widgets.dart';
import 'package:fun_painting/presentation/common/widgets/setting_Widget.dart';
import 'package:fun_painting/presentation/common/widgets/sound_levels_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

/// The audio plugin has no native side in unit tests, so its method channels
/// answer with nothing instead of failing.
void mockAudioChannels() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final name in [
    'xyz.luan/audioplayers.global',
    'xyz.luan/audioplayers',
  ]) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(MethodChannel(name), (call) async => null);
  }
}

void main() {
  setUpAll(mockAudioChannels);

  group('sound level preferences', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await AppPreferences().init();
    });

    test('defaults: music 10%, brush 50%', () {
      expect(AppPreferences().getKMusicVolume(), 0.1);
      expect(AppPreferences().getKBrushVolume(), 0.5);
    });

    test('music and brush levels are saved and read back', () async {
      await AppPreferences().setKMusicVolume(0.3);
      await AppPreferences().setKBrushVolume(0.8);
      expect(AppPreferences().getKMusicVolume(), 0.3);
      expect(AppPreferences().getKBrushVolume(), 0.8);
    });

    test('saved levels are clamped to 0..1', () async {
      await AppPreferences().setKMusicVolume(1.7);
      await AppPreferences().setKBrushVolume(-2);
      expect(AppPreferences().getKMusicVolume(), 1.0);
      expect(AppPreferences().getKBrushVolume(), 0.0);
    });

    test('an old single sound level is used for music until changed', () async {
      SharedPreferences.setMockInitialValues({'SoundVolum': 0.4});
      await AppPreferences().init();
      expect(AppPreferences().getKMusicVolume(), 0.4);
    });
  });

  group('BrushSoundService.setLevel', () {
    test('clamps to 0..1', () {
      final service = BrushSoundService.instance;
      service.setLevel(2);
      expect(service.level, 1.0);
      service.setLevel(-1);
      expect(service.level, 0.0);
      service.setLevel(0.3);
      expect(service.level, 0.3);
    });
  });

  group('SoundLevelsDialog', () {
    Widget host(SoundLevelsDialog dialog) {
      return Sizer(
        builder: (_, _, _) => MaterialApp(home: Scaffold(body: dialog)),
      );
    }

    testWidgets('shows two sliders with their labels and percentages', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          SoundLevelsDialog(
            initialMusic: 0.1,
            initialBrush: 0.5,
            onMusicChanged: (_) {},
            onBrushChanged: (_) {},
          ),
        ),
      );
      expect(find.byType(Slider), findsNWidgets(2));
      expect(find.text('Background music'), findsOneWidget);
      expect(find.text('Brush sounds'), findsOneWidget);
      expect(find.text('10%'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('moving the brush slider reports the new level', (
      tester,
    ) async {
      double? brush;
      await tester.pumpWidget(
        host(
          SoundLevelsDialog(
            initialMusic: 0.1,
            initialBrush: 0.5,
            onMusicChanged: (_) {},
            onBrushChanged: (value) => brush = value,
          ),
        ),
      );
      await tester.drag(find.byType(Slider).last, const Offset(100, 0));
      await tester.pump();
      expect(brush, isNotNull);
      expect(brush!, greaterThan(0.5));
    });
  });

  group('MusicLevel (shared by every page)', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await AppPreferences().init();
    });

    test('set changes the live level and saves it', () async {
      await MusicLevel.set(0.6);
      expect(MusicLevel.level.value, 0.6);
      expect(AppPreferences().getKMusicVolume(), 0.6);
    });

    test('set clamps to 0..1', () async {
      await MusicLevel.set(3);
      expect(MusicLevel.level.value, 1.0);
      await MusicLevel.set(-1);
      expect(MusicLevel.level.value, 0.0);
    });

    test('load reads the saved level at start', () async {
      await AppPreferences().setKMusicVolume(0.25);
      MusicLevel.level.value = 0.9;
      MusicLevel.load();
      expect(MusicLevel.level.value, 0.25);
    });
  });

  group('gallery top bar Sound button', () {
    testWidgets('fits on a phone and opens the Sound levels popup', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(
        740,
        360,
      ); // the app is landscape-only
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        Sizer(
          builder: (_, _, _) => MaterialApp(
            home: Scaffold(
              body: GalleryTopBar(
                emoji: '🎨',
                name: 'Pictures',
                count: 3,
                color: Colors.teal,
                onHome: () {},
                trailing: const SoundLevelButton(size: 44),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(SoundLevelButton));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(SoundLevelsDialog), findsOneWidget);
    });
  });
}
