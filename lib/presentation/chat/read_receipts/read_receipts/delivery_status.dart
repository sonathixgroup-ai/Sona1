// lib/presentation/chat/read_receipts/delivery_status.dart
// Widget icône pour le statut de livraison d'un message

import 'package:flutter/material.dart';

enum DeliveryStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

class DeliveryStatusIcon extends StatelessWidget {
  final DeliveryStatus status;
  final double size;

  const DeliveryStatusIcon({Key? key, required this.status, this.size = 16}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (status) {
      case DeliveryStatus.sending:
        icon = Icons.access_time;
        color = Colors.grey;
        break;
      case DeliveryStatus.sent:
        icon = Icons.check;
        color = Colors.grey;
        break;
      case DeliveryStatus.delivered:
        icon = Icons.done_all;
        color = Colors.grey;
        break;
      case DeliveryStatus.read:
        icon = Icons.done_all;
        color = Colors.blue;
        break;
      case DeliveryStatus.failed:
        icon = Icons.error_outline;
        color = Colors.red;
        break;
    }
    return Icon(icon, size: size, color: color);
  }
}
