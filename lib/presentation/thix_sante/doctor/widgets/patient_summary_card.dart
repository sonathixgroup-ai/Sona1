// 📁 lib/presentation/thix_sante/doctor/widgets/patient_summary_card.dart

import 'package:flutter/material.dart';
import '../../../common/widgets/pill_badge.dart';

class PatientSummaryCard extends StatelessWidget {
  final String patientName;
  final int age;
  final String bloodType;
  final List<String> allergies;
  final String lastVisit;

  const PatientSummaryCard({
    Key? key,
    required this.patientName,
    required this.age,
    required this.bloodType,
    required this.allergies,
    required this.lastVisit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    patientName.isNotEmpty ? patientName[0].toUpperCase() : 'P',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(patientName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('$age ans • $bloodType', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('Dernière visite: $lastVisit', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (allergies.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            const Text('Allergies', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: allergies.map((a) => PillBadge(text: a, color: Colors.red, fontSize: 10)).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
