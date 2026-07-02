import 'package:flutter/material.dart';
import 'package:thix_id/presentation/chat/archive/export_chat_page.dart';

class ExportChatScreen extends StatelessWidget {
  final String conversationId;
  final String conversationName;

  const ExportChatScreen({
    super.key,
    required this.conversationId,
    required this.conversationName,
  });

  @override
  Widget build(BuildContext context) {
    return ExportChatPage(
      conversationId: conversationId,
      conversationName: conversationName,
    );
  }
}
