import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/nav.dart';

class DoctorVoiceDictationPage extends StatelessWidget {
  const DoctorVoiceDictationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dictée vocale'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/sante/doctor/dashboard'),
        ),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            "Ici on branchera la reconnaissance vocale (micro + STT).",
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
