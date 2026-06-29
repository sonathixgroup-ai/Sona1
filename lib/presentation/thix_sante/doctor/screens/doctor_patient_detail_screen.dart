// 📁 lib/presentation/thix_sante/doctor/screens/doctor_patient_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/patient_summary_card.dart';
import '../widgets/vital_signs_chart.dart';
import '../widgets/risk_indicator.dart';
import '../widgets/medical_note_editor.dart';
import '../../../common/widgets/section_title.dart';
import '../../../common/widgets/gradient_button.dart';
import 'package:fl_chart/fl_chart.dart';

class DoctorPatientDetailScreen extends ConsumerStatefulWidget {
  final String patientId;

  const DoctorPatientDetailScreen({Key? key, required this.patientId}) : super(key: key);

  @override
  ConsumerState<DoctorPatientDetailScreen> createState() => _DoctorPatientDetailScreenState();
}

class _DoctorPatientDetailScreenState extends ConsumerState<DoctorPatientDetailScreen> {
  final List<Map<String, String>> _prescriptions = [
    {'drug': 'Amoxicilline', 'dosage': '500mg', 'duration': '7 jours', 'instructions': 'Prendre avec de la nourriture'},
    {'drug': 'Paracétamol', 'dosage': '1000mg', 'duration': 'Si besoin', 'instructions': 'Max 3 par jour'},
  ];

  final List<double> _systolic = [120, 125, 118, 130, 122, 128, 120];
  final List<double> _diastolic = [80, 82, 76, 85, 78, 82, 80];
  final List<String> _labels = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

  @override
  Widget build(BuildContext context) {
    final patient = {
      'name': 'Michel Dupont',
      'age': 39,
      'bloodType': 'A+',
      'allergies': ['Pénicilline', 'Acariens'],
      'lastVisit': '10/12/2024',
    };

    final risks = [
      {'condition': 'Risque cardiovasculaire', 'probability': 0.25},
      {'condition': 'Diabète de type 2', 'probability': 0.45},
      {'condition': 'Hypertension', 'probability': 0.72},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(patient['name']!),
        actions: [
          IconButton(icon: const Icon(Icons.message), onPressed: () {}),
          IconButton(icon: const Icon(Icons.phone), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PatientSummaryCard(
              patientName: patient['name']!,
              age: patient['age']!,
              bloodType: patient['bloodType']!,
              allergies: patient['allergies']!,
              lastVisit: patient['lastVisit']!,
            ),
            const SizedBox(height: 20),
            VitalSignsChart(
              systolicSpots: List.generate(_systolic.length, (i) => FlSpot(i.toDouble(), _systolic[i])),
              diastolicSpots: List.generate(_diastolic.length, (i) => FlSpot(i.toDouble(), _diastolic[i])),
              labels: _labels,
            ),
            const SizedBox(height: 20),
            const SectionTitle(title: 'Risques détectés', showDivider: false),
            const SizedBox(height: 8),
            ...risks.map((r) => RiskIndicator(
              condition: r['condition']!,
              probability: r['probability']!,
              onViewDetails: () {},
            )),
            const SizedBox(height: 20),
            const SectionTitle(title: 'Traitements en cours', showDivider: false),
            const SizedBox(height: 8),
            ..._prescriptions.map((p) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p['drug']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  Text('${p['dosage']} • ${p['duration']}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  if (p['instructions']!.isNotEmpty)
                    Text('📝 ${p['instructions']}', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
                ],
              ),
            )),
            const SizedBox(height: 20),
            MedicalNoteEditor(
              initialNote: 'Patient stable. Suivi dans 1 mois.',
              onSave: (note) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Note enregistrée'), backgroundColor: Colors.green),
                );
              },
            ),
            const SizedBox(height: 20),
            GradientButton(
              text: 'Nouvelle prescription',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DoctorPrescriptionScreen()),
                );
              },
              icon: Icons.add,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
