// presentation/chat/screens/chat_conversation_screen.dart
import 'package:flutter/material.dart';
import '../conversation_page.dart';

class ChatConversationScreen extends StatelessWidget {
  final String chatId;
  final String title;
  final String type;

  const ChatConversationScreen({
    super.key,
    required this.chatId,
    required this.title,
    this.type = 'direct',
  });

  @override
  Widget build(BuildContext context) {
    return ConversationPage(
      chatId: chatId,
      title: title,
      type: type,
    );
  }
}
