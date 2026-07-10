// lib/presentation/mon_pays/pages/values/constitution_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/values_provider.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../utils/mon_pays_colors.dart';
import '../../utils/mon_pays_text_styles.dart';

class ConstitutionPage extends ConsumerWidget {
  const ConstitutionPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(constitutionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Constitution', style: MonPaysTextStyles.heading6.copyWith(color: Colors.white)),
        backgroundColor: MonPaysColors.primaryBlue,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => context.pop()),
      ),
      body: async.when(
        data: (value) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value.title,
                  style: MonPaysTextStyles.heading4.copyWith(
                    color: MonPaysColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (value.category != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Catégorie: ${value.category}',
                    style: MonPaysTextStyles.bodySmall.copyWith(color: MonPaysColors.textSecondary),
                  ),
                ],
                const Divider(height: 32),
                if (value.content != null) ...[
                  Text(
                    'Contenu',
                    style: MonPaysTextStyles.heading6.copyWith(
                      color: MonPaysColors.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value.content!,
                    style: MonPaysTextStyles.bodyMedium.copyWith(height: 1.8),
                  ),
                ],
                if (value.articles != null && value.articles!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Articles',
                    style: MonPaysTextStyles.heading6.copyWith(
                      color: MonPaysColors.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: value.articles!.length,
                    itemBuilder: (context, index) {
                      final article = value.articles![index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            'Article ${article.number}',
                            style: MonPaysTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: MonPaysColors.primaryBlue,
                            ),
                          ),
                          subtitle: Text(
                            article.title,
                            style: MonPaysTextStyles.caption.copyWith(
                              color: MonPaysColors.textSecondary,
                            ),
                          ),
                          onTap: () {
                            // Navigation vers le détail de l'article
                          },
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
            onRetry: () => ref.refresh(constitutionProvider),
          ),
        ),
      ),
    );
  }
}
