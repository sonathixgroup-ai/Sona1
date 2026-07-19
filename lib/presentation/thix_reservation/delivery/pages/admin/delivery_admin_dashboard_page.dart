// ================================================================
// CHEMIN: lib/presentation/thix_reservation/delivery/pages/admin/delivery_admin_dashboard_page.dart
// ROLE: DASHBOARD ADMIN - Stats + accès rapide aux 3 autres pages admin
// C'est la page d'accueil quand tu cliques bouton Admin sur Home
// SCALABLE: Future.wait + Grid + refresh
// ================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/delivery_admin_provider.dart';
import '../../widgets/delivery_admin_widgets.dart';

class DeliveryAdminDashboardPage extends StatefulWidget {
  const DeliveryAdminDashboardPage({super.key});

  @override
  State<DeliveryAdminDashboardPage> createState() => _DeliveryAdminDashboardPageState();
}

class _DeliveryAdminDashboardPageState extends State<DeliveryAdminDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeliveryAdminProvider>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FA),
      appBar: AppBar(
        title: const Text("Admin Delivery", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF6D28D9),
        foregroundColor: Colors.white,
      ),
      body: Consumer<DeliveryAdminProvider>(
        builder: (context, prov, _) {
          if (prov.isLoading) return const Center(child: CircularProgressIndicator());

          return RefreshIndicator(
            onRefresh: () => prov.init(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- STATS 2x2 ---
                  GridView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.6, crossAxisSpacing: 12, mainAxisSpacing: 12),
                    children: [
                      AdminStatCard(title: "Total colis", value: "${prov.stats['total']}", icon: Icons.inventory_2, color: const Color(0xFF6D28D9)),
                      AdminStatCard(title: "En attente", value: "${prov.stats['pending']}", icon: Icons.pending, color: Colors.orange),
                      AdminStatCard(title: "Livrés", value: "${prov.stats['delivered']}", icon: Icons.check_circle, color: Colors.green),
                      AdminStatCard(title: "Aujourd'hui", value: "${prov.stats['today']}", icon: Icons.today, color: Colors.blue),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // --- MENU ADMIN 4 BOUTONS ---
                  const Text("Gestion", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  Row(children: [
                    _AdminMenuBtn(icon: Icons.route, label: "Prix par trajet", onTap: () => Navigator.pushNamed(context, '/delivery-admin-routes')),
                    const SizedBox(width: 12),
                    _AdminMenuBtn(icon: Icons.local_shipping, label: "Tous colis", onTap: () => Navigator.pushNamed(context, '/delivery-admin-shipments')),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    _AdminMenuBtn(icon: Icons.qr_code_scanner, label: "Scanner QR", onTap: () => Navigator.pushNamed(context, '/delivery-admin-scan')),
                    const SizedBox(width: 12),
                    _AdminMenuBtn(icon: Icons.local_offer, label: "Offres", onTap: () {}),
                  ]),
                  const SizedBox(height: 24),

                  // --- LISTE ROUTES RECENTES ---
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text("Trajets actifs", style: TextStyle(fontWeight: FontWeight.bold)),
                    TextButton(onPressed: () => Navigator.pushNamed(context, '/delivery-admin-routes'), child: const Text("Voir tout")),
                  ]),
                 ...prov.routes.take(3).map((r) => AdminRouteCard(route: r, onEdit: () {}, onDelete: () {})),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AdminMenuBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _AdminMenuBtn({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
          child: Column(children: [Icon(icon, color: const Color(0xFF6D28D9), size: 28), const SizedBox(height: 8), Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center)]),
        ),
      ),
    );
  }
}
