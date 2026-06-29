import 'package:flutter/material.dart';

class ConversationScreen extends StatefulWidget {
  final String conversationId;
  const ConversationScreen({super.key, required this.conversationId});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Conversation')), body: Center(child: Text('ID: ${widget.conversationId}')));
}
