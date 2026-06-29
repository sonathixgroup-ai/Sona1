// 📁 lib/presentation/thix_sante/patient/widgets/upcoming_appointments.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../common/widgets/section_title.dart';
import '../../../common/widgets/pill_badge.dart';

class UpcomingAppointments extends ConsumerWidget {
  const UpcomingAppointments({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // À remplacer par un vrai provider d'appointments
    final appointments = [
      {'doctor': 'Dr. Martin', 'specialty': 'Cardiologue', 'date': 'Lundi 18 déc', 'time': '14h30'},
      {'doctor': 'Dr. Bernard', 'specialty': 'Généraliste', 'date': 'Mercredi 20 déc', 'time': '09h00'},
    ];

    if (appointments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        const SectionTitle(title: 'Prochains rendez-vous', seeAllText: 'Voir tout', showDivider: false),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: appointments.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final apt = appointments[index];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.calendar_month, size: 20, color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(apt['doctor']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        Text(apt['specialty']!, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                        Text('${apt['date']} à ${apt['time']}', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                  const PillBadge(text: 'À venir', color: Colors.orange),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
