// lib/presentation/mon_pays/pages/authorities/authority_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_routes.dart';
import '../../providers/authorities_provider.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../utils/mon_pays_colors.dart';
import '../../utils/mon_pays_text_styles.dart';

class AuthorityDetailPage extends ConsumerWidget {
  final String id;

  const AuthorityDetailPage({Key? key, required this.id}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authorityAsync = ref.watch(authorityProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Détail de l\'autorité',
          style: MonPaysTextStyles.heading6.copyWith(
            color: Colors.white,
          ),
        ),
        backgroundColor: MonPaysColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: authorityAsync.when(
        data: (authority) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage: authority.photoUrl != null
                        ? NetworkImage(authority.photoUrl!)
                        : null,
                    backgroundColor: MonPaysColors.primaryRed.withOpacity(0.1),
                    child: authority.photoUrl == null
                        ? Text(
                            authority.name[0].toUpperCase(),
                            style: MonPaysTextStyles.heading3.copyWith(
                              color: MonPaysColors.primaryRed,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  authority.name,
                  style: MonPaysTextStyles.heading4.copyWith(
                    color: MonPaysColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  authority.title,
                  style: MonPaysTextStyles.bodyLarge.copyWith(
                    color: MonPaysColors.primaryRed,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (authority.party != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    authority.party!,
                    style: MonPaysTextStyles.bodyMedium.copyWith(
                      color: MonPaysColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const Divider(height: 32),
                if (authority.biography != null) ...[
                  Text(
                    'Biographie',
                    style: MonPaysTextStyles.heading6.copyWith(
                      color: MonPaysColors.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    authority.biography!,
                    style: MonPaysTextStyles.bodyMedium.copyWith(
                      height: 1.6,
                    ),
                  ),
                ],
                const Divider(height: 32),
                if (authority.startDate != null || authority.endDate != null) ...[
                  Text(
                    'Mandat',
                    style: MonPaysTextStyles.heading6.copyWith(
                      color: MonPaysColors.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: MonPaysColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        '${authority.startDate ?? '?'} - ${authority.endDate ?? 'En cours'}',
                        style: MonPaysTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: LoadingWidget()),
        error: (error, stack) => Center(
          child: MonPaysErrorWidget(
            message: 'Erreur de chargement : $error',
            onRetry: () => ref.refresh(authorityProvider(id)),
          ),
        ),
      ),
    );
  }
}
