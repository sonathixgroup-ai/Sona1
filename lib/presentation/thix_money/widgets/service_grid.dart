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

  // Palette harmonisée et plus mature (Fintech Bank)
  static const _services = [
    _Service(label: 'Crédit', color: Color(0xFF1E3A8A), icon: Icons.bolt_outlined, route: AppRoutes.thixMoneyLoans), // Bleu Royal
    _Service(label: 'Assurance', color: Color(0xFF0F766E), icon: Icons.security_outlined, route: null), // Sarcelle sombre
    _Service(label: 'Épargne', color: Color(0xFFB45309), icon: Icons.savings_outlined, route: AppRoutes.thixMoneySavings), // Bronze/Or sombre
    _Service(label: 'Change', color: Color(0xFF6D28D9), icon: Icons.currency_exchange_outlined, route: null), // Violet institutionnel
    _Service(label: 'Marchand', color: Color(0xFFC2410C), icon: Icons.storefront_outlined, route: AppRoutes.thixMarket), // Cuivre
    _Service(label: 'Dons', color: Color(0xFFBE123C), icon: Icons.favorite_border_rounded, route: null), // Rouge Carmin
    _Service(label: 'Tontine', color: Color(0xFF0369A1), icon: Icons.groups_outlined, route: AppRoutes.thixMoneyTontines), // Bleu Océan
    _Service(label: 'Éducation', color: Color(0xFF0E7490), icon: Icons.school_outlined, route: AppRoutes.education), // Cyan sombre
    _Service(label: 'Virement', color: Color(0xFF1D4ED8), icon: Icons.language_outlined, route: AppRoutes.thixMoneySend), // Bleu Standard
    _Service(label: 'Microfinance', color: Color(0xFF15803D), icon: Icons.account_balance_outlined, route: AppRoutes.thixMoneyLoans), // Vert forêt
    _Service(label: 'Investir', color: Color(0xFFB45309), icon: Icons.show_chart_rounded, route: AppRoutes.thixMoneyInvestments), // Bronze
    _Service(label: 'Planifier', color: Color(0xFF0F172A), icon: Icons.calendar_month_outlined, route: AppRoutes.thixMoneySavings), // Ardoise foncée
  ];

  @override
  Widget build(BuildContext context) {
    // Encapsulation dans une belle carte blanche structurée (Inspiration Fyatu, mais identité Thix)
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04), // Ombre très premium
            blurRadius: 24, 
            offset: const Offset(0, 8)
          )
        ]
      ),
      child: GridView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 20, // Espacement aéré pour un look ordonné
          crossAxisSpacing: 8,
          childAspectRatio: 0.75, // Ajusté pour donner de la hauteur au bloc
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
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  width: 48, 
                  height: 48,
                  decoration: BoxDecoration(
                    color: s.color.withOpacity(0.06), // Fond subtil
                    borderRadius: BorderRadius.circular(14), // Plus carré (style iOS/Banque) au lieu du cercle
                    border: Border.all(color: s.color.withOpacity(0.1), width: 1),
                  ),
                  child: Icon(s.icon, color: s.color, size: 22), 
                ),
                const SizedBox(height: 8), 
                Text(
                  s.label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11, 
                    fontWeight: FontWeight.w700, 
                    color: Color(0xFF334155), // Gris ardoise (texte lisible et mature)
                    letterSpacing: -0.2
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
