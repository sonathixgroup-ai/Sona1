// lib/presentation/mon_pays/cards/wanted_person_card.dart

import 'package:flutter/material.dart';
import '../models/wanted_person_model.dart';
import '../utils/mon_pays_colors.dart';
import '../utils/mon_pays_text_styles.dart';
import '../enums/wanted_status.dart';

class WantedPersonCard extends StatelessWidget {
  final WantedPerson person;
  final VoidCallback? onTap;
  final VoidCallback? onReport;

  const WantedPersonCard({
    Key? key,
    required this.person,
    this.onTap,
    this.onReport,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDangerous = person.status == WantedStatus.dangereuse;
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: isDangerous ? MonPaysColors.primaryRed.withOpacity(0.05) : Colors.white,
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage:
                        person.photoUrl != null ? NetworkImage(person.photoUrl!) : null,
                    backgroundColor: MonPaysColors.primaryRed.withOpacity(0.1),
                    child: person.photoUrl == null
                        ? Text(
                            person.name[0].toUpperCase(),
                            style: MonPaysTextStyles.heading4.copyWith(
                              color: MonPaysColors.primaryRed,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          person.name,
                          style: MonPaysTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: MonPaysColors.primaryBlue,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (person.alias != null)
                          Text(
                            'Alias: ${person.alias}',
                            style: MonPaysTextStyles.caption.copyWith(
                              color: MonPaysColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Motif: ${person.reason}',
                style: MonPaysTextStyles.caption.copyWith(
                  color: MonPaysColors.textSecondary,
                  fontSize: 11,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${person.province} - ${person.date}',
                      style: MonPaysTextStyles.caption.copyWith(
                        color: MonPaysColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getAlertColor(person.alertLevel),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Niv. ${person.alertLevel}',
                      style: MonPaysTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDangerous
                        ? MonPaysColors.primaryRed
                        : MonPaysColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Signaler',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getAlertColor(int level) {
    if (level >= 4) return Colors.red;
    if (level >= 2) return Colors.orange;
    return Colors.yellow.shade700;
  }
}
