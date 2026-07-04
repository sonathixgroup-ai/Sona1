import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// =============================================================================
// LIGHT MODE COLORS (TON DESIGN SYSTEM)
// =============================================================================

class LightModeColors {
  const LightModeColors();

  static const primary = Color(0xFF0A3D62);
  static const secondary = Color(0xFF0A2F5C);
  static const accent = Color(0xFFF9C74F);

  static const onPrimary = Color(0xFFFFFFFF);
  static const onSecondary = Color(0xFFFFFFFF);

  static const background = Color(0xFF0F2B4A);
  static const surface = Color(0xFF133C63);

  static const onSurface = Color(0xFFFFFFFF);
  static const primaryText = Color(0xFFFFFFFF);
  static const secondaryText = Color(0xB3FFFFFF);
  static const hint = Color(0x80FFFFFF);

  static const divider = Color(0x1AFFFFFF);

  static const error = Color(0xFFEF4444);
  static const onError = Color(0xFFFFFFFF);
  static const success = Color(0xFF22C55E);
  static const emergencyRed = Color(0xFFFF3B30);

  static const metalGold = Color(0xFFF9C74F);
  static const metalGoldDeep = Color(0xFFD4A017);
  static const metalGoldSoft = Color(0xFFFFF3B0);

  static const medicalBlue = Color(0xFF3B82F6);
  static const medicalBlueDeep = Color(0xFF2563EB);
  static const medicalBlueSoft = Color(0xFF1E3A5F);

  static const cyberDarkBlue = Color(0xFF081F3A);

  static const transparent = Color(0x00000000);
}

// =============================================================================
// DARK MODE COLORS
// =============================================================================

class DarkModeColors {
  static const primary = Color(0xFF071A2B);
  static const background = Color(0xFF071A2B);
  static const surface = Color(0xFF0B2336);

  static const onSurface = Colors.white;
  static const primaryText = Colors.white;
  static const secondaryText = Color(0xFF94A3B8);

  static const error = Color(0xFFEF4444);
  static const emergencyRed = Color(0xFFFF3B30); // AJOUT: manquait, utilisé par EmergencyFab

  static const metalGold = Color(0xFFD4AF37);
  static const metalGoldDeep = Color(0xFFB8860B);
  static const metalGoldSoft = Color(0xFF5C4E1E);

  static const cyberDarkBlue = Color(0xFF081F3A);
}

// =============================================================================
// EMERGENCY — COULEURS "URGENT" (template sombre premium, même en light mode)
// AJOUT COMPLET: classe totalement absente, cause des erreurs de compilation
// =============================================================================

class EmergencyUrgentColors {
  // Fonds
  static const bg0 = Color(0xFF05111F);
  static const bg1 = Color(0xFF0B1F33);
  static const panel = Color(0xFF0B2036);
  static const card = Color(0xFF102A45);
  static const stroke = Color(0xFF23425F);

  // Texte
  static const text = Colors.white;
  static const textDim = Color(0xFF93A9BE);

  // Accents sémantiques
  static const danger = Color(0xFFFF3B30);
  static const safetyGreen = Color(0xFF22C55E);
  static const amber = Color(0xFFF9C74F);
  static const medicalBlue = Color(0xFF3B82F6);
  static const fireOrange = Color(0xFFF97316);
  static const violet = Color(0xFF8B5CF6);
  static const cyan = Color(0xFF06B6D4);

  static Color scrim() => Colors.black.withValues(alpha: 0.72);
}

class EmergencyUrgentGradients {
  static LinearGradient background() => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [EmergencyUrgentColors.bg0, EmergencyUrgentColors.bg1],
      );

  static LinearGradient panel() => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          EmergencyUrgentColors.panel,
          EmergencyUrgentColors.panel.withValues(alpha: 0.92),
        ],
      );
}

// =============================================================================
// EMERGENCY COLORS (blood sheet / medical) — ajoutées précédemment
// =============================================================================

class EmergencyUrgencyScaleColors {
  static const stable = Color(0xFF22C55E);
  static const moderate = Color(0xFFF9C74F);
  static const urgent = Color(0xFFF97316);
  static const critical = Color(0xFFEF4444);
}

class EmergencyMedicalSheetColors {
  static const stroke = Color(0xFFE2E8F0);
}

