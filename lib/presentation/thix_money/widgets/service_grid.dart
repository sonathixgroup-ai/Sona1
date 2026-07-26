// lib/presentation/thix_money/widgets/service_grid.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/nav.dart';

class _Service {
  final String label; final Color color; final IconData icon; final String? route;
  const _Service({required this.label, required this.color, required this.icon, this.route});
}

class ServiceGrid extends StatelessWidget {
  const ServiceGrid({super.key});
  static const ink = Color(0xFF080E1F);
  static const border = Color(0xFFEFF2F8);

  static const _services = [
    _Service(label: 'Crédit\nexpress', color: Color(0xFF2D5BFF), icon: Icons.bolt_rounded, route: AppRoutes.thixMoneyLoans),
    _Service(label: 'Assurance', color: Color(0xFF0E9F6E), icon: Icons.verified_user_rounded, route: null),
    _Service(label: 'Épargne', color: Color(0xFFC5A46A), icon: Icons.savings_rounded, route: AppRoutes.thixMoneySavings),
    _Service(label: 'Change', color: Color(0xFF7C3AED), icon: Icons.currency_exchange_rounded, route: null),
    _Service(label: 'Marchand', color: Color(0xFFEA580C), icon: Icons.storefront_rounded, route: AppRoutes.thixMarket),
    _Service(label: 'Dons', color: Color(0xFFE11D48), icon: Icons.favorite_rounded, route: null),
    _Service(label: 'Ma Tontine', color: Color(0xFF0EA5E9), icon: Icons.groups_rounded, route: AppRoutes.thixMoneyTontines),
    _Service(label: 'Éducation', color: Color(0xFF0891B2), icon: Icons.school_rounded, route: AppRoutes.education),
    _Service(label: 'Virement\nmondial', color: Color(0xFF0A1931), icon: Icons.public_rounded, route: AppRoutes.thixMoneySend),
    _Service(label: 'Micro\nfinance', color: Color(0xFF16A34A), icon: Icons.account_balance_rounded, route: AppRoutes.thixMoneyLoans),
    _Service(label: 'Investir', color: Color(0xFFCA8A04), icon: Icons.trending_up_rounded, route: AppRoutes.thixMoneyInvestments),
    _Service(label: 'Planifier', color: Color(0xFF080E1F), icon: Icons.calendar_month_rounded, route: AppRoutes.thixMoneySavings),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 14,
        crossAxisSpacing: 12,
        childAspectRatio: 0.70, // FIX MAJEUR : 0.88 -> 0.70 = beaucoup plus haut
      ),
      itemCount: _services.length,
      itemBuilder: (_, i) {
        final s = _services[i];
        final isDark = s.color == const Color(0xFF0A1931) || s.color == const Color(0xFF080E1F);
        return _ServiceTile(service: s, isDark: isDark);
      },
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final _Service service; final bool isDark;
  const _ServiceTile({required this.service, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 14, 6, 10), // PADDING VERTICAL FIX
      decoration: BoxDecoration(
        color: isDark? const Color(0xFF080E1F) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark? Colors.white.withOpacity(0.08) : ServiceGrid.border),
        boxShadow: [BoxShadow(color: const Color(0xFF080E1F).withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 5))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start, // PAS center, pour contrôler l'espace
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: isDark? Colors.white.withOpacity(0.1) : service.color.withOpacity(0.11), borderRadius: BorderRadius.circular(13)),
            child: Icon(service.icon, color: isDark? Colors.white : service.color, size: 22),
          ),
          const SizedBox(height: 14), // DISTANCE FIXE 14px
          Text(
            service.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark? Colors.white : const Color(0xFF080E1F), height: 1.3, letterSpacing: -0.1),
          ),
        ],
      ),
    );
  }
}
