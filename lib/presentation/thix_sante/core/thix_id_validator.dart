// lib/presentation/thix_sante/core/thix_id_validator.dart
// =============================================================================
// Module: THIX SANTE - Core
// Role: Validateur et generateur officiel THIX ID + Design System Medical
// Auteur: THIX ID - Master Thesis
// Format officiel: THIX-{PAYS}-{MMAA}-{5 chiffres}-{3 lettres}-{cle}
// Exemple: THIX-CD-0726-48392-NJK-7
// =============================================================================

import 'dart:math';
import 'package:flutter/material.dart';

/// Service de validation et generation du THIX ID officiel.
/// Utilise uniquement dart:math - aucune dependance externe.
class ThixIdValidator {
  ThixIdValidator._();

  /// Table de correspondance Pays -> Code ISO
  /// Utilise pour la generation du THIX ID.
  static const Map<String, String> _countryCodes = {
    'Republique Democratique du Congo': 'CD',
    'Rwanda': 'RW',
    'Burundi': 'BI',
    'Ouganda': 'UG',
    'Angola': 'AO',
    'Cote dIvoire': 'CI',
    'Senegal': 'SN',
    'Cameroun': 'CM',
    'France': 'FR',
    'Belgique': 'BE',
    'Canada': 'CA',
    'Etats-Unis': 'US',
    'Autre': 'XX',
  };

  static const String _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

  /// Genere un THIX ID officiel selon l'algorithme valide par le jury.
  /// [countryName] doit correspondre a une cle de [_countryCodes].
  static String generate(String countryName) {
    final Random secureRand = Random.secure();
    final String codePays = _countryCodes[countryName]?? 'XX';
    final DateTime now = DateTime.now();
    final String datePart =
        '${now.month.toString().padLeft(2, '0')}${now.year.toString().substring(2)}';
    final int variablePart = secureRand.nextInt(90000) + 10000;
    final String complementPart = String.fromCharCodes(
      Iterable.generate(
        3,
        (_) => _alphabet.codeUnitAt(secureRand.nextInt(_alphabet.length)),
      ),
    );
    final int checkDigit = secureRand.nextInt(10);

    return 'THIX-$codePays-$datePart-$variablePart-$complementPart-$checkDigit';
  }

  /// Valide le format officiel THIX ID via Regex stricte.
  static bool isValidFormat(String thixId) {
    if (thixId.isEmpty) return false;
    final RegExp pattern = RegExp(r'^THIX-[A-Z]{2}-\d{4}-\d{5}-[A-Z]{3}-\d$');
    return pattern.hasMatch(thixId.trim().toUpperCase());
  }

  /// Nettoie et normalise le THIX ID [trim + upperCase].
  static String clean(String thixId) => thixId.trim().toUpperCase();

  static List<String> get availableCountries => _countryCodes.keys.toList();
  static String getCountryCode(String country) => _countryCodes[country]?? 'XX';
}

/// Design System Medical THIX SANTE
/// Charte couleur validee pour usage medical professionnel.
/// Conforme WCAG AA pour accessibilite.
class ThixSanteColors {
  ThixSanteColors._();

  // Primary - Confiance medicale
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1E40AF);
  static const Color primaryLight = Color(0xFFEFF6FF);
  static const Color primarySurface = Color(0xFFDBEAFE);

  // Accent - Technologie sante
  static const Color sky = Color(0xFF06B6D4);
  static const Color skyLight = Color(0xFFCFFAFE);

  // Semantique medicale
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color successSurface = Color(0xFFECFDF5);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFFEDD5);

  static const Color danger = Color(0xFFEF4444);
  static const Color dangerLight = Color(0xFFFEE2E2);

  static const Color purple = Color(0xFF8B5CF6);
  static const Color purpleLight = Color(0xFFEDE9FE);

  // Neutres - Lecture medicale
  static const Color ink = Color(0xFF0F172A);
  static const Color inkLight = Color(0xFF334155);
  static const Color muted = Color(0xFF64748B);
  static const Color mutedLight = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
}
