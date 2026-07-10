// lib/presentation/mon_pays/pages/citizens/citizen_profile_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/citizens_provider.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart'; // ✅
import '../../utils/mon_pays_colors.dart';
import '../../utils/mon_pays_text_styles.dart';

class CitizenProfilePage extends ConsumerWidget {
  final String id;
  const CitizenProfilePage({Key? key, required this.id}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final citizenAsync = ref.watch(citizenProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profil du citoyen',
          style: MonPaysTextStyles.heading6.copyWith(color: Colors.white),
        ),
        backgroundColor: MonPaysColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: citizenAsync.when(
        data: (citizen) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: citizen.photoUrl != null
                      ? NetworkImage(citizen.photoUrl!)
                      : null,
                  backgroundColor: MonPaysColors.primaryBlue.withOpacity(0.1),
                  child: citizen.photoUrl == null
                      ? Text(
                          citizen.name[0].toUpperCase(),
                          style: MonPaysTextStyles.heading1.copyWith(
                            color: MonPaysColors.primaryBlue,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  citizen.name,
                  style: MonPaysTextStyles.heading4.copyWith(
                    color: MonPaysColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  citizen.occupation,
                  style: MonPaysTextStyles.bodyLarge.copyWith(
                    color: MonPaysColors.primaryRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (citizen.city != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '📍 ${citizen.city}',
                    style: MonPaysTextStyles.bodySmall.copyWith(
                      color: MonPaysColors.textSecondary,
                    ),
                  ),
                ],
                if (citizen.score != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: MonPaysColors.goldBadge.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: MonPaysColors.goldBadge),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: MonPaysColors.goldBadge),
                        const SizedBox(width: 8),
                        Text(
                          'Score de confiance : ${citizen.score}%',
                          style: MonPaysTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: MonPaysColors.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Divider(height: 32),

                if (citizen.quote != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: MonPaysColors.backgroundLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: MonPaysColors.cardBorder),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.format_quote, color: MonPaysColors.primaryRed),
                        const SizedBox(height: 8),
                        Text(
                          '"${citizen.quote}"',
                          style: MonPaysTextStyles.bodyMedium.copyWith(
                            fontStyle: FontStyle.italic,
                            height: 1.6,
                            color: MonPaysColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Retour'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: MonPaysColors.primaryBlue),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: LoadingWidget()),
        error: (error, stack) => Center(
          child: MonPaysErrorWidget( // ✅ corrigé
            message: 'Erreur de chargement : $error',
            onRetry: () => ref.refresh(citizenProvider(id)),
          ),
        ),
      ),
    );
  }
}
