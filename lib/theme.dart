import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// =============================================================================
// 1. ESPACEMENTS (inchangé)
// =============================================================================

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double sm2 = 12.0;
  static const double md = 16.0;
  static const double md2 = 20.0;
  static const double lg = 24.0;
  static const double lg2 = 28.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingSm2 = EdgeInsets.all(sm2);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingMd2 = EdgeInsets.all(md2);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingLg2 = EdgeInsets.all(lg2);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);

  static const EdgeInsets horizontalXs = EdgeInsets.symmetric(horizontal: xs);
  static const EdgeInsets horizontalSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets horizontalSm2 = EdgeInsets.symmetric(horizontal: sm2);
  static const EdgeInsets horizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets horizontalMd2 = EdgeInsets.symmetric(horizontal: md2);
  static const EdgeInsets horizontalLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets horizontalLg2 = EdgeInsets.symmetric(horizontal: lg2);
  static const EdgeInsets horizontalXl = EdgeInsets.symmetric(horizontal: xl);

  static const EdgeInsets verticalXs = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets verticalSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets verticalSm2 = EdgeInsets.symmetric(vertical: sm2);
  static const EdgeInsets verticalMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets verticalMd2 = EdgeInsets.symmetric(vertical: md2);
  static const EdgeInsets verticalLg = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets verticalLg2 = EdgeInsets.symmetric(vertical: lg2);
  static const EdgeInsets verticalXl = EdgeInsets.symmetric(vertical: xl);
}

// =============================================================================
// 2. RAYONS (fusion + conservation des anciennes classes)
// =============================================================================

// Nouvelle classe unifiée – utilisez‑la dans vos nouveaux widgets
class AppRadii {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double sm2 = 12.0;
  static const double md = 16.0;
  static const double md2 = 20.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double full = 9999.0;

  // Aliases sémantiques
  static const double button = md;          // 16
  static const double card = md;            // 16
  static const double searchBar = lg;       // 24
  static const double bottomNavbar = lg;    // 24 (on utilise 24 au lieu de 30 pour rester cohérent)
  static const double qrContainer = md;     // 16
}

// Classes existantes conservées pour ne pas casser le code existant
class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double full = 9999.0;
}

class ThixHomeRadii {
  static const searchBar = 24.0;
  static const mainCards = 22.0;
  static const thixPassCard = 24.0;
  static const serviceCards = 18.0;
  static const buttons = 14.0;
  static const bottomNavbar = 30.0;
  static const qrContainer = 16.0;
}

// =============================================================================
// 3. OMBRES (inchangé)
// =============================================================================

class ThixHomeShadows {
  static const main = <BoxShadow>[
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 20,
      offset: Offset(0, 4),
    ),
  ];

  static const secondary = <BoxShadow>[
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];
}

// =============================================================================
// 4. COULEURS (centralisation + conservation)
// =============================================================================

// ---- Palette de base (nouvelle) ----
class AppBaseColors {
  static const primaryBlue = Color(0xFF003BFF);
  static const darkNavy = Color(0xFF02134F);
  static const white = Color(0xFFFFFFFF);
  static const lightGrayBackground = Color(0xFFF5F6FA);
  static const textSecondary = Color(0xFF7B8190);
  static const cardBorder = Color(0xFFE9ECF3);
  static const goldBadge = Color(0xFFF7C948);
  static const successGreen = Color(0xFF1BC47D);
  static const dangerRed = Color(0xFFFF3B30);

  static const primary = Color(0xFF1877F2);
  static const onPrimary = Color(0xFFFFFFFF);
  static const secondary = Color(0xFF0B5ED7);
  static const onSecondary = Color(0xFFFFFFFF);
  static const accent = Color(0xFF00A884);

  static const metalGold = Color(0xFFD4AF37);
  static const metalGoldDeep = Color(0xFFB8860B);
  static const metalGoldSoft = Color(0xFFFFF3B0);

  static const background = Color(0xFFF0F2F5);
  static const surface = Color(0xFFFFFFFF);
  static const onSurface = Color(0xFF111827);
  static const primaryText = Color(0xFF111827);
  static const secondaryText = Color(0xFF4B5563);
  static const hint = Color(0xFF9CA3AF);
  static const error = Color(0xFFDC2626);
  static const emergencyRed = Color(0xFFFF3B30);

