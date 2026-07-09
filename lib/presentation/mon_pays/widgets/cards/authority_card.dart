// lib/presentation/mon_pays/widgets/cards/authority_card.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../models/authority_model.dart';

class AuthorityCard extends StatelessWidget {
  final Authority authority;
  final VoidCallback? onTap;

  const AuthorityCard({
    Key? key,
    required this.authority,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 150,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                AppColors.primaryWhite,
                AppColors.primaryRed.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 35,
                backgroundImage: authority.photoUrl != null
                    ? NetworkImage(authority.photoUrl!)
                    : null,
                backgroundColor: AppColors.primaryRed.withOpacity(0.1),
                child: authority.photoUrl == null
                    ? Text(
                        authority.name[0].toUpperCase(),
                        style: AppTextStyles.heading4.copyWith(
                          color: AppColors.primaryRed,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 10),
              Text(
                authority.name,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                authority.title,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
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
