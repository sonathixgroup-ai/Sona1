// 📁 lib/presentation/thix_sante/pharmacy/widgets/order_status_timeline.dart

import 'package:flutter/material.dart';
import '../../../common/widgets/pill_badge.dart';

class OrderStatusTimeline extends StatelessWidget {
  final String currentStatus;
  final DateTime? createdAt;
  final DateTime? validatedAt;
  final DateTime? deliveredAt;

  const OrderStatusTimeline({
    Key? key,
    required this.currentStatus,
    this.createdAt,
    this.validatedAt,
    this.deliveredAt,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final statuses = [
      {'key': 'created', 'label': 'Créée', 'icon': Icons.add_circle_outline},
      {'key': 'validated', 'label': 'Validée', 'icon': Icons.verified_outline},
      {'key': 'prepared', 'label': 'Préparée', 'icon': Icons.inventory},
      {'key': 'delivered', 'label': 'Livrée', 'icon': Icons.delivery_dining},
    ];

    final statusOrder = ['created', 'validated', 'prepared', 'delivered'];
    final currentIndex = statusOrder.indexOf(currentStatus);

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
              const Icon(Icons.timeline, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              const Text(
                'Suivi de la commande',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              PillBadge(
                text: currentStatus.toUpperCase(),
                color: currentIndex >= 2 ? Colors.green : Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...statuses.asMap().entries.map((entry) {
            final index = entry.key;
            final status = entry.value;
            final isDone = index <= currentIndex;
            final isLast = index == statuses.length - 1;

            return Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDone ? Colors.green : Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isDone ? Icons.check : status['icon'] as IconData,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 30,
                          color: isDone ? Colors.green : Colors.grey.shade200,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status['label'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isDone ? FontWeight.w600 : FontWeight.w400,
                          color: isDone ? Colors.black : Colors.grey.shade500,
                        ),
                      ),
                      if (isDone) ...[
                        const SizedBox(height: 2),
                        Text(
                          _getDateForStatus(status['key'] as String),
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  String _getDateForStatus(String statusKey) {
    switch (statusKey) {
      case 'created':
        return createdAt != null
            ? '${createdAt!.day}/${createdAt!.month}/${createdAt!.year} ${createdAt!.hour}:${createdAt!.minute.toString().padLeft(2, '0')}'
            : '';
      case 'validated':
        return validatedAt != null
            ? '${validatedAt!.day}/${validatedAt!.month}/${validatedAt!.year} ${validatedAt!.hour}:${validatedAt!.minute.toString().padLeft(2, '0')}'
            : '';
      case 'delivered':
        return deliveredAt != null
            ? '${deliveredAt!.day}/${deliveredAt!.month}/${deliveredAt!.year} ${deliveredAt!.hour}:${deliveredAt!.minute.toString().padLeft(2, '0')}'
            : '';
      default:
        return '';
    }
  }
}
