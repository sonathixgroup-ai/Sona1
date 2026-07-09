// lib/presentation/mon_pays/pages/wanted_people/missing_people_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_routes.dart';
import '../../cards/wanted_person_card.dart';
import '../../providers/wanted_people_provider.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../utils/mon_pays_colors.dart';
import '../../utils/mon_pays_text_styles.dart';
import '../../enums/wanted_status.dart';

class MissingPeoplePage extends ConsumerWidget {
  const MissingPeoplePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wantedAsync = ref.watch(wantedPeopleProvider);

    return wantedAsync.when(
      data: (people) {
        final missing = people.where((p) => p.status == WantedStatus.missing).toList();
        if (missing.isEmpty) {
          return Center(
            child: Text(
              'Aucune personne disparue signalée',
              style: MonPaysTextStyles.bodyLarge.copyWith(
                color: MonPaysColors.textSecondary,
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: missing.length,
          itemBuilder: (context, index) {
            final person = missing[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: WantedPersonCard(
                person: person,
                onTap: () {
                  context.push(
                    '${AppRoutes.monPaysWantedDetail}'.replaceFirst(':id', person.id),
                  );
                },
                onReport: () {
                  // Ouvrir le dialogue de signalement
                },
              ),
            );
          },
        );
      },
      loading: () => const Center(child: LoadingWidget()),
      error: (error, stack) => Center(
        child: ErrorWidget(
          message: 'Erreur de chargement : $error',
          onRetry: () => ref.refresh(wantedPeopleProvider),
        ),
      ),
    );
  }
}
