import 'package:flutter/material.dart';

class ShopDetailPage extends StatelessWidget {
  final String shopId;
  const ShopDetailPage({super.key, required this.shopId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Boutique #$shopId')), // À remplacer par le vrai nom
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Page détail de la boutique', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('ID : $shopId', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }
}
