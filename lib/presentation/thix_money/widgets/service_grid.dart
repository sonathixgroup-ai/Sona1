// lib/presentation/thix_money/widgets/service_grid.dart
import 'package:flutter/material.dart';

class ServiceGrid extends StatelessWidget {
  const ServiceGrid({super.key});
  @override
  Widget build(BuildContext context) {
    final services = [
      {'icon': Icons.bolt_rounded, 'label': 'Crédit instantané', 'color': Colors.green},
      {'icon': Icons.shield_rounded, 'label': 'Assurance', 'color': Colors.blue},
      {'icon': Icons.track_changes_rounded, 'label': 'Épargne planifiée', 'color': Colors.red},
      {'icon': Icons.swap_horiz_rounded, 'label': 'Change', 'color': Colors.green},
      {'icon': Icons.store_rounded, 'label': 'Marchand', 'color': Colors.purple},
      {'icon': Icons.volunteer_activism_rounded, 'label': 'Don & Contributions', 'color': Colors.pink},
      {'icon': Icons.groups_rounded, 'label': 'Ma Tontine', 'color': Colors.blue},
      {'icon': Icons.school_rounded, 'label': 'Éducation', 'color': Colors.deepPurple},
      {'icon': Icons.public_rounded, 'label': 'Virement international', 'color': Colors.blue},
      {'icon': Icons.account_balance_rounded, 'label': 'Microfinance', 'color': Colors.green},
      {'icon': Icons.trending_up_rounded, 'label': 'Investissement', 'color': Colors.orange},
      {'icon': Icons.assignment_rounded, 'label': 'Planification', 'color': Colors.blue},
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, childAspectRatio: 0.85, crossAxisSpacing: 8, mainAxisSpacing: 8),
        itemCount: services.length,
        itemBuilder: (_, i) {
          final s = services[i];
          return Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: (s['color'] as Color).withOpacity(0.1), shape: BoxShape.circle), child: Icon(s['icon'] as IconData, size: 20, color: s['color'] as Color)),
              const SizedBox(height: 6),
              Text(s['label'] as String, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600), maxLines: 2),
            ]),
          );
        },
      ),
    );
  }
}
