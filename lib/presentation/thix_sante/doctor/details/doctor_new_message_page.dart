import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/nav.dart';

class DoctorNewMessagePage extends StatelessWidget {
  const DoctorNewMessagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau message'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/sante/doctor/dashboard'),
        ),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            "Sélection du destinataire + création conversation à brancher sur le chat Santé.",
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
