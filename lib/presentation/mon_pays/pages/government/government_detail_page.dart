// lib/presentation/mon_pays/pages/government/government_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/government_provider.dart';
import '../../utils/mon_pays_colors.dart';
import '../../utils/mon_pays_text_styles.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';

class GovernmentDetailPage extends ConsumerWidget {
  final String id;

  const GovernmentDetailPage({Key? key, required this.id}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final governmentAsync = ref.watch(governmentItemProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Détail du Gouvernement',
          style: MonPaysTextStyles.heading6.copyWith(color: Colors.white),
        ),
        backgroundColor: MonPaysColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: governmentAsync.when(
        data: (government) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: MonPaysColors.gradientBlueRed,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          government.logoUrl ?? 'https://via.placeholder.com/80',
                          height: 60,
                          width: 60,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.account_balance,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              government.name,
                              style: MonPaysTextStyles.heading5.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (government.type != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                government.type!,
                                style: MonPaysTextStyles.bodySmall.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Informations',
                          style: MonPaysTextStyles.heading6.copyWith(
                            color: MonPaysColors.primaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(),
                        if (government.description != null) ...[
                          Text(
                            'Description',
                            style: MonPaysTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: MonPaysColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(government.description!, style: MonPaysTextStyles.bodyMedium),
                          const SizedBox(height: 12),
                        ],
                        if (government.website != null) ...[
                          _infoRow('Site web', government.website!),
                        ],
                      ],
                    ),
                  ),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            onRetry: () => ref.refresh(governmentItemProvider(id)),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: MonPaysTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: MonPaysColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: MonPaysTextStyles.bodySmall.copyWith(color: MonPaysColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
