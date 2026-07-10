// lib/presentation/mon_pays/pages/authorities/authority_profile_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_routes.dart';
import '../../providers/authorities_provider.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../utils/mon_pays_colors.dart';
import '../../utils/mon_pays_text_styles.dart';

class AuthorityProfilePage extends ConsumerWidget {
  final String id;

  const AuthorityProfilePage({Key? key, required this.id}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authorityAsync = ref.watch(authorityProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profil de l\'autorité',
          style: MonPaysTextStyles.heading6.copyWith(
            color: Colors.white,
          ),
        ),
        backgroundColor: MonPaysColors.primaryRed,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: authorityAsync.when(
        data: (authority) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header avec photo
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: MonPaysColors.gradientRedBlue,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: authority.photoUrl != null
                            ? NetworkImage(authority.photoUrl!)
                            : null,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: authority.photoUrl == null
                            ? Text(
                                authority.name[0].toUpperCase(),
                                style: MonPaysTextStyles.heading2.copyWith(
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              authority.name,
                              style: MonPaysTextStyles.heading5.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              authority.title,
                              style: MonPaysTextStyles.bodyMedium.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Informations générales
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Informations générales',
                          style: MonPaysTextStyles.heading6.copyWith(
                            color: MonPaysColors.primaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(),
                        _infoRow('Fonction', authority.title),
                        if (authority.party != null)
                          _infoRow('Parti politique', authority.party!),
                        if (authority.startDate != null)
                          _infoRow('Début du mandat', authority.startDate!),
                        if (authority.endDate != null)
                          _infoRow('Fin du mandat', authority.endDate!),
                        _infoRow('Type', authority.type.toString().split('.').last),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Biographie
                if (authority.biography != null) ...[
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Biographie',
                            style: MonPaysTextStyles.heading6.copyWith(
                              color: MonPaysColors.primaryBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(),
                          Text(
                            authority.biography!,
                            style: MonPaysTextStyles.bodyMedium.copyWith(
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Actions (bouton de retour, etc.)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Retour'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: MonPaysColors.primaryRed),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: LoadingWidget()),
        error: (error, stack) => Center(
          child: MonPaysErrorWidget(
            message: 'Erreur de chargement : $error',
            onRetry: () => ref.refresh(authorityProvider(id)),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: MonPaysTextStyles.bodySmall.copyWith(
                color: MonPaysColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: MonPaysTextStyles.bodySmall.copyWith(
                color: MonPaysColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
