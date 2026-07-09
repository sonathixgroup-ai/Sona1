// lib/presentation/mon_pays/cards/ministry_card.dart

import 'package:flutter/material.dart';
import '../models/ministry_model.dart';
import '../utils/mon_pays_colors.dart';
import '../utils/mon_pays_text_styles.dart';

class MinistryCard extends StatelessWidget {
  final Ministry ministry;
  final VoidCallback? onTap;

  const MinistryCard({Key? key, required this.ministry, this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 150,
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  ministry.logoUrl ?? 'https://via.placeholder.com/80',
                  height: 60,
                  width: 60,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.business_center,
                    size: 40,
                    color: MonPaysColors.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                ministry.name,
                style: MonPaysTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: MonPaysColors.primaryBlue,
                ),
                textAlign: TextAlign.center,
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
