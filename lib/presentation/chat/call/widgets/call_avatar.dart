// Route: lib/presentation/chat/call/widgets/call_avatar.dart
import 'package:flutter/material.dart';

class CallAvatar extends StatefulWidget {
  final String name;
  const CallAvatar({super.key, required this.name});

  @override
  State<CallAvatar> createState() => _CallAvatarState();
}

class _CallAvatarState extends State<CallAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.6, end: 1.0).animate(_c),
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF123B7A),
          border: Border.all(color: const Color(0xFFE3B23C), width: 2),
        ),
        child: Center(
          child: Text(
            widget.name.isNotEmpty? widget.name[0].toUpperCase() : '?',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.w900),
          ),
        ),
      ),
    );
  }
}
