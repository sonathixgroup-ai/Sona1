// lib/presentation/mon_pays/pages/values/justice_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/values_provider.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../utils/mon_pays_colors.dart';
import '../../utils/mon_pays_text_styles.dart';

class JusticePage extends ConsumerWidget {
  const JusticePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final justiceAsync = ref.watch(justiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Justice',
          style: MonPaysTextStyles.heading6.copyWith(color: Colors.white),
        ),
        backgroundColor: MonPaysColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: justiceAsync.when(
        data: (justice) {
          if (justice == null) {
            return Center(
              child: Text(
                'Informations sur la justice non disponibles',
                style: MonPaysTextStyles.bodyLarge.copyWith(
                  color: MonPaysColors.textSecondary,
                ),
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Système Judiciaire en RDC',
                  style: MonPaysTextStyles.heading5.copyWith(
                    color: MonPaysColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (justice.description != null)
                  Text(
                    justice.description!,
                    style: MonPaysTextStyles.bodyMedium.copyWith(
                      height: 1.6,
                    ),
                  ),
                const SizedBox(height: 24),
                Text(
                  'Organisation',
                  style: MonPaysTextStyles.heading6.copyWith(
                    color: MonPaysColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: justice.organizations?.length ?? 0,
                  itemBuilder: (context, index) {
                    final org = justice.organizations![index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.scale, color: MonPaysColors.primaryRed),
                        title: Text(
                          org.name,
                          style: MonPaysTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          org.description ?? '',
                          style: MonPaysTextStyles.caption.copyWith(
                            color: MonPaysColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
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
          child: MonPaysErrorWidget(
            message: 'Erreur de chargement : $error',
            onRetry: () => ref.refresh(justiceProvider),
          ),
        ),
      ),
    );
  }
}
