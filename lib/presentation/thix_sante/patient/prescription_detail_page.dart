import 'package:flutter/material.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';

class PrescriptionDetailPage extends StatelessWidget {
  final Prescription prescription;
  const PrescriptionDetailPage({super.key, required this.prescription});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Détail ordonnance')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Médecin : ${prescription.doctorName}'),
            Text('Date : ${prescription.date.toLocal()}'),
            Text('Statut : ${prescription.status.name}'),
            const SizedBox(height: 12),
            const Text('Médicaments :', style: TextStyle(fontWeight: FontWeight.bold)),
            ...prescription.medications.map((m) => ListTile(
                  title: Text(m.name),
                  subtitle: Text('${m.dosage} - ${m.frequency}'),
                )),
          ],
        ),
      ),
    );
  }
}
