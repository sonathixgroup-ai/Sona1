// lib/presentation/mon_pays/cards/news_card.dart

import 'package:flutter/material.dart';
import '../models/news_model.dart';
import '../utils/mon_pays_colors.dart';
import '../utils/mon_pays_text_styles.dart';
import '../enums/news_type.dart';

class NewsCard extends StatelessWidget {
  final News news;
  final VoidCallback? onTap;

  const NewsCard({Key? key, required this.news, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (news.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    news.imageUrl!,
                    height: 60,
                    width: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.image_not_supported,
                      size: 40,
                      color: MonPaysColors.textHint,
                    ),
                  ),
                ),
              if (news.imageUrl != null) const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(news.type),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getCategoryLabel(news.type),
                            style: MonPaysTextStyles.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          news.date,
                          style: MonPaysTextStyles.caption.copyWith(
                            color: MonPaysColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      news.title,
                      style: MonPaysTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: MonPaysColors.primaryBlue,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
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
