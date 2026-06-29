// 📁 lib/presentation/thix_sante/doctor/screens/doctor_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/alert_card.dart';
import '../widgets/upcoming_consultations.dart';
import '../widgets/teleexpertise_request_card.dart';
import '../../../common/widgets/stat_card.dart';

class DoctorDashboardScreen extends ConsumerWidget {
  const DoctorDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Données simulées (à connecter aux providers)
    final consultations = [
      {'patientName': 'Michel Dupont', 'date': '18/12/2024', 'time': '14h30', 'type': 'visio'},
      {'patientName': 'Sophie Martin', 'date': '18/12/2024', 'time': '16h00', 'type': 'presentiel'},
      {'patientName': 'Lucas Bernard', 'date': '19/12/2024', 'time': '09h30', 'type': 'visio'},
    ];

    final alerts = [
      {'patientName': 'Julie Petit', 'message': 'Glycémie élevée (2.1 g/L)', 'severity': AlertSeverity.high},
      {'patientName': 'Paul Moreau', 'message': 'Tension anormale (165/95)', 'severity': AlertSeverity.medium},
    ];

    final teleexpertiseRequests = [
      {'patientName': 'Emma Dubois', 'description': 'Éruption cutanée sur le bras depuis 3 jours', 'date': '17/12/2024'},
      {'patientName': 'Thomas Leroy', 'description': 'Douleur thoracique à l\'effort', 'date': '16/12/2024'},
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            title: Text('Tableau de bord'),
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: false,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Stats
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: 'Patients',
                        value: '24',
                        icon: Icons.people,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        label: 'Consultations',
                        value: '12',
                        trend: 8.5,
                        icon: Icons.calendar_today,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        label: 'Alertes',
                        value: '${alerts.length}',
                        icon: Icons.warning_amber,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Alertes
                if (alerts.isNotEmpty) ...[
                  const Text('⚠️ Alertes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ...alerts.map((a) => AlertCard(
                    patientName: a['patientName']!,
                    message: a['message']!,
                    severity: a['severity']!,
                    onView: () {},
                  )),
                  const SizedBox(height: 20),
                ],
                // Demandes de téléexpertise
                if (teleexpertiseRequests.isNotEmpty) ...[
                  const Text('📩 Demandes de téléexpertise', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ...teleexpertiseRequests.map((r) => TeleexpertiseRequestCard(
                    patientName: r['patientName']!,
                    description: r['description']!,
                    date: r['date']!,
                    onAccept: () {},
                    onDecline: () {},
                  )),
                  const SizedBox(height: 20),
                ],
                // Consultations à venir
                UpcomingConsultations(consultations: consultations),
                const SizedBox(height: 20),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
