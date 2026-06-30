// presentation/thix_sante/doctor/details/doctor_alert_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DoctorAlertPage extends StatefulWidget {
  final String? patientName;
  const DoctorAlertPage({super.key, this.patientName});

  @override
  State<DoctorAlertPage> createState() => _DoctorAlertPageState();
}

class _DoctorAlertPageState extends State<DoctorAlertPage> {
  final List<Map<String, dynamic>> _alerts = [
    {'patient': 'Jean P.', 'risk': 'Élevé', 'message': 'Tension artérielle anormalement haute (160/95)', 'critical': true},
    {'patient': 'Marie D.', 'risk': 'Modéré', 'message': 'Non-observance du traitement antihypertenseur', 'critical': false},
    {'patient': 'Luc R.', 'risk': 'Faible', 'message': 'Consultation de suivi recommandée', 'critical': false},
  ];

  @override
  Widget build(BuildContext context) {
    if (widget.patientName != null) {
      // Détail des alertes pour un patient spécifique
      final patientAlerts = _alerts.where((a) => a['patient'] == widget.patientName).toList();
      return Scaffold(
        appBar: AppBar(title: Text('Alertes - ${widget.patientName}')),
        body: patientAlerts.isEmpty
            ? const Center(child: Text('Aucune alerte pour ce patient.'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: patientAlerts.length,
                itemBuilder: (context, index) {
                  final a = patientAlerts[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        a['critical'] ? Icons.crisis_alert : Icons.warning,
                        color: a['critical'] ? Colors.red : Colors.orange,
                      ),
                      title: Text(a['message']),
                      subtitle: Text('Risque : ${a['risk']}'),
                    ),
                  );
                },
              ),
      );
    }

    // Liste de toutes les alertes
    return Scaffold(
      appBar: AppBar(title: const Text('Alertes patients')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _alerts.length,
        itemBuilder: (context, index) {
          final a = _alerts[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(
                a['critical'] ? Icons.crisis_alert : Icons.warning,
                color: a['critical'] ? Colors.red : Colors.orange,
              ),
              title: Text(a['patient']),
              subtitle: Text('${a['message']} • Risque : ${a['risk']}'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                context.push('/sante/doctor/alert/${a['patient']}');
              },
            ),
          );
        },
      ),
    );
  }
}
