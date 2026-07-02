// lib/presentation/chat/themes/text_styles.dart
// Styles de texte réutilisables (petite police, objectif)

import 'package:flutter/material.dart';

class TextStyles {
  static const String _fontFamily = 'Roboto'; // ou 'SF Pro Text'

  // Titres
  static const TextStyle headline = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    fontFamily: _fontFamily,
  );

  // Corps de message
  static const TextStyle messageBody = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    fontFamily: _fontFamily,
  );

  // Nom dans conversation
  static const TextStyle conversationName = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    fontFamily: _fontFamily,
  );

  // Sous-texte (date, statut, informations)
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    fontFamily: _fontFamily,
  );

  // Texte très petit (badges, indicateurs)
  static const TextStyle tiny = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.normal,
    fontFamily: _fontFamily,
  );

  // Champ de saisie
  static const TextStyle input = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    fontFamily: _fontFamily,
  );

  // Boutons
  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    fontFamily: _fontFamily,
  );
}
