import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/nav.dart';

class DoctorScanBraceletPage extends StatelessWidget {
  const DoctorScanBraceletPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner bracelet'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/sante/doctor/dashboard'),
        ),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            "Fonction de scan à brancher (caméra/NFC). L'écran est prêt côté routing.",
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
