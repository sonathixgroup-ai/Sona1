// presentation/thix_sante/patient/details/patient_consent_page.dart
import 'package:flutter/material.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';

class PatientConsentPage extends StatefulWidget {
  final String? consentId;
  const PatientConsentPage({super.key, this.consentId});

  @override
  State<PatientConsentPage> createState() => _PatientConsentPageState();
}

class _PatientConsentPageState extends State<PatientConsentPage> {
  // Simuler des consentements
  final List<Consent> _consents = [
    Consent(
      id: 'c1',
      patientId: 'p1',
      type: 'Partage de données médicales',
      granted: true,
      date: DateTime.now().subtract(const Duration(days: 10)),
    ),
    Consent(
      id: 'c2',
      patientId: 'p1',
      type: 'Communications marketing',
      granted: false,
      date: DateTime.now().subtract(const Duration(days: 20)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (widget.consentId != null) {
      final consent = _consents.firstWhere((c) => c.id == widget.consentId);
      return Scaffold(
        appBar: AppBar(title: const Text('Détail consentement')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: Icon(consent.granted ? Icons.check_circle : Icons.cancel, color: consent.granted ? Colors.green : Colors.red),
                title: Text(consent.type),
                subtitle: Text('Statut : ${consent.granted ? 'Accepté' : 'Refusé'}'),
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Date'),
                subtitle: Text(consent.date.toLocal().toString().split(' ')[0]),
              ),
              SwitchListTile(
                title: const Text('Modifier le consentement'),
                value: consent.granted,
                onChanged: (value) {
                  // Simuler mise à jour
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Consentement ${value ? 'accepté' : 'refusé'} (simulé)')),
                  );
                },
              ),
            ],
          ),
        ),
      );
    }

    // Liste
    return Scaffold(
      appBar: AppBar(title: const Text('Consentements RGPD')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _consents.length,
        itemBuilder: (context, index) {
          final c = _consents[index];
          return Card(
            child: ListTile(
              leading: Icon(c.granted ? Icons.check_circle : Icons.cancel, color: c.granted ? Colors.green : Colors.red),
              title: Text(c.type),
              subtitle: Text('${c.date.toLocal().toString().split(' ')[0]}'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                context.push('/sante/patient/consent/${c.id}');
              },
            ),
          );
        },
      ),
    );
  }
}
