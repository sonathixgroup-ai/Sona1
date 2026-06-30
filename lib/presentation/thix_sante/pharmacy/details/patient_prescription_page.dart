// presentation/thix_sante/patient/details/patient_prescription_page.dart
import 'package:flutter/material.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';
import 'package:thix_id/presentation/thix_sante/shared/services/health_services.dart';

class PatientPrescriptionPage extends StatefulWidget {
  final String prescriptionId;
  const PatientPrescriptionPage({super.key, required this.prescriptionId});

  @override
  State<PatientPrescriptionPage> createState() => _PatientPrescriptionPageState();
}

class _PatientPrescriptionPageState extends State<PatientPrescriptionPage> {
  final HealthService _service = HealthService.instance;
  Prescription? _prescription;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final all = await _service.fetchPrescriptions('patient-123');
      final found = all.firstWhere((p) => p.id == widget.prescriptionId);
      setState(() {
        _prescription = found;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Détail ordonnance')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Médecin'),
                    subtitle: Text(_prescription!.doctorName),
                  ),
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Date'),
                    subtitle: Text(_prescription!.date.toLocal().toString().split(' ')[0]),
                  ),
                  ListTile(
                    leading: const Icon(Icons.receipt),
                    title: const Text('Statut'),
                    subtitle: Text(_prescription!.status.name),
                  ),
                  const Divider(),
                  const Text('Médicaments', style: TextStyle(fontWeight: FontWeight.bold)),
                  ..._prescription!.medications.map((med) => ListTile(
                        leading: const Icon(Icons.medication),
                        title: Text(med.name),
                        subtitle: Text('${med.dosage} - ${med.frequency}'),
                      )),
                  if (_prescription!.notes != null)
                    ListTile(
                      leading: const Icon(Icons.note),
                      title: const Text('Notes'),
                      subtitle: Text(_prescription!.notes!),
                    ),
                ],
              ),
            ),
    );
  }
}
