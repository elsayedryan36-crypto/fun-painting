import 'package:flutter/foundation.dart';
import 'package:fun_painting/app/app_pref.dart';

/// NEW: the background-music level shared by every screen.
///
/// The Sound button can be pressed on the home, gallery or painting page.
/// The home screen's music player listens to [level], so a change made
/// anywhere reaches the music at once, and is saved for the next launch.
class MusicLevel {
  MusicLevel._();

  static final ValueNotifier<double> level = ValueNotifier<double>(
    kDefaultMusicVolume,
  );

  /// Read the saved level. Call once preferences are initialised.
  static void load() {
    level.value = AppPreferences().getKMusicVolume();
  }

  /// Change and save the level (clamped to 0..1).
  static Future<void> set(double value) {
    final clamped = value.clamp(0.0, 1.0).toDouble();
    level.value = clamped;
    return AppPreferences().setKMusicVolume(clamped);
  }
}
