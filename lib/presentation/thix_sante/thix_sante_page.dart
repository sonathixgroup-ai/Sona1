// presentation/thix_sante/thix_sante_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/presentation/thix_sante/thix_role.dart';
import 'package:thix_id/presentation/thix_sante/health_router.dart';
import 'package:thix_id/presentation/thix_sante/health_constants.dart';

/// Page principale du module THIX Santé
/// Affiche la sélection de rôle ou redirige vers le dashboard correspondant
class ThixSantePage extends StatefulWidget {
  const ThixSantePage({super.key});

  @override
  State<ThixSantePage> createState() => _ThixSantePageState();
}

class _ThixSantePageState extends State<ThixSantePage> {
  @override
  void initState() {
    super.initState();
    _syncRoleFromUser();
  }

  /// Synchronise le rôle depuis les métadonnées de l'utilisateur
  void _syncRoleFromUser() {
    // AppUser (modèle app) n'expose pas directement appMetadata/userMetadata.
    // Pour THIX Santé, on s'appuie sur le user Supabase pour lire les métadonnées.
    final sbUser = Supabase.instance.client.auth.currentUser;
    if (sbUser == null) return;
    ThixRoleController.instance.syncFromSession(
      appMetadata: sbUser.appMetadata,
      userMetadata: sbUser.userMetadata,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Vérifier si un rôle est déjà sélectionné (via le contrôleur)
    final roleController = ThixRoleController.instance;
    final hasValidRole = roleController.verifiedRole != null;

    // Si un rôle existe, on utilise HealthRouter pour afficher le bon dashboard
    // Sinon, on affiche la page de sélection
    return HealthRouter(
      fallback: _buildRoleSelectionPage(),
    );
  }

  /// Page de sélection des rôles (affiche les trois cartes)
  Widget _buildRoleSelectionPage() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(HealthConstants.appTitle),
        backgroundColor: HealthConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // Afficher une info sur le module
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('À propos'),
                  content: const Text(
                    'THIX Santé est un module intégré à THIX ID.\n'
                    'Choisissez votre rôle pour accéder à vos services santé personnalisés.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.health_and_safety,
                size: 80,
                color: HealthConstants.primaryColor,
              ),
              const SizedBox(height: 20),
              Text(
                HealthConstants.welcomeMessage,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Choisissez votre espace pour continuer',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: ThixRoleController.availableRoles.map((role) {
                  return _buildRoleCard(role);
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Carte de sélection pour un rôle donné
  Widget _buildRoleCard(ThixRole role) {
    return GestureDetector(
      onTap: () {
        // 1. Sélectionner le rôle dans le contrôleur (sélection manuelle)
        ThixRoleController.instance.selectRole(role, manual: true);

        // 2. Mettre à jour les métadonnées utilisateur (persistance)
        _updateUserRoleInMetadata(role);

        // 3. Rediriger vers la route santé (qui va utiliser HealthRouter)
        // On utilise go pour remplacer l'historique
        context.go('/sante');
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
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
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                role.shortLabel,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Met à jour les métadonnées de l'utilisateur avec le rôle choisi
  /// (Appel à Supabase ou à l'API)
  Future<void> _updateUserRoleInMetadata(ThixRole role) async {
    try {
      final auth = AuthController.instance;
      final user = auth.currentUser;
      if (user == null) return;

      // Mettre à jour les métadonnées sur le serveur (exemple avec Supabase)
      // On suppose que AuthController expose une méthode updateUserMetadata
      // ou bien on utilise directement le client Supabase.
      // Ici, on simule un appel, à adapter.
      // Dans la vraie vie, on appellerait :
      // await auth.updateUserMetadata({'thix_role': role.toString().split('.').last});
      // Pour l'exemple, on affiche un snackbar de confirmation.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rôle "${role.label}" sélectionné avec succès !'),
            backgroundColor: role.accent,
            duration: HealthConstants.snackBarDuration,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(HealthConstants.errorGeneric),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
