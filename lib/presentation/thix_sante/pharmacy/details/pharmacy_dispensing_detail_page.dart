import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/nav.dart';

class PharmacyDispensingDetailPage extends StatelessWidget {
  final String dispensingId;
  const PharmacyDispensingDetailPage({super.key, required this.dispensingId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail dispensation'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.popOrGo('/sante/pharmacy/dispensing'),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Dispensation $dispensingId • détails à connecter Supabase.'),
        ),
      ),
    );
  }
}
