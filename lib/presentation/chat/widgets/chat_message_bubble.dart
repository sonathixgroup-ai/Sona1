import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:thix_id/models/chat/chat_message.dart';
import 'package:thix_id/models/chat/user_status.dart';
import 'package:thix_id/presentation/chat/widgets/audio_player.dart';
import 'package:thix_id/presentation/chat/encryption_service.dart';
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
  bool _isDecrypted = false;
  String? _decryptedContent;

  final List<String> _emojiReactions = ['👍', '❤️', '😂', '😮', '😢', '😡'];

  // Couleurs THIX ID
  static const Color navyDeep = Color(0xFF0A1F44);
  static const Color navy = Color(0xFF123B7A);
  static const Color gold = Color(0xFFE3B23C);
  static const Color ivory = Color(0xFFF3F5FA);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color darkText = Color(0xFF10182B);
  static const Color mutedText = Color(0xFF6B7690);
  static const Color success = Color(0xFF1FA971);
  static const Color danger = Color(0xFFD64545);

  bool get _isEncrypted {
    final content = widget.message.content;
    return content.startsWith('🔒') ||
        content.contains('base64') ||
        (content.length > 50 && content.contains('+') && content.contains('/'));
  }

  Future<void> _decryptMessage() async {
    final passController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.lock_rounded, color: gold),
            SizedBox(width: 8),
            Text('Message chiffré', style: TextStyle(fontWeight: FontWeight.bold, color: navyDeep)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Entrez le mot de passe pour déchiffrer ce message :'),
            const SizedBox(height: 12),
            TextField(
              controller: passController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mot de passe',
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: navy)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Annuler', style: TextStyle(color: mutedText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: navyDeep,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, passController.text),
            child: const Text('Déchiffrer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        final decrypted = EncryptionService.decryptMessage(widget.message.content, result);
        setState(() {
          _decryptedContent = decrypted;
          _isDecrypted = true;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mot de passe incorrect'), backgroundColor: danger),
        );
      }
    }
  }

  String get _displayContent {
    if (_isEncrypted && !_isDecrypted) {
      return '🔒 Message chiffré (appuyez pour déchiffrer)';
    }
    if (_isEncrypted && _isDecrypted) {
      return _decryptedContent ?? widget.message.content;
    }
    return widget.message.content;
  }

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
                    color: isOwn ? gold : Colors.grey,
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
          onTap: () {
            if (_isEncrypted && !_isDecrypted) {
              _decryptMessage();
            }
          },
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
                color: isOwn ? navy : pureWhite,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
                border: _isEncrypted && !_isDecrypted
                    ? Border.all(color: gold, width: 1.5)
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icône cadenas si chiffré
                  if (_isEncrypted)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(
                            _isDecrypted ? Icons.lock_open_rounded : Icons.lock_rounded,
                            size: 14,
                            color: gold,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isDecrypted ? 'Déchiffré' : 'Chiffré',
                            style: TextStyle(
                              fontSize: 10,
                              color: gold,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Contenu du message
                  if (msg.isCodeSnippet && msg.codeContent != null)
                    ChatCodeSnippet(
                      code: msg.codeContent!,
                      language: msg.codeLanguage ?? 'text',
                    )
                  else if (msg.mediaType == 'audio' && msg.mediaUrl != null)
                    AudioPlayerWidget(
                      audioUrl: msg.mediaUrl!,
                      totalDuration: msg.ephemeralDuration,
                      primaryColor: isOwn ? pureWhite : navy,
                      accentColor: gold,
                    )
                  else if (msg.mediaUrl != null)
                    _buildMediaContent()
                  else
                    Text(
                      _displayContent,
                      style: TextStyle(
                        color: isOwn ? Colors.white : darkText,
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
                          color: isOwn ? Colors.white.withOpacity(0.8) : mutedText,
                        ),
                      ),
                      if (isOwn) ...[
                        const SizedBox(width: 4),
                        Icon(
                          msg.isRead ? Icons.done_all : Icons.done,
                          size: 14,
                          color: msg.isRead ? success : Colors.white.withOpacity(0.6),
                        ),
                      ],
                    ],
                  ),

                  // Réactions
                  if (msg.reactions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: msg.reactions.map((reaction) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              reaction.reaction,
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
                  icon: const Icon(Icons.reply, size: 16, color: mutedText),
                  onPressed: widget.onReply,
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
                if (isOwn)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 16, color: danger),
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
          ? Image.network(
              widget.message.mediaUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 40, color: mutedText),
            )
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
