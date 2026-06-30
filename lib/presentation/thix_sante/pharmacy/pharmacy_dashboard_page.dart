// presentation/thix_sante/pharmacy/pharmacy_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/presentation/thix_sante/shared/widgets/health_header.dart';
import 'package:thix_id/presentation/thix_sante/shared/widgets/health_bottom_nav.dart';
import 'package:thix_id/presentation/thix_sante/thix_role.dart';

class PharmacyDashboardPage extends StatefulWidget {
  const PharmacyDashboardPage({super.key});

  @override
  State<PharmacyDashboardPage> createState() => _PharmacyDashboardPageState();
}

class _PharmacyDashboardPageState extends State<PharmacyDashboardPage> {
  bool _isLoading = true;
  int _pendingOrders = 8;
  int _inProgressOrders = 12;
  int _criticalStock = 5;
  int _deliveriesToday = 4;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    // Simuler chargement
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: HealthHeader(
                        role: ThixRole.pharmacy,
                        onNotificationsTap: () {
                          // Notifications
                        },
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          const SizedBox(height: 16),
                          // Statistiques
                          Row(
                            children: [
                              Expanded(
                                child: _statCard('En attente', _pendingOrders.toString(), Icons.pending, Colors.orange),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _statCard('En cours', _inProgressOrders.toString(), Icons.production_quantity_limits, Colors.blue),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _statCard('Stock critique', _criticalStock.toString(), Icons.warning, Colors.red),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _statCard('Livraisons', _deliveriesToday.toString(), Icons.local_shipping, Colors.green),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Résumé des commandes récentes
                          _buildRecentOrders(),
                          const SizedBox(height: 16),
                          // Actions rapides
                          _buildQuickActions(),
                          const SizedBox(height: 24),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: HealthBottomNav(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            context.go('/sante/pharmacy/orders');
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

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrders() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Commandes récentes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.receipt, color: Colors.orange),
          title: const Text('Commande #1234'),
          subtitle: const Text('Patient : Michel L. • 3 médicaments'),
          trailing: const Chip(label: Text('En attente'), backgroundColor: Colors.orange),
        ),
        ListTile(
          leading: const Icon(Icons.receipt, color: Colors.blue),
          title: const Text('Commande #1233'),
          subtitle: const Text('Patient : Sophie M. • 2 médicaments'),
          trailing: const Chip(label: Text('En cours'), backgroundColor: Colors.blue),
        ),
        ListTile(
          leading: const Icon(Icons.receipt, color: Colors.green),
          title: const Text('Commande #1232'),
          subtitle: const Text('Patient : Jean P. • 5 médicaments'),
          trailing: const Chip(label: Text('Validée'), backgroundColor: Colors.green),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Actions rapides', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _actionChip('Nouvelle commande', Icons.add, () => context.push('/sante/pharmacy/orders/new')),
            _actionChip('Valider ordonnance', Icons.verified, () => context.push('/sante/pharmacy/orders/validation')),
            _actionChip('Inventaire', Icons.inventory, () => context.push('/sante/pharmacy/inventory')),
            _actionChip('Rapports', Icons.bar_chart, () => context.push('/sante/pharmacy/inventory/reports')),
          ],
        ),
      ],
    );
  }

  Widget _actionChip(String label, IconData icon, VoidCallback onTap) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      avatar: Icon(icon, size: 18),
      backgroundColor: Colors.grey[200],
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
              title: const Text('Valider une ordonnance'),
              onTap: () {
                Navigator.pop(context);
                context.push('/sante/pharmacy/orders/validation');
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory, color: Colors.orange),
              title: const Text('Voir l\'inventaire'),
              onTap: () {
                Navigator.pop(context);
                context.push('/sante/pharmacy/inventory');
              },
            ),
          ],
        ),
      ),
    );
  }
}
