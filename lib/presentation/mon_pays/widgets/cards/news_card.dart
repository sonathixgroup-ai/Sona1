// lib/presentation/mon_pays/widgets/cards/news_card.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../models/news_model.dart';

class NewsCard extends StatelessWidget {
  final News news;
  final VoidCallback? onTap;

  const NewsCard({
    Key? key,
    required this.news,
    this.onTap,
  }) : super(key: key);

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(news.category),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      news.category.toUpperCase(),
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    news.date,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                news.title,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBlue,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toUpperCase()) {
      case 'OFFICIEL':
        return AppColors.primaryRed;
      case 'COMMUNIQUÉ':
        return AppColors.primaryBlue;
      case 'NATIONAL':
        return Colors.orange;
      default:
        return AppColors.textSecondary;
    }
  }
}
