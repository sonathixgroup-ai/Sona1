// presentation/thix_sante/pharmacy/pharmacy_orders_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/presentation/thix_sante/shared/widgets/health_bottom_nav.dart';

class PharmacyOrdersPage extends StatefulWidget {
  const PharmacyOrdersPage({super.key});

  @override
  State<PharmacyOrdersPage> createState() => _PharmacyOrdersPageState();
}

class _PharmacyOrdersPageState extends State<PharmacyOrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Données mockées
  final List<Map<String, dynamic>> _orders = [
    {'id': 'ord1', 'patient': 'Michel L.', 'meds': 3, 'status': 'En attente', 'date': '10/03'},
    {'id': 'ord2', 'patient': 'Sophie M.', 'meds': 2, 'status': 'Validée', 'date': '09/03'},
    {'id': 'ord3', 'patient': 'Jean P.', 'meds': 5, 'status': 'Préparée', 'date': '08/03'},
    {'id': 'ord4', 'patient': 'Marie D.', 'meds': 1, 'status': 'Livrée', 'date': '07/03'},
  ];

  final List<Map<String, dynamic>> _pendingPrescriptions = [
    {'id': 'pres1', 'patient': 'Marie D.', 'doctor': 'Dr. Dupont', 'date': '10/03'},
    {'id': 'pres2', 'patient': 'Luc R.', 'doctor': 'Dr. Martin', 'date': '09/03'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        title: const Text('Commandes'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.receipt), text: 'Commandes'),
            Tab(icon: Icon(Icons.verified), text: 'Validation'),
            Tab(icon: Icon(Icons.payment), text: 'Dispensation'),
            Tab(icon: Icon(Icons.local_shipping), text: 'Livraisons'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrdersTab(),
          _buildValidationTab(),
          _buildDispensationTab(),
          _buildDeliveryTab(),
        ],
      ),
      bottomNavigationBar: HealthBottomNav(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            context.go('/sante');
          } else if (index == 2) {
            _showQuickAction(context);
          } else if (index == 3) {
            context.go('/sante/pharmacy/connect');
          } else if (index == 4) {
            context.go('/sante/pharmacy/profile');
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/sante/pharmacy/order/new');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // ----- Onglet Commandes -----
  Widget _buildOrdersTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final o = _orders[index];
        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(o['status']),
              child: Text((o['patient'] as String)[0], style: const TextStyle(color: Colors.white)),
            ),
            title: Text('Commande #${o['id']?.substring(3)}'),
            subtitle: Text('${o['patient']} • ${o['meds']} médicaments • ${o['date']}'),
            trailing: Chip(label: Text(o['status']), backgroundColor: _getStatusColor(o['status']).withOpacity(0.2)),
            onTap: () {
              context.push('/sante/pharmacy/order/${o['id']}');
            },
          ),
        );
      },
    );
  }

  // ----- Onglet Validation d'ordonnance -----
  Widget _buildValidationTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _pendingPrescriptions.length,
      itemBuilder: (context, index) {
        final p = _pendingPrescriptions[index];
        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.receipt, color: Colors.orange),
            title: Text('Ordonnance du ${p['date']}'),
            subtitle: Text('Dr. ${p['doctor']} • ${p['patient']}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () {
                    // Accepter
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ordonnance validée (simulé)')),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () {
                    // Rejeter
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ordonnance rejetée (simulé)')),
                    );
                  },
                ),
              ],
            ),
            onTap: () {
              context.push('/sante/pharmacy/prescription/${p['id']}');
            },
          ),
        );
      },
    );
  }

  // ----- Onglet Dispensation -----
  Widget _buildDispensationTab() {
    final dispensations = [
      {'patient': 'Michel L.', 'medications': 'Paracétamol, Amoxicilline', 'status': 'À dispenser'},
      {'patient': 'Sophie M.', 'medications': 'Ibuprofène', 'status': 'Dispensé'},
    ];
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: dispensations.length,
      itemBuilder: (context, index) {
        final item = dispensations[index];
        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: item['status'] == 'Dispensé' ? Colors.green : Colors.orange,
              child: Text((item['patient'] as String)[0], style: const TextStyle(color: Colors.white)),
            ),
            title: Text(item['patient'] as String),
            subtitle: Text(item['medications'] as String),
            trailing: Chip(
              label: Text(item['status'] as String),
              backgroundColor: item['status'] == 'Dispensé' ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
            ),
            onTap: () {
              // Attribuer au patient (simulé)
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Dispensation pour ${item['patient']} (simulé)')),
              );
            },
          ),
        );
      },
    );
  }

  // ----- Onglet Livraisons -----
  Widget _buildDeliveryTab() {
    final deliveries = [
      {'patient': 'Jean P.', 'address': '12 Rue de Paris', 'status': 'En cours'},
      {'patient': 'Marie D.', 'address': '5 Avenue des Fleurs', 'status': 'Livrée'},
    ];
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: deliveries.length,
      itemBuilder: (context, index) {
        final item = deliveries[index];
        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(item['status'] == 'Livrée' ? Icons.check_circle : Icons.local_shipping,
                color: item['status'] == 'Livrée' ? Colors.green : Colors.blue),
            title: Text(item['patient'] as String),
            subtitle: Text(item['address'] as String),
            trailing: Chip(
              label: Text(item['status'] as String),
              backgroundColor: item['status'] == 'Livrée' ? Colors.green.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
            ),
            onTap: () {
              // Suivre la livraison
              context.push('/sante/pharmacy/delivery');
            },
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'En attente':
        return Colors.orange;
      case 'Validée':
        return Colors.green;
      case 'Préparée':
        return Colors.blue;
      case 'Livrée':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  void _showQuickAction(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.add_shopping_cart, color: Colors.blue),
              title: const Text('Nouvelle commande'),
              onTap: () {
                Navigator.pop(context);
                context.push('/sante/pharmacy/order/new');
              },
            ),
            ListTile(
              leading: const Icon(Icons.verified, color: Colors.green),
              title: const Text('Valider ordonnance'),
              onTap: () {
                Navigator.pop(context);
                context.push('/sante/pharmacy/prescription/p1');
              },
            ),
          ],
        ),
      ),
    );
  }
}
