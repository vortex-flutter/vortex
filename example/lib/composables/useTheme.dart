import 'package:flutter/material.dart';
import 'package:vortex/vortex.dart';

class ThemeState {
  final Ref<bool> isDarkMode;
  final void Function() toggleTheme;

  ThemeState({
    required this.isDarkMode,
    required this.toggleTheme,
  });
}

// Define a custom composable for theme management
ThemeState useTheme(BuildContext context, {bool initialDarkMode = false}) {
  // Create reactive state
  final isDarkMode = ReactiveHooks.useRef<bool>('isDarkTheme', initialDarkMode);

  // Function to toggle theme
  void toggleTheme() {
    print("toggleTheme");
    isDarkMode.value = !isDarkMode.value;
  }
  
  // Return current theme based on state
  return ThemeState(
    isDarkMode: isDarkMode,
    toggleTheme: toggleTheme,
  );
}

// Register the custom composable
void registerThemeComposable() {
  Vortex.registerComposable('useTheme', useTheme);
}