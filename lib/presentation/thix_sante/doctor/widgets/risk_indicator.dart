// 📁 lib/presentation/thix_sante/doctor/widgets/risk_indicator.dart

import 'package:flutter/material.dart';

class RiskIndicator extends StatelessWidget {
  final String condition;
  final double probability; // 0.0 to 1.0
  final VoidCallback onViewDetails;

  const RiskIndicator({
    Key? key,
    required this.condition,
    required this.probability,
    required this.onViewDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color color;
    if (probability >= 0.7) {
      color = Colors.red;
    } else if (probability >= 0.4) {
      color = Colors.orange;
    } else {
      color = Colors.green;
    }

    return InkWell(
      onTap: onViewDetails,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(condition, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: probability,
                    backgroundColor: Colors.grey.shade200,
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(probability * 100).toInt()}%',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
