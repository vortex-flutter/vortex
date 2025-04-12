import 'package:flutter/material.dart';
import 'package:flutterwind_core/flutterwind.dart';
import 'package:vortex/vortex.dart';

class ThemePlugin extends BasePlugin {
  // Theme mode state
  ThemeMode _themeMode = ThemeMode.system;
  
  // Getter for current theme mode
  ThemeMode get themeMode => _themeMode;
  
  @override
  String get name => 'theme';
  
  @override
  Future<void> initialize() async {
    Log.i('Theme plugin initialized');
    // In a real app, you would load saved theme preference here
  }
  
  @override
  Future<void> onAppStart(BuildContext context) async {
    Log.i('Theme plugin: App started with theme mode: $_themeMode');
  }
  
  // Toggle between light and dark mode
  void toggleTheme() {
    if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }
    Log.i('Theme changed to: $_themeMode');
  }
  
  // Set specific theme mode
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    Log.i('Theme set to: $_themeMode');
  }
}