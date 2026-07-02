// lib/presentation/chat/security_advanced/self_destruct.dart
// Gestion des messages à autodestruction après lecture (timer)

import 'dart:async';
import 'package:flutter/material.dart';

class SelfDestructManager {
  static Timer scheduleDeletion(String messageId, Duration after, VoidCallback onDelete) {
    return Timer(after, () {
      onDelete();
    });
  }

  static void cancelTimer(Timer timer) {
    timer.cancel();
  }

  // Widget pour afficher un compte à rebours dans la bulle
  static Widget countdownWidget(int seconds, VoidCallback onExpired) {
    return StatefulBuilder(
      builder: (context, setState) {
        Timer? timer;
        int remaining = seconds;
        timer = Timer.periodic(const Duration(seconds: 1), (t) {
          if (remaining <= 1) {
            t.cancel();
            onExpired();
          } else {
            remaining--;
            setState(() {});
          }
        });
        return Text('${remaining}s', style: const TextStyle(fontSize: 10, color: Colors.orange));
      },
    );
  }
}
