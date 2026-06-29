// 📁 lib/presentation/thix_sante/pharmacy/widgets/order_card.dart

import 'package:flutter/material.dart';
import '../../../common/widgets/pill_badge.dart';
import '../../../common/widgets/gradient_button.dart';

class OrderCard extends StatelessWidget {
  final String orderId;
  final String patientName;
  final String date;
  final String status; // pending, preparing, ready, delivered
  final int itemCount;
  final VoidCallback onTap;
  final VoidCallback? onProcess;

  const OrderCard({
    Key? key,
    required this.orderId,
    required this.patientName,
    required this.date,
    required this.status,
    required this.itemCount,
    required this.onTap,
    this.onProcess,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        statusLabel = 'En attente';
        statusIcon = Icons.pending;
        break;
      case 'preparing':
        statusColor = Colors.blue;
        statusLabel = 'Préparation';
        statusIcon = Icons.inventory;
        break;
      case 'ready':
        statusColor = Colors.green;
        statusLabel = 'Prêt';
        statusIcon = Icons.check_circle;
        break;
      case 'delivered':
        statusColor = Colors.grey;
        statusLabel = 'Livré';
        statusIcon = Icons.delivery_dining;
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = 'Inconnu';
        statusIcon = Icons.help;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
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
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(statusIcon, size: 20, color: statusColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Commande #$orderId',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        patientName,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                PillBadge(
                  text: statusLabel,
                  color: statusColor,
                  fontSize: 10,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  date,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                const SizedBox(width: 16),
                Icon(Icons.medication, size: 12, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  '$itemCount médicament${itemCount > 1 ? 's' : ''}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                const Spacer(),
                if (status == 'pending' || status == 'preparing')
                  GradientButton(
                    text: status == 'pending' ? 'Traiter' : 'Préparer',
                    onPressed: onProcess ?? () {},
                    width: 90,
                    height: 32,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