  static const medicalBlue = Color(0xFF2563EB);
  static const medicalBlueDeep = Color(0xFF1D4ED8);
  static const medicalBlueSoft = Color(0xFFEAF2FF);
  static const cyberDarkBlue = Color(0xFF0D1B2A);

  static const onError = Color(0xFFFFFFFF);
  static const success = Color(0xFF059669);
  static const divider = Color(0xFFE5E7EB);
  static const transparent = Color(0x00000000);

  // Couleurs Cyber (unifiées)
  static const black = Color(0xFF05070C);
  static const panel = Color(0xFF08121E);
  static const panelHi = Color(0xFF0B1B2A);
  static const stroke = Color(0xFF14334D);
  static const text = Color(0xFFEAF2FF);
  static const textDim = Color(0xFF9BB3D3);
  static const electricBlue = Color(0xFF3B82F6);
  static const neonCyan = Color(0xFF22D3EE);
  static const neonViolet = Color(0xFFA78BFA);
  static const cyberDanger = Color(0xFFFB7185);
  static const cyberSuccess = Color(0xFF34D399);

  // Urgence
  static const urgentBg0 = Color(0xFF050A14);
  static const urgentBg1 = Color(0xFF071326);
  static const urgentCard = Color(0xFF0E2234);
  static const urgentStroke = Color(0xFF163A57);
  static const urgentText = Color(0xFFF3F6FF);
  static const urgentTextDim = Color(0xFFA9B8D6);
  static const safetyGreen = Color(0xFF22C55E);
  static const fireOrange = Color(0xFFFF6A3D);
  static const violet = Color(0xFFA78BFA);
  static const amber = Color(0xFFFBBF24);
  static const cyan = Color(0xFF22D3EE);

  // Medical sheet
  static const medicalSheetBg0 = Color(0xFFF3F8FF);
  static const medicalSheetBg1 = Color(0xFFFFFFFF);
  static const medicalSheetStroke = Color(0xFFE2ECFA);
  static const medicalSheetTextDim = Color(0xFF5B6B82);

  // Urgency scale
  static const stable = Color(0xFF22C55E);
  static const moderate = Color(0xFFFBBF24);
  static const urgent = Color(0xFFFF7A3D);
  static const critical = Color(0xFFFF3B30);

  // Institutional
  static const navy = Color(0xFF0B1F36);
  static const navy2 = Color(0xFF123A63);
  static const civicBlue = Color(0xFF1D4ED8);
  static const civicBlueSoft = Color(0xFFDBEAFE);
  static const ink = Color(0xFF0F172A);

  // Market
  static const marketBg = Color(0xFFF7F7F8);
  static const marketOrange = Color(0xFFFF5A1F);
  static const marketOrangeDeep = Color(0xFFEA580C);
  static const marketGrayText = Color(0xFF64748B);
  static const marketStroke = Color(0xFFE5E7EB);
}

// ---- Classes existantes (conservées, mais redirigent vers AppBaseColors) ----
class ThixHomeColors {
  static const primaryBlue = AppBaseColors.primaryBlue;
  static const darkNavy = AppBaseColors.darkNavy;
  static const white = AppBaseColors.white;
  static const lightGrayBackground = AppBaseColors.lightGrayBackground;
  static const textSecondary = AppBaseColors.textSecondary;
  static const cardBorder = AppBaseColors.cardBorder;
  static const goldBadge = AppBaseColors.goldBadge;
  static const successGreen = AppBaseColors.successGreen;
  static const dangerRed = AppBaseColors.dangerRed;
}

class LightModeColors {
  const LightModeColors();

  static const primary = AppBaseColors.primary;
  static const onPrimary = AppBaseColors.onPrimary;
  static const secondary = AppBaseColors.secondary;
  static const onSecondary = AppBaseColors.onSecondary;
  static const accent = AppBaseColors.accent;
  static const metalGold = AppBaseColors.metalGold;
  static const metalGoldDeep = AppBaseColors.metalGoldDeep;
  static const metalGoldSoft = AppBaseColors.metalGoldSoft;
  static const background = AppBaseColors.background;
  static const surface = AppBaseColors.surface;
  static const onSurface = AppBaseColors.onSurface;
  static const primaryText = AppBaseColors.primaryText;
  static const secondaryText = AppBaseColors.secondaryText;
  static const hint = AppBaseColors.hint;
  static const error = AppBaseColors.error;
  static const emergencyRed = AppBaseColors.emergencyRed;
  static const medicalBlue = AppBaseColors.medicalBlue;
  static const medicalBlueDeep = AppBaseColors.medicalBlueDeep;
  static const medicalBlueSoft = AppBaseColors.medicalBlueSoft;
  static const cyberDarkBlue = AppBaseColors.cyberDarkBlue;
  static const onError = AppBaseColors.onError;
  static const success = AppBaseColors.success;
  static const divider = AppBaseColors.divider;
  static const transparent = AppBaseColors.transparent;
}

