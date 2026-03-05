import 'package:flutter/material.dart';
import 'package:persona_app/core/secure_storage.dart';

class ThemeProvider with ChangeNotifier {
  final SecureStorageService _storage = SecureStorageService();
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final mode = await _storage.read("theme_mode");
    if (mode != null) {
      if (mode.contains("light")) _themeMode = ThemeMode.light;
      if (mode.contains("dark")) _themeMode = ThemeMode.dark;
      if (mode.contains("system")) _themeMode = ThemeMode.system;
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _storage.write("theme_mode", mode.toString());
    notifyListeners();
  }
}
