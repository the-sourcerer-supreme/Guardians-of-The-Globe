import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class SettingsController extends ChangeNotifier {
  SettingsController._(this._prefs);

  final SharedPreferences _prefs;

  static const _themeKey = 'theme_preference';
  static const _languageKey = 'language_code';

  ThemePreference _themePreference = ThemePreference.system;
  Locale _locale = const Locale('en');

  ThemePreference get themePreference => _themePreference;
  ThemeMode get themeMode {
    switch (_themePreference) {
      case ThemePreference.light:
        return ThemeMode.light;
      case ThemePreference.dark:
        return ThemeMode.dark;
      case ThemePreference.system:
        return ThemeMode.system;
    }
  }

  Locale get locale => _locale;

  static Future<SettingsController> load() async {
    final prefs = await SharedPreferences.getInstance();
    final controller = SettingsController._(prefs);
    controller._themePreference = _themeFromKey(prefs.getString(_themeKey));
    controller._locale = Locale(prefs.getString(_languageKey) ?? 'en');
    return controller;
  }

  Future<void> setThemePreference(ThemePreference value) async {
    _themePreference = value;
    await _prefs.setString(_themeKey, value.name);
    notifyListeners();
  }

  Future<void> toggleThemePreference() async {
    final next = _themePreference == ThemePreference.dark
        ? ThemePreference.light
        : ThemePreference.dark;
    await setThemePreference(next);
  }

  Future<void> setLocale(Locale value) async {
    _locale = value;
    await _prefs.setString(_languageKey, value.languageCode);
    notifyListeners();
  }
}

ThemePreference _themeFromKey(String? key) {
  switch (key) {
    case 'light':
      return ThemePreference.light;
    case 'dark':
      return ThemePreference.dark;
    default:
      return ThemePreference.system;
  }
}
