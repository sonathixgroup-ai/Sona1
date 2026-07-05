import 'package:flutter/material.dart';

class ChatNotificationsPage extends StatelessWidget {
  const ChatNotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications du chat')),
      body: const Center(child: Text('Notifications (à implémenter)')),
    );
  }
}
