// lib/presentation/thix_money/widgets/service_grid.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/nav.dart';

class _Service {
  final String label;
  final List<Color> gradient;
  final IconData icon;
  final String? route;
  const _Service({required this.label, required this.gradient, required this.icon, this.route});
}

class ServiceGrid extends StatelessWidget {
  const ServiceGrid({super.key});

  static const _services = [
    _Service(label: 'Crédit\ninstantané', gradient: [Color(0xFF2D6CDF), Color(0xFF1E3A8A)], icon: Icons.bolt_rounded, route: AppRoutes.thixMoneyLoans),
    _Service(label: 'Assurance', gradient: [Color(0xFF22A57D), Color(0xFF0F6D4F)], icon: Icons.shield_rounded, route: null),
    _Service(label: 'Épargne\nplanifiée', gradient: [Color(0xFFE3B23C), Color(0xFFB47A12)], icon: Icons.savings_rounded, route: AppRoutes.thixMoneySavings),
    _Service(label: 'Change', gradient: [Color(0xFF9B5CF6), Color(0xFF6D2CC6)], icon: Icons.swap_horiz_rounded, route: null),
    _Service(label: 'Marchand', gradient: [Color(0xFFDC7A2B), Color(0xFF9A4A12)], icon: Icons.storefront_rounded, route: AppRoutes.thixMarket),
    _Service(label: 'Don &\nContributions', gradient: [Color(0xFFE84A7A), Color(0xFFB02A4E)], icon: Icons.volunteer_activism_rounded, route: null),
    _Service(label: 'Ma Tontine', gradient: [Color(0xFF2D9CDB), Color(0xFF1A5F8A)], icon: Icons.groups_rounded, route: AppRoutes.thixMoneyTontines),
    _Service(label: 'Éducation', gradient: [Color(0xFF3AB6D9), Color(0xFF1C7A9A)], icon: Icons.school_rounded, route: AppRoutes.education),
    _Service(label: 'Virement\ninternational', gradient: [Color(0xFF1E3A8A), Color(0xFF0A1F44)], icon: Icons.public_rounded, route: AppRoutes.thixMoneySend),
    _Service(label: 'Microfinance', gradient: [Color(0xFF4CAF50), Color(0xFF2E7D32)], icon: Icons.account_balance_rounded, route: AppRoutes.thixMoneyLoans),
    _Service(label: 'Investissement', gradient: [Color(0xFFD4A72C), Color(0xFF8A6A15)], icon: Icons.trending_up_rounded, route: AppRoutes.thixMoneyInvestments),
    _Service(label: 'Planification', gradient: [Color(0xFF2D6CDF), Color(0xFF123B7A)], icon: Icons.calendar_month_rounded, route: AppRoutes.thixMoneySavings),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 8,
        childAspectRatio: 0.82,
      ),
      itemCount: _services.length,
      itemBuilder: (_, i) {
        final s = _services[i];
        return InkWell(
          onTap: () => s.route!= null? context.push(s.route!) : null,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: s.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: s.gradient.last.withOpacity(0.25), blurRadius: 6, offset: const Offset(0, 3))],
                ),
                child: Icon(s.icon, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 4),
              Text(
                s.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF0A1F44), height: 1.1, letterSpacing: -0.2),
              ),
            ],
          ),
        );
      },
    );
  }
}
