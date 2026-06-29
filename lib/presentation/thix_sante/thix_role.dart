// presentation/thix_sante/thix_role.dart
import 'package:flutter/material.dart';

/// Énumération des rôles disponibles dans THIX Santé
enum ThixRole {
  patient,
  doctor,
  pharmacy,
}

/// Extensions pour faciliter l'utilisation des rôles
extension ThixRoleX on ThixRole {
  /// Libellé affiché (ex: "Patient")
  String get label {
    switch (this) {
      case ThixRole.patient:
        return 'Patient';
      case ThixRole.doctor:
        return 'Médecin';
      case ThixRole.pharmacy:
        return 'Pharmacie';
    }
  }

  /// Libellé court (ex: "Santé")
  String get shortLabel {
    switch (this) {
      case ThixRole.patient:
        return 'Santé';
      case ThixRole.doctor:
        return 'Cabinet';
      case ThixRole.pharmacy:
        return 'Officine';
    }
  }

  /// Icône associée
  IconData get icon {
    switch (this) {
      case ThixRole.patient:
        return Icons.favorite_rounded;
      case ThixRole.doctor:
        return Icons.medical_services_rounded;
      case ThixRole.pharmacy:
        return Icons.local_pharmacy_rounded;
    }
  }

  /// Couleur d'accent
  Color get accent {
    switch (this) {
      case ThixRole.patient:
        return const Color(0xFF00C3A5);
      case ThixRole.doctor:
        return const Color(0xFF3F51FF);
      case ThixRole.pharmacy:
        return const Color(0xFFFF7A00);
    }
  }

  /// Dégradé de fond
  LinearGradient get gradient {
    switch (this) {
      case ThixRole.patient:
        return const LinearGradient(
          colors: [Color(0xFF1E56E6), Color(0xFF14C7B7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case ThixRole.doctor:
        return const LinearGradient(
          colors: [Color(0xFF102A86), Color(0xFF5C7CFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case ThixRole.pharmacy:
        return const LinearGradient(
          colors: [Color(0xFFFF7A00), Color(0xFFFFB347)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  /// Convertir depuis une chaîne (utile pour les métadonnées)
  static ThixRole? fromString(String value) {
    final trimmed = value.trim().toLowerCase();
    switch (trimmed) {
      case 'patient':
        return ThixRole.patient;
      case 'doctor':
      case 'medecin':
      case 'médecin':
        return ThixRole.doctor;
      case 'pharmacy':
      case 'pharmacie':
        return ThixRole.pharmacy;
      default:
        return null;
    }
  }
}

/// Contrôleur pour gérer l'état du rôle sélectionné et sa persistance
/// Utilisé comme singleton, accessible via ThixRoleController.instance
class ThixRoleController extends ChangeNotifier {
  ThixRoleController._();

  static final ThixRoleController instance = ThixRoleController._();

  /// Correspondance entre les valeurs stockées dans les métadonnées et les rôles
  static const _allowedClaims = {
    'patient': ThixRole.patient,
    'doctor': ThixRole.doctor,
    'pharmacy': ThixRole.pharmacy,
  };

  // État interne
  ThixRole _role = ThixRole.patient;
  ThixRole? _verifiedRole;
  bool _manualSelection = false;

  // Getters
  ThixRole get role => _role;
  ThixRole? get verifiedRole => _verifiedRole;
  bool get hasManualSelection => _manualSelection;

  // Liste des rôles disponibles (ordre d'affichage)
  static const List<ThixRole> availableRoles = [
    ThixRole.patient,
    ThixRole.doctor,
    ThixRole.pharmacy,
  ];

  /// Synchronise le rôle depuis les métadonnées de l'utilisateur (appMetadata ou userMetadata)
  /// Appeler cette méthode après une connexion réussie.
  void syncFromSession({
    Map<String, dynamic>? appMetadata,
    Map<String, dynamic>? userMetadata,
  }) {
    final resolved = _parseRoleFromMetadata(appMetadata) ??
        _parseRoleFromMetadata(userMetadata);

    // Si le rôle résolu est identique à celui déjà vérifié et que
    // l'utilisateur n'a pas forcé une sélection manuelle, on ne notifie pas.
    if (resolved == _verifiedRole &&
        (_manualSelection || resolved == _role || resolved == null)) {
      return;
    }

    _verifiedRole = resolved;
    if (!_manualSelection && resolved != null) {
      _role = resolved;
    }
    notifyListeners();
  }

  /// Sélectionne un rôle manuellement (par exemple depuis l'écran de choix)
  void selectRole(ThixRole nextRole, {bool manual = true}) {
    if (_role == nextRole && _manualSelection == manual) return;
    _role = nextRole;
    _manualSelection = manual;
    notifyListeners();
  }

  /// Réinitialise au rôle vérifié (utile si l'utilisateur a fait une sélection manuelle)
  void resetToVerifiedRole() {
    if (_verifiedRole == null) return;
    _manualSelection = false;
    _role = _verifiedRole!;
    notifyListeners();
  }

  /// Parse les métadonnées pour extraire le rôle
  ThixRole? _parseRoleFromMetadata(Map<String, dynamic>? metadata) {
    if (metadata == null) return null;
    final raw = (metadata['thix_role'] ?? metadata['role'])?.toString().trim().toLowerCase();
    if (raw == null || raw.isEmpty) return null;
    return _allowedClaims[raw];
  }
}
