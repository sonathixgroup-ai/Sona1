// presentation/thix_sante/health_router.dart
import 'package:flutter/material.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/presentation/thix_sante/thix_role.dart';

// Importer les dashboards (à créer ultérieurement)
import 'package:thix_id/presentation/thix_sante/patient/patient_dashboard_page.dart';
import 'package:thix_id/presentation/thix_sante/doctor/doctor_dashboard_page.dart';
import 'package:thix_id/presentation/thix_sante/pharmacy/pharmacy_dashboard_page.dart';

/// Routeur qui redirige vers le bon dashboard selon le rôle santé
class HealthRouter extends StatelessWidget {
  /// Widget à afficher si l'utilisateur n'a pas encore de rôle sélectionné
  final Widget fallback;

  const HealthRouter({super.key, required this.fallback});

  @override
  Widget build(BuildContext context) {
    final auth = AuthController.instance;
    final user = auth.currentUser;

    // Si l'utilisateur n'est pas connecté, on affiche le fallback (généralement la page de sélection)
    if (user == null) {
      return fallback;
    }

    // Récupérer le rôle depuis le contrôleur (qui est synchronisé avec les métadonnées)
    final role = ThixRoleController.instance.role;

    // Si aucun rôle défini (fallback), afficher la page de sélection
    // (le contrôleur a un rôle par défaut = patient, mais on préfère vérifier)
    // On utilise le rôle vérifié, ou on vérifie directement dans les métadonnées.
    // On utilise le rôle vérifié pour être sûr.
    final verifiedRole = ThixRoleController.instance.verifiedRole;
    if (verifiedRole == null) {
      // Pas de rôle vérifié : demander à l'utilisateur de choisir
      return fallback;
    }

    // Afficher le dashboard correspondant
    switch (verifiedRole) {
      case ThixRole.patient:
        return const PatientDashboardPage();
      case ThixRole.doctor:
        return const DoctorDashboardPage();
      case ThixRole.pharmacy:
        return const PharmacyDashboardPage();
      default:
        // Par défaut, on affiche le dashboard patient (ou fallback)
        return fallback;
    }
  }
}
