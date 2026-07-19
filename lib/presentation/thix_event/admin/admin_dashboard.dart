// lib/presentation/thix_event/admin/admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'core/admin_constants.dart';
import 'core/admin_guards.dart';
import 'providers/admin_event_provider.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  AdminRole _role = AdminRole.superAdmin;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _role = await AdminGuard.getCurrentRole();
    if (mounted) setState((){});
    // On ne charge PAS tous les events, seulement les compteurs via RPC
    context.read<AdminEventProvider>().loadDashboardStats();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminEventProvider>();
    
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1F44),
        title: Row(children: [
          const Icon(Icons.shield, color: Color(0xFFE3B23C)),
          const SizedBox(width: 8),
          const Text('THIX ADMIN • SCALABLE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
          const SizedBox(width: 8),
          if (AdminConstants.isDevOpenAccess) 
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), 
              decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(6)), 
              child: const Text('DEV OPEN', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900))
            )
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: ()=> provider.loadDashboardStats()),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildStatsGrid(provider)),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(child: _buildActionGrid()),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(AdminEventProvider p) {
    // Stats légères depuis RPC, pas de chargement de millions de rows
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(spacing: 12, runSpacing: 12, children: [
        _StatCard(label: 'Events Total', value: '${p.stats.totalEvents}', icon: Icons.event),
        _StatCard(label: 'Bookings', value: '${p.stats.totalBookings}', icon: Icons.confirmation_number),
        _StatCard(label: 'Revenu', value: '${p.stats.totalRevenue} FC', icon: Icons.attach_money),
        _StatCard(label: 'File d\'attente', value: '${p.stats.waitingQueue}', icon: Icons.queue),
      ]),
    );
  }

  Widget _buildActionGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.count(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.2,
        children: [
          _ActionCard('Événements', 'Liste paginée 20 par 20', Icons.list_alt, '/thix-event/admin/events', _role),
          _ActionCard('Créer Event', 'Upload + validation', Icons.add_circle, '/thix-event/admin/events/create', _role),
          _ActionCard('Sièges', 'Génération par batch 200', Icons.event_seat, '/thix-event/admin/seats', _role),
          _ActionCard('Réservations', '50 par page + filtres', Icons.receipt_long, '/thix-event/admin/bookings', _role),
          _ActionCard('Anti-Fraude', 'BookingLimits', Icons.security, '/thix-event/admin/limits', _role),
          _ActionCard('Analytics', 'RPC Supabase', Icons.analytics, '/thix-event/admin/analytics', _role),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value; final IconData icon;
  const _StatCard({required this.label, required this.value, required this.icon});
  @override Widget build(BuildContext context) {
    return Container(width: (MediaQuery.of(context).size.width-36)/2, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE7EEFC))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, size: 20, color: const Color(0xFF123B7A)), const SizedBox(height: 8), Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0A1F44))), Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF7386A8)))]));
  }
}

class _ActionCard extends StatelessWidget {
  final String title, subtitle, route; final IconData icon; final AdminRole role;
  const _ActionCard(this.title, this.subtitle, this.icon, this.route, this.role);
  @override Widget build(BuildContext context) {
    final canWrite = AdminGuard.canWrite(role);
    return InkWell(onTap: ()=> context.push(route), child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE7EEFC))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(padding: const EdgeInsets.all(10), decoration: const BoxDecoration(color: Color(0xFFEFF5FF), shape: BoxShape.circle), child: Icon(icon, color: const Color(0xFF2D6CDF))), const Spacer(), Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)), Text(subtitle, style: const TextStyle(fontSize: 10, color: Color(0xFF7386A8))), if(!canWrite && title=='Créer Event') const Text('Lecture seule', style: TextStyle(fontSize: 9, color: Colors.red)) ])));
  }
}
