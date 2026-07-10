// lib/presentation/mon_pays/pages/values/institutions_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/values_provider.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../utils/mon_pays_colors.dart';
import '../../utils/mon_pays_text_styles.dart';

class InstitutionsPage extends ConsumerWidget {
  const InstitutionsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(institutionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Institutions', style: MonPaysTextStyles.heading6.copyWith(color: Colors.white)),
        backgroundColor: MonPaysColors.primaryBlue,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => context.pop()),
      ),
      body: async.when(
        data: (institutions) {
          if (institutions.isEmpty) return const Center(child: Text('Aucune institution disponible'));
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.9,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: institutions.length,
            itemBuilder: (context, index) {
              final institution = institutions[index];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    // Navigation vers le détail
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.account_balance, color: MonPaysColors.primaryRed, size: 40),
                        const SizedBox(height: 8),
                        Text(
                          institution.title, // Utilisation de title (ou name)
                          style: MonPaysTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: MonPaysColors.primaryBlue,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: LoadingWidget()),
        error: (e, _) => Center(
          child: MonPaysErrorWidget(
            message: e.toString(),
            onRetry: () => ref.refresh(institutionsProvider),
          ),
        ),
      ),
    );
  }
}
