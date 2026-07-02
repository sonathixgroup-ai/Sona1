// lib/presentation/chat/online_status/typing_indicator.dart
// Indicateur "quelqu'un écrit..." avec animation de points

import 'package:flutter/material.dart';

class TypingIndicator extends StatelessWidget {
  final List<String> users; // liste des pseudos en train d'écrire

  const TypingIndicator({Key? key, required this.users}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) return const SizedBox.shrink();

    String text;
    if (users.length == 1) {
      text = '${users.first} écrit...';
    } else if (users.length == 2) {
      text = '${users.first} et ${users.last} écrivent...';
    } else {
      text = 'Plusieurs personnes écrivent...';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _TypingDots(),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final value = (_controller.value * 2 + index * 0.33) % 1.0;
            final opacity = (value < 0.5) ? value * 2 : 2 - value * 2;
            return Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