extension LightModeColorsInstance on LightModeColors {
  Color get metalGold => LightModeColors.metalGold;
  Color get metalGoldDeep => LightModeColors.metalGoldDeep;
  Color get metalGoldSoft => LightModeColors.metalGoldSoft;
}

class DarkModeColors {
  static const primary = Color(0xFF071A2B);
  static const onPrimary = Color(0xFFFFFFFF);
  static const secondary = metalGoldDeep;
  static const onSecondary = Color(0xFF071A2B);
  static const accent = metalGold;
  static const metalGold = AppBaseColors.metalGold;
  static const metalGoldDeep = AppBaseColors.metalGoldDeep;
  static const metalGoldSoft = AppBaseColors.metalGoldSoft;
  static const background = Color(0xFF071A2B);
  static const surface = Color(0xFF0B2336);
  static const onSurface = Color(0xFFF8FAFC);
  static const primaryText = Color(0xFFF8FAFC);
  static const secondaryText = Color(0xFF94A3B8);
  static const hint = Color(0xFF475569);
  static const error = Color(0xFFEF4444);
  static const emergencyRed = AppBaseColors.emergencyRed;
  static const medicalBlue = Color(0xFF60A5FA);
  static const medicalBlueDeep = Color(0xFF3B82F6);
  static const medicalBlueSoft = Color(0xFF0B2336);
  static const cyberDarkBlue = AppBaseColors.cyberDarkBlue;
  static const onError = AppBaseColors.onError;
  static const success = Color(0xFF10B981);
  static const divider = Color(0xFF1E5F8C);
  static const transparent = AppBaseColors.transparent;
}

// Classes Cyber (redirigent vers AppBaseColors)
class AdminCyberColors {
  static const black = AppBaseColors.black;
  static const panel = AppBaseColors.panel;
  static const panelHi = AppBaseColors.panelHi;
  static const stroke = AppBaseColors.stroke;
  static const text = AppBaseColors.text;
  static const textDim = AppBaseColors.textDim;
  static const electricBlue = AppBaseColors.electricBlue;
  static const neonCyan = AppBaseColors.neonCyan;
  static const neonViolet = AppBaseColors.neonViolet;
  static const danger = AppBaseColors.cyberDanger;
  static const success = AppBaseColors.cyberSuccess;
}

class LearningCyberColors {
  static const black = AppBaseColors.black;
  static const bg0 = AppBaseColors.black; // ajusté pour être cohérent
  static const bg1 = Color(0xFF071326);
  static const panel = AppBaseColors.panel;
  static const panelHi = AppBaseColors.panelHi;
  static const stroke = AppBaseColors.stroke;
  static const text = AppBaseColors.text;
  static const textDim = AppBaseColors.textDim;
  static const electricBlue = AppBaseColors.electricBlue;
  static const neonCyan = AppBaseColors.neonCyan;
  static const neonViolet = AppBaseColors.neonViolet;
  static const danger = AppBaseColors.cyberDanger;
  static const success = AppBaseColors.cyberSuccess;
}

class EventsCyberColors {
  static const black = AppBaseColors.black;
  static const bg0 = AppBaseColors.black;
  static const bg1 = Color(0xFF06152B);
  static const panel = AppBaseColors.panel;
  static const panelHi = AppBaseColors.panelHi;
  static const stroke = AppBaseColors.stroke;
  static const text = AppBaseColors.text;
  static const textDim = AppBaseColors.textDim;
  static const electricBlue = AppBaseColors.electricBlue;
  static const neonCyan = AppBaseColors.neonCyan;
  static const neonViolet = AppBaseColors.neonViolet;
  static const danger = AppBaseColors.cyberDanger;
  static const success = AppBaseColors.cyberSuccess;
}

