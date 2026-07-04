import 'package:flutter/material.dart';

/// ============================================================================
/// STABLE THEME LAYER (backward-compatible)
/// ----------------------------------------------------------------------------
/// This file intentionally keeps legacy class names used across old pages:
/// - LearningCyberColors
/// - LearningCyberGradients
/// - InstitutionalColors
/// - DarkModeColors (with success)
///
/// It prevents compile breaks after refactors by preserving public API.
/// ============================================================================

@immutable
class LearningCyberColors {
  const LearningCyberColors._();

  // Base surfaces
  static const Color bg0 = Color(0xFF070B14);
  static const Color panel = Color(0xFF101A2B);
  static const Color panelHi = Color(0xFF162238);
  static const Color stroke = Color(0xFF2A3A57);

  // Text
  static const Color text = Color(0xFFEAF2FF);
  static const Color textDim = Color(0xFF9CB0D2);

  // Accents
  static const Color neonCyan = Color(0xFF22E7FF);
  static const Color neonViolet = Color(0xFF8B5CF6);
  static const Color electricBlue = Color(0xFF2F80FF);

  // Feedback / utility
  static const Color success = Color(0xFF22C55E);
  static const Color danger = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color black = Colors.black;
  static const Color white = Colors.white;
}

@immutable
class LearningCyberGradients {
  const LearningCyberGradients._();

  static Gradient background() {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[
        Color(0xFF050912),
        Color(0xFF0A1222),
        Color(0xFF101A2B),
      ],
      stops: <double>[0.0, 0.45, 1.0],
    );
  }

  static Gradient glowBlue() {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[
        Color(0x3322E7FF),
        Color(0x1A2F80FF),
      ],
    );
  }

  static Gradient glowViolet() {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[
        Color(0x338B5CF6),
        Color(0x1A22E7FF),
      ],
    );
  }
}

@immutable
class InstitutionalColors {
  const InstitutionalColors._();

  static const Color civicBlue = Color(0xFF1565C0);
  static const Color civicBlueSoft = Color(0xFF4F8FD8);
  static const Color navy = Color(0xFF0C2340);
  static const Color navy2 = Color(0xFF163A63);
}

@immutable
class DarkModeColors {
  const DarkModeColors._();

  static const Color primary = Color(0xFF0B1220);
  static const Color cyberDarkBlue = Color(0xFF0D1B2A);

  // Required by existing pages (fixes "Member not found: success")
  static const Color success = Color(0xFF22C55E);

  // Optional aliases for consistency
  static const Color text = LearningCyberColors.text;
  static const Color textDim = LearningCyberColors.textDim;
  static const Color danger = LearningCyberColors.danger;
}

/// Optional central app theme.
/// Safe defaults for Material 3.
@immutable
class AppTheme {
  const AppTheme._();

  static ThemeData get dark {
    final ThemeData base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: LearningCyberColors.bg0,
      colorScheme: base.colorScheme.copyWith(
        brightness: Brightness.dark,
        primary: LearningCyberColors.neonCyan,
        secondary: LearningCyberColors.electricBlue,
        surface: LearningCyberColors.panel,
        error: LearningCyberColors.danger,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: LearningCyberColors.bg0,
        foregroundColor: LearningCyberColors.text,
        elevation: 0,
      ),
    );
  }

  static ThemeData get light {
    final ThemeData base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        brightness: Brightness.light,
        primary: InstitutionalColors.civicBlue,
        secondary: InstitutionalColors.civicBlueSoft,
        error: LearningCyberColors.danger,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF111827),
        elevation: 0,
      ),
    );
  }
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
// CONTEXT EXTENSIONS
// =============================================================================

extension ThixThemeX on BuildContext {
  TextTheme get textStyles => Theme.of(this).textTheme;
}

// =============================================================================
// TEXTSTYLE EXTENSIONS (.semiBold / .bold)
// =============================================================================

extension ThixTextStyleX on TextStyle {
  TextStyle get semiBold => copyWith(fontWeight: FontWeight.w600);
  TextStyle get bold => copyWith(fontWeight: FontWeight.w700);
}
