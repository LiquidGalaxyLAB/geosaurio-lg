import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  ThemeService._internal();

  static final ThemeService instance = ThemeService._internal();

  static const String _darkModeKey = 'dark_mode';

  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeMode get themeMode {
    return _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> loadTheme() async {
    final preferences = await SharedPreferences.getInstance();

    _isDarkMode = preferences.getBool(_darkModeKey) ?? false;

    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    if (_isDarkMode == value) return;

    _isDarkMode = value;
    notifyListeners();

    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_darkModeKey, value);
  }

  Future<void> toggleTheme() async {
    await setDarkMode(!_isDarkMode);
  }
}