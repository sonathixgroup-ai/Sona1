import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/nav.dart';

class PharmacyOrderCreatePage extends StatelessWidget {
  const PharmacyOrderCreatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer une commande'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.popOrGo('/sante/pharmacy/orders'),
        ),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Création de commande à connecter aux tables Supabase (health_orders).'),
        ),
      ),
    );
  }
}
