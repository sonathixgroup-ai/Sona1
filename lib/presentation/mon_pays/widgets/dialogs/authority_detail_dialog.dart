// lib/presentation/mon_pays/widgets/dialogs/authority_detail_dialog.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../models/authority_model.dart';

class AuthorityDetailDialog extends StatelessWidget {
  final Authority authority;

  const AuthorityDetailDialog({Key? key, required this.authority})
      : super(key: key);

  static Future<void> show(
    BuildContext context,
    Authority authority,
  ) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AuthorityDetailDialog(authority: authority),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar / Photo
            CircleAvatar(
              radius: 60,
              backgroundImage: authority.photoUrl != null
                  ? NetworkImage(authority.photoUrl!)
                  : null,
              backgroundColor: AppColors.primaryRed.withOpacity(0.1),
              child: authority.photoUrl == null
                  ? Text(
                      authority.name[0].toUpperCase(),
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.primaryRed,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 16),

            // Nom
            Text(
              authority.name,
              style: AppTextStyles.heading4.copyWith(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            // Fonction
            Text(
              authority.title,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primaryRed,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (authority.party != null) ...[
              const SizedBox(height: 4),
              Text(
                authority.party!,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
            // Biographie
            if (authority.biography != null)
              Text(
                authority.biography!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 24),

            // Bouton Fermer
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
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
}
