import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// =======================================================
/// SPACING SYSTEM
/// =======================================================
class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const sm2 = 12.0;
  static const md = 16.0;
  static const md2 = 20.0;
  static const lg = 24.0;
  static const lg2 = 28.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

/// =======================================================
/// RADIUS SYSTEM
/// =======================================================
class AppRadius {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const full = 9999.0;
}

/// =======================================================
/// LIGHT COLORS
/// =======================================================
class LightModeColors {
  static const primary = Color(0xFF1877F2);
  static const secondary = Color(0xFF0B5ED7);
  static const accent = Color(0xFF00A884);

  static const background = Color(0xFFF0F2F5);
  static const surface = Color(0xFFFFFFFF);

  static const primaryText = Color(0xFF111827);
  static const secondaryText = Color(0xFF4B5563);
  static const hint = Color(0xFF9CA3AF);

  static const error = Color(0xFFDC2626);
  static const success = Color(0xFF059669);

  static const divider = Color(0xFFE5E7EB);

  // medical
  static const medicalBlue = Color(0xFF2563EB);
  static const medicalBlueSoft = Color(0xFFEAF2FF);
}

/// =======================================================
/// DARK COLORS
/// =======================================================
class DarkModeColors {
  static const primary = Color(0xFF071A2B);
  static const surface = Color(0xFF0B2336);
  static const background = Color(0xFF071A2B);

  static const primaryText = Color(0xFFF8FAFC);
  static const secondaryText = Color(0xFF94A3B8);

  static const error = Color(0xFFEF4444);
  static const success = Color(0xFF10B981);

  static const divider = Color(0xFF1E5F8C);

  static const gold = Color(0xFFD4AF37);
  static const goldDeep = Color(0xFFB8860B);
}

/// =======================================================
/// FONT SIZES
/// =======================================================
class FontSizes {
  static const headlineLarge = 32.0;
  static const headlineMedium = 26.0;
  static const titleLarge = 20.0;
  static const titleMedium = 17.0;
  static const bodyLarge = 16.0;
  static const bodyMedium = 14.0;
  static const bodySmall = 12.0;
  static const labelLarge = 15.0;
  static const labelMedium = 13.0;
  static const labelSmall = 11.0;
}

/// =======================================================
/// TEXT THEME BUILDER
/// =======================================================
TextTheme _buildTextTheme(Color color) {
  return TextTheme(
    headlineLarge: GoogleFonts.plusJakartaSans(
      fontSize: FontSizes.headlineLarge,
      fontWeight: FontWeight.w800,
      color: color,
    ),
    headlineMedium: GoogleFonts.plusJakartaSans(
      fontSize: FontSizes.headlineMedium,
      fontWeight: FontWeight.w700,
      color: color,
    ),
    titleLarge: GoogleFonts.plusJakartaSans(
      fontSize: FontSizes.titleLarge,
      fontWeight: FontWeight.w700,
      color: color,
    ),
    titleMedium: GoogleFonts.plusJakartaSans(
      fontSize: FontSizes.titleMedium,
      fontWeight: FontWeight.w600,
      color: color,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: FontSizes.bodyLarge,
      fontWeight: FontWeight.w400,
      color: color,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: FontSizes.bodyMedium,
      fontWeight: FontWeight.w400,
      color: color,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: FontSizes.bodySmall,
      fontWeight: FontWeight.w400,
      color: color,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: FontSizes.labelLarge,
      fontWeight: FontWeight.w600,
      color: color,
    ),
  );
}

/// =======================================================
/// LIGHT THEME
/// =======================================================
ThemeData get lightTheme {
  final scheme = ColorScheme.light(
    primary: LightModeColors.primary,
    secondary: LightModeColors.secondary,
    surface: LightModeColors.surface,
    error: LightModeColors.error,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: LightModeColors.background,

    textTheme: _buildTextTheme(LightModeColors.primaryText),

    appBarTheme: const AppBarTheme(
      backgroundColor: LightModeColors.surface,
      elevation: 0,
      centerTitle: true,
    ),

    cardTheme: CardTheme(
      color: LightModeColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
    ),

    dividerTheme: const DividerThemeData(
      color: LightModeColors.divider,
      thickness: 1,
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: LightModeColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: LightModeColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        borderSide: const BorderSide(color: LightModeColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        borderSide: const BorderSide(color: LightModeColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        borderSide: const BorderSide(color: LightModeColors.primary),
      ),
    ),
  );
}

/// =======================================================
/// DARK THEME
/// =======================================================
ThemeData get darkTheme {
  final scheme = ColorScheme.dark(
    primary: DarkModeColors.primary,
    secondary: DarkModeColors.goldDeep,
    surface: DarkModeColors.surface,
    error: DarkModeColors.error,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: DarkModeColors.background,

    textTheme: _buildTextTheme(DarkModeColors.primaryText),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
    ),

    cardTheme: CardTheme(
      color: DarkModeColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
    ),

    dividerTheme: const DividerThemeData(
      color: DarkModeColors.divider,
      thickness: 1,
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: DarkModeColors.goldDeep,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
    ),
  );
}

/// =======================================================
/// CONTEXT EXTENSIONS
/// =======================================================
extension ThemeContext on BuildContext {
  TextTheme get text => Theme.of(this).textTheme;
  ColorScheme get colors => Theme.of(this).colorScheme;
}
