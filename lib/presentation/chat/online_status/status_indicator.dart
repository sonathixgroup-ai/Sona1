// lib/presentation/chat/online_status/status_indicator.dart
// Widget circulaire indiquant le statut en ligne/hors ligne

import 'package:flutter/material.dart';

class StatusIndicator extends StatelessWidget {
  final bool isOnline;
  final double radius;

  const StatusIndicator({
    Key? key,
    required this.isOnline,
    this.radius = 6,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isOnline ? Colors.green : Colors.grey,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
    );
  }
}
