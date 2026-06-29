import 'package:flutter/material.dart';

import 'package:thix_id/presentation/chat/screens/chat_dashboard_screen.dart';

/// THIX CHAT entry screen.
///
/// This is the dashboard (conversations list). Conversation details are opened
/// through routes (see `lib/nav.dart`).
class ChatHomeScreen extends StatelessWidget {
  const ChatHomeScreen({super.key});

  @override
  Widget build(BuildContext context) => const ChatDashboardScreen();
}
