// 📁 lib/presentation/thix_sante/pharmacy/screens/pharmacy_orders_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/order_card.dart';
import '../widgets/order_status_timeline.dart';
import '../../../common/widgets/empty_state.dart';
import '../../../common/widgets/section_title.dart';

class PharmacyOrdersScreen extends ConsumerStatefulWidget {
  const PharmacyOrdersScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PharmacyOrdersScreen> createState() => _PharmacyOrdersScreenState();
}

class _PharmacyOrdersScreenState extends ConsumerState<PharmacyOrdersScreen> {
  int _selectedTab = 0;
  final List<String> _tabs = ['Toutes', 'En attente', 'En préparation', 'Livrées'];

  // Données simulées
  final List<Map<String, dynamic>> _orders = [
    {'id': 'CMD001', 'patient': 'Michel Dupont', 'date': '18/12/2024', 'items': 3, 'status': 'pending'},
    {'id': 'CMD002', 'patient': 'Sophie Martin', 'date': '18/12/2024', 'items': 2, 'status': 'preparing'},
    {'id': 'CMD003', 'patient': 'Lucas Bernard', 'date': '17/12/2024', 'items': 1, 'status': 'delivered'},
    {'id': 'CMD004', 'patient': 'Julie Petit', 'date': '17/12/2024', 'items': 4, 'status': 'pending'},
    {'id': 'CMD005', 'patient': 'Paul Moreau', 'date': '16/12/2024', 'items': 2, 'status': 'ready'},
  ];

  List<Map<String, dynamic>> get _filteredOrders {
    if (_selectedTab == 0) return _orders;
    final statusMap = ['', 'pending', 'preparing', 'delivered'];
    final status = statusMap[_selectedTab];
    return _orders.where((o) => o['status'] == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredOrders;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Commandes'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // Onglets
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: _tabs.asMap().entries.map((entry) {
                final index = entry.key;
                final label = entry.value;
                final isSelected = _selectedTab == index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.green : Colors.transparent,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? Colors.white : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 0),
          // Liste
          Expanded(
            child: filtered.isEmpty
                ? const EmptyStateWidget(
                    title: 'Aucune commande',
                    subtitle: 'Aucune commande dans cette catégorie',
                    icon: Icons.inbox_outlined,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final o = filtered[index];
                      return OrderCard(
                        orderId: o['id']!,
                        patientName: o['patient']!,
                        date: o['date']!,
                        status: o['status']!,
                        itemCount: o['items']!,
                        onTap: () {
                          // Naviguer vers le détail avec timeline
                          _showOrderDetail(o);
                        },
                        onProcess: o['status'] == 'pending' || o['status'] == 'preparing'
                            ? () {
                                setState(() {
                                  o['status'] = o['status'] == 'pending' ? 'preparing' : 'ready';
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Statut mis à jour'), backgroundColor: Colors.green),
                                );
                              }
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showOrderDetail(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Commande #${order['id']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            OrderStatusTimeline(
              currentStatus: order['status'],
              createdAt: DateTime.now().subtract(const Duration(days: 1)),
              validatedAt: order['status'] != 'pending' ? DateTime.now().subtract(const Duration(hours: 2)) : null,
              deliveredAt: order['status'] == 'delivered' ? DateTime.now() : null,
            ),
            const SizedBox(height: 16),
            const Text('Médicaments', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...List.generate(order['items'], (i) => ListTile(
              leading: const Icon(Icons.medication, size: 16),
              title: Text('Médicament ${i+1}', style: const TextStyle(fontSize: 13)),
              subtitle: const Text('1 boîte', style: TextStyle(fontSize: 11)),
            )),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        ),
      ),
    );
  }
}
