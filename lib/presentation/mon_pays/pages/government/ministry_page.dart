// lib/presentation/mon_pays/pages/government/ministry_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_routes.dart';
import '../../cards/ministry_card.dart';
import '../../providers/ministry_provider.dart'; // À créer si nécessaire, ou utilisez un provider existant
import '../../widgets/app_bar.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../utils/mon_pays_colors.dart';
import '../../utils/mon_pays_text_styles.dart';

// Note : Assurez-vous d'avoir un provider `ministriesProvider` qui retourne List<Ministry>.
// Si ce n'est pas encore défini, vous pouvez l'ajouter dans `ministry_provider.dart`.

class MinistryPage extends ConsumerWidget {
  const MinistryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Supposons que vous ayez un provider `ministriesProvider`
    final ministriesAsync = ref.watch(ministriesProvider);

    return Scaffold(
      appBar: MonPaysAppBar(
        title: 'Ministères',
      ),
      body: ministriesAsync.when(
        data: (ministries) {
          if (ministries.isEmpty) {
            return Center(
              child: Text(
                'Aucun ministère disponible',
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
            itemCount: ministries.length,
            itemBuilder: (context, index) {
              final ministry = ministries[index];
              return MinistryCard(
                ministry: ministry,
                onTap: () {
                  context.push(
                    '${AppRoutes.monPaysMinistryDetail}'.replaceFirst(':id', ministry.id),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(
          child: LoadingWidget(
            message: 'Chargement des ministères...',
          ),
        ),
        error: (error, stack) => Center(
          child: ErrorWidget(
            message: 'Erreur de chargement : $error',
            onRetry: () => ref.refresh(ministriesProvider),
          ),
        ),
      ),
    );
  }
}
