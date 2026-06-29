// 📁 lib/presentation/thix_sante/patient/screens/patient_appointments_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../common/widgets/gradient_button.dart';
import '../../../common/widgets/empty_state.dart';
import '../../../common/widgets/pill_badge.dart';

class PatientAppointmentsScreen extends ConsumerStatefulWidget {
  const PatientAppointmentsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PatientAppointmentsScreen> createState() => _PatientAppointmentsScreenState();
}

class _PatientAppointmentsScreenState extends ConsumerState<PatientAppointmentsScreen> {
  final List<Map<String, dynamic>> _appointments = [
    {'doctor': 'Dr. Martin', 'specialty': 'Cardiologue', 'date': DateTime(2024, 12, 18), 'time': '14h30', 'type': 'visio', 'status': 'confirmed'},
    {'doctor': 'Dr. Bernard', 'specialty': 'Généraliste', 'date': DateTime(2024, 12, 22), 'time': '09h00', 'type': 'presentiel', 'status': 'pending'},
  ];

  @override
  Widget build(BuildContext context) {
    final upcoming = _appointments.where((a) => (a['date'] as DateTime).isAfter(DateTime.now())).toList();
    final past = _appointments.where((a) => (a['date'] as DateTime).isBefore(DateTime.now())).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes rendez-vous'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showNewAppointmentDialog(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (upcoming.isNotEmpty) ...[
              const Text('📅 À venir', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...upcoming.map((a) => _buildAppointmentCard(a)),
              const SizedBox(height: 20),
            ],
            if (past.isNotEmpty) ...[
              const Text('📜 Historique', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...past.map((a) => _buildAppointmentCard(a, isPast: true)),
            ],
            if (_appointments.isEmpty)
              const EmptyStateWidget(
                title: 'Aucun rendez-vous',
                subtitle: 'Prenez votre premier rendez-vous',
                icon: Icons.calendar_today,
              ),
            const SizedBox(height: 16),
            GradientButton(
              text: 'Prendre un rendez-vous',
              onPressed: () => _showNewAppointmentDialog(),
              icon: Icons.calendar_month,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> apt, {bool isPast = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: apt['type'] == 'visio' ? Colors.purple.shade50 : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(apt['type'] == 'visio' ? Icons.video_call : Icons.local_hospital, size: 22, color: apt['type'] == 'visio' ? Colors.purple : Colors.blue),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(apt['doctor'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                Text(apt['specialty'], style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                Text(
                  '${(apt['date'] as DateTime).day}/${(apt['date'] as DateTime).month}/${(apt['date'] as DateTime).year} à ${apt['time']}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          if (!isPast) ...[
            if (apt['status'] == 'confirmed')
              const PillBadge(text: 'Confirmé', color: Colors.green)
            else
              const PillBadge(text: 'En attente', color: Colors.orange),
            const SizedBox(width: 8),
            if (apt['type'] == 'visio')
              GradientButton(
                text: 'Rejoindre',
                onPressed: () {},
                width: 80,
                height: 32,
              ),
          ] else
            const PillBadge(text: 'Passé', color: Colors.grey),
        ],
      ),
    );
  }

  void _showNewAppointmentDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Nouveau rendez-vous', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(labelText: 'Médecin', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(labelText: 'Date (DD/MM/YYYY)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(labelText: 'Heure', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            GradientButton(
              text: 'Confirmer',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
