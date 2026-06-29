// 📁 lib/presentation/thix_sante/pharmacy/screens/pharmacy_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/order_card.dart';
import '../widgets/stock_alert_widget.dart';
import '../../../common/widgets/stat_card.dart';

class PharmacyDashboardScreen extends ConsumerWidget {
  const PharmacyDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Données simulées (à connecter aux providers)
    final pendingOrders = [
      {'id': 'CMD001', 'patient': 'Michel Dupont', 'date': '18/12/2024', 'items': 3, 'status': 'pending'},
      {'id': 'CMD002', 'patient': 'Sophie Martin', 'date': '18/12/2024', 'items': 2, 'status': 'pending'},
    ];

    final stockAlerts = [
      {'drug': 'Amoxicilline', 'dosage': '500mg', 'quantity': 12, 'threshold': 30},
      {'drug': 'Paracétamol', 'dosage': '1000mg', 'quantity': 5, 'threshold': 20},
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            title: Text('Pharmacie'),
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: false,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Statistiques
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: 'Commandes en attente',
                        value: '${pendingOrders.length}',
                        icon: Icons.pending_actions,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        label: 'Stock critique',
                        value: '${stockAlerts.length}',
                        icon: Icons.warning_amber,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Alertes stock
                if (stockAlerts.isNotEmpty) ...[
                  const Text('⚠️ Alertes stock', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ...stockAlerts.map((a) => StockAlertWidget(
                    drugName: a['drug']!,
                    dosage: a['dosage']!,
                    currentQuantity: a['quantity']!,
                    threshold: a['threshold']!,
                    onReorder: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Réapprovisionnement lancé'), backgroundColor: Colors.green),
                      );
                    },
                  )),
                  const SizedBox(height: 20),
                ],
                // Commandes récentes
                const Text('📦 Commandes récentes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...pendingOrders.map((o) => OrderCard(
                  orderId: o['id']!,
                  patientName: o['patient']!,
                  date: o['date']!,
                  status: o['status']!,
                  itemCount: o['items']!,
                  onTap: () {
                    // Naviguer vers le détail
                  },
                  onProcess: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Traitement en cours...'), backgroundColor: Colors.blue),
                    );
                  },
                )),
                const SizedBox(height: 20),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
