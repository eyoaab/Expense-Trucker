import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class PreferencesProvider extends ChangeNotifier {
  late SharedPreferences _prefs;
  ThemeMode _themeMode = ThemeMode.system;
  String _currencyCode = AppConstants.defaultCurrencyCode;
  bool _firstTimeUser = true;
  bool _isInitialized = false;

  PreferencesProvider() {
    _loadPreferences();
  }

  // Getters
  ThemeMode get themeMode => _themeMode;
  String get currencyCode => _currencyCode;
  bool get firstTimeUser => _firstTimeUser;
  bool get isInitialized => _isInitialized;

  Future<void> _loadPreferences() async {
    try {
      _prefs = await SharedPreferences.getInstance();

      // Load theme preference
      final themePref = _prefs.getString(AppConstants.themeModeKey);
      if (themePref == 'light') {
        _themeMode = ThemeMode.light;
      } else if (themePref == 'dark') {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.system;
      }

      // Load currency preference
      _currencyCode = _prefs.getString(AppConstants.currencyCodeKey) ??
          AppConstants.defaultCurrencyCode;

      // Load first time user flag
      _firstTimeUser = _prefs.getBool(AppConstants.firstTimeUserKey) ?? true;

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      // If there's an error, use default values
      _themeMode = ThemeMode.system;
      _currencyCode = AppConstants.defaultCurrencyCode;
      _firstTimeUser = true;
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;

    try {
      String themePrefValue;
      switch (mode) {
        case ThemeMode.light:
          themePrefValue = 'light';
          break;
        case ThemeMode.dark:
          themePrefValue = 'dark';
          break;
        default:
          themePrefValue = 'system';
      }

      await _prefs.setString(AppConstants.themeModeKey, themePrefValue);
    } catch (e) {
      // Ignore errors
    }

    notifyListeners();
  }

  Future<void> setCurrencyCode(String code) async {
    if (!AppConstants.supportedCurrencies.contains(code)) {
      code = AppConstants.defaultCurrencyCode;
    }

    _currencyCode = code;

    try {
      await _prefs.setString(AppConstants.currencyCodeKey, code);
    } catch (e) {
      // Ignore errors
    }

    notifyListeners();
  }

  Future<void> setFirstTimeUser(bool isFirstTime) async {
    _firstTimeUser = isFirstTime;

    try {
      await _prefs.setBool(AppConstants.firstTimeUserKey, isFirstTime);
    } catch (e) {
      // Ignore errors
    }

    notifyListeners();
  }
}
