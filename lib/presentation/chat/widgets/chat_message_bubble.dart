import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:thix_id/models/chat/chat_message.dart';
import 'package:thix_id/models/chat/user_status.dart';
import 'chat_code_snippet.dart';
import 'chat_ephemeral_timer.dart';

class ChatMessageBubble extends StatefulWidget {
  final ChatMessage message;
  final bool isOwn;
  final VoidCallback? onReply;
  final void Function(String reaction)? onReaction;
  final VoidCallback? onDelete;
  final ChatMessage? replyToMessage;
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

    return Column(
      crossAxisAlignment: isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        // Message cité (réponse)
        if (widget.replyToMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 16, right: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isOwn ? Colors.white.withOpacity(0.5) : Colors.grey[300]!.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border(
                  left: BorderSide(
                    color: isOwn ? const Color(0xFFD4AF37) : Colors.grey,
                    width: 3,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.reply, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.replyToMessage!.senderId == widget.message.senderId
                              ? 'Vous'
                              : 'Réponse',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          widget.replyToMessage!.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Bulle principale
        GestureDetector(
          onLongPress: () {
            setState(() => _showReactions = !_showReactions);
          },
          child: MouseRegion(
            onEnter: (_) => setState(() => _isHovering = true),
            onExit: (_) => setState(() => _isHovering = false),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              padding: const EdgeInsets.all(12),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                color: isOwn ? const Color(0xFFD4AF37) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Contenu du message
                  if (msg.isCodeSnippet && msg.codeContent != null)
                    ChatCodeSnippet(
                      code: msg.codeContent!,
                      language: msg.codeLanguage ?? 'text',
                    )
                  else if (msg.mediaUrl != null)
                    _buildMediaContent()
                  else
                    Text(
                      msg.content,
                      style: TextStyle(
                        color: isOwn ? Colors.white : Colors.black87,
                        fontSize: 14,
                      ),
                    ),

                  const SizedBox(height: 4),

                  // Date + accusés
                  Row(
                    mainAxisAlignment: isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      if (widget.isEphemeralActive)
                        ChatEphemeralTimer(
                          duration: widget.message.ephemeralDuration ?? 60,
                          onExpired: () {
                            if (widget.onDelete != null) widget.onDelete!();
                          },
                        ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('HH:mm').format(msg.createdAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: isOwn ? Colors.white.withOpacity(0.8) : Colors.grey[500],
                        ),
                      ),
                      if (isOwn) ...[
                        const SizedBox(width: 4),
                        Icon(
                          msg.isRead ? Icons.done_all : Icons.done,
                          size: 14,
                          color: msg.isRead ? Colors.green : Colors.white.withOpacity(0.6),
                        ),
                      ],
                    ],
                  ),

                  // 👇 CORRECTION ICI : Réactions avec typage explicite
                  if (msg.reactions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: msg.reactions.map((reaction) {
                          // Typage explicite pour éviter l'erreur
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              reaction.reaction,  // 👈 Utilisation correcte
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Barre d'actions (hover ou long press)
        if (_isHovering || _showReactions)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Row(
              mainAxisAlignment: isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                if (_showReactions)
                  ..._emojiReactions.map((emoji) => _buildReactionButton(emoji)),
                IconButton(
                  icon: const Icon(Icons.reply, size: 16, color: Colors.grey),
                  onPressed: widget.onReply,
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
                if (isOwn)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                    onPressed: widget.onDelete,
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildReactionButton(String emoji) {
    return InkWell(
      onTap: () {
        if (widget.onReaction != null) widget.onReaction!(emoji);
        setState(() => _showReactions = false);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(emoji, style: const TextStyle(fontSize: 20)),
      ),
    );
  }

  Widget _buildMediaContent() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[200],
      ),
      child: widget.message.mediaType == 'image'
          ? Image.network(widget.message.mediaUrl!, fit: BoxFit.cover)
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.message.mediaType == 'video'
                        ? Icons.video_library
                        : Icons.attachment,
                    size: 40,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.message.mediaType ?? 'Fichier joint',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
    );
  }
}
