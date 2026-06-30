// presentation/thix_sante/pharmacy/details/pharmacy_delivery_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PharmacyDeliveryPage extends StatefulWidget {
  final String? deliveryId;
  const PharmacyDeliveryPage({super.key, this.deliveryId});

  @override
  State<PharmacyDeliveryPage> createState() => _PharmacyDeliveryPageState();
}

class _PharmacyDeliveryPageState extends State<PharmacyDeliveryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<Map<String, dynamic>> _deliveries = [
    {'patient': 'Jean P.', 'address': '12 Rue de Paris', 'status': 'En cours'},
    {'patient': 'Marie D.', 'address': '5 Avenue des Fleurs', 'status': 'Livrée'},
    {'patient': 'Luc R.', 'address': '3 Rue de la Santé', 'status': 'En attente'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi livraisons'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'En attente'),
            Tab(text: 'En cours'),
            Tab(text: 'Livrée'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(_deliveries.where((d) => d['status'] == 'En attente').toList()),
          _buildList(_deliveries.where((d) => d['status'] == 'En cours').toList()),
          _buildList(_deliveries.where((d) => d['status'] == 'Livrée').toList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nouvelle livraison (simulé)')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return const Center(child: Text('Aucune livraison dans cette catégorie.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(Icons.local_shipping, color: Colors.blue),
            title: Text(item['patient'] as String),
            subtitle: Text(item['address'] as String),
            trailing: Chip(label: Text(item['status'] as String), backgroundColor: Colors.blue.withOpacity(0.2)),
            onTap: () {
              // Suivre la livraison
            },
          ),
        );
      },
    );
  }
}
