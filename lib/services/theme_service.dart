import 'package:flutter/material.dart';

class ThemeService extends ChangeNotifier {

  // Stores if dark mode is enabled
  bool _isDarkMode = false;

  // Get the current theme
  bool get isDarkMode => _isDarkMode;

  // Set light or dark mode
  void setDarkMode(bool value) {
    if (_isDarkMode == value) return;

    _isDarkMode = value;

    // Update the UI
    notifyListeners();
  }

  // Switch between light and dark mode
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}