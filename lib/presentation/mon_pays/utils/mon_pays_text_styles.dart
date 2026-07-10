// lib/presentation/mon_pays/utils/mon_pays_text_styles.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mon_pays_colors.dart';

/// Styles de texte pour le module Mon Pays
class MonPaysTextStyles {
  static TextStyle get heading1 => GoogleFonts.roboto(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: MonPaysColors.textPrimary,
      );

  static TextStyle get heading2 => GoogleFonts.roboto(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: MonPaysColors.textPrimary,
      );

  static TextStyle get heading3 => GoogleFonts.roboto(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: MonPaysColors.textPrimary,
      );

  static TextStyle get heading4 => GoogleFonts.roboto(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: MonPaysColors.textPrimary,
      );

  static TextStyle get heading5 => GoogleFonts.roboto(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: MonPaysColors.textPrimary,
      );

  static TextStyle get heading6 => GoogleFonts.roboto(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: MonPaysColors.textPrimary,
      );

  static TextStyle get bodyLarge => GoogleFonts.roboto(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: MonPaysColors.textPrimary,
      );

  static TextStyle get bodyMedium => GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: MonPaysColors.textPrimary,
      );

  static TextStyle get bodySmall => GoogleFonts.roboto(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: MonPaysColors.textPrimary,
      );

  static TextStyle get caption => GoogleFonts.roboto(
        fontSize: 11,
        fontWeight: FontWeight.normal,
        color: MonPaysColors.textSecondary,
      );
}
