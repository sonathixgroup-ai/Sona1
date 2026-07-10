// lib/presentation/chat/widgets/chat_ephemeral_timer.dart
import 'package:flutter/material.dart';
import 'dart:async';

class ChatEphemeralTimer extends StatefulWidget {
  final int duration; // secondes
  final VoidCallback onExpired;

  const ChatEphemeralTimer({
    super.key,
    required this.duration,
    required this.onExpired,
  });

  @override
  State<ChatEphemeralTimer> createState() => _ChatEphemeralTimerState();
}

class _ChatEphemeralTimerState extends State<ChatEphemeralTimer> {
  late int _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.duration;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remaining--;
        if (_remaining <= 0) {
          timer.cancel();
          widget.onExpired();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _remaining < 5 ? Colors.red.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.timer,
            size: 14,
            color: Colors.orange,
          ),
          const SizedBox(width: 2),
          Text(
            '${_remaining}s',
            style: TextStyle(
              fontSize: 10,
              color: _remaining < 5 ? Colors.red : Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
