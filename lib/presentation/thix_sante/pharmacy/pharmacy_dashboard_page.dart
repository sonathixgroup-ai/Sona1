// presentation/thix_sante/pharmacy/pharmacy_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/presentation/thix_sante/health_constants.dart';
import 'package:thix_id/presentation/thix_sante/shared/services/health_services.dart';
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
  final HealthService _service = HealthService.instance;
  int _pendingOrders = 0;
  int _inProgressOrders = 0;
  int _criticalStock = 0;
  int _deliveriesToday = 0;
  List<Map<String, dynamic>> _recentOrders = const [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = AuthController.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');
      final pharmacyId = user.id;
      final stats = await _service.fetchPharmacyDashboardStats(pharmacyId);
      final orders = await _service.fetchPharmacyRecentOrders(pharmacyId, limit: 5);
      if (!mounted) return;
      setState(() {
        _pendingOrders = stats['pending'] ?? 0;
        _inProgressOrders = stats['in_progress'] ?? 0;
        _criticalStock = stats['critical_stock'] ?? 0;
        _deliveriesToday = stats['deliveries_today'] ?? 0;
        _recentOrders = orders;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('PharmacyDashboard: load failed: $e');
      if (mounted) setState(() => _isLoading = false);
    }
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
                        onSwitchRoleTap: () => _openRoleSwitchSheet(context),
                        onNotificationsTap: () {
                          // Notifications (à créer)
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

  Future<void> _openRoleSwitchSheet(BuildContext context) async {
    final selected = await showModalBottomSheet<ThixRole>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _RoleSwitchSheet(currentRole: ThixRole.pharmacy),
    );

    if (selected == null || selected == ThixRole.pharmacy) return;
    await _selectRoleAndNavigate(context, selected);
  }

  Future<void> _selectRoleAndNavigate(BuildContext context, ThixRole role) async {
    try {
      ThixRoleController.instance.selectRole(role, manual: true);
      try {
        await Supabase.instance.client.auth.updateUser(UserAttributes(data: {'thix_role': role.name}));
      } catch (e) {
        debugPrint('THIX Santé: role metadata update failed: $e');
      }

      if (!context.mounted) return;
      switch (role) {
        case ThixRole.patient:
          context.go('/sante/patient/dashboard');
        case ThixRole.doctor:
          context.go('/sante/doctor/dashboard');
        case ThixRole.pharmacy:
          context.go('/sante/pharmacy/dashboard');
      }
    } catch (e, st) {
      debugPrint('THIX Santé: selectRoleAndNavigate failed: $e');
      debugPrint(st.toString());
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(HealthConstants.errorGeneric), backgroundColor: Colors.red),
      );
    }
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
    final orders = _recentOrders;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Commandes récentes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (orders.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Aucune commande récente.', style: TextStyle(color: Colors.grey)),
          )
        else
          ...orders.map((o) {
            final id = (o['id'] ?? '').toString();
            final patient = (o['patient_name'] ?? o['patient'] ?? '').toString();
            final meds = o['meds_count'] ?? o['meds'] ?? '';
            final status = (o['status'] ?? '').toString();
            return ListTile(
              leading: const Icon(Icons.receipt),
              title: Text(id.isNotEmpty ? 'Commande #$id' : 'Commande'),
              subtitle: Text(
                [
                  if (patient.trim().isNotEmpty) 'Patient : $patient',
                  if (meds.toString().trim().isNotEmpty) '${meds.toString()} médicaments',
                ].join(' • '),
              ),
              trailing: status.isEmpty
                  ? null
                  : Chip(
                      label: Text(status, style: const TextStyle(fontSize: 11)),
                      backgroundColor: _getStatusColor(status),
                    ),
              onTap: id.isEmpty ? null : () => context.push('/sante/pharmacy/order/$id'),
            );
          }),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'En attente':
        return Colors.orange.withValues(alpha: 0.2);
      case 'En cours':
        return Colors.blue.withValues(alpha: 0.2);
      case 'Validée':
        return Colors.green.withValues(alpha: 0.2);
      default:
        return Colors.grey.withValues(alpha: 0.2);
    }
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
            _actionChip('Nouvelle commande', Icons.add, () => context.push('/sante/pharmacy/order/new')),
            _actionChip('Valider ordonnance', Icons.verified, () => context.push('/sante/pharmacy/prescription/p1')),
            _actionChip('Inventaire', Icons.inventory, () => context.push('/sante/pharmacy/inventory')),
            _actionChip('Rapports', Icons.bar_chart, () => context.push('/sante/pharmacy/report')),
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
                context.pop();
                context.push('/sante/pharmacy/order/new');
              },
            ),
            ListTile(
              leading: const Icon(Icons.verified, color: Colors.green),
              title: const Text('Valider une ordonnance'),
              onTap: () {
                context.pop();
                context.push('/sante/pharmacy/prescription/p1');
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory, color: Colors.orange),
              title: const Text('Voir l\'inventaire'),
              onTap: () {
                context.pop();
                context.push('/sante/pharmacy/inventory');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleSwitchSheet extends StatelessWidget {
  final ThixRole currentRole;
  const _RoleSwitchSheet({required this.currentRole});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Changer de rôle', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('Quitter le mode pharmacie et accéder à un autre espace.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).hintColor)),
            const SizedBox(height: 12),
            for (final role in ThixRoleController.availableRoles)
              _RoleTile(role: role, selected: role == currentRole, onTap: () => context.pop(role)),
          ],
        ),
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  final ThixRole role;
  final bool selected;
  final VoidCallback onTap;

  const _RoleTile({required this.role, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? role.accent : Colors.transparent, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: role.accent.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(14)),
              child: Icon(role.icon, color: role.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(role.label, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(role.shortLabel, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor)),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check_circle, color: HealthConstants.primaryColor),
          ],
        ),
      ),
    );
  }
}
