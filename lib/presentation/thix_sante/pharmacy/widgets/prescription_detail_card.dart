// 📁 lib/presentation/thix_sante/pharmacy/widgets/prescription_detail_card.dart

import 'package:flutter/material.dart';
import '../../../common/widgets/pill_badge.dart';

class PrescriptionDetailCard extends StatelessWidget {
  final String doctorName;
  final String patientName;
  final String date;
  final List<Map<String, String>> items;
  final String status; // pending, validated, delivered
  final VoidCallback onValidate;
  final VoidCallback? onReject;

  const PrescriptionDetailCard({
    Key? key,
    required this.doctorName,
    required this.patientName,
    required this.date,
    required this.items,
    required this.status,
    required this.onValidate,
    this.onReject,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isPending = status == 'pending';

    return Container(
      padding: const EdgeInsets.all(16),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt, size: 20, color: Colors.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ordonnance',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Dr. $doctorName • $patientName',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              PillBadge(
                text: isPending ? 'À valider' : 'Validée',
                color: isPending ? Colors.orange : Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'] ?? '',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '${item['dosage']} • ${item['frequency']}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Qté: ${item['quantity'] ?? 1}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          )),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(
                date,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
              const Spacer(),
              if (isPending) ...[
                GradientButton(
                  text: 'Valider',
                  onPressed: onValidate,
                  width: 100,
                  height: 34,
                ),
                const SizedBox(width: 8),
                if (onReject != null)
                  OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text('Rejeter', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
