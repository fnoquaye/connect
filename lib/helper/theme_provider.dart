import 'package:flutter/material.dart';
// import 'package:flutter/scheduler.dart'; // For system brightness

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system; // Default to system preference

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      // Get the current brightness of the platform
      final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
      return brightness == Brightness.dark;
    } else {
      return _themeMode == ThemeMode.dark;
    }
  }

  void toggleTheme(ThemeMode? newThemeMode) {
    if (newThemeMode == null) { // Optional: for a three-way toggle (light, dark, system)
      if (_themeMode == ThemeMode.light) {
        _themeMode = ThemeMode.dark;
      } else if (_themeMode == ThemeMode.dark) {
        _themeMode = ThemeMode.system;
      } else {
        _themeMode = ThemeMode.light;
      }
    } else {
      _themeMode = newThemeMode;
    }
    notifyListeners();
  }
}