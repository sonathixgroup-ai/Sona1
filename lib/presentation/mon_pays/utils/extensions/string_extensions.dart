// lib/presentation/mon_pays/utils/extensions/string_extensions.dart

import 'package:intl/intl.dart';

extension StringExtensions on String {
  /// Met la première lettre en majuscule
  String get capitalize {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }

  /// Met en majuscule chaque mot
  String get titleCase {
    if (isEmpty) return this;
    return split(' ').map((e) => e.capitalize).join(' ');
  }

  /// Truncate avec points de suspension
  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return substring(0, maxLength) + ellipsis;
  }

  /// Vérifie si la chaîne est un email valide
  bool get isValidEmail {
    final RegExp regex = RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    );
    return regex.hasMatch(this);
  }

  /// Vérifie si la chaîne est un numéro de téléphone valide
  bool get isValidPhone {
    final RegExp regex = RegExp(r'^\+?[0-9]{10,15}$');
    return regex.hasMatch(this);
  }

  /// Vérifie si la chaîne est une date au format YYYY-MM-DD
  bool get isValidDate {
    final RegExp regex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!regex.hasMatch(this)) return false;
    try {
      DateFormat('yyyy-MM-dd').parse(this);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Formate une date en français
  String toFrenchDate() {
    try {
      final date = DateFormat('yyyy-MM-dd').parse(this);
      return DateFormat('d MMMM yyyy', 'fr').format(date);
    } catch (_) {
      return this;
    }
  }

  /// Vérifie si la chaîne est une URL valide
  bool get isValidUrl {
    final RegExp regex = RegExp(
      r'^(http|https)://[a-zA-Z0-9\-\.]+\.[a-zA-Z]{2,}(/\S*)?$',
    );
    return regex.hasMatch(this);
  }
}
