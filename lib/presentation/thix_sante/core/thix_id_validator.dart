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
import 'thix_sante_colors.dart';
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

