// presentation/thix_sante/health_constants.dart
import 'package:flutter/material.dart';

class HealthConstants {
  // Couleurs globales du module
  static const Color primaryColor = Color(0xFF00C3A5);
  static const Color secondaryColor = Color(0xFF1E56E6);

  // Couleurs par rôle (surcharge possible)
  static const Map<dynamic, Color> roleColors = {
    // Les couleurs sont définies dans l'extension de ThixRole, ici on garde des valeurs de fallback
  };

  // Durées par défaut
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration snackBarDuration = Duration(seconds: 3);

  // Messages d'erreur
  static const String errorGeneric = 'Une erreur est survenue. Veuillez réessayer.';
  static const String errorNoRole = 'Aucun rôle santé défini pour cet utilisateur.';
  static const String errorNetwork = 'Problème de connexion réseau.';

  // Textes génériques
  static const String appTitle = 'THIX Santé';
  static const String welcomeMessage = 'Votre santé, notre priorité.';

  // Clés de stockage (SharedPreferences, etc.)
  static const String prefKeySelectedRole = 'selected_health_role';
  static const String prefKeyManualSelection = 'manual_selection';

  // Routes (on utilise AppRoutes existantes, mais on peut les redéfinir ici pour cohérence)
  // Les routes sont définies dans AppRoutes (nav.dart), mais on peut les importer.
  // On laisse les constantes dans AppRoutes pour éviter les duplications.

  // Seuils pour les alertes (exemple)
  static const double criticalTemperature = 39.0;
  static const double criticalBmiLow = 18.5;
  static const double criticalBmiHigh = 30.0;

  // Pagination
  static const int defaultPageSize = 20;

  // Localisation
  static const String defaultLocale = 'fr';
}
