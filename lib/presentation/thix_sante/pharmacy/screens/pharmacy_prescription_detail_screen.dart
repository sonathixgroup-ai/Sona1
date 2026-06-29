// 📁 lib/presentation/thix_sante/pharmacy/screens/pharmacy_prescription_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/prescription_detail_card.dart';
import '../widgets/validation_badge.dart';
import '../../../common/widgets/gradient_button.dart';

class PharmacyPrescriptionDetailScreen extends ConsumerStatefulWidget {
  final String prescriptionId;

  const PharmacyPrescriptionDetailScreen({Key? key, required this.prescriptionId}) : super(key: key);

  @override
  ConsumerState<PharmacyPrescriptionDetailScreen> createState() => _PharmacyPrescriptionDetailScreenState();
}

class _PharmacyPrescriptionDetailScreenState extends ConsumerState<PharmacyPrescriptionDetailScreen> {
  // Données simulées
  final Map<String, dynamic> _prescription = {
    'id': 'PRES001',
    'doctor': 'Dr. Martin',
    'patient': 'Michel Dupont',
    'date': '18/12/2024',
    'status': 'pending',
    'items': [
      {'name': 'Amoxicilline', 'dosage': '500mg', 'frequency': '2x/jour', 'quantity': 2},
      {'name': 'Paracétamol', 'dosage': '1000mg', 'frequency': 'si besoin', 'quantity': 1},
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail ordonnance'),
        actions: [
          ValidationBadge(
            isValidated: _prescription['status'] != 'pending',
            validatedBy: _prescription['status'] != 'pending' ? 'Pharmacie' : null,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            PrescriptionDetailCard(
              doctorName: _prescription['doctor']!,
              patientName: _prescription['patient']!,
              date: _prescription['date']!,
              items: List<Map<String, String>>.from(_prescription['items']).map((item) {
                return {
                  'name': item['name'],
                  'dosage': item['dosage'],
                  'frequency': item['frequency'],
                  'quantity': item['quantity'].toString(),
                };
              }).toList(),
              status: _prescription['status']!,
              onValidate: () {
                setState(() {
                  _prescription['status'] = 'validated';
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ordonnance validée'), backgroundColor: Colors.green),
                );
              },
              onReject: () {
                setState(() {
                  _prescription['status'] = 'rejected';
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ordonnance rejetée'), backgroundColor: Colors.red),
                );
              },
            ),
            const SizedBox(height: 20),
            GradientButton(
              text: 'Imprimer l\'ordonnance',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Impression lancée'), backgroundColor: Colors.blue),
                );
              },
              icon: Icons.print,
            ),
          ],
        ),
      ),
    );
  }
}
