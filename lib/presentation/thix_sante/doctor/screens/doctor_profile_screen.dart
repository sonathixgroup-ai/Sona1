// 📁 lib/presentation/thix_sante/doctor/screens/doctor_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../common/widgets/gradient_button.dart';

class DoctorProfileScreen extends ConsumerWidget {
  const DoctorProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doctor = {
      'name': 'Dr. Martin',
      'specialty': 'Cardiologue',
      'email': 'dr.martin@hopital.fr',
      'phone': '+33 6 12 34 56 78',
      'hospital': 'Hôpital Central',
      'years': '12 ans d\'expérience',
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
                child: Icon(Icons.local_hospital, size: 50, color: Colors.green),
              ),
            ),
            const SizedBox(height: 16),
            Text(doctor['name']!, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(doctor['specialty']!, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            const SizedBox(height: 20),
            _buildInfoRow('📧 Email', doctor['email']!),
            _buildInfoRow('📞 Téléphone', doctor['phone']!),
            _buildInfoRow('🏥 Hôpital', doctor['hospital']!),
            _buildInfoRow('📅 Expérience', doctor['years']!),
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
          Text(value, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ],
      ),
    );
  }
}
