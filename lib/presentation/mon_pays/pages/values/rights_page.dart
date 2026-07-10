// lib/presentation/mon_pays/pages/values/rights_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/values_provider.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../utils/mon_pays_colors.dart';
import '../../utils/mon_pays_text_styles.dart';

class RightsPage extends ConsumerWidget {
  const RightsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rightsAsync = ref.watch(rightsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Droits du Citoyen',
          style: MonPaysTextStyles.heading6.copyWith(color: Colors.white),
        ),
        backgroundColor: MonPaysColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: rightsAsync.when(
        data: (rights) {
          if (rights.isEmpty) {
            return Center(
              child: Text(
                'Aucun droit disponible',
                style: MonPaysTextStyles.bodyLarge.copyWith(
                  color: MonPaysColors.textSecondary,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rights.length,
            itemBuilder: (context, index) {
              final right = rights[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: MonPaysColors.primaryRed.withOpacity(0.1),
                    child: Icon(
                      Icons.verified_user,
                      color: MonPaysColors.primaryRed,
                    ),
                  ),
                  title: Text(
                    right.title,
                    style: MonPaysTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: MonPaysColors.primaryBlue,
                    ),
                  ),
                  subtitle: right.description != null
                      ? Text(
                          right.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: MonPaysTextStyles.caption.copyWith(
                            color: MonPaysColors.textSecondary,
                          ),
                        )
                      : null,
                  onTap: () {
                    // Navigation vers le détail
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
            onRetry: () => ref.refresh(rightsProvider),
          ),
        ),
      ),
    );
  }
}
