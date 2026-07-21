import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:thix_id/models/chat/chat_message.dart';
import 'package:thix_id/presentation/chat/widgets/audio_player.dart';
import 'package:thix_id/presentation/chat/encryption_service.dart';
import 'chat_code_snippet.dart';
import 'chat_ephemeral_timer.dart';
// ─── IMPORTS POUR LE SENTIMENT ──────────────────────────────
import 'package:thix_id/models/chat/sentiment.dart';
import 'package:thix_id/presentation/chat/widgets/sentiment_indicator.dart';

class ChatMessageBubble extends StatefulWidget {
  final ChatMessage message;
  final bool isOwn;
  final VoidCallback? onReply;
  final void Function(String reaction)? onReaction;
  final VoidCallback? onDelete;
  final ChatMessage? replyToMessage;
  final bool isEphemeralActive;
  final bool isInternalNote;
  final bool isAgentView;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isOwn,
    this.onReply,
    this.onReaction,
    this.onDelete,
    this.replyToMessage,
    this.isEphemeralActive = false,
    this.isInternalNote = false,
    this.isAgentView = false,
  });

  @override
  State<ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends State<ChatMessageBubble> {
  bool _isHovering = false;
  bool _showReactions = false;
  bool _isDecrypted = false;
  String? _decryptedContent;

  final List<String> _emojiReactions = ['🔥', '🙌', '❤️', '😀', '😖', '👍'];

  static const Color primaryBlue = Color(0xFF4A8BFF);
  static const Color leftBubbleColor = Color(0xFFE9F0FF);
  static const Color navyDeep = Color(0xFF0A1F44);
  static const Color navy = Color(0xFF123B7A);
  static const Color gold = Color(0xFFE3B23C);
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
          const SnackBar(content: Text('Mot de passe incorrect'), backgroundColor: danger),
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
    if (widget.isInternalNote && !widget.isAgentView) {
      return const SizedBox.shrink();
    }

    final isOwn = widget.isOwn;
    final msg = widget.message;
    final bool isFromAgent = msg.senderId != null && msg.senderId!.contains('agent_');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Avatar et Nom
          if (!isOwn && !widget.isInternalNote)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 4),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: leftBubbleColor,
                    backgroundImage: msg.senderAvatar != null ? NetworkImage(msg.senderAvatar!) : null,
                    child: msg.senderAvatar == null
                        ? Text(
                            msg.senderName.isNotEmpty ? msg.senderName[0].toUpperCase() : '?',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: primaryBlue),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    msg.senderName,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: mutedText),
                  ),
                  if (isFromAgent) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(color: navy.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: const Text('Agent', style: TextStyle(fontSize: 9, color: navy, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ],
              ),
            ),

          // Message cité
          if (widget.replyToMessage != null && !widget.isInternalNote)
            Padding(
              padding: EdgeInsets.only(bottom: 4, left: isOwn ? 40 : 12, right: isOwn ? 12 : 40),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isOwn ? primaryBlue.withOpacity(0.15) : leftBubbleColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border(left: BorderSide(color: isOwn ? primaryBlue : Colors.grey, width: 3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.reply, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.replyToMessage!.senderId == widget.message.senderId ? 'Vous' : widget.replyToMessage!.senderName,
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

          // Bulle de message
          Row(
            mainAxisAlignment: isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isOwn) const SizedBox(width: 4),

              GestureDetector(
                onTap: () {
                  if (_isEncrypted && !_isDecrypted) _decryptMessage();
                },
                onLongPress: () => setState(() => _showReactions = !_showReactions),
                child: MouseRegion(
                  onEnter: (_) => setState(() => _isHovering = true),
                  onExit: (_) => setState(() => _isHovering = false),
                  child: Container(
                    padding: msg.mediaType == 'image' 
                        ? const EdgeInsets.all(4)
                        : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: widget.isInternalNote
                          ? Colors.yellow.shade100
                          : (isOwn ? primaryBlue : leftBubbleColor),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(isOwn ? 20 : 4),
                        bottomRight: Radius.circular(isOwn ? 4 : 20),
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1)),
                      ],
                      border: widget.isInternalNote
                          ? Border.all(color: Colors.orange.shade700, width: 2)
                          : (_isEncrypted && !_isDecrypted ? Border.all(color: gold, width: 1.5) : null),
                    ),
                    child: Column(
                      crossAxisAlignment: isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        // Badges + indicateur de sentiment
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Wrap(
                                spacing: 4,
                                runSpacing: 2,
                                children: [
                                  if (widget.isInternalNote) _badge(Icons.note_rounded, 'Note interne', Colors.orange),
                                  if (_isEncrypted) _badge(_isDecrypted ? Icons.lock_open_rounded : Icons.lock_rounded, _isDecrypted ? 'Déchiffré' : 'Chiffré', gold),
                                  if (widget.isEphemeralActive) _badge(Icons.timer_rounded, 'Éphémère', Colors.orange),
                                  if (msg.mediaType != null && msg.mediaType != 'image' && msg.mediaType != 'audio') 
                                    _badge(msg.mediaType == 'video' ? Icons.videocam_rounded : Icons.insert_drive_file_rounded, msg.mediaType ?? 'Fichier', Colors.blue),
                                ],
                              ),
                            ),
                            // ─── INDICATEUR DE SENTIMENT ──────────────────────
                            if (msg.sentiment != null)
                              SentimentIndicator(
                                result: msg.sentiment!,
                                size: 14,
                                showLabel: false,
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Contenu du message
                        if (msg.isCodeSnippet && msg.codeContent != null)
                          ChatCodeSnippet(code: msg.codeContent!, language: msg.codeLanguage ?? 'text')
                        else if (msg.mediaType == 'audio' && msg.mediaUrl != null)
                          AudioPlayerWidget(
                            audioUrl: msg.mediaUrl!,
                            totalDuration: msg.ephemeralDuration,
                            primaryColor: isOwn ? pureWhite : primaryBlue,
                            accentColor: isOwn ? leftBubbleColor : gold,
                          )
                        else if (msg.mediaUrl != null)
                          _buildMediaContent()
                        else if (_displayContent.isNotEmpty)
                          Text(
                            _displayContent,
                            style: TextStyle(
                              color: widget.isInternalNote ? Colors.black87 : (isOwn ? Colors.white : darkText),
                              fontSize: 15,
                              height: 1.3,
                            ),
                          ),

                        // Réactions
                        if (msg.reactions.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Wrap(
                              spacing: 4,
                              runSpacing: 2,
                              children: msg.reactions.map((reaction) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: mutedText.withOpacity(0.2))),
                                  child: Text(reaction.reaction, style: const TextStyle(fontSize: 14)),
                                );
                              }).toList(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Heure et accusés de réception (en dehors de la bulle)
          Padding(
            padding: EdgeInsets.only(top: 4, left: isOwn ? 0 : 8, right: isOwn ? 8 : 0),
            child: Row(
              mainAxisAlignment: isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                if (widget.isEphemeralActive)
                  ChatEphemeralTimer(
                    duration: widget.message.ephemeralDuration ?? 60,
                    onExpired: () { if (widget.onDelete != null) widget.onDelete!(); },
                  ),
                if (widget.isEphemeralActive) const SizedBox(width: 6),
                Text(
                  DateFormat('HH:mm').format(msg.createdAt),
                  style: const TextStyle(fontSize: 9, color: mutedText),
                ),
                if (isOwn) ...[
                  const SizedBox(width: 4),
                  Icon(
                    msg.isRead ? Icons.done_all_rounded : Icons.check_rounded,
                    size: 13,
                    color: msg.isRead ? primaryBlue : mutedText.withOpacity(0.7),
                  ),
                ],
              ],
            ),
          ),

          // Barre d'actions flottante
          if ((_isHovering || _showReactions) && !widget.isInternalNote)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Row(
                mainAxisAlignment: isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  if (_showReactions) ..._emojiReactions.map((emoji) => _buildReactionButton(emoji)),
                  IconButton(
                    icon: const Icon(Icons.reply, size: 16, color: mutedText),
                    onPressed: widget.onReply,
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
                  if (isOwn)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 16, color: danger),
                      onPressed: widget.onDelete,
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─── BADGE ────────────────────────────────────────────────────
  Widget _badge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withOpacity(0.3))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 2),
          Text(text, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ─── BOUTON DE RÉACTION ────────────────────────────────────
  Widget _buildReactionButton(String emoji) {
    return InkWell(
      onTap: () {
        if (widget.onReaction != null) widget.onReaction!(emoji);
        setState(() => _showReactions = false);
      },
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text(emoji, style: const TextStyle(fontSize: 20))),
    );
  }

  // ─── MÉDIA ──────────────────────────────────────────────────
  Widget _buildMediaContent() {
    if (widget.message.mediaType == 'image') {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FullScreenImagePage(
                imageUrl: widget.message.mediaUrl!,
                tag: widget.message.id,
              ),
            ),
          );
        },
        child: Hero(
          tag: widget.message.id,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 250),
              child: Image.network(
                widget.message.mediaUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Icon(Icons.broken_image, size: 40, color: mutedText),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 120),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: pureWhite.withOpacity(0.3)),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.message.mediaType == 'video' ? Icons.video_library_rounded : Icons.insert_drive_file_rounded, size: 32, color: widget.isOwn ? Colors.white : primaryBlue),
            const SizedBox(height: 8),
            Text(widget.message.mediaType ?? 'Fichier joint', style: TextStyle(color: widget.isOwn ? Colors.white : darkText, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ─── FULL SCREEN IMAGE PAGE ────────────────────────────────

class FullScreenImagePage extends StatelessWidget {
  final String imageUrl;
  final String tag;

  const FullScreenImagePage({
    super.key,
    required this.imageUrl,
    required this.tag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4.0,
          child: Hero(
            tag: tag,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
      ),
    );
  }
}
