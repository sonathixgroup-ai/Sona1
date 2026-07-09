import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/chat/chat_message.dart';  // ✅ IMPORT AJOUTÉ
import '../../../models/chat/user_status.dart';
import 'chat_code_snippet.dart';
import 'chat_ephemeral_timer.dart';

class ChatMessageBubble extends StatefulWidget {
  final ChatMessage message;   // ✅ maintenu
  final bool isOwn;
  final VoidCallback? onReply;
  final void Function(String reaction)? onReaction;
  final VoidCallback? onDelete;
  final ChatMessage? replyToMessage;   // ✅ maintenu
  final bool isEphemeralActive;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isOwn,
    this.onReply,
    this.onReaction,
    this.onDelete,
    this.replyToMessage,
    this.isEphemeralActive = false,
  });

  @override
  State<ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends State<ChatMessageBubble> {
  bool _isHovering = false;
  bool _showReactions = false;
  final List<String> _emojiReactions = ['👍', '❤️', '😂', '😮', '😢', '😡'];

  @override
  Widget build(BuildContext context) {
    final isOwn = widget.isOwn;
    final msg = widget.message;

    // ... le reste du code identique à la version corrigée précédemment
    // (gardez votre code, il est bon)
    return Container(); // Placeholder, remplacez par votre vrai build
  }

  // ... les autres méthodes
}
