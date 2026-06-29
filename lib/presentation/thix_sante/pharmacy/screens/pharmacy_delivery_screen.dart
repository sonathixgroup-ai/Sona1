// 📁 lib/presentation/thix_sante/pharmacy/screens/pharmacy_delivery_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/delivery_tracker.dart';
import '../../../common/widgets/empty_state.dart';

class PharmacyDeliveryScreen extends ConsumerStatefulWidget {
  const PharmacyDeliveryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PharmacyDeliveryScreen> createState() => _PharmacyDeliveryScreenState();
}

class _PharmacyDeliveryScreenState extends ConsumerState<PharmacyDeliveryScreen> {
  final List<Map<String, dynamic>> _deliveries = [
    {'id': 'LIV001', 'patient': 'Michel Dupont', 'address': '12 rue de Paris, 75001 Paris', 'status': 'in_transit', 'estimated': DateTime.now().add(const Duration(days: 1))},
    {'id': 'LIV002', 'patient': 'Sophie Martin', 'address': '5 avenue des Champs, 75008 Paris', 'status': 'preparing', 'estimated': DateTime.now().add(const Duration(days: 2))},
    {'id': 'LIV003', 'patient': 'Lucas Bernard', 'address': '3 rue de la Paix, 75002 Paris', 'status': 'delivered', 'estimated': DateTime.now().subtract(const Duration(days: 1))},
  ];

  @override
  Widget build(BuildContext context) {
    final activeDeliveries = _deliveries.where((d) => d['status'] != 'delivered').toList();
    final delivered = _deliveries.where((d) => d['status'] == 'delivered').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Livraisons'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () {}),
        ],
      ),
      body: activeDeliveries.isEmpty && delivered.isEmpty
          ? const EmptyStateWidget(
              title: 'Aucune livraison',
              subtitle: 'Les livraisons apparaîtront ici',
              icon: Icons.delivery_dining_outlined,
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: activeDeliveries.length + (delivered.isNotEmpty ? 1 : 0) + delivered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index < activeDeliveries.length) {
                  final d = activeDeliveries[index];
                  return DeliveryTracker(
                    orderId: d['id']!,
                    patientName: d['patient']!,
                    address: d['address']!,
                    status: d['status']!,
                    estimatedDelivery: d['estimated']!,
                    onTrack: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Suivi de livraison'), backgroundColor: Colors.blue),
                      );
                    },
                  );
                } else if (index == activeDeliveries.length && delivered.isNotEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Text('📦 Livraisons terminées', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  );
                } else {
                  final d = delivered[index - activeDeliveries.length - 1];
                  return DeliveryTracker(
                    orderId: d['id']!,
                    patientName: d['patient']!,
                    address: d['address']!,
                    status: d['status']!,
                    estimatedDelivery: d['estimated']!,
                    onTrack: () {},
                  );
                }
              },
            ),
    );
  }
}
