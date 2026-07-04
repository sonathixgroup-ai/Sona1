import 'package:flutter/material.dart';

class ChatPage extends StatelessWidget {
  final String conversationId;

  const ChatPage({super.key, required this.conversationId});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Discussion')),
        body: Center(child: Text('Conversation $conversationId')),
      );
}
