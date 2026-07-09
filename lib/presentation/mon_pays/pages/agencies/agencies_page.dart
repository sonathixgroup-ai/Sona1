// lib/presentation/mon_pays/pages/agencies/agencies_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_routes.dart';
import '../../cards/agency_card.dart';
import '../../providers/agencies_provider.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../utils/mon_pays_colors.dart';
import '../../utils/mon_pays_text_styles.dart';

class AgenciesPage extends ConsumerWidget {
  const AgenciesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agenciesAsync = ref.watch(agenciesProvider);

    return Scaffold(
      appBar: MonPaysAppBar(
        title: 'Agences & Institutions',
      ),
      body: agenciesAsync.when(
        data: (agencies) {
          if (agencies.isEmpty) {
            return Center(
              child: Text(
                'Aucune agence disponible',
                style: MonPaysTextStyles.bodyLarge.copyWith(
                  color: MonPaysColors.textSecondary,
                ),
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.9,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: agencies.length,
            itemBuilder: (context, index) {
              final agency = agencies[index];
              return AgencyCard(
                agency: agency,
                onTap: () {
                  context.push(
                    '${AppRoutes.monPaysAgencyDetail}'.replaceFirst(':id', agency.id),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(
          child: LoadingWidget(
            message: 'Chargement des agences...',
          ),
        ),
        error: (error, stack) => Center(
          child: ErrorWidget(
            message: 'Erreur de chargement : $error',
            onRetry: () => ref.refresh(agenciesProvider),
          ),
        ),
      ),
    );
  }
}
