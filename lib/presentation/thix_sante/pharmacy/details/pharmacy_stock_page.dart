// presentation/thix_sante/pharmacy/details/pharmacy_stock_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PharmacyStockPage extends StatefulWidget {
  final String? alertId;
  const PharmacyStockPage({super.key, this.alertId});

  @override
  State<PharmacyStockPage> createState() => _PharmacyStockPageState();
}

class _PharmacyStockPageState extends State<PharmacyStockPage> {
  final List<Map<String, dynamic>> _alerts = [
    {'name': 'Amoxicilline', 'quantity': 30, 'threshold': 40},
    {'name': 'Ibuprofène', 'quantity': 20, 'threshold': 30},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alertes stock bas')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _alerts.length,
        itemBuilder: (context, index) {
          final alert = _alerts[index];
          return Card(
            elevation: 1,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.warning, color: Colors.red),
              title: Text(alert['name'] as String),
              subtitle: Text('Stock : ${alert['quantity']} / Seuil : ${alert['threshold']}'),
              trailing: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Commande de réapprovisionnement envoyée')),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                child: const Text('Réapprovisionner'),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Réapprovisionnement automatique
        },
        child: const Icon(Icons.add_shopping_cart),
      ),
    );
  }
}
