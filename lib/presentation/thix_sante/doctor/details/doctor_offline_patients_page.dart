import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/nav.dart';

class DoctorOfflinePatientsPage extends StatelessWidget {
  const DoctorOfflinePatientsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patients hors-ligne'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.popOrGo('/sante/doctor/dashboard'),
        ),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            "Mode hors-ligne: à connecter à un stockage local sécurisé. (Page créée pour éviter les routes manquantes.)",
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
