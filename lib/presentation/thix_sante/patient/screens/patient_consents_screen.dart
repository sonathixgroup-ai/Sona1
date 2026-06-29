// 📁 lib/presentation/thix_sante/patient/screens/patient_consents_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../common/widgets/pill_badge.dart';

class PatientConsentsScreen extends ConsumerStatefulWidget {
  const PatientConsentsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PatientConsentsScreen> createState() => _PatientConsentsScreenState();
}

class _PatientConsentsScreenState extends ConsumerState<PatientConsentsScreen> {
  final List<Map<String, dynamic>> _consents = [
    {'name': 'Dr. Martin', 'role': 'Médecin traitant', 'access': 'Complet', 'expires': 'Jamais', 'status': 'active'},
    {'name': 'Pharmacie Dubois', 'role': 'Pharmacie', 'access': 'Ordonnances', 'expires': '31/12/2024', 'status': 'active'},
    {'name': 'Dr. Bernard', 'role': 'Cardiologue', 'access': 'Lecture seule', 'expires': '15/01/2025', 'status': 'active'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Consentements et partages')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _consents.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final c = _consents[index];
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
                    Text(c['name'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    PillBadge(text: c['access'], color: Colors.blue, fontSize: 10),
                  ],
                ),
                const SizedBox(height: 4),
                Text(c['role'], style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text('Expire: ${c['expires']}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: const Text('Révoquer', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
} 
