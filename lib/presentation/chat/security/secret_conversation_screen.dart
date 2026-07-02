import 'package:flutter/material.dart';

class SecretConversationScreen extends StatelessWidget {
  final String conversationId;

  const SecretConversationScreen({
    super.key,
    required this.conversationId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conversation secrète')),
      body: Center(
        child: Text('Conversation secrète ID : $conversationId'),
      ),
    );
  }
}
