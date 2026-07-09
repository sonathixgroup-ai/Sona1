// lib/presentation/mon_pays/widgets/header/profile_avatar.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class ProfileAvatar extends StatelessWidget {
  final VoidCallback? onTap;
  final String? imageUrl;
  final String name; // pour initiales

  const ProfileAvatar({
    Key? key,
    this.onTap,
    this.imageUrl,
    this.name = 'Citoyen',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 20,
        backgroundColor: AppColors.primaryRed.withOpacity(0.1),
        backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
        child: imageUrl == null
            ? Text(
                _getInitials(name),
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.primaryRed,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
    );
  }

  String _getInitials(String fullName) {
    final names = fullName.trim().split(' ');
    if (names.length == 1) {
      return names[0][0].toUpperCase();
    }
    return '${names[0][0]}${names.last[0]}'.toUpperCase();
  }
}
