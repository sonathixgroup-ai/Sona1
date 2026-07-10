// lib/presentation/mon_pays/sections/news_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/routes/app_routes.dart';
import '../cards/news_card.dart';
import '../providers/news_provider.dart';
import '../widgets/section_title.dart';

class NewsSection extends ConsumerWidget {
  const NewsSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(newsProvider);

    return newsAsync.when(
      data: (news) {
        if (news.isEmpty) return const SizedBox.shrink();
        final displayNews = news.take(4).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(
              title: 'À la Une',
              subtitle: 'Actualités officielles',
              seeAllText: 'Voir toutes',
              onSeeAll: () {
                context.push(AppRoutes.monPaysNews);
              },
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: displayNews.length,
              itemBuilder: (context, index) {
                final newsItem = displayNews[index];
                return NewsCard(
                  news: newsItem,
                  onTap: () {
                    context.push(
                      '${AppRoutes.monPaysNewsDetail}'.replaceFirst(':id', newsItem.id),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => const SizedBox(
        height: 200,
        child: Center(child: Text('Erreur de chargement')),
      ),
    );
  }
}