class InstitutionalColors {
  static const navy = AppBaseColors.navy;
  static const navy2 = AppBaseColors.navy2;
  static const civicBlue = AppBaseColors.civicBlue;
  static const civicBlueSoft = AppBaseColors.civicBlueSoft;
  static const ink = AppBaseColors.ink;
}

class MarketColors {
  static const ink = AppBaseColors.ink;
  static const bg = AppBaseColors.marketBg;
  static const surface = AppBaseColors.surface;
  static const orange = AppBaseColors.marketOrange;
  static const orangeDeep = AppBaseColors.marketOrangeDeep;
  static const grayText = AppBaseColors.marketGrayText;
  static const stroke = AppBaseColors.marketStroke;
}

class EmergencyUrgentColors {
  static const bg0 = AppBaseColors.urgentBg0;
  static const bg1 = AppBaseColors.urgentBg1;
  static const panel = AppBaseColors.panel;
  static const card = AppBaseColors.urgentCard;
  static const stroke = AppBaseColors.urgentStroke;
  static const text = AppBaseColors.urgentText;
  static const textDim = AppBaseColors.urgentTextDim;
  static const danger = DarkModeColors.emergencyRed;
  static const medicalBlue = Color(0xFF2F7DFF);
  static const safetyGreen = AppBaseColors.safetyGreen;
  static const fireOrange = AppBaseColors.fireOrange;
  static const violet = AppBaseColors.violet;
  static const amber = AppBaseColors.amber;
  static const cyan = AppBaseColors.cyan;

  static Color scrim() => const Color(0xFF00040A).withOpacity(0.62);
}

class EmergencyMedicalSheetColors {
  static const bg0 = AppBaseColors.medicalSheetBg0;
  static const bg1 = AppBaseColors.medicalSheetBg1;
  static const panel = AppBaseColors.surface;
  static const stroke = AppBaseColors.medicalSheetStroke;
  static const text = LightModeColors.primary;
  static const textDim = AppBaseColors.medicalSheetTextDim;
  static const medicalBlue = LightModeColors.medicalBlue;
  static const medicalBlueSoft = LightModeColors.medicalBlueSoft;
}

class EmergencyUrgencyScaleColors {
  static const stable = AppBaseColors.stable;
  static const moderate = AppBaseColors.moderate;
  static const urgent = AppBaseColors.urgent;
  static const critical = AppBaseColors.critical;
}

// =============================================================================
// 5. DÉGRADÉS (centralisation + conservation)
// =============================================================================

class AppGradients {
  static LinearGradient backgroundTopToBottom(Color start, Color end) =>
      LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [start, end],
      );

  static LinearGradient glowBlue() => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppBaseColors.electricBlue, AppBaseColors.neonCyan],
      );

  static LinearGradient glowViolet() => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppBaseColors.neonViolet, AppBaseColors.electricBlue],
      );

  static LinearGradient thixGold(ColorScheme scheme) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [scheme.tertiary, scheme.secondary],
      );

  static LinearGradient thixNavyToGold(ColorScheme scheme) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [scheme.primary, scheme.tertiary],
      );

  static LinearGradient cinematicScrim() => LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          Colors.black.withOpacity(0.82),
          Colors.black.withOpacity(0.35),
          Colors.transparent
        ],
        stops: const [0, 0.55, 1],
      );
}

// Classes existantes (redirigent vers AppGradients ou utilisent les couleurs de base)
class EventsCyberGradients {
  static LinearGradient background() => AppGradients.backgroundTopToBottom(
        EventsCyberColors.bg0,
        EventsCyberColors.bg1,
      );
  static LinearGradient glowBlue() => AppGradients.glowBlue();
  static LinearGradient cinematicScrim() => AppGradients.cinematicScrim();
}

class LearningCyberGradients {
  static LinearGradient background() => AppGradients.backgroundTopToBottom(
        LearningCyberColors.bg0,
        LearningCyberColors.bg1,
      );
  static LinearGradient glowBlue() => AppGradients.glowBlue();
}

class AdminCyberGradients {
  static LinearGradient glowBlue() => AppGradients.glowBlue();
  static LinearGradient glowViolet() => AppGradients.glowViolet();
}

class AppPremiumGradients {
  static LinearGradient thixGold(ColorScheme scheme) =>
      AppGradients.thixGold(scheme);
  static LinearGradient thixNavyToGold(ColorScheme scheme) =>
      AppGradients.thixNavyToGold(scheme);
}

