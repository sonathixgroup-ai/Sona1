// lib/presentation/mon_pays/pages/values/laws_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/values_provider.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../utils/mon_pays_colors.dart';
import '../../utils/mon_pays_text_styles.dart';

class LawsPage extends ConsumerWidget {
  const LawsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(lawsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Codes et Lois', style: MonPaysTextStyles.heading6.copyWith(color: Colors.white)),
        backgroundColor: MonPaysColors.primaryBlue,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => context.pop()),
      ),
      body: async.when(
        data: (laws) {
          if (laws.isEmpty) {
            return const Center(child: Text('Aucune loi disponible'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: laws.length,
            itemBuilder: (context, index) {
              final law = laws[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const Icon(Icons.book, color: MonPaysColors.primaryRed),
                  title: Text(
                    law.title,
                    style: MonPaysTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: MonPaysColors.primaryBlue,
                    ),
                  ),
                  subtitle: law.summary != null
                      ? Text(
                          law.summary!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: MonPaysTextStyles.caption.copyWith(color: MonPaysColors.textSecondary),
                        )
                      : null,
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: MonPaysColors.primaryRed),
                  onTap: () {
                    // Navigation vers le détail de la loi
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: LoadingWidget()),
        error: (e, _) => Center(
          child: MonPaysErrorWidget(
            message: e.toString(),
            onRetry: () => ref.refresh(lawsProvider),
          ),
        ),
      ),
    );
  }
}
