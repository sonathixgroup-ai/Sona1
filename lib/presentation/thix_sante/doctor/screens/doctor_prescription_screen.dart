// 📁 lib/presentation/thix_sante/doctor/screens/doctor_prescription_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/prescription_form.dart';
import '../widgets/prescription_preview.dart';

class DoctorPrescriptionScreen extends ConsumerStatefulWidget {
  const DoctorPrescriptionScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DoctorPrescriptionScreen> createState() => _DoctorPrescriptionScreenState();
}

class _DoctorPrescriptionScreenState extends ConsumerState<DoctorPrescriptionScreen> {
  final List<Map<String, String>> _items = [];
  final TextEditingController _patientNameCtrl = TextEditingController();

  @override
  void dispose() {
    _patientNameCtrl.dispose();
    super.dispose();
  }

  void _addItem(Map<String, dynamic> item) {
    setState(() {
      _items.add({
        'drug': item['drug'],
        'dosage': item['dosage'],
        'duration': item['duration'] ?? '',
        'instructions': item['instructions'] ?? '',
      });
    });
  }

  void _validatePrescription() {
    if (_patientNameCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer le nom du patient'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoutez au moins un médicament'), backgroundColor: Colors.orange),
      );
      return;
    }
    // Simuler l'envoi
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ordonnance validée et envoyée'), backgroundColor: Colors.green),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescription'),
        actions: [
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _validatePrescription,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _patientNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nom du patient',
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            PrescriptionForm(onSubmit: _addItem),
            const SizedBox(height: 16),
            PrescriptionPreview(
              items: _items,
              onValidate: _validatePrescription,
              onCancel: () => setState(() => _items.clear()),
            ),
          ],
        ),
      ),
    );
  }
}
