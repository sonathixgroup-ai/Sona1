// lib/presentation/thix_event/admin/pages/analytics/analytics_page.dart
import 'package:flutter/material.dart';
import '../../widgets/admin_app_bar.dart';
import '../../widgets/admin_stat_card.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: const AdminAppBar(title: 'Analytics • RPC'),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, children: const [
          AdminStatCard(label: 'Taux remplissage', value: '78%', icon: Icons.pie_chart),
          AdminStatCard(label: 'Panier moyen', value: '12 500 FC', icon: Icons.shopping_cart),
          AdminStatCard(label: 'No-show', value: '4.2%', icon: Icons.person_off),
          AdminStatCard(label: 'Revenu / Event', value: '2.1M FC', icon: Icons.trending_up),
        ]),
        const SizedBox(height: 20),
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE7EEFC))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Revenu 7 derniers jours', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          const SizedBox(height: 16),
          // Ici tu brancheras fl_chart avec données depuis RPC get_revenue_chart()
          Container(height: 120, decoration: BoxDecoration(color: const Color(0xFFEFF5FF), borderRadius: BorderRadius.circular(12)), child: const Center(child: Text('Graph fl_chart ici\nDonnées depuis RPC, pas depuis SELECT *', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Color(0xFF7386A8))))),
        ])),
      ]),
    );
  }
}
