import 'package:flutter/material.dart';

enum ThixRole {
  patient,
  doctor,
  pharmacy,
}

extension ThixRoleExtension on ThixRole {
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

  IconData get icon {
    switch (this) {
      case ThixRole.patient:
        return Icons.person;
      case ThixRole.doctor:
        return Icons.medical_services;
      case ThixRole.pharmacy:
        return Icons.local_pharmacy;
    }
  }

  Color get accent {
    switch (this) {
      case ThixRole.patient:
        return Colors.blue;
      case ThixRole.doctor:
        return Colors.green;
      case ThixRole.pharmacy:
        return Colors.purple;
    }
  }
}

class ThixRoleController {
  // Singleton
  static final ThixRoleController _instance = ThixRoleController._internal();
  factory ThixRoleController() => _instance;
  ThixRoleController._internal();

  ThixRole _currentRole = ThixRole.patient;

  // ---- GETTERS ----
  ThixRole get currentRole => _currentRole;

  // Liste des rôles disponibles
  static List<ThixRole> get availableRoles => ThixRole.values;

  // ---- MÉTHODES ----
  void selectRole(ThixRole role, {bool manual = false}) {
    _currentRole = role;
    // Ajoutez ici toute logique supplémentaire (persistance, etc.)
    // Si vous utilisez SharedPreferences ou Supabase, faites-le ici.
    if (manual) {
      // Exemple: sauvegarder le rôle choisi par l'utilisateur
      // await SharedPreferences.getInstance().setString('thix_role', role.name);
    }
  }
}
