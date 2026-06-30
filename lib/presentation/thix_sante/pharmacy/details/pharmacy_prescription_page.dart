// presentation/thix_sante/pharmacy/details/pharmacy_prescription_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';

class PharmacyPrescriptionPage extends StatefulWidget {
  final String prescriptionId;
  const PharmacyPrescriptionPage({super.key, required this.prescriptionId});

  @override
  State<PharmacyPrescriptionPage> createState() => _PharmacyPrescriptionPageState();
}

class _PharmacyPrescriptionPageState extends State<PharmacyPrescriptionPage> {
  Prescription? _prescription;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrescription();
  }

  void _loadPrescription() {
    // Simuler chargement
    _prescription = Prescription(
      id: widget.prescriptionId,
      patientId: 'p1',
      patientName: 'Michel L.',
      doctorId: 'doc1',
      doctorName: 'Dr. Dupont',
      date: DateTime.now().subtract(const Duration(hours: 2)),
      status: PrescriptionStatus.active,
      medications: [
        Medication(id: 'm1', name: 'Paracétamol', dosage: '500 mg', frequency: '3x/jour', startDate: DateTime.now()),
        Medication(id: 'm2', name: 'Amoxicilline', dosage: '250 mg', frequency: '2x/jour', startDate: DateTime.now()),
      ],
      notes: 'Traitement pour infection',
    );
    _isLoading = false;
  }

  void _validate(bool accept) {
    // Simuler validation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(accept ? 'Ordonnance validée' : 'Ordonnance rejetée')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Validation ordonnance')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Patient : ${_prescription!.patientName}'),
            Text('Médecin : ${_prescription!.doctorName}'),
            Text('Date : ${_prescription!.date.toLocal().toString().split(' ')[0]}'),
            const SizedBox(height: 16),
            const Text('Médicaments :', style: TextStyle(fontWeight: FontWeight.bold)),
            ..._prescription!.medications.map((med) => ListTile(
                  title: Text(med.name),
                  subtitle: Text('${med.dosage} • ${med.frequency}'),
                )),
            if (_prescription!.notes != null)
              Text('Notes : ${_prescription!.notes}'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _validate(true),
                    icon: const Icon(Icons.check),
                    label: const Text('Valider'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _validate(false),
                    icon: const Icon(Icons.close),
                    label: const Text('Rejeter'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
