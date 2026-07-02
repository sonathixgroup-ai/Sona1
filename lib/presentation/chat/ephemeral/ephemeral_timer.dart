// lib/presentation/chat/ephemeral/ephemeral_timer.dart
// Widget qui affiche un compte à rebours pour un message éphémère non encore ouvert

import 'dart:async';
import 'package:flutter/material.dart';
import '../core/chat_models.dart';
import '../core/chat_utils.dart';

class EphemeralTimer extends StatefulWidget {
  final EphemeralMessage message;
  final VoidCallback onExpired;

  const EphemeralTimer({
    Key? key,
    required this.message,
    required this.onExpired,
  }) : super(key: key);

  @override
  State<EphemeralTimer> createState() => _EphemeralTimerState();
}

class _EphemeralTimerState extends State<EphemeralTimer> {
  late Timer _timer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
      if (_remainingSeconds <= 0) {
        _timer.cancel();
        widget.onExpired();
      }
    });
  }

  void _updateRemaining() {
    final remaining = ChatUtils.getRemainingEphemeralSeconds(
      widget.message.sentAt,
      widget.message.durationSeconds,
      openedAt: widget.message.openedAt,
    );
    if (mounted && remaining != _remainingSeconds) {
      setState(() => _remainingSeconds = remaining);
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_remainingSeconds <= 0) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, size: 12, color: Colors.orange),
          const SizedBox(width: 4),
          Text(
            '$_remainingSeconds s',
            style: const TextStyle(fontSize: 10, color: Colors.orange),
          ),
        ],
      ),
    );
  }
}
