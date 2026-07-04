import 'package:flutter/material.dart';

class OrderDetailPage extends StatelessWidget {
  final String orderId;

  const OrderDetailPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Détail commande')),
        body: Center(child: Text('Commande #$orderId')),
      );
}
