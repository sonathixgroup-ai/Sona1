// lib/presentation/mon_pays/sections/banner_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/routes/app_routes.dart';
import '../providers/news_provider.dart';
import '../utils/mon_pays_colors.dart';
import '../utils/mon_pays_text_styles.dart';
import '../widgets/glass_card.dart';

class BannerSection extends ConsumerWidget {
  const BannerSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(newsProvider);

    return newsAsync.when(
      data: (news) {
        if (news.isEmpty) return const SizedBox.shrink();
        final topNews = news.take(3).toList();
        return GlassCard(
          padding: EdgeInsets.zero,
          child: SizedBox(
            height: 200,
            child: PageView.builder(
              itemCount: topNews.length,
              itemBuilder: (context, index) {
                final item = topNews[index];
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        MonPaysColors.primaryRed,
                        MonPaysColors.primaryBlue,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getCategoryLabel(item.type),
                          style: MonPaysTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        item.title,
                        style: MonPaysTextStyles.heading5.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.date,
                        style: MonPaysTextStyles.bodySmall.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
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
