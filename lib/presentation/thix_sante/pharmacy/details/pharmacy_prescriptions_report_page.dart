import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/nav.dart';

class PharmacyPrescriptionsReportPage extends StatelessWidget {
  const PharmacyPrescriptionsReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapport prescriptions'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.popOrGo('/sante/pharmacy/report'),
        ),
      ),
      body: const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Rapport prescriptions à connecter Supabase.'))),
    );
  }
}
