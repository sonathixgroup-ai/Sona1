// lib/presentation/chat/ephemeral/ephemeral_indicator.dart
// Petit indicateur visuel (sablier) pour signaler un message éphémère

import 'package:flutter/material.dart';

class EphemeralIndicator extends StatelessWidget {
  final bool isExpired;

  const EphemeralIndicator({Key? key, this.isExpired = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isExpired ? Colors.grey.shade300 : Colors.orange.shade100,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.timer_outlined,
        size: 14,
        color: isExpired ? Colors.grey : Colors.orange,
      ),
    );
  }
}
