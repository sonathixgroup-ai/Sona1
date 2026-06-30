// presentation/thix_sante/pharmacy/details/pharmacy_prescription_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';
import 'package:thix_id/presentation/thix_sante/shared/services/health_services.dart';

class PharmacyPrescriptionPage extends StatefulWidget {
  final String prescriptionId;
  const PharmacyPrescriptionPage({super.key, required this.prescriptionId});

  @override
  State<PharmacyPrescriptionPage> createState() => _PharmacyPrescriptionPageState();
}

class _PharmacyPrescriptionPageState extends State<PharmacyPrescriptionPage> {
  final HealthService _healthService = HealthService.instance;
  Prescription? _prescription;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPrescription();
  }

  Future<void> _loadPrescription() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // Récupération réelle depuis le service (si la table existe)
      // Ici on simule un appel, mais on pourrait utiliser :
      // final data = await _healthService.fetchPrescriptions('patient-id');
      // Pour l'instant on garde le mock mais avec les bons champs
      await Future.delayed(const Duration(milliseconds: 300));
      _prescription = Prescription(
        id: widget.prescriptionId,
        patientId: 'p1',
        patientName: 'Michel L.',
        doctorId: 'doc1',
        doctorName: 'Dr. Dupont',
        date: DateTime.now().subtract(const Duration(hours: 2)),
        status: PrescriptionStatus.active,
        medications: [
          Medication(
            id: 'm1',
            patientId: 'p1', // PatientId ajouté (nullable)
            name: 'Paracétamol',
            dosage: '500 mg',
            frequency: '3x/jour',
            startDate: DateTime.now(),
          ),
          Medication(
            id: 'm2',
            patientId: 'p1',
            name: 'Amoxicilline',
            dosage: '250 mg',
            frequency: '2x/jour',
            startDate: DateTime.now(),
          ),
        ],
        notes: 'Traitement pour infection',
      );
    } catch (e) {
      setState(() => _error = 'Erreur de chargement : $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _validate(bool accept) {
    // Logique de validation réelle à connecter au service
    // Exemple : appeler _healthService.validatePrescription(id, accept)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(accept ? '✅ Ordonnance validée' : '❌ Ordonnance rejetée'),
        backgroundColor: accept ? Colors.green : Colors.red,
      ),
    );
    // Retour à la liste
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Validation ordonnance')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadPrescription,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    final prescription = _prescription!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation ordonnance'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Informations générales
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            'Patient : ${prescription.patientName ?? 'Inconnu'}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.medical_services, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(
                            'Médecin : ${prescription.doctorName}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.orange),
                          const SizedBox(width: 8),
                          Text(
                            'Date : ${prescription.date.toLocal().toString().split(' ')[0]}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      if (prescription.validUntil != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.hourglass_top, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(
                              'Valable jusqu\'au : ${prescription.validUntil!.toLocal().toString().split(' ')[0]}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Liste des médicaments
              const Text(
                'Médicaments prescrits :',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              ...prescription.medications.map((med) => Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: const Icon(Icons.medication, color: Colors.blue),
                      title: Text(med.name),
                      subtitle: Text('${med.dosage} • ${med.frequency}'),
                    ),
                  )),
              if (prescription.notes != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Notes :',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Card(
                  color: Colors.grey[100],
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(prescription.notes!),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              // Boutons d'action
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _validate(true),
                      icon: const Icon(Icons.check),
                      label: const Text('Valider'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _validate(false),
                      icon: const Icon(Icons.close),
                      label: const Text('Rejeter'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
