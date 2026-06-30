import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/nav.dart';

class DoctorStatisticsDetailPage extends StatelessWidget {
  final String? patientId;
  const DoctorStatisticsDetailPage({super.key, this.patientId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail statistiques'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.popOrGo('/sante/doctor/statistics'),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            patientId == null
                ? 'Sélectionne un patient pour afficher les statistiques.'
                : 'Statistiques patient: $patientId',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
