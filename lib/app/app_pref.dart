import 'package:shared_preferences/shared_preferences.dart';

const String kIsMute = 'IsMute';
const String kOpenCount = 'OpenCount';
const String kSoundVolum = 'SoundVolum';

class AppPreferences {
  static final AppPreferences _instance = AppPreferences._();
  late SharedPreferences _prefs;

  AppPreferences._();

  factory AppPreferences() => _instance;

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
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
}