class EmergencyUrgentGradients {
  static LinearGradient background() => AppGradients.backgroundTopToBottom(
        EmergencyUrgentColors.bg0,
        EmergencyUrgentColors.bg1,
      );
  static LinearGradient panel() => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          EmergencyUrgentColors.panel,
          EmergencyUrgentColors.card,
        ],
      );
}

class EmergencyMedicalSheetGradients {
  static LinearGradient background() => AppGradients.backgroundTopToBottom(
        EmergencyMedicalSheetColors.bg0,
        EmergencyMedicalSheetColors.bg1,
      );
}

// =============================================================================
// 6. TYPOGRAPHIE (inchangée, ajout d’extensions pratiques)
// =============================================================================

class FontSizes {
  static const double headlineLarge = 20;
  static const double headlineMedium = 26.0;
  static const double titleLarge = 20.0;
  static const double titleMedium = 17.0;
  static const double bodyLarge = 16.0;
  static const double bodyMedium = 14.0;
  static const double bodySmall = 12.0;
  static const double labelLarge = 15.0;
  static const double labelMedium = 13.0;
  static const double labelSmall = 11.0;
}

extension TextStyleContext on BuildContext {
  TextTheme get textStyles => Theme.of(this).textTheme;
}

extension TextStyleExtensions on TextStyle {
  TextStyle get bold => copyWith(fontWeight: FontWeight.w700);
  TextStyle get semiBold => copyWith(fontWeight: FontWeight.w600);
  TextStyle get medium => copyWith(fontWeight: FontWeight.w500);
  TextStyle get normal => copyWith(fontWeight: FontWeight.w400);
  TextStyle get light => copyWith(fontWeight: FontWeight.w300);
  TextStyle withColor(Color color) => copyWith(color: color);
  TextStyle withSize(double size) => copyWith(fontSize: size);
}

// =============================================================================
// 7. THEME EXTENSION (NOUVEAU – pour les couleurs personnalisées)
// =============================================================================

@immutable
class AppCustomColors extends ThemeExtension<AppCustomColors> {
  final Color goldBadge;
  final Color emergencyRed;
  final Color medicalBlue;
  final Color medicalBlueDeep;
  final Color medicalBlueSoft;
  final Color cyberDarkBlue;
  final Color successGreen;
  final Color dangerRed;
  final Color cardBorder;
  final Color lightGrayBackground;
  final Color textSecondary;
  final Color primaryBlue;
  final Color darkNavy;

  const AppCustomColors({
    required this.goldBadge,
    required this.emergencyRed,
    required this.medicalBlue,
    required this.medicalBlueDeep,
    required this.medicalBlueSoft,
    required this.cyberDarkBlue,
    required this.successGreen,
    required this.dangerRed,
    required this.cardBorder,
    required this.lightGrayBackground,
    required this.textSecondary,
    required this.primaryBlue,
    required this.darkNavy,
  });

  @override
  AppCustomColors copyWith({
    Color? goldBadge,
    Color? emergencyRed,
    Color? medicalBlue,
    Color? medicalBlueDeep,
    Color? medicalBlueSoft,
    Color? cyberDarkBlue,
    Color? successGreen,
    Color? dangerRed,
    Color? cardBorder,
    Color? lightGrayBackground,
    Color? textSecondary,
    Color? primaryBlue,
    Color? darkNavy,
  }) {
    return AppCustomColors(
      goldBadge: goldBadge ?? this.goldBadge,
      emergencyRed: emergencyRed ?? this.emergencyRed,
      medicalBlue: medicalBlue ?? this.medicalBlue,
      medicalBlueDeep: medicalBlueDeep ?? this.medicalBlueDeep,
      medicalBlueSoft: medicalBlueSoft ?? this.medicalBlueSoft,
      cyberDarkBlue: cyberDarkBlue ?? this.cyberDarkBlue,
      successGreen: successGreen ?? this.successGreen,
      dangerRed: dangerRed ?? this.dangerRed,
      cardBorder: cardBorder ?? this.cardBorder,
      lightGrayBackground: lightGrayBackground ?? this.lightGrayBackground,
      textSecondary: textSecondary ?? this.textSecondary,
      primaryBlue: primaryBlue ?? this.primaryBlue,
      darkNavy: darkNavy ?? this.darkNavy,
    );
  }

