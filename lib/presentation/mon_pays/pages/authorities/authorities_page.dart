// lib/presentation/mon_pays/pages/authorities/authorities_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_routes.dart';
import '../../cards/authority_card.dart';
import '../../providers/authorities_provider.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../utils/mon_pays_colors.dart';
import '../../utils/mon_pays_text_styles.dart';

class AuthoritiesPage extends ConsumerWidget {
  const AuthoritiesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authoritiesAsync = ref.watch(authoritiesProvider);

    return Scaffold(
      appBar: MonPaysAppBar(
        title: 'Toutes les autorités',
      ),
      body: authoritiesAsync.when(
        data: (authorities) {
          if (authorities.isEmpty) {
            return Center(
              child: Text(
                'Aucune autorité disponible',
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
            itemCount: authorities.length,
            itemBuilder: (context, index) {
              final authority = authorities[index];
              return AuthorityCard(
                authority: authority,
                onTap: () {
                  context.push(
                    '${AppRoutes.monPaysAuthorityDetail}'.replaceFirst(':id', authority.id),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(
          child: LoadingWidget(
            message: 'Chargement des autorités...',
          ),
        ),
        error: (error, stack) => Center(
          child: MonPaysErrorWidget(
            message: 'Erreur de chargement : $error',
            onRetry: () => ref.refresh(authoritiesProvider),
          ),
        ),
      ),
    );
  }
}
