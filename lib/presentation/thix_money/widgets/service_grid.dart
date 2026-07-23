// lib/presentation/thix_money/widgets/service_grid.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/nav.dart';

class _Service {
  final String label;
  final Color color; // Remplacement du gradient par une couleur unique forte
  final IconData icon;
  final String? route;
  const _Service({required this.label, required this.color, required this.icon, this.route});
}

class ServiceGrid extends StatelessWidget {
  const ServiceGrid({super.key});

  // Utilisation des couleurs dominantes pour chaque service
  static const _services = [
    _Service(label: 'Crédit\ninstantané', color: Color(0xFF2D6CDF), icon: Icons.bolt_rounded, route: AppRoutes.thixMoneyLoans),
    _Service(label: 'Assurance', color: Color(0xFF22A57D), icon: Icons.shield_rounded, route: null),
    _Service(label: 'Épargne\nplanifiée', color: Color(0xFFE3B23C), icon: Icons.savings_rounded, route: AppRoutes.thixMoneySavings),
    _Service(label: 'Change', color: Color(0xFF9B5CF6), icon: Icons.swap_horiz_rounded, route: null),
    _Service(label: 'Marchand', color: Color(0xFFDC7A2B), icon: Icons.storefront_rounded, route: AppRoutes.thixMarket),
    _Service(label: 'Don &\nContributions', color: Color(0xFFE84A7A), icon: Icons.volunteer_activism_rounded, route: null),
    _Service(label: 'Ma Tontine', color: Color(0xFF2D9CDB), icon: Icons.groups_rounded, route: AppRoutes.thixMoneyTontines),
    _Service(label: 'Éducation', color: Color(0xFF3AB6D9), icon: Icons.school_rounded, route: AppRoutes.education),
    _Service(label: 'Virement\ninternational', color: Color(0xFF1E3A8A), icon: Icons.public_rounded, route: AppRoutes.thixMoneySend),
    _Service(label: 'Microfinance', color: Color(0xFF4CAF50), icon: Icons.account_balance_rounded, route: AppRoutes.thixMoneyLoans),
    _Service(label: 'Investissement', color: Color(0xFFD4A72C), icon: Icons.trending_up_rounded, route: AppRoutes.thixMoneyInvestments),
    _Service(label: 'Planification', color: Color(0xFF123B7A), icon: Icons.calendar_month_rounded, route: AppRoutes.thixMoneySavings),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12, // Espacement vertical réduit
        crossAxisSpacing: 8,  // Espacement horizontal réduit
        childAspectRatio: 0.80, // Ajusté pour rapprocher le texte de l'icône
      ),
      itemCount: _services.length,
      itemBuilder: (_, i) {
        final s = _services[i];
        return InkWell(
          onTap: () => s.route != null ? context.push(s.route!) : null,
          splashColor: s.color.withOpacity(0.1),
          highlightColor: s.color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                width: 52, // Légèrement plus grand pour bien respirer en cercle
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle, // Forme circulaire comme sur la photo
                  boxShadow: [
                    // Ombre douce colorée (Glow effect)
                    BoxShadow(
                      color: s.color.withOpacity(0.15), 
                      blurRadius: 12, 
                      offset: const Offset(0, 4)
                    ),
                    // Ombre grise très subtile pour la profondeur
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03), 
                      blurRadius: 4, 
                      offset: const Offset(0, 1)
                    ),
                  ],
                ),
                child: Icon(s.icon, color: s.color, size: 24), // L'icône prend la couleur
              ),
              const SizedBox(height: 6), // Espace réduit entre l'icône et le texte
              Text(
                s.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(
                  fontSize: 9.5, 
                  fontWeight: FontWeight.w600, 
                  color: Color(0xFF0A1F44), 
                  height: 1.15, 
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
