// 📁 lib/presentation/thix_sante/patient/widgets/quick_services.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../common/widgets/section_title.dart';

class QuickServices extends StatelessWidget {
  const QuickServices({Key? key}) : super(key: key);

  final List<Map<String, dynamic>> services = const [
    {'icon': Icons.search, 'label': 'Médecin', 'route': '/patient/doctors'},
    {'icon': Icons.folder, 'label': 'Dossier', 'route': '/patient/medical-record'},
    {'icon': Icons.analytics, 'label': 'Analyses', 'route': '/patient/analysis'},
    {'icon': Icons.receipt, 'label': 'Ordonnances', 'route': '/patient/prescriptions'},
    {'icon': Icons.local_hospital, 'label': 'Hôpital', 'route': '/emergency-map'},
    {'icon': Icons.local_pharmacy, 'label': 'Pharmacie', 'route': '/emergency-map'},
    {'icon': Icons.warning, 'label': 'Urgences', 'route': '/emergency-screen'},
    {'icon': Icons.phone, 'label': '15', 'route': 'tel:15'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SectionTitle(title: 'Services rapides', showDivider: false),
        const SizedBox(height: 8),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          childAspectRatio: 0.9,
          children: services.map((service) {
            return _ServiceItem(
              icon: service['icon'],
              label: service['label'],
              onTap: () {
                if (service['route'] == 'tel:15') {
                  // Logique d'appel
                } else {
                  context.push(service['route']);
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ServiceItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ServiceItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22, color: Colors.green.shade700),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
