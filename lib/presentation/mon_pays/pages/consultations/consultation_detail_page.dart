// lib/presentation/mon_pays/pages/consultations/consultation_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/consultations_provider.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../utils/mon_pays_colors.dart';
import '../../utils/mon_pays_text_styles.dart';

class ConsultationDetailPage extends ConsumerWidget {
  final String id;

  const ConsultationDetailPage({Key? key, required this.id}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consultationAsync = ref.watch(consultationProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Détail de la consultation',
          style: MonPaysTextStyles.heading6.copyWith(color: Colors.white),
        ),
        backgroundColor: MonPaysColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: consultationAsync.when(
        data: (consultation) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec statut
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: consultation.isActive
                        ? MonPaysColors.gradientBlueRed
                        : LinearGradient(
                            colors: [Colors.grey.shade400, Colors.grey.shade600],
                          ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            consultation.isActive
                                ? Icons.check_circle
                                : Icons.lock,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
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
                              consultation.isActive ? 'Active' : 'Fermée',
                              style: MonPaysTextStyles.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        consultation.title,
                        style: MonPaysTextStyles.heading5.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Informations
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
                          consultation.description,
                          style: MonPaysTextStyles.bodyMedium.copyWith(
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _infoRow('Date de début', consultation.startDate),
                        _infoRow('Date de fin', consultation.endDate),
                        if (consultation.participants != null)
                          _infoRow('Participants', '${consultation.participants}'),
                        if (consultation.link != null) ...[
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () {
                              // Ouvrir le lien si disponible
                            },
                            child: Text(
                              '🔗 ${consultation.link}',
                              style: MonPaysTextStyles.bodySmall.copyWith(
                                color: MonPaysColors.primaryBlue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Bouton de participation (si active)
                if (consultation.isActive)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Navigation vers la participation
                      },
                      icon: const Icon(Icons.participation),
                      label: const Text('Participer à cette consultation'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MonPaysColors.primaryRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 12),

                // Retour
                SizedBox(
                  width: double.infinity,
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
          );
        },
        loading: () => const Center(child: LoadingWidget()),
        error: (error, stack) => Center(
          child: ErrorWidget(
            message: 'Erreur de chargement : $error',
            onRetry: () => ref.refresh(consultationProvider(id)),
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
            width: 100,
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
