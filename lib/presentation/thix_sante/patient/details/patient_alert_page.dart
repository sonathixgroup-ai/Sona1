// presentation/thix_sante/patient/details/patient_alert_page.dart
import 'package:flutter/material.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';
import 'package:thix_id/presentation/thix_sante/shared/services/health_services.dart';

class PatientAlertPage extends StatefulWidget {
  final String? alertId;
  const PatientAlertPage({super.key, this.alertId});

  @override
  State<PatientAlertPage> createState() => _PatientAlertPageState();
}

class _PatientAlertPageState extends State<PatientAlertPage> {
  final HealthService _service = HealthService.instance;
  List<HealthAlert> _alerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final list = await _service.fetchHealthAlerts('patient-123');
      setState(() {
        _alerts = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.alertId != null) {
      // Détail d'une alerte spécifique
      final alert = _alerts.firstWhere((a) => a.id == widget.alertId);
      return Scaffold(
        appBar: AppBar(title: Text(alert.title)),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(alert.severityIcon, color: alert.severityColor),
                  const SizedBox(width: 8),
                  Chip(label: Text(alert.severity.name), backgroundColor: alert.severityColor.withOpacity(0.2)),
                ],
              ),
              const SizedBox(height: 16),
              Text(alert.description),
              const SizedBox(height: 16),
              Text('Source : ${alert.source ?? 'Inconnue'}'),
              Text('Date : ${alert.date.toLocal().toString().split(' ')[0]}'),
            ],
          ),
        ),
      );
    }

    // Liste des alertes
    return Scaffold(
      appBar: AppBar(title: const Text('Alertes sanitaires')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _alerts.length,
              itemBuilder: (context, index) {
                final alert = _alerts[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(alert.severityIcon, color: alert.severityColor),
                    title: Text(alert.title),
                    subtitle: Text(alert.description),
                    trailing: Chip(label: Text(alert.severity.name), backgroundColor: alert.severityColor.withOpacity(0.2)),
                    onTap: () {
                      context.push('/sante/patient/alert/${alert.id}');
                    },
                  ),
                );
              },
            ),
    );
  }
}
