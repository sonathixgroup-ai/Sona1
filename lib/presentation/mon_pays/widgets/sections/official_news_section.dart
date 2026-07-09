// lib/presentation/mon_pays/widgets/sections/official_news_section.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../models/news_model.dart';
import '../cards/news_card.dart';
import '../shared/section_title.dart';

class OfficialNewsSection extends StatelessWidget {
  final List<News> news;

  const OfficialNewsSection({Key? key, required this.news}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (news.isEmpty) {
      return const SizedBox.shrink();
    }

    // Afficher les 4 dernières actualités par défaut
    final displayNews = news.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: 'À la Une',
          subtitle: 'Actualités officielles',
          seeAllText: 'Voir toutes',
          onSeeAll: null,
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: displayNews.length,
          itemBuilder: (context, index) {
            return NewsCard(news: displayNews[index]);
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
