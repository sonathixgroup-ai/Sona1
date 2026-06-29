// 📁 lib/presentation/thix_sante/common/screens/teleconsultation_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/health_card.dart';

class TeleconsultationScreen extends ConsumerStatefulWidget {
  const TeleconsultationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TeleconsultationScreen> createState() => _TeleconsultationScreenState();
}

class _TeleconsultationScreenState extends ConsumerState<TeleconsultationScreen> {
  final List<Map<String, dynamic>> _upcoming = [
    {'doctor': 'Dr. Martin', 'specialty': 'Cardiologue', 'date': '18 déc 2024', 'time': '14h30', 'type': 'visio'},
    {'doctor': 'Dr. Bernard', 'specialty': 'Généraliste', 'date': '22 déc 2024', 'time': '09h00', 'type': 'visio'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Téléconsultation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {},
            tooltip: 'Historique',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Consultation express
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.green, Colors.greenAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Consultation immédiate',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Un médecin disponible dans les 30 min',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  GradientButton(
                    text: '🎥 Démarrer une consultation',
                    onPressed: () => _startCall(),
                    gradient: const LinearGradient(colors: [Colors.white, Colors.white70]),
                    textColor: Colors.green,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '📅 Prochains rendez-vous',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ..._upcoming.map((rdv) => HealthCard(
              title: rdv['doctor'],
              value: '${rdv['specialty']} • ${rdv['date']} à ${rdv['time']}',
              icon: Icons.video_call,
              iconColor: Colors.blue,
              onTap: () => _joinCall(rdv),
            )),
            const SizedBox(height: 16),
            Center(
              child: TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.calendar_month, size: 16),
                label: const Text('Prendre un rendez-vous', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startCall() {
    // Intégration Jitsi Meet à implémenter
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lancement de l\'appel...'), backgroundColor: Colors.green),
    );
  }

  void _joinCall(Map<String, dynamic> rdv) {
    // Rejoindre une consultation existante
  }
}
