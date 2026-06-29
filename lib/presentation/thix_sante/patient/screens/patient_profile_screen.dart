// 📁 lib/presentation/thix_sante/patient/screens/patient_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../common/widgets/gradient_button.dart';
import '../../../shared/providers/role_provider.dart';

class PatientProfileScreen extends ConsumerWidget {
  const PatientProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patient = {
      'name': 'Michel Dupont',
      'email': 'michel.dupont@email.com',
      'phone': '+33 6 12 34 56 78',
      'birthDate': '15/03/1985',
      'bloodType': 'A+',
      'allergies': 'Pénicilline',
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
                child: Icon(Icons.person, size: 50, color: Colors.green),
              ),
            ),
            const SizedBox(height: 16),
            Text(patient['name']!, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(patient['email']!, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            const SizedBox(height: 20),
            _buildInfoRow('📞 Téléphone', patient['phone']!),
            _buildInfoRow('🎂 Date de naissance', patient['birthDate']!),
            _buildInfoRow('🩸 Groupe sanguin', patient['bloodType']!),
            _buildInfoRow('⚠️ Allergies', patient['allergies']!),
            const SizedBox(height: 20),
            GradientButton(
              text: 'Modifier le profil',
              onPressed: () {},
              icon: Icons.edit,
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                ref.read(roleProvider.notifier).switchRole(UserRole.doctor);
              },
              icon: const Icon(Icons.switch_account),
              label: const Text('Basculer en mode médecin (test)'),
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
          Text(value, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ],
      ),
    );
  }
}
