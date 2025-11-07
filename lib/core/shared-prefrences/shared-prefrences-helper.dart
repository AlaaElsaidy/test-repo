import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsHelper {
  static SharedPreferences? _prefs;

  static Future init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Save String
  static Future<void> saveString(String key, String value) async {
    await _prefs?.setString(key, value);
  }

  /// Get String
  static String? getString(String key) {
    return _prefs?.getString(key);
  }

  /// Save Bool
  static Future<void> saveBool(String key, bool value) async {
    await _prefs?.setBool(key, value);
  }

  /// Get Bool
  static bool? getBool(String key) {
    return _prefs?.getBool(key);
  }

  /// Save Int
  static Future<void> saveInt(String key, int value) async {
    await _prefs?.setInt(key, value);
  }

  /// Get Int
  static int? getInt(String key) {
    return _prefs?.getInt(key);
  }

  /// Remove key
  static Future<void> remove(String key) async {
    await _prefs?.remove(key);
  }

  /// Clear all
  static Future<void> clear() async {
    await _prefs?.clear();
  }
}
