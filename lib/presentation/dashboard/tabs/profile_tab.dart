import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/models/app_user.dart';
import 'package:thix_id/models/thix_profile.dart';
import 'package:thix_id/services/profile_service.dart';
import 'package:thix_id/services/user_service.dart';
import '../../nav.dart';
import '../../theme.dart';

// N'oublie pas d'importer tes widgets fraîchement séparés :
import '../widgets/dashboard_card.dart';
import '../widgets/dashboard_shared_widgets.dart'; // Si tu as mis DashboardInfoRow ici
// import '../editors/profile_editor_sheet.dart'; // À décommenter plus tard

class ProfileTab extends StatelessWidget {
  final AppUser authUser;
  final ThixProfile profile;
  final int score;
  final ProfileService profileService;
  final UserService userService;

  const ProfileTab({
    super.key,
    required this.authUser,
    required this.profile,
    required this.score,
    required this.profileService,
    required this.userService,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 960;
    final isActivated = authUser.thixId.trim().toUpperCase() != 'THIX-PENDING';
    final hasActiveTrial = authUser.hasActiveTrial;

    final left = <Widget>[
      if (!isActivated && !hasActiveTrial)
        // ActivationCalloutCard(onActivate: () { ... }) // À importer
        const SizedBox(), 
      
      DashboardCard(
        icon: Icons.badge_rounded,
        title: 'Profil Professionnel',
        subtitle: 'Données sécurisées liées à votre THIX ID',
        child: Column(
          children: [
            // Utilise tes DashboardInfoRow ici
            Text('Contenu du profil (Bio, Contact, etc.)'), 
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    await context.read<AuthController>().signOut();
                    if (context.mounted) context.go(AppRoutes.home);
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Déconnexion'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // ProfileEditorSheet.show(context, profile: profile, profileService: profileService, authUser: authUser);
                  },
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('Modifier Profil'),
                ),
              ],
            ),
          ],
        ),
      ),
      // ... Reste des DashboardCards de la colonne gauche
    ];

    final right = <Widget>[
      DashboardCard(
        icon: Icons.school_rounded,
        title: 'Cursus scolaire',
        subtitle: '${profile.education.length} entrée(s)',
        child: const Text('Liste des formations...'),
      ),
      // ... Reste des DashboardCards de la colonne droite
    ];

    // Le TabScaffold devra aussi être extrait dans tes widgets partagés
    if (!isWide) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [...left, const SizedBox(height: 16), ...right]),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Column(children: left)),
          const SizedBox(width: 24),
          Expanded(child: Column(children: right)),
        ],
      ),
    );
  }
}
