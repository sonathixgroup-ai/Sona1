import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:thix_id/models/chat/chat_message.dart';
import 'package:thix_id/presentation/chat/widgets/audio_player.dart';
import 'package:thix_id/presentation/chat/encryption_service.dart';
import 'chat_code_snippet.dart';
import 'chat_ephemeral_timer.dart';
import 'package:thix_id/models/chat/sentiment.dart';
import 'package:thix_id/presentation/chat/widgets/sentiment_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';

class _C {
  static const bg = Color(0xFF050508);
  static const surface = Color(0xFF0C0C12);
  static const surfaceAlt = Color(0xFF111118);
  static const cardBorder = Color(0x14FFFFFF);
  static const violet = Color(0xFF7C5CFF);
  static const gold = Color(0xFFE3B23C);
  static const white = Colors.white;
  static const textMuted = Color(0x66FFFFFF);
  static const textSecondary = Color(0x99FFFFFF);
  static const red = Color(0xFFFF0A54);
  static const green = Color(0xFF10B981);
  static const leftBubble = Color(0xFF15151E);
}

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

  @override State<ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends State<ChatMessageBubble> {
  bool _isHovering = false;
  bool _showReactions = false;
  bool _isDecrypted = false;
  String? _decryptedContent;

  final List<String> _quick = ['❤️','😂','🔥','👍','😮','😢'];

  // Drapeaux split 1 par ligne pour build_runner - sans tag flags qui cassent le parser
  static const List<String> flags = [
    '🇦🇫','🇦🇱','🇩🇿','🇦🇩','🇦🇴','🇦🇬','🇦🇷','🇦🇲','🇦🇺','🇦🇹',
    '🇦🇿','🇧🇸','🇧🇭','🇧🇩','🇧🇧','🇧🇾','🇧🇪','🇧🇿','🇧🇯','🇧🇹',
    '🇧🇴','🇧🇦','🇧🇼','🇧🇷','🇧🇳','🇧🇬','🇧🇫','🇧🇮','🇰🇭','🇨🇲',
    '🇨🇦','🇨🇻','🇨🇫','🇹🇩','🇨🇱','🇨🇳','🇨🇴','🇰🇲','🇨🇬','🇨🇩',
    '🇨🇷','🇭🇷','🇨🇺','🇨🇾','🇨🇿','🇩🇰','🇩🇯','🇩🇲','🇩🇴','🇪🇨',
    '🇪🇬','🇸🇻','🇬🇶','🇪🇷','🇪🇪','🇸🇿','🇪🇹','🇫🇯','🇫🇮','🇫🇷',
    '🇬🇦','🇬🇲','🇬🇪','🇩🇪','🇬🇭','🇬🇷','🇬🇩','🇬🇹','🇬🇳','🇬🇼',
    '🇬🇾','🇭🇹','🇭🇳','🇭🇺','🇮🇸','🇮🇳','🇮🇩','🇮🇷','🇮🇶','🇮🇪',
    '🇮🇱','🇮🇹','🇯🇲','🇯🇵','🇯🇴','🇰🇿','🇰🇪','🇰🇮','🇰🇵','🇰🇷',
    '🇰🇼','🇰🇬','🇱🇦','🇱🇻','🇱🇧','🇱🇸','🇱🇷','🇱🇾','🇱🇮','🇱🇹',
    '🇱🇺','🇲🇬','🇲🇼','🇲🇾','🇲🇻','🇲🇱','🇲🇹','🇲🇭','🇲🇷','🇲🇺',
    '🇲🇽','🇫🇲','🇲🇩','🇲🇨','🇲🇳','🇲🇪','🇲🇦','🇲🇿','🇲🇲','🇳🇦',
    '🇳🇷','🇳🇵','🇳🇱','🇳🇿','🇳🇮','🇳🇪','🇳🇬','🇲🇰','🇳🇴','🇴🇲',
    '🇵🇰','🇵🇼','🇵🇸','🇵🇦','🇵🇬','🇵🇾','🇵🇪','🇵🇭','🇵🇱','🇵🇹',
    '🇶🇦','🇷🇴','🇷🇺','🇷🇼','🇰🇳','🇱🇨','🇻🇨','🇼🇸','🇸🇲','🇸🇹',
    '🇸🇦','🇸🇳','🇷🇸','🇸🇨','🇸🇱','🇸🇬','🇸🇰','🇸🇮','🇸🇧','🇸🇴',
    '🇿🇦','🇸🇸','🇪🇸','🇱🇰','🇸🇩','🇸🇷','🇸🇪','🇨🇭','🇸🇾','🇹🇯',
    '🇹🇿','🇹🇭','🇹🇱','🇹🇬','🇹🇴','🇹🇹','🇹🇳','🇹🇷','🇹🇲','🇹🇻',
    '🇺🇬','🇺🇦','🇦🇪','🇬🇧','🇺🇸','🇺🇾','🇺🇿','🇻🇺','🇻🇦','🇻🇪',
    '🇻🇳','🇾🇪','🇿🇲','🇿🇼','🇹🇼','🇭🇰','🇲🇴','🇵🇷','🇬🇺','🇽🇰',
    '🇪🇺','🇺🇳',
  ];

  // Stickers simplifiés sans ZWJ complexes
  static const List<String> stickers = [
    '😀','😃','😄','😁','😆','😅','😂','🤣','😊','😇',
    '🙂','😉','😌','😍','🥰','😘','🤩','🥳','🤗','🤔',
    '😏','😒','🙄','😬','😔','😪','😴','🤒','😷','🥵',
    '🥶','😵','🤯','🥴','🤠','❤️','🧡','💛','💚','💙',
    '💜','🖤','🤍','💔','💕','💞','💓','💗','💖','💝',
    '💘','💌','💋','💯','🔥','⭐','🌟','💫','✨','🎉',
    '🎊','🎈','🎁','🏆','👍','👎','👌','✌️','👈','👉',
    '👆','👇','✋','👋','🙏','💪','👀','🐶','🐱','🦊',
    '🐻','🐼','🐨','🦁','🐮','🐷','🐸','🐵','🐔','🐧',
    '🐦','🐤','🦆','🐺','🐴','🦄','🐝','🦋','🐌','🐢',
    '🐍','🐙','🐠','🐬','🐳','🐋','🦈','🍏','🍎','🍐',
    '🍊','🍋','🍌','🍉','🍇','🍓','🍒','🍑','🥭','🍍',
    '🥝','🍅','🥑','🥦','🥒','🌽','🥕','🍞','🧀','🍔',
    '🍟','🍕','🌮','🍝','🍣','🍱','🍙','🍚','🍦','🍰',
    '🎂','🍭','🍫','🍿','🍩','☕','🍵','🍺','⚽','🏀',
    '🏈','🎾','🏐','🎱','🏓','🥊','🛹','🎿','🎯','🎮',
    '🎲','🧩','🎨','🎤','🎧','🎵','🎶','🎹','🥁','🎸',
  ];

  bool get _isEncrypted => EncryptionService.isEncrypted(widget.message.content);

  Future<void> _decrypt() async {
    final c = TextEditingController();
    final pass = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _C.cardBorder),
        ),
        title: const Row(
          children: [
            Icon(Icons.lock_rounded, color: _C.gold, size: 16),
            SizedBox(width: 6),
            Text('Message chiffré',
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
          ],
        ),
        content: TextField(
          controller: c,
          obscureText: true,
          style: const TextStyle(color: Colors.white, fontSize: 12),
          decoration: InputDecoration(
            labelText: 'Mot de passe',
            labelStyle: const TextStyle(color: _C.textMuted, fontSize: 11),
            filled: true,
            fillColor: _C.bg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _C.cardBorder),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler', style: TextStyle(color: _C.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
            onPressed: () => Navigator.pop(ctx, c.text),
            child: const Text('Déchiffrer', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (pass!= null && pass.isNotEmpty) {
      try {
        final d = EncryptionService.decryptMessage(widget.message.content, pass);
        setState(() {
          _decryptedContent = d;
          _isDecrypted = true;
        });
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mot de passe incorrect'), backgroundColor: _C.red),
          );
        }
      }
    }
  }

  String get _display {
    if (_isEncrypted &&!_isDecrypted) {
      return '🔒 Message chiffré (tap pour déchiffrer)';
    }
    if (_isDecrypted) {
      return _decryptedContent?? widget.message.content;
    }
    return widget.message.content;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isInternalNote &&!widget.isAgentView) {
      return const SizedBox.shrink();
    }
    final isOwn = widget.isOwn;
    final msg = widget.message;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: isOwn? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isOwn &&!widget.isInternalNote)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 4),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: _C.surfaceAlt,
                    backgroundImage: msg.senderAvatar!= null
                       ? CachedNetworkImageProvider(msg.senderAvatar!)
                        : null,
                    child: msg.senderAvatar == null
                       ? Text(
                            msg.senderName.isNotEmpty? msg.senderName[0].toUpperCase() : '?',
                            style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w800),
                          )
                        : null,
                  ),
                  const SizedBox(width: 6),
                  Text(msg.senderName, style: const TextStyle(fontSize: 10, color: _C.textMuted, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          if (widget.replyToMessage!= null &&!widget.isInternalNote)
            Padding(
              padding: EdgeInsets.only(bottom: 4, left: isOwn? 40 : 12, right: isOwn? 12 : 40),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isOwn? _C.violet.withOpacity(0.15) : _C.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border(left: BorderSide(color: isOwn? _C.violet : _C.textMuted, width: 2.5)),
                ),
                child: Text(widget.replyToMessage!.content, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: _C.textSecondary)),
              ),
            ),
          Row(
            mainAxisAlignment: isOwn? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  if (_isEncrypted &&!_isDecrypted) _decrypt();
                },
                onLongPress: () => setState(() => _showReactions =!_showReactions),
                child: MouseRegion(
                  onEnter: (_) => setState(() => _isHovering = true),
                  onExit: (_) => setState(() => _isHovering = false),
                  child: Container(
                    padding: msg.mediaType == 'image'? const EdgeInsets.all(3) : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.74),
                    decoration: BoxDecoration(
                      color: widget.isInternalNote? const Color(0xFF1A1505) : (isOwn? _C.violet : _C.leftBubble),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isOwn? 18 : 4),
                        bottomRight: Radius.circular(isOwn? 4 : 18),
                      ),
                      border: Border.all(color: _C.cardBorder, width: 0.8),
                    ),
                    child: Column(
                      crossAxisAlignment: isOwn? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        if (_isEncrypted || widget.isEphemeralActive || widget.isInternalNote) _badges(),
                        if (msg.sentiment!= null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: SentimentIndicator(result: msg.sentiment!, size: 12, showLabel: false),
                          ),
                        if (msg.isCodeSnippet && msg.codeContent!= null)
                          ChatCodeSnippet(code: msg.codeContent!, language: msg.codeLanguage?? 'text')
                        else if (msg.mediaType == 'audio' && msg.mediaUrl!= null)
                          AudioPlayerWidget(audioUrl: msg.mediaUrl!, totalDuration: msg.ephemeralDuration, primaryColor: Colors.white, accentColor: Colors.white24)
                        else if (msg.mediaUrl!= null)
                          _media()
                        else if (_display.isNotEmpty)
                          Text(_display, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.35)),
                        if (msg.reactions.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: msg.reactions.map((r) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: _C.bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: _C.cardBorder)),
                                child: Text(r.reaction, style: const TextStyle(fontSize: 12)),
                              )).toList(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(top: 4, left: isOwn? 0 : 8, right: isOwn? 8 : 0),
            child: Row(
              mainAxisAlignment: isOwn? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                if (widget.isEphemeralActive)
                  ChatEphemeralTimer(duration: widget.message.ephemeralDuration?? 60, onExpired: () => widget.onDelete?.call()),
                if (widget.isEphemeralActive) const SizedBox(width: 6),
                Text(DateFormat('HH:mm').format(msg.createdAt), style: const TextStyle(fontSize: 9, color: _C.textMuted)),
                if (isOwn)...[
                  const SizedBox(width: 4),
                  Icon(msg.isRead? Icons.done_all_rounded : Icons.check_rounded, size: 12, color: msg.isRead? _C.violet : _C.textMuted),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badges() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Wrap(
        spacing: 4,
        children: [
          if (widget.isInternalNote) _badge(Icons.note_rounded, 'Interne', Colors.orange),
          if (_isEncrypted) _badge(_isDecrypted? Icons.lock_open_rounded : Icons.lock_rounded, _isDecrypted? 'Déchiffré' : 'Chiffré', _C.gold),
          if (widget.isEphemeralActive) _badge(Icons.timer_rounded, 'Éphémère', Colors.orange),
        ],
      ),
    );
  }

  Widget _badge(IconData ic, String t, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(6), border: Border.all(color: c.withOpacity(0.25))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ic, size: 10, color: c),
          const SizedBox(width: 3),
          Text(t, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: c)),
        ],
      ),
    );
  }

  Widget _media() {
    final url = widget.message.mediaUrl;
    if (url == null || url.isEmpty) {
      return Text(widget.message.content, style: const TextStyle(color: Colors.white, fontSize: 11));
    }
    final type = widget.message.mediaType?? 'file';
    if (type == 'image') {
      return GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FullScreenImagePage(imageUrl: url, tag: widget.message.id))),
        child: Hero(
          tag: widget.message.id,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              memCacheWidth: 600,
              placeholder: (_, __) => Container(height: 130, width: 190, color: _C.surfaceAlt, child: const Center(child: CircularProgressIndicator(color: _C.violet, strokeWidth: 2))),
              errorWidget: (_, __, ___) => Container(height: 100, width: 180, color: _C.surfaceAlt, child: const Icon(Icons.broken_image_rounded, color: _C.textMuted)),
            ),
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(type == 'video'? Icons.videocam_rounded : Icons.insert_drive_file_rounded, size: 16, color: widget.isOwn? Colors.white : _C.violet),
          const SizedBox(width: 6),
          Flexible(child: Text(widget.message.content.isNotEmpty? widget.message.content : type, style: const TextStyle(color: Colors.white, fontSize: 11), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

class FullScreenImagePage extends StatelessWidget {
  final String imageUrl;
  final String tag;
  const FullScreenImagePage({super.key, required this.imageUrl, required this.tag});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white)),
      body: Center(child: InteractiveViewer(minScale: 0.5, maxScale: 4, child: Hero(tag: tag, child: CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.contain)))),
    );
  }
}