class EmergencyMedicalSheetGradients {
  static LinearGradient background() => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white, Color(0xFFF8FAFC)],
      );
}

// =============================================================================
// SPACING
// =============================================================================

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double sm2 = 12.0;
  static const double md = 16.0;
  static const double md2 = 20.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets horizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets verticalMd = EdgeInsets.symmetric(vertical: md);
}

// =============================================================================
// RADIUS
// =============================================================================

class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double full = 9999.0;
}

// =============================================================================
// SHADOWS
// =============================================================================

class AppShadows {
  static const soft = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];

  static const light = [
    BoxShadow(
      color: Color(0x22000000),
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ];
}

// =============================================================================
// TEXT THEME
// =============================================================================

TextTheme _buildTextTheme(Color color) {
  return TextTheme(
    headlineLarge: GoogleFonts.plusJakartaSans(
      fontSize: 22,
      fontWeight: FontWeight.w800,
      color: color,
    ),
    titleLarge: GoogleFonts.plusJakartaSans(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: color,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: color,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: color,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: color,
    ),
  );
}

// =============================================================================
// LIGHT THEME
// =============================================================================

ThemeData get lightTheme => ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      scaffoldBackgroundColor: LightModeColors.primary,

      colorScheme: const ColorScheme.dark(
        primary: LightModeColors.primary,
        secondary: LightModeColors.secondary,
        tertiary: LightModeColors.accent,
        surface: LightModeColors.surface,

        onPrimary: LightModeColors.onPrimary,
        onSecondary: LightModeColors.onSecondary,
        onSurface: LightModeColors.onSurface,
        error: LightModeColors.error,
      ),

      dividerColor: LightModeColors.divider,

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),

      cardTheme: CardThemeData(
        color: LightModeColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: LightModeColors.divider),
        ),
      ),

      textTheme: _buildTextTheme(LightModeColors.primaryText),
    );

// =============================================================================
// DARK THEME
// =============================================================================

ThemeData get darkTheme => ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      scaffoldBackgroundColor: DarkModeColors.background,

      colorScheme: const ColorScheme.dark(
        primary: DarkModeColors.primary,
        surface: DarkModeColors.surface,
        onSurface: Colors.white,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),

      cardTheme: CardThemeData(
        color: DarkModeColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),

      textTheme: _buildTextTheme(DarkModeColors.primaryText),
    );

// =============================================================================
// ADMIN CYBER COLORS
// =============================================================================

class AdminCyberColors {
  static const text = Color(0xFFDCEFFF);
  static const textDim = Color(0xFF7EAABF);
  static const panel = Color(0xFF081828);
  static const panelHi = Color(0xFF0B2040);
  static const stroke = Color(0xFF1E3A5F);
  static const neonCyan = Color(0xFF00E5FF);
  static const neonViolet = Color(0xFFBB6BFF);
  static const electricBlue = Color(0xFF0EA5E9);
  static const black = Color(0xFF05111F);
  static const success = Color(0xFF22C55E);
  static const danger = Color(0xFFEF4444);
}

// =============================================================================
// ADMIN CYBER GRADIENTS
// =============================================================================

class AdminCyberGradients {
  static LinearGradient glowBlue() => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0EA5E9), Color(0xFF00E5FF)],
      );

  static LinearGradient glowViolet() => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF7C3AED), Color(0xFFBB6BFF)],
      );
}

// =============================================================================
// MARKET COLORS
// =============================================================================

class MarketColors {
  static const orange = Color(0xFFF97316);
  static const orangeDeep = Color(0xFFEA580C);
  static const stroke = Color(0xFFE2E8F0);
  static const ink = Color(0xFF1E293B);
  static const grayText = Color(0xFF94A3B8);
  static const bg = Color(0xFFF1F5F9);
}

// =============================================================================
// CONTEXT EXTENSIONS
// =============================================================================

extension ThixThemeX on BuildContext {
  TextTheme get textStyles => Theme.of(this).textTheme;
}

// =============================================================================
// TEXTSTYLE EXTENSIONS (.semiBold / .bold)
// AJOUT: manquait totalement, utilisé partout dans emergency_overlay.dart
// =============================================================================

extension ThixTextStyleX on TextStyle {
  TextStyle get semiBold => copyWith(fontWeight: FontWeight.w600);
  TextStyle get bold => copyWith(fontWeight: FontWeight.w700);
}
