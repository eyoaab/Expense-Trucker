import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _isSystemDarkMode = false; // Tracks the system theme mode

  ThemeProvider() {
    _loadThemePreference();
  }

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return _isSystemDarkMode;
    }
    return _themeMode == ThemeMode.dark;
  }

  // Called by UI to update tracking of system theme mode
  void setSystemDarkMode(bool isDark) {
    _isSystemDarkMode = isDark;
    // Only notify if we're using system theme
    if (_themeMode == ThemeMode.system) {
      notifyListeners();
    }
  }

  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themePref = prefs.getString(AppConstants.themeModeKey);

      if (themePref == 'light') {
        _themeMode = ThemeMode.light;
      } else if (themePref == 'dark') {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.system;
      }
      notifyListeners();
    } catch (e) {
      // If there's an error, use default value
      _themeMode = ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String themePrefValue;

      switch (themeMode) {
        case ThemeMode.light:
          themePrefValue = 'light';
          break;
        case ThemeMode.dark:
          themePrefValue = 'dark';
          break;
        default:
          themePrefValue = 'system';
      }

      await prefs.setString(AppConstants.themeModeKey, themePrefValue);
      _themeMode = themeMode;
      notifyListeners();
    } catch (e) {
      // If there's an error, just update state without saving
      _themeMode = themeMode;
      notifyListeners();
    }
  }

  // Helper methods to set specific theme modes
  Future<void> setLightMode() => setThemeMode(ThemeMode.light);
  Future<void> setDarkMode() => setThemeMode(ThemeMode.dark);
  Future<void> setSystemMode() => setThemeMode(ThemeMode.system);

  // Toggle between light and dark mode
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      await setDarkMode();
    } else {
      await setLightMode();
    }
  }
}
