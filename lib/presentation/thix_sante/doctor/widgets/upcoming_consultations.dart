// 📁 lib/presentation/thix_sante/doctor/widgets/upcoming_consultations.dart

import 'package:flutter/material.dart';
import '../../../common/widgets/section_title.dart';
import '../../../common/widgets/pill_badge.dart';

class UpcomingConsultations extends StatelessWidget {
  final List<Map<String, dynamic>> consultations;

  const UpcomingConsultations({Key? key, required this.consultations}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (consultations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        const SectionTitle(title: 'Consultations à venir', seeAllText: 'Voir tout', showDivider: false),
        const SizedBox(height: 8),
        ...consultations.map((c) => Container(
          margin: const EdgeInsets.only(bottom: 8),
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
                  color: c['type'] == 'visio' ? Colors.purple.shade50 : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(c['type'] == 'visio' ? Icons.video_call : Icons.local_hospital, size: 20, color: c['type'] == 'visio' ? Colors.purple : Colors.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c['patientName'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    Text('${c['time']} • ${c['date']}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              PillBadge(text: c['type'] == 'visio' ? 'Visio' : 'Présentiel', color: c['type'] == 'visio' ? Colors.purple : Colors.blue, fontSize: 10),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.videocam, size: 18),
                onPressed: c['type'] == 'visio' ? () {} : null,
                color: c['type'] == 'visio' ? Colors.green : Colors.grey,
              ),
            ],
          ),
        )),
      ],
    );
  }
}
