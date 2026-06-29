// 📁 lib/presentation/thix_sante/doctor/widgets/patient_list_tile.dart

import 'package:flutter/material.dart';
import '../../../../data/models/user/patient_model.dart';
import '../../../common/widgets/pill_badge.dart';

class PatientListTile extends StatelessWidget {
  final PatientModel patient;
  final VoidCallback onTap;
  final int? unreadMessages;
  final bool hasAlert;

  const PatientListTile({
    Key? key,
    required this.patient,
    required this.onTap,
    this.unreadMessages,
    this.hasAlert = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  patient.name.isNotEmpty ? patient.name[0].toUpperCase() : 'P',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(patient.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      if (hasAlert) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.warning_amber, size: 14, color: Colors.red),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    patient.email,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (patient.birthDate != null)
                        Text(
                          'Né(e) le ${patient.birthDate}',
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                        ),
                      if (patient.bloodType != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            patient.bloodType!,
                            style: TextStyle(fontSize: 9, color: Colors.grey.shade700),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Badge messages non lus
            if (unreadMessages != null && unreadMessages! > 0)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(
                  '$unreadMessages',
                  style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
