// presentation/thix_sante/pharmacy/pharmacy_inventory_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/presentation/thix_sante/shared/widgets/health_bottom_nav.dart';

class PharmacyInventoryPage extends StatefulWidget {
  const PharmacyInventoryPage({super.key});

  @override
  State<PharmacyInventoryPage> createState() => _PharmacyInventoryPageState();
}

class _PharmacyInventoryPageState extends State<PharmacyInventoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Données mockées
  final List<Map<String, dynamic>> _inventory = [
    {'name': 'Paracétamol', 'quantity': 150, 'threshold': 50, 'unitPrice': 5.5},
    {'name': 'Amoxicilline', 'quantity': 30, 'threshold': 40, 'unitPrice': 8.0},
    {'name': 'Ibuprofène', 'quantity': 20, 'threshold': 30, 'unitPrice': 4.5},
    {'name': 'Oméprazole', 'quantity': 60, 'threshold': 50, 'unitPrice': 6.0},
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
        title: const Text('Inventaire'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.inventory), text: 'Inventaire'),
            Tab(icon: Icon(Icons.warning), text: 'Alertes stock'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Rapports'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _InventoryTab(inventory: _inventory),
          _StockAlertsTab(),
          _ReportsTab(),
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
          context.push('/sante/pharmacy/inventory/add');
        },
        child: const Icon(Icons.add),
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
// 1. INVENTAIRE
// ============================================================
class _InventoryTab extends StatelessWidget {
  final List<Map<String, dynamic>> inventory;
  const _InventoryTab({required this.inventory});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: inventory.length,
      itemBuilder: (context, index) {
        final item = inventory[index];
        final isLow = (item['quantity'] as int) < (item['threshold'] as int);
        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(isLow ? Icons.warning : Icons.check_circle, color: isLow ? Colors.red : Colors.green),
            title: Text(item['name'] as String),
            subtitle: Text('Quantité : ${item['quantity']} • Seuil : ${item['threshold']}'),
            trailing: Text('${item['unitPrice']} €', style: const TextStyle(fontWeight: FontWeight.bold)),
            onTap: () {
              // Modifier l'inventaire
            },
          ),
        );
      },
    );
  }
}

// ============================================================
// 2. ALERTES STOCK BAS
// ============================================================
class _StockAlertsTab extends StatelessWidget {
  const _StockAlertsTab();

  @override
  Widget build(BuildContext context) {
    // Données mockées
    final alerts = [
      {'name': 'Amoxicilline', 'quantity': 30, 'threshold': 40},
      {'name': 'Ibuprofène', 'quantity': 20, 'threshold': 30},
    ];
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: alerts.length,
      itemBuilder: (context, index) {
        final alert = alerts[index];
        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.warning, color: Colors.red),
            title: Text(alert['name'] as String),
            subtitle: Text('Stock : ${alert['quantity']} / Seuil : ${alert['threshold']}'),
            trailing: ElevatedButton(
              onPressed: () {
                // Réapprovisionner
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
    );
  }
}

// ============================================================
// 3. RAPPORTS
// ============================================================
class _ReportsTab extends StatelessWidget {
  const _ReportsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rapports de gestion', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Chiffre d\'affaires : 1 250 €', style: TextStyle(fontSize: 16)),
                Text('Commandes : 45', style: TextStyle(fontSize: 16)),
                Text('Médicaments prescrits : 120', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Télécharger les rapports', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ListTile(
          leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
          title: const Text('Rapport mensuel'),
          onTap: () {
            // Télécharger PDF
          },
        ),
        ListTile(
          leading: const Icon(Icons.insert_chart, color: Colors.blue),
          title: const Text('Rapport des médicaments prescrits'),
          onTap: () {
            // Télécharger
          },
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            // Générer nouveau rapport
          },
          icon: const Icon(Icons.generating_tokens),
          label: const Text('Générer un rapport'),
        ),
      ],
    );
  }
}
