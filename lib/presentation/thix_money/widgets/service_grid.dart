// lib/presentation/thix_money/widgets/service_grid.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/nav.dart';

class _GridItem {
  final String label;
  final IconData icon;
  final bool accent;
  final String? route;
  const _GridItem({required this.label, required this.icon, this.accent = false, this.route});
}

class ServiceGrid extends StatelessWidget {
  const ServiceGrid({super.key});

  static const navy = Color(0xFF123B7A);
  static const gold = Color(0xFFE3B23C);
  static const ivory = Color(0xFFF6F7FB);
  static const navyDeep = Color(0xFF0A1F44);

  // Ordre et accents identiques au mockup HTML V2
  static const _items = [
    _GridItem(label: 'Envoyer', icon: Icons.call_made_rounded, route: AppRoutes.thixMoneySend),
    _GridItem(label: 'Recharger', icon: Icons.add_card_outlined, accent: true, route: AppRoutes.thixMoneyRecharge),
    _GridItem(label: 'Scanner', icon: Icons.qr_code_scanner_outlined, route: AppRoutes.thixMoneyScanner),
    _GridItem(label: 'Retrait', icon: Icons.call_received_rounded, route: null),

    _GridItem(label: 'Crédit instantané', icon: Icons.bolt_outlined, route: AppRoutes.thixMoneyLoans),
    _GridItem(label: 'Assurance', icon: Icons.shield_outlined, route: null),
    _GridItem(label: 'Épargne planifiée', icon: Icons.savings_outlined, accent: true, route: AppRoutes.thixMoneySavings),
    _GridItem(label: 'Change', icon: Icons.currency_exchange_outlined, route: null),

    _GridItem(label: 'Marchand', icon: Icons.storefront_outlined, route: AppRoutes.thixMarket),
    _GridItem(label: 'Don & Contributions', icon: Icons.volunteer_activism_outlined, route: null),
    _GridItem(label: 'Ma Tontine', icon: Icons.groups_outlined, accent: true, route: AppRoutes.thixMoneyTontines),
    _GridItem(label: 'Éducation', icon: Icons.school_outlined, route: AppRoutes.education),

    _GridItem(label: 'Virement international', icon: Icons.public_outlined, route: AppRoutes.thixMoneySend),
    _GridItem(label: 'Microfinance', icon: Icons.account_balance_outlined, route: AppRoutes.thixMoneyLoans),
    _GridItem(label: 'Investissement', icon: Icons.show_chart_rounded, accent: true, route: AppRoutes.thixMoneyInvestments),
    _GridItem(label: 'Planification', icon: Icons.calendar_month_outlined, route: AppRoutes.thixMoneySavings),
  ];

  void _handleTap(BuildContext context, _GridItem item) {
    if (item.route != null && item.route!.isNotEmpty) {
      context.push(item.route!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.label} sera bientôt disponible !'),
          duration: const Duration(seconds: 2),
          backgroundColor: navyDeep,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 6),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 26,
          crossAxisSpacing: 4,
          childAspectRatio: 0.68,
        ),
        itemBuilder: (context, i) {
          final item = _items[i];
          return InkWell(
            onTap: () => _handleTap(context, item),
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: ivory,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    item.icon,
                    color: item.accent ? gold : navy,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  item.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: navyDeep,
                    height: 1.25,
                    letterSpacing: -0.1,
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