  @override
  AppCustomColors lerp(ThemeExtension<AppCustomColors>? other, double t) {
    if (other is! AppCustomColors) return this;
    return AppCustomColors(
      goldBadge: Color.lerp(goldBadge, other.goldBadge, t)!,
      emergencyRed: Color.lerp(emergencyRed, other.emergencyRed, t)!,
      medicalBlue: Color.lerp(medicalBlue, other.medicalBlue, t)!,
      medicalBlueDeep: Color.lerp(medicalBlueDeep, other.medicalBlueDeep, t)!,
      medicalBlueSoft: Color.lerp(medicalBlueSoft, other.medicalBlueSoft, t)!,
      cyberDarkBlue: Color.lerp(cyberDarkBlue, other.cyberDarkBlue, t)!,
      successGreen: Color.lerp(successGreen, other.successGreen, t)!,
      dangerRed: Color.lerp(dangerRed, other.dangerRed, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      lightGrayBackground: Color.lerp(lightGrayBackground, other.lightGrayBackground, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      primaryBlue: Color.lerp(primaryBlue, other.primaryBlue, t)!,
      darkNavy: Color.lerp(darkNavy, other.darkNavy, t)!,
    );
  }
}

// Instances pour les thèmes clair/sombre
const _lightCustomColors = AppCustomColors(
  goldBadge: ThixHomeColors.goldBadge,
  emergencyRed: LightModeColors.emergencyRed,
  medicalBlue: LightModeColors.medicalBlue,
  medicalBlueDeep: LightModeColors.medicalBlueDeep,
  medicalBlueSoft: LightModeColors.medicalBlueSoft,
  cyberDarkBlue: LightModeColors.cyberDarkBlue,
  successGreen: ThixHomeColors.successGreen,
  dangerRed: ThixHomeColors.dangerRed,
  cardBorder: ThixHomeColors.cardBorder,
  lightGrayBackground: ThixHomeColors.lightGrayBackground,
  textSecondary: ThixHomeColors.textSecondary,
  primaryBlue: ThixHomeColors.primaryBlue,
  darkNavy: ThixHomeColors.darkNavy,
);

const _darkCustomColors = AppCustomColors(
  goldBadge: ThixHomeColors.goldBadge,
  emergencyRed: DarkModeColors.emergencyRed,
  medicalBlue: DarkModeColors.medicalBlue,
  medicalBlueDeep: DarkModeColors.medicalBlueDeep,
  medicalBlueSoft: DarkModeColors.medicalBlueSoft,
  cyberDarkBlue: DarkModeColors.cyberDarkBlue,
  successGreen: ThixHomeColors.successGreen,
  dangerRed: ThixHomeColors.dangerRed,
  cardBorder: ThixHomeColors.cardBorder,
  lightGrayBackground: ThixHomeColors.lightGrayBackground,
  textSecondary: ThixHomeColors.textSecondary,
  primaryBlue: ThixHomeColors.primaryBlue,
  darkNavy: ThixHomeColors.darkNavy,
);

// Extension pour récupérer facilement les couleurs personnalisées
extension BuildContextX on BuildContext {
  AppCustomColors get customColors => Theme.of(this).extension<AppCustomColors>()!;
}

// =============================================================================
// 8. THÈMES (inchangés, mais on ajoute les extensions)
// =============================================================================

ThemeData get lightTheme => ThemeData(
      useMaterial3: true,
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      colorScheme: const ColorScheme.light(
        primary: LightModeColors.primary,
        onPrimary: LightModeColors.onPrimary,
        secondary: LightModeColors.secondary,
        onSecondary: LightModeColors.onSecondary,
        tertiary: LightModeColors.accent,
        onTertiary: LightModeColors.onPrimary,
        error: LightModeColors.error,
        onError: LightModeColors.onError,
        surface: LightModeColors.surface,
        onSurface: LightModeColors.onSurface,
      ),
      brightness: Brightness.light,
      scaffoldBackgroundColor: LightModeColors.background,
      iconTheme:
          const IconThemeData(color: LightModeColors.secondaryText, size: 22),
      appBarTheme: const AppBarTheme(
        backgroundColor: LightModeColors.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: LightModeColors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: LightModeColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: LightModeColors.primary.withOpacity(0.12),
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.2,
            color: LightModeColors.secondaryText,
          ),
        ),
        iconTheme: const WidgetStatePropertyAll(IconThemeData(size: 22)),
      ),
      dividerTheme: const DividerThemeData(
        color: LightModeColors.divider,
        thickness: 1,
        space: 1,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),
      cardTheme: CardThemeData(
        color: LightModeColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(
            color: LightModeColors.divider,
            width: 1,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: LightModeColors.surface,
        hintStyle: GoogleFonts.inter(
            color: LightModeColors.hint, fontSize: 14, height: 1.2),
        labelStyle: GoogleFonts.inter(
            color: LightModeColors.secondaryText, fontSize: 14, height: 1.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          borderSide: const BorderSide(color: LightModeColors.divider, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          borderSide: const BorderSide(color: LightModeColors.divider, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          borderSide: const BorderSide(color: LightModeColors.primary, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: const WidgetStatePropertyAll(LightModeColors.primary),
          foregroundColor: const WidgetStatePropertyAll(LightModeColors.onPrimary),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
          ),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: const WidgetStatePropertyAll(LightModeColors.primary),
          side: const WidgetStatePropertyAll(
            BorderSide(color: LightModeColors.divider, width: 1),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
          ),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          ),
        ),
      ),
      textTheme: _buildTextTheme(LightModeColors.primaryText),
      extensions: const [_lightCustomColors], // <-- AJOUT
    );

ThemeData get darkTheme => ThemeData(
      useMaterial3: true,
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      colorScheme: const ColorScheme.dark(
        primary: DarkModeColors.primary,
        onPrimary: DarkModeColors.onPrimary,
        secondary: DarkModeColors.metalGoldDeep,
        onSecondary: DarkModeColors.onSecondary,
        tertiary: DarkModeColors.metalGold,
        onTertiary: DarkModeColors.onSecondary,
        error: DarkModeColors.error,
        onError: DarkModeColors.onError,
        surface: DarkModeColors.surface,
        onSurface: DarkModeColors.onSurface,
      ),
      brightness: Brightness.dark,
      scaffoldBackgroundColor: DarkModeColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: DarkModeColors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: DarkModeColors.divider,
        thickness: 1,
        space: 1,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),
      cardTheme: CardThemeData(
        color: DarkModeColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(
            color: DarkModeColors.divider,
            width: 1,
          ),
        ),
      ),
      textTheme: _buildTextTheme(DarkModeColors.primaryText),
      extensions: const [_darkCustomColors], // <-- AJOUT
    );

