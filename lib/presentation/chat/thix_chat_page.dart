import 'package:flutter/material.dart';
import 'package:thix_id/presentation/chat/chat_home_screen.dart';

/// Route wrapper kept for backward-compatibility with older router tables.
///
/// The actual implementation lives in [ChatHomeScreen].
class ThixChatPage extends StatelessWidget {
  const ThixChatPage({super.key});

  @override
  Widget build(BuildContext context) => const ChatHomeScreen();
}
