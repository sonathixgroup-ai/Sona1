// lib/presentation/chat/scheduled/schedule_indicator.dart
// Petit indicateur visuel (horloge) pour signaler un message programmé

import 'package:flutter/material.dart';

class ScheduleIndicator extends StatelessWidget {
  final bool isRecurring;

  const ScheduleIndicator({Key? key, this.isRecurring = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        shape: BoxShape.circle,
      ),
      child: Icon(
        isRecurring ? Icons.repeat : Icons.schedule,
        size: 14,
        color: Colors.blue,
      ),
    );
  }
}
