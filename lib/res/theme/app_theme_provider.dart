import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppThemeProvider extends ChangeNotifier {
  late Color _seedColor;
  late ThemeMode _themeMode;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  static const String _themeKey = "THEME_MODE";

  Color get seedColor => _seedColor;
  ThemeMode get themeMode => _themeMode;

  set seedColor(value) {
    _seedColor = value;
    notifyListeners();
  }

  set themeMode(value) {
    _themeMode = value;
    _saveThemeMode();
    notifyListeners();
  }

  AppThemeProvider({
    required Color defaultColor,
    ThemeMode defaultThemeMode = ThemeMode.system, // Use system theme by default
  }) {
    _seedColor = Color.lerp(defaultColor, Colors.black, 0.1) ?? defaultColor;
    _themeMode = defaultThemeMode;
    // Load saved theme preference on initialization
    loadThemeMode();
  }

  void updateTheme(Color currentColor) {
    seedColor = currentColor;
  }

  void toggleThemeMode() {
    // Once user manually toggles, we save their preference and stop following system
    if (_themeMode == ThemeMode.system || _themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }
    _saveThemeMode();
    notifyListeners();
  }

  bool get isDarkMode => _themeMode == ThemeMode.dark;
  
  /// Check if the current effective theme is dark (considering system theme)
  bool isCurrentlyDark(BuildContext context) {
    switch (_themeMode) {
      case ThemeMode.dark:
        return true;
      case ThemeMode.light:
        return false;
      case ThemeMode.system:
        return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
  }
  
  /// Load theme preference from secure storage
  Future<void> loadThemeMode() async {
    try {
      final savedTheme = await _storage.read(key: _themeKey);
      if (savedTheme != null) {
        switch (savedTheme) {
          case 'dark':
            _themeMode = ThemeMode.dark;
            break;
          case 'light':
            _themeMode = ThemeMode.light;
            break;
          case 'system':
            _themeMode = ThemeMode.system;
            break;
          default:
            _themeMode = ThemeMode.light;
        }
        notifyListeners();
      }
    } catch (e) {
      // If loading fails, keep default theme
      print('Failed to load theme preference: $e');
    }
  }
  
  /// Save theme preference to secure storage
  Future<void> _saveThemeMode() async {
    try {
      String themeString;
      switch (_themeMode) {
        case ThemeMode.dark:
          themeString = 'dark';
          break;
        case ThemeMode.light:
          themeString = 'light';
          break;
        case ThemeMode.system:
          themeString = 'system';
          break;
      }
      await _storage.write(key: _themeKey, value: themeString);
    } catch (e) {
      print('Failed to save theme preference: $e');
    }
  }
}