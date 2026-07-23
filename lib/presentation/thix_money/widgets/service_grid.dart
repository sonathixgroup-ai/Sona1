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

  // Utilisation des icônes "_outlined" (plus fines, plus élégantes, style Apple/Premium)
  static const _services = [
    _Service(label: 'Crédit\ninstantané', color: Color(0xFF2D6CDF), icon: Icons.bolt_outlined, route: AppRoutes.thixMoneyLoans),
    _Service(label: 'Assurance', color: Color(0xFF22A57D), icon: Icons.security_outlined, route: null),
    _Service(label: 'Épargne', color: Color(0xFFE3B23C), icon: Icons.savings_outlined, route: AppRoutes.thixMoneySavings),
    _Service(label: 'Change', color: Color(0xFF9B5CF6), icon: Icons.currency_exchange_outlined, route: null),
    _Service(label: 'Marchand', color: Color(0xFFDC7A2B), icon: Icons.storefront_outlined, route: AppRoutes.thixMarket),
    _Service(label: 'Dons', color: Color(0xFFE84A7A), icon: Icons.favorite_border_rounded, route: null), // Cœur fin
    _Service(label: 'Ma Tontine', color: Color(0xFF2D9CDB), icon: Icons.groups_outlined, route: AppRoutes.thixMoneyTontines),
    _Service(label: 'Éducation', color: Color(0xFF3AB6D9), icon: Icons.school_outlined, route: AppRoutes.education),
    _Service(label: 'Virement', color: Color(0xFF1E3A8A), icon: Icons.language_outlined, route: AppRoutes.thixMoneySend), // Globe fin
    _Service(label: 'Microfinance', color: Color(0xFF4CAF50), icon: Icons.account_balance_outlined, route: AppRoutes.thixMoneyLoans),
    _Service(label: 'Investir', color: Color(0xFFD4A72C), icon: Icons.show_chart_rounded, route: AppRoutes.thixMoneyInvestments), // Graphique fin
    _Service(label: 'Planifier', color: Color(0xFF123B7A), icon: Icons.calendar_month_outlined, route: AppRoutes.thixMoneySavings),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8, // ESPACE VERTICAL RÉDUIT
        crossAxisSpacing: 4, // ESPACE HORIZONTAL RÉDUIT
        childAspectRatio: 0.88, // AUGMENTÉ (rapproche visuellement le texte du cercle)
      ),
      itemCount: _services.length,
      itemBuilder: (_, i) {
        final s = _services[i];
        
        return GestureDetector(
          // HitTestBehavior.opaque force Flutter à détecter le clic même sur les espaces transparents
          behavior: HitTestBehavior.opaque, 
          onTap: () {
            if (s.route != null && s.route!.isNotEmpty) {
              context.push(s.route!);
            } else {
              // Preuve visuelle que le clic fonctionne sur les boutons inactifs
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${s.label.replaceAll('\n', ' ')} sera bientôt disponible !'),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            }
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                width: 50, 
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    // Ombre lumineuse très douce
                    BoxShadow(
                      color: s.color.withOpacity(0.18), 
                      blurRadius: 10, 
                      offset: const Offset(0, 4)
                    ),
                  ],
                ),
                child: Icon(s.icon, color: s.color, size: 24), // Taille de l'icône équilibrée
              ),
              const SizedBox(height: 6), // Espace très réduit entre l'icône et le texte
              Text(
                s.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(
                  fontSize: 10, 
                  fontWeight: FontWeight.w600, 
                  color: Color(0xFF0A1F44), 
                  height: 1.1, 
                  letterSpacing: -0.2
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
