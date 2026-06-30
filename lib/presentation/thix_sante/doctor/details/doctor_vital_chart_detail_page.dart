import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/nav.dart';

class DoctorVitalChartDetailPage extends StatelessWidget {
  final String? patientId;
  const DoctorVitalChartDetailPage({super.key, this.patientId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Constantes (détail)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.popOrGo('/sante/doctor/dashboard'),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            patientId == null
                ? 'Aucun patient sélectionné.'
                : 'Graphiques constantes pour patient: $patientId',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
