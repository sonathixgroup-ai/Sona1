// lib/presentation/mon_pays/widgets/shared/section_title.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? seeAllText;
  final VoidCallback? onSeeAll;
  final bool showDivider;

  const SectionTitle({
    Key? key,
    required this.title,
    this.subtitle,
    this.seeAllText,
    this.onSeeAll,
    this.showDivider = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.heading6.copyWith(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (seeAllText != null && onSeeAll != null)
                GestureDetector(
                  onTap: onSeeAll,
                  child: Row(
                    children: [
                      Text(
                        seeAllText!,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primaryRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: AppColors.primaryRed,
                        size: 12,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (showDivider) ...[
            const SizedBox(height: 8),
            Container(
              height: 2,
              width: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryRed, AppColors.primaryBlue],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
