import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/nav.dart';

class PharmacyPrescriptionAcceptPage extends StatelessWidget {
  final String prescriptionId;
  const PharmacyPrescriptionAcceptPage({super.key, required this.prescriptionId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accepter prescription'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.popOrGo('/sante/pharmacy/prescription/${Uri.encodeComponent(prescriptionId)}'),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Prescription $prescriptionId • action accept à brancher sur Supabase.'),
        ),
      ),
    );
  }
}
