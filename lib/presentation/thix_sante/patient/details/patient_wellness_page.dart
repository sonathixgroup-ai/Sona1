// presentation/thix_sante/patient/details/patient_wellness_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PatientWellnessPage extends StatefulWidget {
  final String? programId;
  final bool isTracking;

  const PatientWellnessPage({super.key, this.programId, this.isTracking = false});

  @override
  State<PatientWellnessPage> createState() => _PatientWellnessPageState();
}

class _PatientWellnessPageState extends State<PatientWellnessPage> {
  @override
  Widget build(BuildContext context) {
    if (widget.isTracking) {
      return Scaffold(
        appBar: AppBar(title: const Text('Suivi programme')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Programme : Gestion du stress', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text('Progression : 40%'),
              const LinearProgressIndicator(value: 0.4),
              const SizedBox(height: 16),
              const Text('Objectifs atteints : 2/5'),
              const Text('Prochaine étape : Méditation du jour'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {},
                child: const Text('Marquer une étape'),
              ),
            ],
          ),
        ),
      );
    }

    // Détail programme
    return Scaffold(
      appBar: AppBar(title: const Text('Programme bien-être')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Gestion du stress', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Durée : 30 jours'),
            const Text('Objectif : Réduire l\'anxiété'),
            const SizedBox(height: 16),
            const Text('Modules :', style: TextStyle(fontWeight: FontWeight.bold)),
            const ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green),
              title: Text('Module 1 : Respiration'),
            ),
            const ListTile(
              leading: Icon(Icons.circle_outlined),
              title: Text('Module 2 : Méditation'),
            ),
            const ListTile(
              leading: Icon(Icons.circle_outlined),
              title: Text('Module 3 : Gestion des émotions'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.push('/sante/patient/wellness/${widget.programId}/track');
              },
              child: const Text('Commencer le programme'),
            ),
          ],
        ),
      ),
    );
  }
}
