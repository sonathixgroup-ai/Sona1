// lib/presentation/mon_pays/pages/values/constitution_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/values_provider.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../utils/mon_pays_colors.dart';
import '../../utils/mon_pays_text_styles.dart';

class ConstitutionPage extends ConsumerWidget {
  const ConstitutionPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final constitutionAsync = ref.watch(constitutionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Constitution',
          style: MonPaysTextStyles.heading6.copyWith(color: Colors.white),
        ),
        backgroundColor: MonPaysColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: constitutionAsync.when(
        data: (constitution) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Constitution de la République Démocratique du Congo',
                  style: MonPaysTextStyles.heading5.copyWith(
                    color: MonPaysColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Adoptée le 18 février 2006',
                  style: MonPaysTextStyles.bodySmall.copyWith(
                    color: MonPaysColors.textSecondary,
                  ),
                ),
                const Divider(height: 32),
                Text(
                  constitution.content ?? 'Contenu de la Constitution...',
                  style: MonPaysTextStyles.bodyMedium.copyWith(
                    height: 1.8,
                  ),
                ),
                const SizedBox(height: 20),
                // Articles
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
                  itemCount: constitution.articles?.length ?? 0,
                  itemBuilder: (context, index) {
                    final article = constitution.articles![index];
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
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          // Navigation vers le détail de l'article
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: LoadingWidget()),
        error: (error, stack) => Center(
          child: MonPaysErrorWidget(
            message: 'Erreur de chargement : $error',
            onRetry: () => ref.refresh(constitutionProvider),
          ),
        ),
      ),
    );
  }
}
