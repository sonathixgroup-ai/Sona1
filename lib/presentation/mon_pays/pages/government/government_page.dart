// lib/presentation/mon_pays/pages/government/government_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_routes.dart';
import '../../cards/agency_card.dart';
import '../../providers/government_provider.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../utils/mon_pays_colors.dart';
import '../../utils/mon_pays_text_styles.dart';

class GovernmentPage extends ConsumerWidget {
  const GovernmentPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final governmentAsync = ref.watch(governmentProvider);

    return Scaffold(
      appBar: MonPaysAppBar(
        title: 'Gouvernement',
      ),
      body: governmentAsync.when(
        data: (governments) {
          if (governments.isEmpty) {
            return Center(
              child: Text(
                'Aucune information sur le gouvernement',
                style: MonPaysTextStyles.bodyLarge.copyWith(
                  color: MonPaysColors.textSecondary,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: governments.length,
            itemBuilder: (context, index) {
              final gov = governments[index];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      gov.logoUrl ?? 'https://via.placeholder.com/60',
                      height: 50,
                      width: 50,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.account_balance,
                        size: 40,
                        color: MonPaysColors.primaryRed,
                      ),
                    ),
                  ),
                  title: Text(
                    gov.name,
                    style: MonPaysTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: MonPaysColors.primaryBlue,
                    ),
                  ),
                  subtitle: gov.description != null
                      ? Text(
                          gov.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: MonPaysTextStyles.caption.copyWith(
                            color: MonPaysColors.textSecondary,
                          ),
                        )
                      : null,
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    color: MonPaysColors.primaryRed,
                    size: 16,
                  ),
                  onTap: () {
                    context.push(
                      '${AppRoutes.monPaysGovernmentDetail}'.replaceFirst(':id', gov.id),
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: LoadingWidget(
            message: 'Chargement du gouvernement...',
          ),
        ),
        error: (error, stack) => Center(
          child: ErrorWidget(
            message: 'Erreur de chargement : $error',
            onRetry: () => ref.refresh(governmentProvider),
          ),
        ),
      ),
    );
  }
}
