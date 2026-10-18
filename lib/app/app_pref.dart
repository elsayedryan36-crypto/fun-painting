import 'package:shared_preferences/shared_preferences.dart';

const String kIsMute = 'IsMute';
const String kOpenCount = 'OpenCount';
const String kSoundVolum = 'SoundVolum';
// NEW: separate levels for background music and brush sounds
const String kMusicVolume = 'MusicVolume';
const String kBrushVolume = 'BrushVolume';
const double kDefaultMusicVolume = 0.1;
const double kDefaultBrushLevel = 0.5;

class AppPreferences {
  static final AppPreferences _instance = AppPreferences._();
  late SharedPreferences _prefs;
  bool _ready = false; // NEW: true once init() has run

  AppPreferences._();

  factory AppPreferences() => _instance;

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    _ready = true; // NEW
    // (old) _prefs = await SharedPreferences.getInstance();
  }

  Future<void> init() async {
    await _init();
  }

  /////////////////////////////////////////////////////////////////
  // MUTE VOLUME
  /////////////////////////////////////////////////////////////////

  double getkIsMute() {
    return _prefs.getDouble(kIsMute) ?? 0.2;
  }

  Future<void> setkIsMute(double isMute) {
    return _prefs.setDouble(kIsMute, isMute);
  }

  /////////////////////////////////////////////////////////////////
  // OPEN COUNT
  /////////////////////////////////////////////////////////////////

  int getKOpenCount() {
    return _prefs.getInt(kOpenCount) ?? 0;
  }

  Future<void> setKOpenCount(int openCount) {
    return _prefs.setInt(kOpenCount, openCount); // ✅ fixed key
  }

  /////////////////////////////////////////////////////////////////
  // SOUND VOLUME
  /////////////////////////////////////////////////////////////////

  double getKSoundVolum() {
    return _prefs.getDouble(kSoundVolum) ?? 0.1; // ✅ fixed key
  }

  Future<void> setKSoundVolum(double soundVolum) {
    return _prefs.setDouble(kSoundVolum, soundVolum); // ✅ fixed key
  }

  /////////////////////////////////////////////////////////////////
  // SOUND LEVELS (NEW): background music and brush sounds
  /////////////////////////////////////////////////////////////////

  /// Background music level, 0..1. Users who only had the old single level
  /// keep it until they change the music level.
  double getKMusicVolume() {
    if (!_ready) return kDefaultMusicVolume;
    return _prefs.getDouble(kMusicVolume) ?? getKSoundVolum();
  }

  Future<void> setKMusicVolume(double volume) {
    return _prefs.setDouble(kMusicVolume, volume.clamp(0.0, 1.0));
  }

  /// Brush sounds level, 0..1.
  double getKBrushVolume() {
    if (!_ready) return kDefaultBrushLevel;
    return _prefs.getDouble(kBrushVolume) ?? kDefaultBrushLevel;
  }

  Future<void> setKBrushVolume(double volume) {
    return _prefs.setDouble(kBrushVolume, volume.clamp(0.0, 1.0));
  }
}
