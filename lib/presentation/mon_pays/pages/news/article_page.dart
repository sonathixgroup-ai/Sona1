// lib/presentation/mon_pays/pages/news/article_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_routes.dart';
import '../../providers/news_provider.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../utils/mon_pays_colors.dart';
import '../../utils/mon_pays_text_styles.dart';
import '../../enums/news_type.dart';

class ArticlePage extends ConsumerWidget {
  final String id;

  const ArticlePage({Key? key, required this.id}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(newsItemProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Article',
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
      body: newsAsync.when(
        data: (news) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Catégorie et date
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(news.type),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getCategoryLabel(news.type),
                        style: MonPaysTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      news.date,
                      style: MonPaysTextStyles.caption.copyWith(
                        color: MonPaysColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Titre
                Text(
                  news.title,
                  style: MonPaysTextStyles.heading4.copyWith(
                    color: MonPaysColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Image (si disponible)
                if (news.imageUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      news.imageUrl!,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 200,
                        color: MonPaysColors.backgroundLight,
                        child: const Icon(
                          Icons.image_not_supported,
                          size: 50,
                          color: MonPaysColors.textHint,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Contenu
                Text(
                  news.content,
                  style: MonPaysTextStyles.bodyMedium.copyWith(
                    height: 1.8,
                  ),
                ),

                const SizedBox(height: 20),

                // Auteur et vues
                if (news.author != null || news.views != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: MonPaysColors.backgroundLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        if (news.author != null) ...[
                          const Icon(
                            Icons.person_outline,
                            size: 16,
                            color: MonPaysColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            news.author!,
                            style: MonPaysTextStyles.caption.copyWith(
                              color: MonPaysColors.textSecondary,
                            ),
                          ),
                        ],
                        if (news.author != null && news.views != null)
                          const Spacer(),
                        if (news.views != null) ...[
                          const Icon(
                            Icons.visibility_outlined,
                            size: 16,
                            color: MonPaysColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${news.views} vues',
                            style: MonPaysTextStyles.caption.copyWith(
                              color: MonPaysColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // Retour
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Retour aux actualités'),
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
            onRetry: () => ref.refresh(newsItemProvider(id)),
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(NewsType type) {
    switch (type) {
      case NewsType.official:
        return MonPaysColors.primaryRed;
      case NewsType.communique:
        return MonPaysColors.primaryBlue;
      case NewsType.national:
        return Colors.orange;
      case NewsType.international:
        return Colors.green;
    }
  }

  String _getCategoryLabel(NewsType type) {
    switch (type) {
      case NewsType.official:
        return 'OFFICIEL';
      case NewsType.communique:
        return 'COMMUNIQUÉ';
      case NewsType.national:
        return 'NATIONAL';
      case NewsType.international:
        return 'INTERNATIONAL';
    }
  }
}
