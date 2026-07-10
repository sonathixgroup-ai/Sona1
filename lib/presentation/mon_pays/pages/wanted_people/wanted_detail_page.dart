// lib/presentation/mon_pays/pages/wanted_people/wanted_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_routes.dart';
import '../../providers/wanted_people_provider.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../utils/mon_pays_colors.dart';
import '../../utils/mon_pays_text_styles.dart';
import '../../enums/wanted_status.dart';

class WantedDetailPage extends ConsumerWidget {
  final String id;

  const WantedDetailPage({Key? key, required this.id}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personAsync = ref.watch(wantedPersonProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Détail',
          style: MonPaysTextStyles.heading6.copyWith(color: Colors.white),
        ),
        backgroundColor: MonPaysColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: personAsync.when(
        data: (person) {
          final isDangerous = person.status == WantedStatus.dangerous;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec photo
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: isDangerous
                        ? MonPaysColors.gradientRedYellow
                        : MonPaysColors.gradientBlueRed,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: person.photoUrl != null
                            ? NetworkImage(person.photoUrl!)
                            : null,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: person.photoUrl == null
                            ? Text(
                                person.name[0].toUpperCase(),
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
                              person.name,
                              style: MonPaysTextStyles.heading5.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (person.alias != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Alias: ${person.alias}',
                                style: MonPaysTextStyles.bodyMedium.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isDangerous ? '🚨 Dangereux' : '🔍 Disparu',
                                style: MonPaysTextStyles.caption.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
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
                          'Informations',
                          style: MonPaysTextStyles.heading6.copyWith(
                            color: MonPaysColors.primaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(),
                        _infoRow('Motif', person.reason),
                        _infoRow('Province', person.province),
                        _infoRow('Date de signalement', person.date),
                        _infoRow('Niveau d\'alerte', '${person.alertLevel}/5'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Description détaillée
                if (person.description != null) ...[
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
                            'Description',
                            style: MonPaysTextStyles.heading6.copyWith(
                              color: MonPaysColors.primaryBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(),
                          Text(
                            person.description!,
                            style: MonPaysTextStyles.bodyMedium.copyWith(
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Boutons d'action
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Ouvrir le dialogue de signalement
                        },
                        icon: const Icon(Icons.report),
                        label: const Text('Signaler'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDangerous
                              ? MonPaysColors.primaryRed
                              : MonPaysColors.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Retour'),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: MonPaysColors.primaryBlue),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: LoadingWidget()),
        error: (error, stack) => Center(
          child: ErrorWidget(
            message: 'Erreur de chargement : $error',
            onRetry: () => ref.refresh(wantedPersonProvider(id)),
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
                fontWeight: FontWeight.w600,
                color: MonPaysColors.textSecondary,
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
