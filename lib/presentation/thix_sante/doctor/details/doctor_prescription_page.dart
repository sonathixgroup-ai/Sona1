// presentation/thix_sante/doctor/details/doctor_prescription_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';

class DoctorPrescriptionPage extends StatefulWidget {
  final String? prescriptionId;
  final bool isEditing;
  const DoctorPrescriptionPage({super.key, this.prescriptionId, this.isEditing = false});

  @override
  State<DoctorPrescriptionPage> createState() => _DoctorPrescriptionPageState();
}

class _DoctorPrescriptionPageState extends State<DoctorPrescriptionPage> {
  final List<Map<String, dynamic>> _medications = [];
  final TextEditingController _patientNameController = TextEditingController();
  final TextEditingController _doctorNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.prescriptionId != null) {
      _loadPrescription();
    } else {
      // Nouvelle prescription
      _patientNameController.text = 'Patient';
      _doctorNameController.text = 'Dr. Dupont';
    }
  }

  void _loadPrescription() {
    // Simuler chargement
    _patientNameController.text = 'Michel L.';
    _doctorNameController.text = 'Dr. Dupont';
    _medications.add({'name': 'Paracétamol', 'dosage': '500 mg', 'frequency': '3x/jour'});
    _medications.add({'name': 'Amoxicilline', 'dosage': '250 mg', 'frequency': '2x/jour'});
  }

  void _addMedication() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un médicament'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: const InputDecoration(labelText: 'Nom')),
            TextField(decoration: const InputDecoration(labelText: 'Dosage')),
            TextField(decoration: const InputDecoration(labelText: 'Fréquence')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _medications.add({'name': 'Nouveau', 'dosage': '100 mg', 'frequency': '1x/jour'});
              });
              Navigator.pop(context);
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Prescription enregistrée (simulé)')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.prescriptionId == null;
    final title = isNew ? 'Nouvelle prescription' : (widget.isEditing ? 'Modifier' : 'Détail prescription');

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isNew && !widget.isEditing) ...[
                _buildDetailView(),
              ] else ...[
                _buildFormView(),
              ],
              const SizedBox(height: 16),
              if (widget.isEditing || isNew) ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _save,
                        child: Text(isNew ? 'Créer' : 'Enregistrer'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Patient : Michel L.'),
        const Text('Médecin : Dr. Dupont'),
        const Text('Date : 10/03/2024'),
        const SizedBox(height: 16),
        const Text('Médicaments :', style: TextStyle(fontWeight: FontWeight.bold)),
        ..._medications.map((m) => Card(
              child: ListTile(
                title: Text(m['name']),
                subtitle: Text('${m['dosage']} • ${m['frequency']}'),
              ),
            )),
      ],
    );
  }

  Widget _buildFormView() {
    return Column(
      children: [
        TextField(
          controller: _patientNameController,
          decoration: const InputDecoration(labelText: 'Patient'),
        ),
        TextField(
          controller: _doctorNameController,
          decoration: const InputDecoration(labelText: 'Médecin'),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Text('Médicaments', style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addMedication,
            ),
          ],
        ),
        ..._medications.map((m) => Card(
              child: ListTile(
                title: Text(m['name']),
                subtitle: Text('${m['dosage']} • ${m['frequency']}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _medications.remove(m);
                    });
                  },
                ),
              ),
            )),
      ],
    );
  }
}
