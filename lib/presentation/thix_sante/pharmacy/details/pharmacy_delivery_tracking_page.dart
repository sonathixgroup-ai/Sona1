import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/nav.dart';

class PharmacyDeliveryTrackingPage extends StatelessWidget {
  final String deliveryId;
  const PharmacyDeliveryTrackingPage({super.key, required this.deliveryId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi livraison'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.popOrGo('/sante/pharmacy/delivery'),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Livraison $deliveryId • tracking à connecter (maps + status).'),
        ),
      ),
    );
  }
}
