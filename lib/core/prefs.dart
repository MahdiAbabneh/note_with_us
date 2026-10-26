import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper around [SharedPreferences] for device-local settings.
abstract final class Prefs {
  static SharedPreferences? _prefs;

  /// Loads preferences; call once before `runApp`.
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static String? getString(String key) => _prefs?.getString(key);
  static bool? getBool(String key) => _prefs?.getBool(key);

  static Future<void> setString(String key, String value) async =>
      _prefs?.setString(key, value);

  static Future<void> setBool(String key, bool value) async =>
      _prefs?.setBool(key, value);
}
