// presentation/thix_sante/pharmacy/pharmacy_orders_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/presentation/thix_sante/shared/widgets/health_bottom_nav.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';

class PharmacyOrdersPage extends StatefulWidget {
  const PharmacyOrdersPage({super.key});

  @override
  State<PharmacyOrdersPage> createState() => _PharmacyOrdersPageState();
}

class _PharmacyOrdersPageState extends State<PharmacyOrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Données mockées
  final List<Order> _orders = [
    Order(
      id: 'ord1',
      pharmacyId: 'pharm1',
      patientId: 'p1',
      patientName: 'Michel L.',
      items: [
        OrderItem(id: 'i1', productName: 'Paracétamol', quantity: 2, unitPrice: 5.5),
        OrderItem(id: 'i2', productName: 'Amoxicilline', quantity: 1, unitPrice: 8.0),
      ],
      status: OrderStatus.pending,
      orderDate: DateTime.now().subtract(const Duration(hours: 2)),
      totalAmount: 19.0,
    ),
    Order(
      id: 'ord2',
      pharmacyId: 'pharm1',
      patientId: 'p2',
      patientName: 'Sophie M.',
      items: [
        OrderItem(id: 'i3', productName: 'Ibuprofène', quantity: 1, unitPrice: 4.5),
      ],
      status: OrderStatus.validated,
      orderDate: DateTime.now().subtract(const Duration(days: 1)),
      deliveryDate: DateTime.now().add(const Duration(hours: 4)),
      totalAmount: 4.5,
    ),
    Order(
      id: 'ord3',
      pharmacyId: 'pharm1',
      patientId: 'p3',
      patientName: 'Jean P.',
      items: [
        OrderItem(id: 'i4', productName: 'Oméprazole', quantity: 3, unitPrice: 6.0),
      ],
      status: OrderStatus.prepared,
      orderDate: DateTime.now().subtract(const Duration(days: 2)),
      totalAmount: 18.0,
    ),
  ];

  // Ordonnances à valider (simulées)
  final List<Prescription> _pendingPrescriptions = [
    Prescription(
      id: 'pres1',
      patientId: 'p4',
      patientName: 'Marie D.',
      doctorId: 'doc1',
      doctorName: 'Dr. Dupont',
      date: DateTime.now().subtract(const Duration(hours: 5)),
      status: PrescriptionStatus.active,
      medications: [],
    ),
    Prescription(
      id: 'pres2',
      patientId: 'p5',
      patientName: 'Luc R.',
      doctorId: 'doc2',
      doctorName: 'Dr. Martin',
      date: DateTime.now().subtract(const Duration(days: 1)),
      status: PrescriptionStatus.active,
      medications: [],
    ),
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
          _OrdersTab(orders: _orders),
          _PrescriptionValidationTab(prescriptions: _pendingPrescriptions),
          _DispensationTab(),
          _DeliveryTab(),
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
    );
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
                context.push('/sante/pharmacy/orders/new');
              },
            ),
            ListTile(
              leading: const Icon(Icons.verified, color: Colors.green),
              title: const Text('Valider ordonnance'),
              onTap: () {
                Navigator.pop(context);
                context.push('/sante/pharmacy/orders/validation');
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 1. COMMANDES
// ============================================================
class _OrdersTab extends StatelessWidget {
  final List<Order> orders;
  const _OrdersTab({required this.orders});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(order.status),
              child: Text(order.patientName?[0] ?? '?', style: const TextStyle(color: Colors.white)),
            ),
            title: Text('Commande #${order.id.substring(0, 4)}'),
            subtitle: Text('${order.patientName} • ${order.items.length} médicaments'),
            trailing: Chip(
              label: Text(_getStatusLabel(order.status)),
              backgroundColor: _getStatusColor(order.status).withOpacity(0.2),
            ),
            onTap: () {
              // Détail de la commande
            },
          ),
        );
      },
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.validated:
        return Colors.green;
      case OrderStatus.prepared:
        return Colors.blue;
      case OrderStatus.delivered:
        return Colors.purple;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  String _getStatusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'En attente';
      case OrderStatus.validated:
        return 'Validée';
      case OrderStatus.prepared:
        return 'Préparée';
      case OrderStatus.delivered:
        return 'Livrée';
      case OrderStatus.cancelled:
        return 'Annulée';
    }
  }
}

// ============================================================
// 2. VALIDATION D'ORDONNANCE
// ============================================================
class _PrescriptionValidationTab extends StatelessWidget {
  final List<Prescription> prescriptions;
  const _PrescriptionValidationTab({required this.prescriptions});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: prescriptions.length,
      itemBuilder: (context, index) {
        final pres = prescriptions[index];
        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.receipt, color: Colors.orange),
            title: Text('Ordonnance du ${pres.date.day}/${pres.date.month}/${pres.date.year}'),
            subtitle: Text('Dr. ${pres.doctorName} • ${pres.patientName}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () {
                    // Accepter
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ordonnance validée')),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () {
                    // Rejeter
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ordonnance rejetée')),
                    );
                  },
                ),
              ],
            ),
            onTap: () {
              // Voir l'ordonnance
            },
          ),
        );
      },
    );
  }
}

// ============================================================
// 3. DISPENSATION
// ============================================================
class _DispensationTab extends StatelessWidget {
  const _DispensationTab();

  @override
  Widget build(BuildContext context) {
    // Données mockées
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
              // Attribuer au patient
            },
          ),
        );
      },
    );
  }
}

// ============================================================
// 4. SUIVI DES LIVRAISONS
// ============================================================
class _DeliveryTab extends StatelessWidget {
  const _DeliveryTab();

  @override
  Widget build(BuildContext context) {
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
            },
          ),
        );
      },
    );
  }
}
