// lib/presentation/mon_pays/pages/documentaries/documentaries_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_routes.dart';
import '../../cards/documentary_card.dart';
import '../../providers/documentaries_provider.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../utils/mon_pays_colors.dart';
import '../../utils/mon_pays_text_styles.dart';

class DocumentariesPage extends ConsumerWidget {
  const DocumentariesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentariesAsync = ref.watch(documentariesProvider);

    return Scaffold(
      appBar: MonPaysAppBar(
        title: 'Documentaires & Archives',
      ),
      body: documentariesAsync.when(
        data: (documentaries) {
          if (documentaries.isEmpty) {
            return Center(
              child: Text(
                'Aucun documentaire disponible',
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
              childAspectRatio: 0.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: documentaries.length,
            itemBuilder: (context, index) {
              final documentary = documentaries[index];
              return DocumentaryCard(
                documentary: documentary,
                onTap: () {
                  context.push(
                    '${AppRoutes.monPaysDocumentaryDetail}'
                        .replaceFirst(':id', documentary.id),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(
          child: LoadingWidget(
            message: 'Chargement des documentaires...',
          ),
        ),
        error: (error, stack) => Center(
          child: ErrorWidget(
            message: 'Erreur de chargement : $error',
            onRetry: () => ref.refresh(documentariesProvider),
          ),
        ),
      ),
    );
  }
}
