// lib/presentation/mon_pays/utils/validators.dart

/// Validateurs de formulaires pour le module Mon Pays
class MonPaysValidators {
  /// Valide un champ requis
  static String? required(String? value, {String fieldName = 'Ce champ'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName est requis';
    }
    return null;
  }

  /// Valide une adresse email
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'L\'email est requis';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Email invalide';
    }
    return null;
  }

  /// Valide un numéro de téléphone
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le numéro de téléphone est requis';
    }
    final phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Numéro invalide (10-15 chiffres)';
    }
    return null;
  }

  /// Valide une URL
  static String? url(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // L'URL est optionnelle
    }
    final urlRegex = RegExp(
      r'^(http|https)://[a-zA-Z0-9\-\.]+\.[a-zA-Z]{2,}(/\S*)?$',
    );
    if (!urlRegex.hasMatch(value.trim())) {
      return 'URL invalide';
    }
    return null;
  }

  /// Valide une date au format YYYY-MM-DD
  static String? date(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La date est requise';
    }
    final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!dateRegex.hasMatch(value.trim())) {
      return 'Format invalide (AAAA-MM-JJ)';
    }
    return null;
  }

  /// Valide un nombre entier
  static String? integer(String? value, {int? min, int? max}) {
    if (value == null || value.trim().isEmpty) {
      return 'Ce champ est requis';
    }
    final intValue = int.tryParse(value.trim());
    if (intValue == null) {
      return 'Doit être un nombre entier';
    }
    if (min != null && intValue < min) {
      return 'Doit être supérieur ou égal à $min';
    }
    if (max != null && intValue > max) {
      return 'Doit être inférieur ou égal à $max';
    }
    return null;
  }

  /// Valide une longueur de chaîne
  static String? length(String? value, {int min = 0, int max = 255}) {
    if (value == null) return 'Ce champ est requis';
    final len = value.trim().length;
    if (len < min) {
      return 'Minimum $min caractères';
    }
    if (len > max) {
      return 'Maximum $max caractères';
    }
    return null;
  }

  /// Valide une confirmation de mot de passe (exemple)
  static String? passwordMatch(String? value, String? confirmValue) {
    if (value == null || confirmValue == null || value != confirmValue) {
      return 'Les mots de passe ne correspondent pas';
    }
    return null;
  }
}
