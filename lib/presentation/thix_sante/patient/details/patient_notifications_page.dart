// presentation/thix_sante/patient/details/patient_notifications_page.dart
import 'package:flutter/material.dart';

class PatientNotificationsPage extends StatefulWidget {
  const PatientNotificationsPage({super.key});

  @override
  State<PatientNotificationsPage> createState() => _PatientNotificationsPageState();
}

class _PatientNotificationsPageState extends State<PatientNotificationsPage> {
  final List<Map<String, String>> _notifications = [
    {'title': 'Rappel médicament', 'body': 'Paracétamol à prendre dans 1h', 'date': 'Aujourd\'hui 14:00'},
    {'title': 'Rendez-vous confirmé', 'body': 'Consultation avec Dr. Dupont demain 10h', 'date': 'Hier 18:30'},
    {'title': 'Résultat examen', 'body': 'Votre prise de sang est disponible', 'date': 'Il y a 2 jours'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notif = _notifications[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.notifications, color: Colors.blue),
              title: Text(notif['title']!),
              subtitle: Text('${notif['body']!} • ${notif['date']!}'),
              onTap: () {
                // Marquer comme lu
              },
            ),
          );
        },
      ),
    );
  }
}
