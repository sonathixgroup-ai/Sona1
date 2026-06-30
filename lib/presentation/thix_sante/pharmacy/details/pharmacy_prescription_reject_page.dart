import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/nav.dart';

class PharmacyPrescriptionRejectPage extends StatelessWidget {
  final String prescriptionId;
  const PharmacyPrescriptionRejectPage({super.key, required this.prescriptionId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Refuser prescription'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.popOrGo('/sante/pharmacy/prescription/${Uri.encodeComponent(prescriptionId)}'),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Prescription $prescriptionId • action reject à brancher sur Supabase.'),
        ),
      ),
    );
  }
}
