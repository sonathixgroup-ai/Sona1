// 📁 lib/presentation/thix_sante/pharmacy/screens/pharmacy_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../common/widgets/gradient_button.dart';

class PharmacyProfileScreen extends ConsumerWidget {
  const PharmacyProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pharmacy = {
      'name': 'Pharmacie Dubois',
      'address': '12 rue de la République, 75001 Paris',
      'phone': '+33 1 23 45 67 89',
      'email': 'contact@pharmacie-dubois.fr',
      'siret': '123 456 789 00012',
      'opening': '09:00 - 19:30 (Lun-Sam)',
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.local_pharmacy, size: 50, color: Colors.green),
              ),
            ),
            const SizedBox(height: 16),
            Text(pharmacy['name']!, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(pharmacy['address']!, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            const SizedBox(height: 20),
            _buildInfoRow('📞 Téléphone', pharmacy['phone']!),
            _buildInfoRow('📧 Email', pharmacy['email']!),
            _buildInfoRow('📌 SIRET', pharmacy['siret']!),
            _buildInfoRow('🕐 Horaires', pharmacy['opening']!),
            const SizedBox(height: 20),
            GradientButton(
              text: 'Modifier le profil',
              onPressed: () {},
              icon: Icons.edit,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {},
              child: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
