// 📁 lib/presentation/thix_sante/patient/screens/patient_notifications_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../common/widgets/empty_state.dart';
import '../../../common/widgets/pill_badge.dart';

class PatientNotificationsScreen extends ConsumerWidget {
  const PatientNotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Simulons des notifications (à connecter au provider alertProvider)
    final notifications = [
      {'title': 'Rappel médicament', 'message': 'Prenez votre traitement', 'date': 'Aujourd\'hui 14h30', 'read': false, 'type': 'medication'},
      {'title': 'Résultat d\'analyse', 'message': 'Vos résultats sont disponibles', 'date': 'Hier', 'read': true, 'type': 'analysis'},
      {'title': 'Alerte sanitaire', 'message': 'Épidémie de grippe dans votre région', 'date': '02/12/2024', 'read': true, 'type': 'alert'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (notifications.where((n) => !n['read']).isNotEmpty)
            TextButton(
              onPressed: () {},
              child: const Text('Tout marquer lu', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? const EmptyStateWidget(
              title: 'Aucune notification',
              subtitle: 'Vous serez informé des actualités',
              icon: Icons.notifications_none,
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final n = notifications[index];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: n['read'] ? Colors.white : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: n['type'] == 'medication' ? Colors.green.shade100 : (n['type'] == 'analysis' ? Colors.purple.shade100 : Colors.orange.shade100),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          n['type'] == 'medication' ? Icons.medication : (n['type'] == 'analysis' ? Icons.science : Icons.warning),
                          size: 20,
                          color: n['type'] == 'medication' ? Colors.green : (n['type'] == 'analysis' ? Colors.purple : Colors.orange),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(n['title'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(n['message'], style: const TextStyle(fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(n['date'], style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                          ],
                        ),
                      ),
                      if (!n['read']) const PillBadge(text: 'Nouveau', color: Colors.red, fontSize: 10),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
