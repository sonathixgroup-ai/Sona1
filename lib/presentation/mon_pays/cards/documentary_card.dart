// lib/presentation/mon_pays/cards/documentary_card.dart

import 'package:flutter/material.dart';
import '../models/documentary_model.dart';
import '../utils/mon_pays_colors.dart';
import '../utils/mon_pays_text_styles.dart';

class DocumentaryCard extends StatelessWidget {
  final Documentary documentary;
  final VoidCallback? onTap;

  const DocumentaryCard({Key? key, required this.documentary, this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 180,
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  documentary.thumbnailUrl,
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 100,
                    color: MonPaysColors.backgroundLight,
                    child: const Icon(
                      Icons.movie,
                      color: MonPaysColors.primaryRed,
                      size: 40,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: MonPaysColors.primaryRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  documentary.category,
                  style: MonPaysTextStyles.caption.copyWith(
                    color: MonPaysColors.primaryRed,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                documentary.title,
                style: MonPaysTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: MonPaysColors.primaryBlue,
                  fontSize: 12,
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
}
