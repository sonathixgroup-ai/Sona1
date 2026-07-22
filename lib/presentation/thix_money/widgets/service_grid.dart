// lib/presentation/thix_money/widgets/service_grid.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/nav.dart';

class ServiceItem {
  final String label;
  final IconData icon;
  final Color bg;
  final Color iconColor;
  final String? route;
  const ServiceItem({required this.label, required this.icon, required this.bg, required this.iconColor, this.route});
}

class ServiceGrid extends StatelessWidget {
  const ServiceGrid({super.key});

  static const _services = [
    ServiceItem(label: 'Crédit instantané', icon: Icons.bolt, bg: Color(0xFFE8F5E9), iconColor: Color(0xFF43A047), route: AppRoutes.thixMoneyLoans),
    ServiceItem(label: 'Assurance', icon: Icons.shield, bg: Color(0xFFE3F2FD), iconColor: Color(0xFF1E88E5), route: null),
    ServiceItem(label: 'Épargne planifiée', icon: Icons.cached, bg: Color(0xFFFCE4EC), iconColor: Color(0xFFE53935), route: AppRoutes.thixMoneySavings),
    ServiceItem(label: 'Change', icon: Icons.swap_horiz, bg: Color(0xFFE8F5E9), iconColor: Color(0xFF43A047), route: null),
    ServiceItem(label: 'Marchand', icon: Icons.store, bg: Color(0xFFF3E5F5), iconColor: Color(0xFF8E24AA), route: AppRoutes.thixMarket),
    ServiceItem(label: 'Don & Contributions', icon: Icons.volunteer_activism, bg: Color(0xFFFCE4EC), iconColor: Color(0xFFE91E63), route: null),
    ServiceItem(label: 'Ma Tontine', icon: Icons.groups, bg: Color(0xFFE3F2FD), iconColor: Color(0xFF1E88E5), route: AppRoutes.thixMoneyTontines),
    ServiceItem(label: 'Éducation', icon: Icons.school, bg: Color(0xFFEDE7F6), iconColor: Color(0xFF5E35B1), route: AppRoutes.education),
    ServiceItem(label: 'Virement international', icon: Icons.language, bg: Color(0xFFE3F2FD), iconColor: Color(0xFF039BE5), route: AppRoutes.thixMoneySend),
    ServiceItem(label: 'Microfinance', icon: Icons.account_balance, bg: Color(0xFFE8F5E9), iconColor: Color(0xFF388E3C), route: AppRoutes.thixMoneyLoans),
    ServiceItem(label: 'Investissement', icon: Icons.trending_up, bg: Color(0xFFFFF3E0), iconColor: Color(0xFFFF9800), route: AppRoutes.thixMoneyInvestments),
    ServiceItem(label: 'Planification', icon: Icons.assignment, bg: Color(0xFFE3F2FD), iconColor: Color(0xFF1976D2), route: AppRoutes.thixMoneySavings),
  ];

  void _onTap(BuildContext context, ServiceItem item) {
    if (item.route!= null) {
      context.push(item.route!);
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            Icon(item.icon, size: 48, color: item.iconColor),
            const SizedBox(height: 12),
            Text(item.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text('${item.label} lié à votre THIX ID vérifié en base profiles. Bientôt disponible.', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer'))),
          ]),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemCount: _services.length,
      itemBuilder: (_, i) {
        final s = _services[i];
        return InkWell(
          onTap: () => _onTap(context, s),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
            padding: const EdgeInsets.all(8),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: s.bg, shape: BoxShape.circle), child: Icon(s.icon, color: s.iconColor, size: 22)),
              const SizedBox(height: 8),
              Text(s.label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
            ]),
          ),
        );
      },
    );
  }
}
