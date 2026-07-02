// presentation/thix_sante/pharmacy/pharmacy_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

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

  // Quick actions
  static const List<_QuickAction> _quickActions = [
    _QuickAction('Nouvelle commande', Icons.add_shopping_cart, '/sante/pharmacy/order/new'),
    _QuickAction('Valider ordonnance', Icons.verified, '/sante/pharmacy/prescription/p1'),
    _QuickAction('Inventaire', Icons.inventory, '/sante/pharmacy/inventory'),
    _QuickAction('Rapports', Icons.bar_chart, '/sante/pharmacy/report'),
  ];

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
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de chargement : $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        floatingActionButton: _fab(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: _BottomNav(
          currentIndex: 0,
          onTap: (index) {
            if (index == 1) context.go('/sante/pharmacy/orders');
            if (index == 2) context.go('/sante/pharmacy/messages');
            if (index == 3) context.go('/sante/pharmacy/profile');
          },
        ),
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(child: _topBar()),
                      SliverToBoxAdapter(child: _statsGrid()),
                      SliverToBoxAdapter(child: _recentOrdersSection()),
                      SliverToBoxAdapter(child: _quickActionsSection()),
                      const SliverToBoxAdapter(child: SizedBox(height: 90)),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  // =========================================================
  // TOP BAR (comme dans le dashboard patient)
  // =========================================================
  Widget _topBar() {
    final user = AuthController.instance.currentUser;
    final name = user?.displayName ?? "Pharmacie";

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'THIX SANTÉ',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade800,
                ),
              ),
              Text(
                'Espace Pharmacie',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const Spacer(),
          Stack(
            children: [
              _glassIcon(Icons.notifications_none, onTap: () {
                // Naviguer vers les notifications (si implémenté)
                // context.push('/sante/pharmacy/notifications');
              }),
              // On peut ajouter un badge si nécessaire
            ],
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.orange.shade100,
            child: Text(
              name.isNotEmpty ? name.substring(0, 1).toUpperCase() : "P",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }

  // =========================================================
  // GRILLE DES STATISTIQUES
  // =========================================================
  Widget _statsGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              _statCard('En attente', _pendingOrders.toString(), Icons.pending, Colors.orange),
              const SizedBox(width: 12),
              _statCard('En cours', _inProgressOrders.toString(), Icons.production_quantity_limits, Colors.blue),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _statCard('Stock critique', _criticalStock.toString(), Icons.warning, Colors.red),
              const SizedBox(width: 12),
              _statCard('Livraisons', _deliveriesToday.toString(), Icons.local_shipping, Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // COMMANDES RÉCENTES
  // =========================================================
  Widget _recentOrdersSection() {
    final orders = _recentOrders;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Commandes récentes',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (orders.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'Aucune commande récente.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...orders.map((o) {
              final id = (o['id'] ?? '').toString();
              final patient = (o['patient_name'] ?? o['patient'] ?? '').toString();
              final meds = o['meds_count'] ?? o['meds'] ?? '';
              final status = (o['status'] ?? '').toString();
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            id.isNotEmpty ? 'Commande #$id' : 'Commande',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            [
                              if (patient.trim().isNotEmpty) 'Patient : $patient',
                              if (meds.toString().trim().isNotEmpty) '$meds médicaments',
                            ].join(' • '),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (status.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: _getStatusColor(status),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'En attente':
        return Colors.orange;
      case 'En cours':
        return Colors.blue;
      case 'Validée':
        return Colors.green;
      case 'Préparée':
        return Colors.purple;
      case 'Livrée':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  // =========================================================
  // ACTIONS RAPIDES (GRILLE 2x2)
  // =========================================================
  Widget _quickActionsSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actions rapides',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.85,
            ),
            itemCount: _quickActions.length,
            itemBuilder: (_, index) {
              final action = _quickActions[index];
              final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple];
              final color = colors[index % colors.length];
              return _quickActionTile(action, color);
            },
          ),
        ],
      ),
    );
  }

  Widget _quickActionTile(_QuickAction action, Color color) {
    return GestureDetector(
      onTap: () => context.push(action.route),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(action.icon, color: color, size: 30),
            const SizedBox(height: 6),
            Text(
              action.label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // FAB (Nouvelle commande)
  // =========================================================
  Widget _fab() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF9800), Color(0xFFFFB74D)],
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: FloatingActionButton(
        backgroundColor: Colors.transparent,
        onPressed: () => context.push('/sante/pharmacy/order/new'),
        child: const Icon(Icons.add),
      ),
    );
  }

  // =========================================================
  // STYLE HELPERS
  // =========================================================
  BoxDecoration _glass() => BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          )
        ],
      );

  Widget _glassIcon(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: _glass(),
        child: Icon(icon, color: Colors.grey.shade700),
      ),
    );
  }

  // =========================================================
  // ROLE SWITCH
  // =========================================================
  Future<void> _openRoleSwitchSheet(BuildContext context) async {
    final selected = await showModalBottomSheet<ThixRole>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _RoleSwitchSheet(currentRole: ThixRole.pharmacy),
    );

    if (selected == null || selected == ThixRole.pharmacy) return;
    await _selectRoleAndNavigate(context, selected);
  }

  Future<void> _selectRoleAndNavigate(BuildContext context, ThixRole role) async {
    try {
      ThixRoleController.instance.selectRole(role, manual: true);
      try {
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(data: {'thix_role': role.name}),
        );
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
        const SnackBar(
          content: Text(HealthConstants.errorGeneric),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// =========================================================
// MODÈLE ACTION RAPIDE
// =========================================================
class _QuickAction {
  final String label;
  final IconData icon;
  final String route;
  const _QuickAction(this.label, this.icon, this.route);
}

// =========================================================
// BOTTOM NAVIGATION (identique à celui du patient)
// =========================================================
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: const Color(0xFFFF9800),
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Accueil',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart),
          label: 'Commandes',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.message),
          label: 'Messages',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.store),
          label: 'Profil',
        ),
      ],
    );
  }
}

// =========================================================
// ROLE SWITCH SHEET
// =========================================================
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
            Text(
              'Changer de rôle',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Quitter le mode pharmacie et accéder à un autre espace.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
            ),
            const SizedBox(height: 12),
            for (final role in ThixRoleController.availableRoles)
              _RoleTile(
                role: role,
                selected: role == currentRole,
                onTap: () => context.pop(role),
              ),
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
          border: Border.all(
            color: selected ? role.accent : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: role.accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(role.icon, color: role.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role.label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    role.shortLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                  ),
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
