import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:thix_id/models/chat/chat_message.dart';
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
  final bool isInternalNote;        // Nouveau : note interne
  final bool isAgentView;           // Nouveau : vue agent (pour afficher les notes internes)

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
    // Ne pas afficher si c'est une note interne et que l'utilisateur n'est pas un agent
    if (widget.isInternalNote && !widget.isAgentView) {
      return const SizedBox.shrink();
    }

    final isOwn = widget.isOwn;
    final msg = widget.message;
    final bool isFromAgent = msg.senderId != null && msg.senderId!.contains('agent_'); // exemple, à adapter

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Nom de l'expéditeur (pour les messages reçus) – sauf pour les notes internes (on les affiche différemment)
          if (!isOwn && !widget.isInternalNote)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 2),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: navy.withOpacity(0.1),
                    backgroundImage: msg.senderAvatar != null
                        ? NetworkImage(msg.senderAvatar!)
                        : null,
                    child: msg.senderAvatar == null
                        ? Text(
                            msg.senderName.isNotEmpty ? msg.senderName[0].toUpperCase() : '?',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: navy),
                          )
                        : null,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    msg.senderName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: mutedText,
                    ),
                  ),
                  if (isFromAgent) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: navy.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Agent',
                        style: TextStyle(fontSize: 9, color: navy, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ],
              ),
            ),

          // Message cité (réponse)
          if (widget.replyToMessage != null && !widget.isInternalNote)
            Padding(
              padding: EdgeInsets.only(
                bottom: 4,
                left: isOwn ? 40 : 12,
                right: isOwn ? 12 : 40,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isOwn ? gold.withOpacity(0.15) : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border(
                    left: BorderSide(
                      color: isOwn ? gold : Colors.grey,
                      width: 3,
                    ),
                  ),
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
                            widget.replyToMessage!.senderId == widget.message.senderId
                                ? 'Vous'
                                : widget.replyToMessage!.senderName,
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
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.72,
                    ),
                    decoration: BoxDecoration(
                      // Style différent pour les notes internes
                      color: widget.isInternalNote
                          ? Colors.yellow.shade100
                          : (isOwn ? navy : pureWhite),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: isOwn ? const Radius.circular(16) : const Radius.circular(4),
                        bottomRight: isOwn ? const Radius.circular(4) : const Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                      border: widget.isInternalNote
                          ? Border.all(color: Colors.orange.shade700, width: 2)
                          : (_isEncrypted && !_isDecrypted
                              ? Border.all(color: gold, width: 1.5)
                              : null),
                    ),
                    child: Column(
                      crossAxisAlignment: isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        // Badges : Note interne, chiffré, éphémère, document
                        Wrap(
                          spacing: 4,
                          runSpacing: 2,
                          children: [
                            // Badge note interne
                            if (widget.isInternalNote)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.orange.shade700),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.note_rounded, size: 12, color: Colors.orange),
                                    SizedBox(width: 2),
                                    Text(
                                      'Note interne',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.orange,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Badge chiffré
                            if (_isEncrypted)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: gold.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: gold.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _isDecrypted ? Icons.lock_open_rounded : Icons.lock_rounded,
                                      size: 12,
                                      color: gold,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      _isDecrypted ? 'Déchiffré' : 'Chiffré',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: gold,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Badge éphémère
                            if (widget.isEphemeralActive)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.timer_rounded, size: 12, color: Colors.orange),
                                    SizedBox(width: 2),
                                    Text(
                                      'Éphémère',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.orange,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Badge document
                            if (msg.mediaType != null && msg.mediaType != 'audio')
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      msg.mediaType == 'image' ? Icons.image_rounded :
                                      msg.mediaType == 'video' ? Icons.videocam_rounded :
                                      Icons.insert_drive_file_rounded,
                                      size: 12,
                                      color: Colors.blue,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      msg.mediaType ?? 'Fichier',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.blue,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 4),

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
                              color: widget.isInternalNote
                                  ? Colors.black87
                                  : (isOwn ? Colors.white : darkText),
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),

                        const SizedBox(height: 6),

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
                            const SizedBox(width: 6),
                            Text(
                              DateFormat('HH:mm').format(msg.createdAt),
                              style: TextStyle(
                                fontSize: 10,
                                color: widget.isInternalNote
                                    ? Colors.black54
                                    : (isOwn ? Colors.white.withOpacity(0.7) : mutedText),
                              ),
                            ),
                            if (isOwn) ...[
                              const SizedBox(width: 4),
                              Icon(
                                msg.isRead ? Icons.done_all : Icons.done,
                                size: 14,
                                color: msg.isRead ? success : Colors.white.withOpacity(0.5),
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
                                    color: Colors.grey[200],
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
            ],
          ),

          // Barre d'actions (hover ou long press) – cachée pour les notes internes
          if ((_isHovering || _showReactions) && !widget.isInternalNote)
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
      ),
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
