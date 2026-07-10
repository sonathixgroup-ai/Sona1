// lib/presentation/mon_pays/pages/consultations/consultations_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../nav.dart'; // pour AppRoutes
import '../../models/consultation_model.dart';
import '../../providers/consultations_provider.dart';
import '../../cards/consultation_card.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_widget.dart';
import '../../widgets/error_widget.dart' as custom; // alias pour éviter conflit

class ConsultationsPage extends ConsumerWidget {
  const ConsultationsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consultationsAsync = ref.watch(consultationsProvider);

    return Scaffold(
      appBar: MonPaysAppBar(
        title: 'Consultations Publiques',
      ),
      body: consultationsAsync.when(
        data: (consultations) {
          if (consultations.isEmpty) {
            return const EmptyWidget(
              message: 'Aucune consultation disponible',
            );
          }
          // Tri : les actives d'abord
          final sorted = List<Consultation>.from(consultations)
            ..sort((a, b) {
              if (a.isActive && !b.isActive) return -1;
              if (!a.isActive && b.isActive) return 1;
              return 0;
            });
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sorted.length,
            itemBuilder: (context, index) {
              final consultation = sorted[index];
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
          );
        },
        loading: () => const Center(
          child: LoadingWidget(
            message: 'Chargement des consultations...',
          ),
        ),
        error: (error, stack) => Center(
          child: custom.MonPaysErrorWidget(
            message: 'Erreur de chargement : $error',
            onRetry: () => ref.refresh(consultationsProvider),
          ),
        ),
      ),
    );
  }
}
