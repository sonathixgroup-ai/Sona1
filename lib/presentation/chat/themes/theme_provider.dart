// lib/presentation/chat/themes/theme_provider.dart
// Provider pour basculer entre thème clair et sombre (avec Riverpod)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'light_theme.dart';
import 'dark_theme.dart';

// État du thème
class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system);

  void setLightMode() => state = ThemeMode.light;
  void setDarkMode() => state = ThemeMode.dark;
  void setSystemMode() => state = ThemeMode.system;
  void toggle() {
    if (state == ThemeMode.light) {
      state = ThemeMode.dark;
    } else if (state == ThemeMode.dark) {
      state = ThemeMode.light;
    } else {
      // Si système, basculer vers le mode opposé du système (optionnel)
      state = ThemeMode.light;
    }
  }
}

// Provider du notifier
final themeNotifierProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

// Provider du ThemeData actuel (réactif)
final themeDataProvider = Provider<ThemeData>((ref) {
  final mode = ref.watch(themeNotifierProvider);
  switch (mode) {
    case ThemeMode.light:
      return LightTheme.theme;
    case ThemeMode.dark:
      return DarkTheme.theme;
    case ThemeMode.system:
      // Détecter le thème système
      final brightness = WidgetsBinding.instance.window.platformBrightness;
      return brightness == Brightness.dark ? DarkTheme.theme : LightTheme.theme;
    default:
      return LightTheme.theme;
  }
});
