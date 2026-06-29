// 📁 lib/presentation/thix_sante/doctor/widgets/prescription_preview.dart

import 'package:flutter/material.dart';
import '../../../common/widgets/gradient_button.dart';

class PrescriptionPreview extends StatelessWidget {
  final List<Map<String, String>> items;
  final VoidCallback onValidate;
  final VoidCallback onCancel;

  const PrescriptionPreview({
    Key? key,
    required this.items,
    required this.onValidate,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ordonnance',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final item = items[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${index + 1}. ${item['drug']}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      Text('Dosage: ${item['dosage']}', style: const TextStyle(fontSize: 11)),
                      if (item['duration']?.isNotEmpty == true)
                        Text('Durée: ${item['duration']}', style: const TextStyle(fontSize: 11)),
                      if (item['instructions']?.isNotEmpty == true)
                        Text('Instructions: ${item['instructions']}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GradientButton(
                    text: 'Valider',
                    onPressed: onValidate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text('Annuler', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
