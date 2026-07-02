// lib/presentation/chat/themes/dark_theme.dart
// Thème sombre complet

import 'package:flutter/material.dart';
import 'custom_colors.dart';
import 'text_styles.dart';

class DarkTheme {
  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: CustomColors.primary,
      scaffoldBackgroundColor: CustomColors.darkBackground,
      cardColor: CustomColors.darkSurface,
      dividerColor: CustomColors.darkDivider,
      appBarTheme: const AppBarTheme(
        backgroundColor: CustomColors.darkBackground,
        foregroundColor: CustomColors.darkTextPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyles.headline,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: CustomColors.darkBackground,
        selectedItemColor: CustomColors.primary,
        unselectedItemColor: CustomColors.darkTextSecondary,
        type: BottomNavigationBarType.fixed,
      ),
      listTileTheme: const ListTileThemeData(
        textColor: CustomColors.darkTextPrimary,
        subtitleTextStyle: TextStyles.caption,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyles.messageBody.copyWith(color: CustomColors.darkTextPrimary),
        bodyMedium: TextStyles.caption.copyWith(color: CustomColors.darkTextSecondary),
        titleLarge: TextStyles.headline.copyWith(color: CustomColors.darkTextPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CustomColors.darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyles.caption.copyWith(color: CustomColors.darkTextSecondary),
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
        backgroundColor: CustomColors.darkSurface,
        labelStyle: TextStyles.caption.copyWith(color: CustomColors.darkTextPrimary),
        secondaryLabelStyle: TextStyles.caption.copyWith(color: CustomColors.darkTextPrimary),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }
}
