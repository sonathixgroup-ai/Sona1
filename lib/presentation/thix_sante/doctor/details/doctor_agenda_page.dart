// presentation/thix_sante/doctor/details/doctor_agenda_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DoctorAgendaPage extends StatefulWidget {
  const DoctorAgendaPage({super.key});

  @override
  State<DoctorAgendaPage> createState() => _DoctorAgendaPageState();
}

class _DoctorAgendaPageState extends State<DoctorAgendaPage> {
  final List<Map<String, dynamic>> _appointments = [
    {'patient': 'Michel L.', 'time': '09:00', 'type': 'Consultation'},
    {'patient': 'Sophie M.', 'time': '10:30', 'type': 'Téléconsultation'},
    {'patient': 'Jean P.', 'time': '14:00', 'type': 'Consultation'},
  ];

  void _manageSlots() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gestion des créneaux (simulé)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _manageSlots,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Aujourd\'hui', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('10/03/2024'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._appointments.map((a) => ListTile(
                          leading: const Icon(Icons.calendar_today),
                          title: Text('${a['patient']}'),
                          subtitle: Text('${a['time']} • ${a['type']}'),
                          onTap: () {
                            // Détail rendez-vous
                          },
                        )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _manageSlots,
              icon: const Icon(Icons.add),
              label: const Text('Gérer les créneaux'),
            ),
          ],
        ),
      ),
    );
  }
}
