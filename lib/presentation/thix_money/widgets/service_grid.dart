// lib/presentation/thix_money/widgets/service_grid.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/nav.dart';

class _Service {
  final String label;
  final Color color;
  final IconData icon;
  final String? route;
  const _Service({required this.label, required this.color, required this.icon, this.route});
}

class ServiceGrid extends StatelessWidget {
  const ServiceGrid({super.key});

  static const _services = [
    _Service(label: 'Crédit', color: Color(0xFF1E3A8A), icon: Icons.bolt_outlined, route: AppRoutes.thixMoneyLoans),
    _Service(label: 'Assurance', color: Color(0xFF0F766E), icon: Icons.security_outlined, route: null),
    _Service(label: 'Épargne', color: Color(0xFFB45309), icon: Icons.savings_outlined, route: AppRoutes.thixMoneySavings),
    _Service(label: 'Change', color: Color(0xFF6D28D9), icon: Icons.currency_exchange_outlined, route: null),
    _Service(label: 'Marchand', color: Color(0xFFC2410C), icon: Icons.storefront_outlined, route: AppRoutes.thixMarket),
    _Service(label: 'Dons', color: Color(0xFFBE123C), icon: Icons.favorite_border_rounded, route: null),
    _Service(label: 'Tontine', color: Color(0xFF0369A1), icon: Icons.groups_outlined, route: AppRoutes.thixMoneyTontines),
    _Service(label: 'Éducation', color: Color(0xFF0E7490), icon: Icons.school_outlined, route: AppRoutes.education),
    _Service(label: 'Virement', color: Color(0xFF1D4ED8), icon: Icons.language_outlined, route: AppRoutes.thixMoneySend),
    _Service(label: 'Microfinance', color: Color(0xFF15803D), icon: Icons.account_balance_outlined, route: AppRoutes.thixMoneyLoans),
    _Service(label: 'Investir', color: Color(0xFFB45309), icon: Icons.show_chart_rounded, route: AppRoutes.thixMoneyInvestments),
    _Service(label: 'Planifier', color: Color(0xFF0F172A), icon: Icons.calendar_month_outlined, route: AppRoutes.thixMoneySavings),
  ];

  @override
  Widget build(BuildContext context) {
    // Grille resserrée : icônes petites, espacement réduit, pas de vide
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: GridView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 12,
          crossAxisSpacing: 2,
          childAspectRatio: 0.82,
        ),
        itemCount: _services.length,
        itemBuilder: (_, i) {
          final s = _services[i];

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (s.route != null && s.route!.isNotEmpty) {
                context.push(s.route!);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${s.label.replaceAll('\n', ' ')} sera bientôt disponible !'),
                    duration: const Duration(seconds: 2),
                    backgroundColor: const Color(0xFF0F172A),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: s.color.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: s.color.withOpacity(0.1), width: 1),
                  ),
                  child: Icon(s.icon, color: s.color, size: 19),
                ),
                const SizedBox(height: 6),
                Text(
                  s.label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
