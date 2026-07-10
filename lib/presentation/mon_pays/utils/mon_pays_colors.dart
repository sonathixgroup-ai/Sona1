// lib/presentation/mon_pays/utils/mon_pays_colors.dart

import 'package:flutter/material.dart';

/// Palette de couleurs institutionnelles pour le module Mon Pays
/// Inspirée des couleurs de la République Démocratique du Congo
class MonPaysColors {
  // Couleurs principales
  static const Color primaryRed = Color(0xFFE53935); // Rouge RDC
  static const Color primaryBlue = Color(0xFF0033A0); // Bleu RDC
  static const Color primaryYellow = Color(0xFFFFD700); // Or RDC

  // Neutres
  static const Color primaryWhite = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFFFFF5F5); // Fond clair avec touche rouge
  static const Color backgroundDark = Color(0xFF1A1A2E);

  // Textes
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color darkText = Color(0xFF1A1A1A);
  // États
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFFF9800);
  static const Color dangerRed = Color(0xFFD32F2F);

  // Bordures et ombres
  static const Color cardBorder = Color(0xFFE5E7EB);
  static const Color shadowLight = Color(0x0F000000);
  static const Color shadowSecondary = Color(0x0A000000);

  // Dégradés institutionnels
  static const LinearGradient gradientRedBlue = LinearGradient(
    colors: [primaryRed, primaryBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientBlueRed = LinearGradient(
    colors: [primaryBlue, primaryRed],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientYellowRed = LinearGradient(
    colors: [primaryYellow, primaryRed],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientRedYellow = LinearGradient(
    colors: [primaryRed, primaryYellow],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Ombres prédéfinies
  static List<BoxShadow> get defaultShadow => [
        BoxShadow(
          color: primaryRed.withOpacity(0.15),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get lightShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get heavyShadow => [
        BoxShadow(
          color: primaryRed.withOpacity(0.25),
          blurRadius: 15,
          offset: const Offset(0, 6),
        ),
      ];
}
