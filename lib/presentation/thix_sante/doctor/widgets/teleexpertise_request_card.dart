// 📁 lib/presentation/thix_sante/doctor/widgets/teleexpertise_request_card.dart

import 'package:flutter/material.dart';
import '../../../common/widgets/gradient_button.dart';
import '../../../common/widgets/pill_badge.dart';

class TeleexpertiseRequestCard extends StatelessWidget {
  final String patientName;
  final String description;
  final String date;
  final String? imageUrl;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const TeleexpertiseRequestCard({
    Key? key,
    required this.patientName,
    required this.description,
    required this.date,
    this.imageUrl,
    required this.onAccept,
    required this.onDecline,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Center(child: Icon(Icons.medical_services, size: 20, color: Colors.orange)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(patientName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    Text(date, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              PillBadge(text: 'En attente', color: Colors.orange),
            ],
          ),
          const SizedBox(height: 12),
          Text(description, style: const TextStyle(fontSize: 12), maxLines: 2),
          if (imageUrl != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(imageUrl!, height: 100, width: double.infinity, fit: BoxFit.cover),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GradientButton(
                  text: 'Accepter',
                  onPressed: onAccept,
                  gradient: const LinearGradient(colors: [Colors.green, Colors.greenAccent]),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: onDecline,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('Refuser', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
