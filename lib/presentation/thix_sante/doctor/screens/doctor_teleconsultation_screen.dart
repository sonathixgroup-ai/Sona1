// 📁 lib/presentation/thix_sante/doctor/screens/doctor_teleconsultation_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../common/widgets/gradient_button.dart';
import '../../../common/widgets/section_title.dart';
import '../../../common/widgets/pill_badge.dart';

class DoctorTeleconsultationScreen extends ConsumerStatefulWidget {
  const DoctorTeleconsultationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DoctorTeleconsultationScreen> createState() => _DoctorTeleconsultationScreenState();
}

class _DoctorTeleconsultationScreenState extends ConsumerState<DoctorTeleconsultationScreen> {
  final List<Map<String, dynamic>> _calls = [
    {'patient': 'Michel Dupont', 'time': '14h30', 'status': 'en_cours', 'type': 'visio'},
    {'patient': 'Sophie Martin', 'time': '16h00', 'status': 'programmé', 'type': 'visio'},
    {'patient': 'Lucas Bernard', 'time': 'Demain 09h30', 'status': 'programmé', 'type': 'visio'},
  ];

  @override
  Widget build(BuildContext context) {
    final current = _calls.where((c) => c['status'] == 'en_cours').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Téléconsultations'),
        actions: [
          IconButton(icon: const Icon(Icons.history), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (current.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.green.shade700, Colors.green.shade500]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🟢 Consultation en cours',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(current[0]['patient'], style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(current[0]['time'], style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 16),
                    GradientButton(
                      text: '🎥 Rejoindre',
                      onPressed: () {
                        // Lancer appel Jitsi
                      },
                      gradient: const LinearGradient(colors: [Colors.white, Colors.white70]),
                      textColor: Colors.green,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            SectionTitle(title: 'Consultations à venir', seeAllText: 'Voir tout', showDivider: false),
            const SizedBox(height: 8),
            ..._calls.where((c) => c['status'] == 'programmé').map((c) => Container(
              margin: const EdgeInsets.only(bottom: 10),
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
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.video_call, size: 20, color: Colors.purple),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c['patient'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        Text(c['time'], style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  PillBadge(text: 'Programmé', color: Colors.blue),
                  const SizedBox(width: 8),
                  GradientButton(
                    text: 'Démarrer',
                    onPressed: () {},
                    width: 80,
                    height: 34,
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