// =============================================================================
// 9. FONCTION DE CONSTRUCTION DES TEXTSTYLES (inchangée)
// =============================================================================

TextTheme _buildTextTheme(Color textColor) {
  return TextTheme(
    headlineLarge: GoogleFonts.plusJakartaSans(
      fontSize: FontSizes.headlineLarge,
      fontWeight: FontWeight.w800,
      height: 1.2,
      color: textColor,
    ),
    headlineMedium: GoogleFonts.plusJakartaSans(
      fontSize: FontSizes.headlineMedium,
      fontWeight: FontWeight.w700,
      height: 1.25,
      color: textColor,
    ),
    titleLarge: GoogleFonts.plusJakartaSans(
      fontSize: FontSizes.titleLarge,
      fontWeight: FontWeight.w700,
      height: 1.3,
      color: textColor,
    ),
    titleMedium: GoogleFonts.plusJakartaSans(
      fontSize: FontSizes.titleMedium,
      fontWeight: FontWeight.w600,
      height: 1.4,
      color: textColor,
    ),
    labelLarge: GoogleFonts.plusJakartaSans(
      fontSize: FontSizes.labelLarge,
      fontWeight: FontWeight.w600,
      height: 1.2,
      color: textColor,
    ),
    labelMedium: GoogleFonts.plusJakartaSans(
      fontSize: FontSizes.labelMedium,
      fontWeight: FontWeight.w600,
      height: 1.2,
      color: textColor,
    ),
    labelSmall: GoogleFonts.plusJakartaSans(
      fontSize: FontSizes.labelSmall,
      fontWeight: FontWeight.w700,
      height: 1.1,
      color: textColor,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: FontSizes.bodyLarge,
      fontWeight: FontWeight.w400,
      height: 1.55,
      color: textColor,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: FontSizes.bodyMedium,
      fontWeight: FontWeight.w400,
      height: 1.45,
      color: textColor,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: FontSizes.bodySmall,
      fontWeight: FontWeight.w400,
      height: 1.35,
      color: textColor,
    ),
  );
}
