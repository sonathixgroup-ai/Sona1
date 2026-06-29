// lib/presentation/thix_sante/thix_sante_page.dart
import 'package:flutter/material.dart';

// ============================================================
// Énumération des rôles
// ============================================================
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

  String get headline {
    switch (this) {
      case ThixRole.patient:
        return 'Votre santé entre de bonnes mains';
      case ThixRole.doctor:
        return 'Pilotez vos consultations et vos alertes';
      case ThixRole.pharmacy:
        return 'Sécurisez chaque ordonnance et chaque dispensation';
    }
  }

  String get subtitle {
    switch (this) {
      case ThixRole.patient:
        return 'Consultez, suivez et prenez soin de votre santé au quotidien.';
      case ThixRole.doctor:
        return 'Suivez vos patients, prescriptions et téléconsultations depuis une seule interface.';
      case ThixRole.pharmacy:
        return 'Gérez les ordonnances, le stock et les livraisons dans le même flux métier.';
    }
  }

  String get ctaLabel {
    switch (this) {
      case ThixRole.patient:
        return 'Dossier de santé';
      case ThixRole.doctor:
        return 'Agenda du jour';
      case ThixRole.pharmacy:
        return 'Valider les ordonnances';
    }
  }

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
}

// ============================================================
// Page d'accueil du module Santé (hub)
// ============================================================
class ThixSantePage extends StatelessWidget {
  const ThixSantePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('THIX Santé'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.health_and_safety, size: 80, color: Colors.teal),
            const SizedBox(height: 20),
            const Text(
              'Bienvenue sur THIX Santé',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Choisissez votre espace ci-dessous',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            Wrap(
              spacing: 20,
              runSpacing: 20,
              alignment: WrapAlignment.center,
              children: ThixRole.values.map((role) {
                return _RoleCard(role: role);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final ThixRole role;
  const _RoleCard({required this.role});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigation vers la page spécifique du rôle
        String route;
        switch (role) {
          case ThixRole.patient:
            route = AppRoutes.thixSantePatient;
            break;
          case ThixRole.doctor:
            route = AppRoutes.thixSanteDoctor;
            break;
          case ThixRole.pharmacy:
            route = AppRoutes.thixSantePharmacy;
            break;
        }
        // Utilisation de GoRouter si disponible, sinon on peut faire un push
        // Ici on suppose que le contexte a un Navigator standard
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ThixSanteRolePage(role: role),
          ),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 140,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(role.icon, size: 50, color: role.accent),
              const SizedBox(height: 8),
              Text(
                role.label,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                role.shortLabel,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Page spécifique pour un rôle
// ============================================================
class ThixSanteRolePage extends StatelessWidget {
  final ThixRole role;
  const ThixSanteRolePage({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(role.label),
        backgroundColor: role.accent,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: role.gradient,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(role.icon, size: 80, color: Colors.white),
                const SizedBox(height: 20),
                Text(
                  role.headline,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  role.subtitle,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    // Action selon le rôle
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${role.ctaLabel} – Fonctionnalité à implémenter'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: role.accent,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(role.ctaLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Référence aux routes pour utilisation dans _RoleCard
// (Optionnel : si vous voulez utiliser GoRouter, vous pouvez
// importer vos routes depuis un fichier partagé)
// ============================================================
// Pour éviter une dépendance circulaire, on définit ici une classe
// factice si elle n'est pas déjà définie ailleurs.
// Dans votre projet, vous avez déjà AppRoutes, donc adaptez.
class AppRoutes {
  static const String thixSantePatient = '/sante/patient';
  static const String thixSanteDoctor = '/sante/medecin';
  static const String thixSantePharmacy = '/sante/pharmacie';
}
