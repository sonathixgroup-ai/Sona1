// lib/presentation/mon_pays/cards/consultation_card.dart

import 'package:flutter/material.dart';
import '../models/consultation_model.dart';
import '../utils/mon_pays_colors.dart';
import '../utils/mon_pays_text_styles.dart';

class ConsultationCard extends StatelessWidget {
  final Consultation consultation;
  final VoidCallback? onTap;

  const ConsultationCard({Key? key, required this.consultation, this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: MonPaysColors.primaryRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.poll,
              color: MonPaysColors.primaryRed,
            ),
          ),
          title: Text(
            consultation.title,
            style: MonPaysTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            'Jusqu\'au ${consultation.endDate}',
            style: MonPaysTextStyles.caption.copyWith(
              color: MonPaysColors.textSecondary,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: consultation.isActive ? Colors.green : Colors.grey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  consultation.isActive ? 'Active' : 'Fermée',
                  style: MonPaysTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: MonPaysColors.primaryRed,
              ),
            ],
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
