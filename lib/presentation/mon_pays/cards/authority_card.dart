// lib/presentation/mon_pays/cards/authority_card.dart

import 'package:flutter/material.dart';
import '../models/authority_model.dart';
import '../utils/mon_pays_colors.dart';
import '../utils/mon_pays_text_styles.dart';

class AuthorityCard extends StatelessWidget {
  final Authority authority;
  final VoidCallback? onTap;

  const AuthorityCard({Key? key, required this.authority, this.onTap})
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
              CircleAvatar(
                radius: 35,
                backgroundImage:
                    authority.photoUrl != null ? NetworkImage(authority.photoUrl!) : null,
                backgroundColor: MonPaysColors.primaryRed.withOpacity(0.1),
                child: authority.photoUrl == null
                    ? Text(
                        authority.name[0].toUpperCase(),
                        style: MonPaysTextStyles.heading4.copyWith(
                          color: MonPaysColors.primaryRed,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 8),
              Text(
                authority.name,
                style: MonPaysTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: MonPaysColors.primaryBlue,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                authority.title,
                style: MonPaysTextStyles.caption.copyWith(
                  color: MonPaysColors.textSecondary,
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
