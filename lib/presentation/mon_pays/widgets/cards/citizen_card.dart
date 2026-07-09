// lib/presentation/mon_pays/widgets/cards/citizen_card.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../models/exemplary_citizen_model.dart';

class CitizenCard extends StatelessWidget {
  final ExemplaryCitizen citizen;
  final VoidCallback? onTap;

  const CitizenCard({
    Key? key,
    required this.citizen,
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
          width: 170,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 35,
                backgroundImage: citizen.photoUrl != null
                    ? NetworkImage(citizen.photoUrl!)
                    : null,
                backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                child: citizen.photoUrl == null
                    ? Text(
                        citizen.name[0].toUpperCase(),
                        style: AppTextStyles.heading4.copyWith(
                          color: AppColors.primaryBlue,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 8),
              Text(
                citizen.name,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                citizen.occupation,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (citizen.quote != null) ...[
                const SizedBox(height: 6),
                Text(
                  '"${citizen.quote}"',
                  style: AppTextStyles.caption.copyWith(
                    fontStyle: FontStyle.italic,
                    color: AppColors.primaryRed,
                    fontSize: 10,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
