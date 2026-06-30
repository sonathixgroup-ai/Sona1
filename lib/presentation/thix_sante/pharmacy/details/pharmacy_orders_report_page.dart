import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/nav.dart';

class PharmacyOrdersReportPage extends StatelessWidget {
  const PharmacyOrdersReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapport commandes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.popOrGo('/sante/pharmacy/report'),
        ),
      ),
      body: const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Rapport commandes à connecter Supabase.'))),
    );
  }
}
