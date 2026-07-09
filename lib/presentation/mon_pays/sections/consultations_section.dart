// lib/presentation/mon_pays/sections/consultations_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/routes/app_routes.dart';
import '../cards/consultation_card.dart';
import '../providers/consultations_provider.dart';
import '../widgets/section_title.dart';

class ConsultationsSection extends ConsumerWidget {
  const ConsultationsSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consultationsAsync = ref.watch(consultationsProvider);

    return consultationsAsync.when(
      data: (consultations) {
        if (consultations.isEmpty) return const SizedBox.shrink();
        final activeConsultations = consultations.where((c) => c.isActive).take(3).toList();
        if (activeConsultations.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(
              title: 'Consultations Publiques',
              subtitle: 'Participez à la construction du pays',
              seeAllText: 'Voir toutes',
              onSeeAll: () {
                context.push(AppRoutes.monPaysConsultations);
              },
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: activeConsultations.length,
              itemBuilder: (context, index) {
                final consultation = activeConsultations[index];
                return ConsultationCard(
                  consultation: consultation,
                  onTap: () {
                    context.push(
                      '${AppRoutes.monPaysConsultationDetail}'
                          .replaceFirst(':id', consultation.id),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => const SizedBox(
        height: 200,
        child: Center(child: Text('Erreur de chargement')),
      ),
    );
  }
}
