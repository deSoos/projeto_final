import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// global app state: theme mode and locale.
/// widgets that need to react to changes should listen to this notifier.
class AppState extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  Locale? _locale; // null = system

  ThemeMode get themeMode => _themeMode;
  Locale? get locale => _locale;

  /// call once at startup to restore persisted preferences.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString('theme_mode') ?? 'system';
    final lang  = prefs.getString('language')   ?? 'system';
    _themeMode = _parseTheme(theme);
    _locale    = _parseLang(lang);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', _themeKey(mode));
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    _locale = _parseLang(lang);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
    notifyListeners();
  }

  // helpers

  static ThemeMode _parseTheme(String v) {
    switch (v) {
      case 'light':  return ThemeMode.light;
      case 'dark':   return ThemeMode.dark;
      default:       return ThemeMode.system;
    }
  }

  static String _themeKey(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:  return 'light';
      case ThemeMode.dark:   return 'dark';
      case ThemeMode.system: return 'system';
    }
  }

  static Locale? _parseLang(String v) {
    switch (v) {
      case 'pt': return const Locale('pt');
      case 'en': return const Locale('en');
      default:   return null; // system
    }
  }

  /// returns the display string for the current language setting.
  String get languageKey {
    if (_locale == null) return 'system';
    return _locale!.languageCode; // 'pt' or 'en'
  }
}
