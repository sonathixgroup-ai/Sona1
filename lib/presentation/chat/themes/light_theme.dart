// lib/presentation/chat/themes/light_theme.dart
// Thème clair complet

import 'package:flutter/material.dart';
import 'custom_colors.dart';
import 'text_styles.dart';

class LightTheme {
  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: CustomColors.primary,
      scaffoldBackgroundColor: CustomColors.lightBackground,
      cardColor: CustomColors.lightSurface,
      dividerColor: CustomColors.lightDivider,
      appBarTheme: const AppBarTheme(
        backgroundColor: CustomColors.lightBackground,
        foregroundColor: CustomColors.lightTextPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyles.headline,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: CustomColors.lightBackground,
        selectedItemColor: CustomColors.primary,
        unselectedItemColor: CustomColors.lightTextSecondary,
        type: BottomNavigationBarType.fixed,
      ),
      listTileTheme: const ListTileThemeData(
        textColor: CustomColors.lightTextPrimary,
        subtitleTextStyle: TextStyles.caption,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyles.messageBody,
        bodyMedium: TextStyles.caption,
        titleLarge: TextStyles.headline,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CustomColors.lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyles.caption.copyWith(color: CustomColors.lightTextSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: CustomColors.primary,
          foregroundColor: Colors.white,
          textStyle: TextStyles.button,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: CustomColors.lightSurface,
        labelStyle: TextStyles.caption,
        secondaryLabelStyle: TextStyles.caption,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }
}
