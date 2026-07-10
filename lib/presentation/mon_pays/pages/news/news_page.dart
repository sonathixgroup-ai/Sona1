// lib/presentation/mon_pays/pages/news/news_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_routes.dart';
import '../../cards/news_card.dart';
import '../../providers/news_provider.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../utils/mon_pays_colors.dart';
import '../../utils/mon_pays_text_styles.dart';

class NewsPage extends ConsumerWidget {
  const NewsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(newsProvider);

    return Scaffold(
      appBar: MonPaysAppBar(
        title: 'Toutes les actualités',
      ),
      body: newsAsync.when(
        data: (news) {
          if (news.isEmpty) {
            return Center(
              child: Text(
                'Aucune actualité disponible',
                style: MonPaysTextStyles.bodyLarge.copyWith(
                  color: MonPaysColors.textSecondary,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: news.length,
            itemBuilder: (context, index) {
              final newsItem = news[index];
              return NewsCard(
                news: newsItem,
                onTap: () {
                  context.push(
                    '${AppRoutes.monPaysNewsDetail}'.replaceFirst(':id', newsItem.id),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(
          child: LoadingWidget(
            message: 'Chargement des actualités...',
          ),
        ),
        error: (error, stack) => Center(
          child: ErrorWidget(
            message: 'Erreur de chargement : $error',
            onRetry: () => ref.refresh(newsProvider),
          ),
        ),
      ),
    );
  }
}
