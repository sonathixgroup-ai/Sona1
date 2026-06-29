// 📁 lib/presentation/thix_sante/doctor/widgets/alert_card.dart

import 'package:flutter/material.dart';
import '../../../common/widgets/gradient_button.dart';

enum AlertSeverity { low, medium, high }

class AlertCard extends StatelessWidget {
  final String patientName;
  final String message;
  final AlertSeverity severity;
  final VoidCallback onView;

  const AlertCard({
    Key? key,
    required this.patientName,
    required this.message,
    required this.severity,
    required this.onView,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    IconData icon;
    Color iconColor;

    switch (severity) {
      case AlertSeverity.high:
        backgroundColor = Colors.red.shade50;
        icon = Icons.warning_amber;
        iconColor = Colors.red;
        break;
      case AlertSeverity.medium:
        backgroundColor = Colors.orange.shade50;
        icon = Icons.notification_important;
        iconColor = Colors.orange;
        break;
      case AlertSeverity.low:
        backgroundColor = Colors.blue.shade50;
        icon = Icons.info_outline;
        iconColor = Colors.blue;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.transparent),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patientName,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GradientButton(
            text: 'Voir',
            onPressed: onView,
            width: 70,
            height: 34,
          ),
        ],
      ),
    );
  }
}
