import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/nav.dart';

class DoctorPhotoCapturePage extends StatelessWidget {
  const DoctorPhotoCapturePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prendre une photo'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/sante/doctor/dashboard'),
        ),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            "Caméra à intégrer (permissions + capture). Page créée pour compléter le module terrain.",
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
