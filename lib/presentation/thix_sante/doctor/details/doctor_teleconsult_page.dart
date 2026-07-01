// presentation/thix_sante/doctor/details/doctor_teleconsult_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_teleconsultation_jitsi_page.dart';

class DoctorTeleconsultPage extends StatefulWidget {
  final String? consultationId;
  const DoctorTeleconsultPage({super.key, this.consultationId});

  @override
  State<DoctorTeleconsultPage> createState() => _DoctorTeleconsultPageState();
}

class _DoctorTeleconsultPageState extends State<DoctorTeleconsultPage> {
  final List<Map<String, dynamic>> _consultations = [
    {'patientName': 'Michel L.', 'date': 'Aujourd\'hui 14:00', 'link': 'https://meet.jit.si/consult1'},
    {'patientName': 'Sophie M.', 'date': 'Demain 10:30', 'link': 'https://meet.jit.si/consult2'},
  ];

  void _createConsultation() {
    // Simuler création
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lien de téléconsultation généré (simulé)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Téléconsultation')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.videocam, size: 48, color: Colors.purple),
                  SizedBox(height: 8),
                  Text('Téléconsultation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Créez un lien Jitsi pour consulter vos patients à distance'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Consultations à venir', style: TextStyle(fontWeight: FontWeight.bold)),
          ..._consultations.map((c) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person), backgroundColor: Colors.purple),
                  title: Text(c['patientName']),
                  subtitle: Text(c['date']),
                  trailing: ElevatedButton(
                    onPressed: () {
                      context.push('/sante/doctor/teleconsultation/jitsi', extra: c['link']);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
                    child: const Text('Rejoindre'),
                  ),
                ),
              )),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _createConsultation,
            icon: const Icon(Icons.add),
            label: const Text('Créer une téléconsultation'),
          ),
        ],
      ),
    );
  }
}
