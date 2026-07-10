// lib/presentation/mon_pays/pages/values/duties_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/values_provider.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../utils/mon_pays_colors.dart';
import '../../utils/mon_pays_text_styles.dart';

class DutiesPage extends ConsumerWidget {
  const DutiesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dutiesAsync = ref.watch(dutiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Devoirs du Citoyen',
          style: MonPaysTextStyles.heading6.copyWith(color: Colors.white),
        ),
        backgroundColor: MonPaysColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: dutiesAsync.when(
        data: (duties) {
          if (duties.isEmpty) {
            return Center(
              child: Text(
                'Aucun devoir disponible',
                style: MonPaysTextStyles.bodyLarge.copyWith(
                  color: MonPaysColors.textSecondary,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: duties.length,
            itemBuilder: (context, index) {
              final duty = duties[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: MonPaysColors.primaryBlue.withOpacity(0.1),
                    child: Icon(
                      Icons.assignment,
                      color: MonPaysColors.primaryBlue,
                    ),
                  ),
                  title: Text(
                    duty.title,
                    style: MonPaysTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: MonPaysColors.primaryBlue,
                    ),
                  ),
                  subtitle: duty.description != null
                      ? Text(
                          duty.description!,
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
          child: MonPaysErrorWidget(
            message: 'Erreur de chargement : $error',
            onRetry: () => ref.refresh(dutiesProvider),
          ),
        ),
      ),
    );
  }
}
