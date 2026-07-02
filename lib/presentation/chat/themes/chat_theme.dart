// lib/presentation/chat/themes/custom_colors.dart
// Palette de couleurs personnalisées pour les thèmes clair et sombre

import 'package:flutter/material.dart';

class CustomColors {
  // Couleurs communes
  static const Color primary = Color(0xFF1877F2);   // Bleu Facebook
  static const Color success = Color(0xFF42B72A);
  static const Color warning = Color(0xFFF7B928);
  static const Color error = Color(0xFFE41E3F);

  // Thème clair
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF0F2F5);
  static const Color lightTextPrimary = Color(0xFF050505);
  static const Color lightTextSecondary = Color(0xFF65676B);
  static const Color lightDivider = Color(0xFFE4E6EB);

  // Thème sombre
  static const Color darkBackground = Color(0xFF18191A);
  static const Color darkSurface = Color(0xFF242526);
  static const Color darkTextPrimary = Color(0xFFE4E6EB);
  static const Color darkTextSecondary = Color(0xFFB0B3B8);
  static const Color darkDivider = Color(0xFF3E4042);

  // Bulles de message
  static const Color lightBubbleMe = Color(0xFFE7F3FF);
  static const Color lightBubbleOther = Color(0xFFF0F2F5);
  static const Color darkBubbleMe = Color(0xFF0084FF);
  static const Color darkBubbleOther = Color(0xFF3E4042);
}
