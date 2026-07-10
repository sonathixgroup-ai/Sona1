// lib/presentation/mon_pays/pages/values/justice_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/values_provider.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../utils/mon_pays_colors.dart';
import '../../utils/mon_pays_text_styles.dart';

class JusticePage extends ConsumerWidget {
  const JusticePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(justiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Justice', style: MonPaysTextStyles.heading6.copyWith(color: Colors.white)),
        backgroundColor: MonPaysColors.primaryBlue,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => context.pop()),
      ),
      body: async.when(
        data: (justice) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  justice.title,
                  style: MonPaysTextStyles.heading5.copyWith(
                    color: MonPaysColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (justice.description != null)
                  Text(
                    justice.description!,
                    style: MonPaysTextStyles.bodyMedium.copyWith(height: 1.6),
                  ),
                if (justice.organizations != null && justice.organizations!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Organisations',
                    style: MonPaysTextStyles.heading6.copyWith(
                      color: MonPaysColors.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: justice.organizations!.length,
                    itemBuilder: (context, index) {
                      final org = justice.organizations![index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.scale, color: MonPaysColors.primaryRed),
                          title: Text(
                            org.name,
                            style: MonPaysTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                          ),
                          subtitle: org.description != null
                              ? Text(
                                  org.description!,
                                  style: MonPaysTextStyles.caption.copyWith(color: MonPaysColors.textSecondary),
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Retour'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: MonPaysColors.primaryBlue),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: LoadingWidget()),
        error: (e, _) => Center(
          child: MonPaysErrorWidget(
            message: e.toString(),
            onRetry: () => ref.refresh(justiceProvider),
          ),
        ),
      ),
    );
  }
}
