// lib/presentation/mon_pays/cards/citizen_card.dart

import 'package:flutter/material.dart';
import '../models/citizen_model.dart';
import '../utils/mon_pays_colors.dart';
import '../utils/mon_pays_text_styles.dart';

class CitizenCard extends StatelessWidget {
  final ExemplaryCitizen citizen;
  final VoidCallback? onTap;

  const CitizenCard({Key? key, required this.citizen, this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 170,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 35,
                backgroundImage:
                    citizen.photoUrl != null ? NetworkImage(citizen.photoUrl!) : null,
                backgroundColor: MonPaysColors.primaryBlue.withOpacity(0.1),
                child: citizen.photoUrl == null
                    ? Text(
                        citizen.name[0].toUpperCase(),
                        style: MonPaysTextStyles.heading4.copyWith(
                          color: MonPaysColors.primaryBlue,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 8),
              Text(
                citizen.name,
                style: MonPaysTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: MonPaysColors.primaryBlue,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                citizen.occupation,
                style: MonPaysTextStyles.caption.copyWith(
                  color: MonPaysColors.textSecondary,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (citizen.quote != null) ...[
                const SizedBox(height: 6),
                Text(
                  '"${citizen.quote}"',
                  style: MonPaysTextStyles.caption.copyWith(
                    fontStyle: FontStyle.italic,
                    color: MonPaysColors.primaryRed,
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
