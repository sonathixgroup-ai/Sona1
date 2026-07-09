// lib/presentation/mon_pays/cards/history_card.dart

import 'package:flutter/material.dart';
import '../models/history_model.dart';
import '../utils/mon_pays_colors.dart';
import '../utils/mon_pays_text_styles.dart';

class HistoryCard extends StatelessWidget {
  final HistoricalFigure figure;
  final VoidCallback? onTap;

  const HistoryCard({Key? key, required this.figure, this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 160,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  figure.imageUrl ?? 'https://via.placeholder.com/150',
                  height: 110,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 110,
                    color: MonPaysColors.backgroundLight,
                    child: const Icon(
                      Icons.person_outline,
                      color: MonPaysColors.primaryRed,
                      size: 50,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                figure.name,
                style: MonPaysTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: MonPaysColors.primaryBlue,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                figure.period,
                style: MonPaysTextStyles.caption.copyWith(
                  color: MonPaysColors.textSecondary,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
