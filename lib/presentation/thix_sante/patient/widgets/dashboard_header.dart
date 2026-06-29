// 📁 lib/presentation/thix_sante/patient/widgets/dashboard_header.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/role_provider.dart';

class DashboardHeader extends ConsumerWidget {
  const DashboardHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientName = 'Michel'; // À connecter au provider utilisateur
    final role = ref.watch(roleProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                patientName.isNotEmpty ? patientName[0].toUpperCase() : 'P',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green.shade700),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour, $patientName',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.verified_user, size: 12, color: Colors.green.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Compte Patient',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_none, size: 20, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}
