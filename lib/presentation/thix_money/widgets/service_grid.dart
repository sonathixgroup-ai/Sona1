// lib/presentation/thix_money/widgets/service_grid.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/nav.dart';

class _Service {
  final String label;
  final IconData icon;
  final String? route;
  const _Service({required this.label, required this.icon, this.route});
}

class ServiceGrid extends StatelessWidget {
  const ServiceGrid({super.key});

  // Palette inspirée de Mixx (Bleu nuit institutionnel)
  static const Color primaryBlue = Color(0xFF003882); 

  // Les vraies routes, sans données fictives
  static const _services = [
    _Service(label: 'Envoyer', icon: Icons.send_outlined, route: AppRoutes.thixMoneySend),
    _Service(label: 'Recharger', icon: Icons.add_card_outlined, route: AppRoutes.thixMoneyRecharge),
    _Service(label: 'Lipa Simu', icon: Icons.qr_code_scanner_outlined, route: AppRoutes.thixMoneyScanner),
    _Service(label: 'Retrait', icon: Icons.call_received_rounded, route: null),
    
    _Service(label: 'Crédit', icon: Icons.bolt_outlined, route: AppRoutes.thixMoneyLoans),
    _Service(label: 'Assurance', icon: Icons.shield_outlined, route: null),
    _Service(label: 'Épargne', icon: Icons.savings_outlined, route: AppRoutes.thixMoneySavings),
    _Service(label: 'Change', icon: Icons.currency_exchange_outlined, route: null),
    
    _Service(label: 'Marchand', icon: Icons.storefront_outlined, route: AppRoutes.thixMarket),
    _Service(label: 'Dons', icon: Icons.volunteer_activism_outlined, route: null),
    _Service(label: 'Tontine', icon: Icons.groups_outlined, route: AppRoutes.thixMoneyTontines),
    _Service(label: 'Éducation', icon: Icons.school_outlined, route: AppRoutes.education),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Padding ajusté pour s'intégrer proprement sous le Header
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: GridView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 24, // Espacement aéré verticalement
          crossAxisSpacing: 8,
          childAspectRatio: 0.85, // Ajusté pour donner de la place au texte (2 lignes)
        ),
        itemCount: _services.length,
        itemBuilder: (_, i) {
          final s = _services[i];
          
          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              // Logique de navigation conservée
              if (s.route != null && s.route!.isNotEmpty) {
                context.push(s.route!);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${s.label} sera bientôt disponible !'),
                    duration: const Duration(seconds: 2),
                    backgroundColor: primaryBlue,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // 🌟 PLUS DE FOND COLORÉ : L'icône est nue, petite et élégante
                Icon(
                  s.icon, 
                  color: primaryBlue, 
                  size: 28 // Taille réduite pour coller à l'image
                ),
                const SizedBox(height: 10), 
                Text(
                  s.label,
                  textAlign: TextAlign.center,
                  maxLines: 2, // Permet au texte long de passer sur 2 lignes
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11, 
                    fontWeight: FontWeight.w600, 
                    color: primaryBlue, // Texte bleu comme dans Mixx
                    height: 1.2,
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
