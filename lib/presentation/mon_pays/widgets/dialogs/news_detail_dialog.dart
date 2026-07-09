// lib/presentation/mon_pays/widgets/dialogs/news_detail_dialog.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../models/news_model.dart';

class NewsDetailDialog extends StatelessWidget {
  final News news;

  const NewsDetailDialog({Key? key, required this.news}) : super(key: key);

  static Future<void> show(
    BuildContext context,
    News news,
  ) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => NewsDetailDialog(news: news),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450, maxHeight: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Catégorie et date
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(news.category),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    news.category.toUpperCase(),
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  news.date,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Titre
            Text(
              news.title,
              style: AppTextStyles.heading5.copyWith(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Contenu (avec scroll si long)
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  news.content,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.6,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Bouton Fermer
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('Fermer', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
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
