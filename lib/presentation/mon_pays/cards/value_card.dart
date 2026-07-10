// lib/presentation/mon_pays/cards/value_card.dart

import 'package:flutter/material.dart';
import '../models/value_model.dart';
import '../utils/mon_pays_colors.dart';
import '../utils/mon_pays_text_styles.dart';

class ValueCard extends StatelessWidget {
  final Value value;
  final VoidCallback? onTap;

  const ValueCard({Key? key, required this.value, this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                MonPaysColors.primaryRed.withOpacity(0.05),
                MonPaysColors.primaryBlue.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                value.iconCode != null
                    ? IconData(int.parse(value.iconCode!), fontFamily: 'MaterialIcons')
                    : Icons.library_books,
                color: MonPaysColors.primaryRed,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                value.title,
                style: MonPaysTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: MonPaysColors.primaryBlue,
                  fontSize: 12,
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
