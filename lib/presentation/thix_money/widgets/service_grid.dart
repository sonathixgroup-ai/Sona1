// lib/presentation/thix_money/widgets/service_grid.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/nav.dart';

class _Service {
  final String label;
  final List<Color> gradient;
  final String emoji;
  final String? route;
  const _Service({required this.label, required this.gradient, required this.emoji, this.route});
}

class ServiceGrid extends StatelessWidget {
  const ServiceGrid({super.key});

  static const _services = [
    _Service(label: 'Crédit\ninstantané', gradient: [Color(0xFF2D6CDF), Color(0xFF123B7A)], emoji: '⚡', route: AppRoutes.thixMoneyLoans),
    _Service(label: 'Assurance', gradient: [Color(0xFF1FA97F), Color(0xFF0E6B4E)], emoji: '🛡️', route: null),
    _Service(label: 'Épargne\nplanifiée', gradient: [Color(0xFFE3B23C), Color(0xFFB8862A)], emoji: '💰', route: AppRoutes.thixMoneySavings),
    _Service(label: 'Change', gradient: [Color(0xFF9B59B6), Color(0xFF5E3370)], emoji: '⇄', route: null),
    _Service(label: 'Marchand', gradient: [Color(0xFFE0743C), Color(0xFF9C4A22)], emoji: '🏬', route: AppRoutes.thixMarket),
    _Service(label: 'Don &\nContributions', gradient: [Color(0xFFE0507A), Color(0xFF9C2E4E)], emoji: '🤝', route: null),
    _Service(label: 'Ma Tontine', gradient: [Color(0xFF2DA6DF), Color(0xFF12557A)], emoji: '👥', route: AppRoutes.thixMoneyTontines),
    _Service(label: 'Éducation', gradient: [Color(0xFF3CB4E3), Color(0xFF1D6F8C)], emoji: '🎓', route: AppRoutes.education),
    _Service(label: 'Virement\ninternational', gradient: [Color(0xFF123B7A), Color(0xFF0A1F44)], emoji: '🌍', route: AppRoutes.thixMoneySend),
    _Service(label: 'Microfinance', gradient: [Color(0xFF4CAF50), Color(0xFF2E6B30)], emoji: '🏦', route: AppRoutes.thixMoneyLoans),
    _Service(label: 'Investissement', gradient: [Color(0xFFE3B23C), Color(0xFF8A6420)], emoji: '📈', route: AppRoutes.thixMoneyInvestments),
    _Service(label: 'Planification', gradient: [Color(0xFF2D6CDF), Color(0xFF1A3D8C)], emoji: '📅', route: AppRoutes.thixMoneySavings),
  ];

  void _onTap(BuildContext context, _Service item) {
    if (item.route!= null) {
      context.push(item.route!);
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (_) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            Container(width: 64, height: 64, decoration: BoxDecoration(gradient: LinearGradient(colors: item.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(18)), child: Center(child: Text(item.emoji, style: const TextStyle(fontSize: 28)))),
            const SizedBox(height: 12),
            Text(item.label.replaceAll('\n', ' '), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF0A1F44))),
            const SizedBox(height: 8),
            Text('${item.label.replaceAll('\n', ' ')} lié à votre THIX ID ${"THIX-CD-0726-81105-BWG-0"} vérifié. Bientôt disponible.', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4)),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, height: 48, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A1F44), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), onPressed: () => Navigator.pop(context), child: const Text('Fermer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
          ]),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 18,
        crossAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: _services.length,
      itemBuilder: (_, i) {
        final s = _services[i];
        return InkWell(
          onTap: () => _onTap(context, s),
          borderRadius: BorderRadius.circular(18),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: s.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: s.gradient.last.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Center(child: Text(s.emoji, style: const TextStyle(fontSize: 22))),
              ),
              const SizedBox(height: 7),
              Text(
                s.label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10.2, fontWeight: FontWeight.w600, color: Color(0xFF0A1F44), height: 1.2, letterSpacing: -0.1),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}
