import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  static const String _themeKey = 'selected_theme';

  // Theme mode options
  static const String lightMode = 'light';
  static const String darkMode = 'dark';
  static const String systemMode = 'system';

  final RxString selectedTheme = darkMode.obs;

  @override
  void onInit() {
    super.onInit();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themeKey) ?? darkMode;
    selectedTheme.value = savedTheme;
  }

  Future<void> _saveThemePreference(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme);
  }

  Future<void> setTheme(String theme) async {
    selectedTheme.value = theme;
    await _saveThemePreference(theme);
    
    // Update app theme mode
    Get.changeThemeMode(_getThemeMode());
  }

  ThemeMode _getThemeMode() {
    switch (selectedTheme.value) {
      case lightMode:
        return ThemeMode.light;
      case darkMode:
        return ThemeMode.dark;
      case systemMode:
      default:
        return ThemeMode.system;
    }
  }

  ThemeMode get currentThemeMode => _getThemeMode();

  bool get isDarkMode {
    if (selectedTheme.value == darkMode) return true;
    if (selectedTheme.value == lightMode) return false;
    return Get.isPlatformDarkMode;
  }
}
