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
  static const ink = Color(0xFF070F1E);
  static const line = Color(0xFFE8ECF3);

  static const _services = [
    _Service(label: 'Envoyer', color: Color(0xFF2D5BFF), icon: Icons.send_rounded, route: AppRoutes.thixMoneySend),
    _Service(label: 'Crédit', color: Color(0xFF2D5BFF), icon: Icons.bolt_rounded, route: AppRoutes.thixMoneyLoans),
    _Service(label: 'Acheter Carte', color: Color(0xFF7C3AED), icon: Icons.credit_card_rounded, route: null),
    _Service(label: 'Airtime', color: Color(0xFF0E9F6E), icon: Icons.call_rounded, route: null),
    _Service(label: 'Mes Comptes', color: Color(0xFF0A1931), icon: Icons.link_rounded, route: null),
    _Service(label: 'Transactions', color: Color(0xFFEA580C), icon: Icons.bar_chart_rounded, route: AppRoutes.thixMoneyLoans),
    _Service(label: 'Marchand', color: Color(0xFFEA580C), icon: Icons.storefront_rounded, route: AppRoutes.thixMarket),
    _Service(label: 'Support', color: Color(0xFF070F1E), icon: Icons.headset_mic_rounded, route: null),
    _Service(label: 'Épargne', color: Color(0xFFC5A46A), icon: Icons.savings_rounded, route: AppRoutes.thixMoneySavings),
    _Service(label: 'Tontine', color: Color(0xFF0EA5E9), icon: Icons.groups_rounded, route: AppRoutes.thixMoneyTontines),
    _Service(label: 'Investir', color: Color(0xFFCA8A04), icon: Icons.trending_up_rounded, route: AppRoutes.thixMoneyInvestments),
    _Service(label: 'Éducation', color: Color(0xFF0891B2), icon: Icons.school_rounded, route: AppRoutes.education),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: line)),
      child: GridView.builder(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 18, // ESPACE VERTICAL GÉNÉREUX
          crossAxisSpacing: 10,
          childAspectRatio: 0.78, // HAUTEUR POUR ÉVITER CHEVAUCHEMENT
        ),
        itemCount: _services.length,
        itemBuilder: (_, i) {
          final s = _services[i];
          return _Tile(s: s);
        },
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final _Service s; const _Tile({required this.s});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (s.route!= null && s.route!.isNotEmpty) context.push(s.route!);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56, height: 56, // PLUS GRAND QUE FYATU
            decoration: BoxDecoration(color: s.color.withOpacity(0.09), borderRadius: BorderRadius.circular(16), border: Border.all(color: s.color.withOpacity(0.12), width: 1)),
            child: Icon(s.icon, color: s.color, size: 26),
          ),
          const SizedBox(height: 12), // DISTANCE ICONE-TEXTE CORRIGÉE
          Text(s.label, textAlign: TextAlign.center, maxLines: 2, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF070F1E), height: 1.25)),
        ],
      ),
    );
  }
}
