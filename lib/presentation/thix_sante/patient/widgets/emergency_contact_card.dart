// 📁 lib/presentation/thix_sante/patient/widgets/emergency_contact_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../common/widgets/gradient_button.dart';

class EmergencyContactCard extends ConsumerWidget {
  const EmergencyContactCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text('Urgence médicale', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red)),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'En cas d\'urgence, appelez immédiatement le 15. Votre localisation et vos informations médicales seront partagées.',
            style: TextStyle(fontSize: 12, color: Colors.red),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GradientButton(
                  text: '📞 Appeler le 15',
                  onPressed: () {
                    // Lancer appel
                  },
                  gradient: const LinearGradient(colors: [Colors.red, Colors.redAccent]),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GradientButton(
                  text: '🆘 Alerte famille',
                  onPressed: () {
                    // Envoyer notification aux proches
                  },
                  gradient: LinearGradient(colors: [Colors.orange.shade700, Colors.orange]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
