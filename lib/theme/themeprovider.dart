import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = "theme_mode";
  ThemeMode _themeMode = ThemeMode.light;

  ThemeProvider();

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme() {
    // Keep a strict brand look (red + white) in this app.
    _themeMode = ThemeMode.light;
    _saveThemeToPrefs();
    notifyListeners();
  }

  Future<void> loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? ThemeMode.light.index;
    _themeMode = ThemeMode.values[themeIndex];

    if (_themeMode != ThemeMode.light) {
      _themeMode = ThemeMode.light;
      await prefs.setInt(_themeKey, ThemeMode.light.index);
    }

    notifyListeners();
  }

  Future<void> _saveThemeToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt(_themeKey, _themeMode.index);
  }
}
