import 'package:flutter/material.dart';
import 'package:vortex/src/reactive/ref.dart';
import 'package:vortex/src/utils/logger.dart';
import 'package:vortex/src/vortex_core.dart';

/// A class representing the theme state
class ThemeState {
  final Ref<ThemeData> theme;
  final Ref<bool> isDarkMode;
  final Ref<ThemeData> lightTheme;
  final Ref<ThemeData> darkTheme;
  static const String _darkModeKey = 'theme_dark_mode';

  ThemeState({
    required this.theme,
    required this.isDarkMode,
    required this.lightTheme,
    required this.darkTheme,
  }) {
    // Load saved theme preference
    _loadThemePreference();
  }

  /// Load saved theme preference
  void _loadThemePreference() {
    try {
      final savedDarkMode = Vortex.store.getState<bool>(
        _darkModeKey,
        persistent: true,
      );
      if (savedDarkMode != null) {
        isDarkMode.value = savedDarkMode;
        _updateTheme();
      }
    } catch (e) {
      // If Vortex is not initialized, just use the current value
      Log.i(
        'Vortex not initialized yet, using current theme value: ${isDarkMode.value}',
      );
    }
  }

  /// Save theme preference
  void _saveThemePreference() {
    try {
      Vortex.store.setState(_darkModeKey, isDarkMode.value, persistent: true);
    } catch (e) {
      Log.w('Failed to save theme preference: $e');
    }
  }

  /// Toggle dark mode
  void toggleDarkMode() {
    isDarkMode.value = !isDarkMode.value;
    _updateTheme();
    _saveThemePreference();
    Log.i('Theme toggled to ${isDarkMode.value ? "dark" : "light"}');
  }

  /// Set dark mode explicitly
  void setDarkMode(bool value) {
    if (isDarkMode.value != value) {
      isDarkMode.value = value;
      _updateTheme();
      _saveThemePreference();
      Log.i('Theme set to ${value ? "dark" : "light"}');
    }
  }

  /// Update the current theme based on dark mode state
  void _updateTheme() {
    final newTheme = isDarkMode.value ? darkTheme.value : lightTheme.value;
    if (theme.value != newTheme) {
      theme.value = newTheme;
      Log.i('Theme updated: ${isDarkMode.value ? "dark" : "light"}');
    }
  }

  /// Set custom light theme
  void setLightTheme(ThemeData newTheme) {
    if (lightTheme.value != newTheme) {
      lightTheme.value = newTheme;
      _updateTheme();
      Log.i('Light theme updated');
    }
  }

  /// Set custom dark theme
  void setDarkTheme(ThemeData newTheme) {
    if (darkTheme.value != newTheme) {
      darkTheme.value = newTheme;
      _updateTheme();
      Log.i('Dark theme updated');
    }
  }
}

// Global theme state
ThemeState? _globalThemeState;

/// Composable function for managing theme state
ThemeState useTheme({
  String? key,
  ThemeData? lightTheme,
  ThemeData? darkTheme,
  bool initialDarkMode = false,
}) {
  // Return existing global state if available
  if (_globalThemeState != null) {
    return _globalThemeState!;
  }

  // Create reactive refs with initial values
  final themeRef = Ref<ThemeData>(
    initialDarkMode
        ? (darkTheme ?? ThemeData.dark())
        : (lightTheme ?? ThemeData.light()),
  );
  final isDarkModeRef = Ref<bool>(initialDarkMode);
  final lightThemeRef = Ref<ThemeData>(lightTheme ?? ThemeData.light());
  final darkThemeRef = Ref<ThemeData>(darkTheme ?? ThemeData.dark());

  // Create the theme state
  _globalThemeState = ThemeState(
    theme: themeRef,
    isDarkMode: isDarkModeRef,
    lightTheme: lightThemeRef,
    darkTheme: darkThemeRef,
  );

  // Try to load saved theme preference if Vortex is initialized
  try {
    final savedDarkMode = Vortex.store.getState<bool>(
      'theme_dark_mode',
      persistent: true,
    );
    if (savedDarkMode != null && _globalThemeState != null) {
      _globalThemeState!.setDarkMode(savedDarkMode);
    }
  } catch (e) {
    // If Vortex is not initialized, just use the initial value
    Log.i(
      'Vortex not initialized yet, using initial theme value: $initialDarkMode',
    );
  }

  return _globalThemeState!;
}
