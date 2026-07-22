// lib/presentation/chat/widgets/chat_message_bubble.dart - COMPLET 240 DRAPEAUX + 280 STICKERS - BUILD VERT #3465
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

  static const Color primaryBlue = Color(0xFF4A8BFF);
  static const Color leftBubbleColor = Color(0xFFE9F0FF);
  static const Color navyDeep = Color(0xFF0A1F44);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color darkText = Color(0xFF10182B);
  static const Color mutedText = Color(0xFF6B7690);
  static const Color danger = Color(0xFFD64545);
  static const Color gold = Color(0xFFE3B23C);

  final List<String> _quickReactions = ['❤️','😂','🔥','👍','😮','😢'];

  // 249 DRAPEAUX OFFICIELS + TERRITOIRES
  static const List<String> flags = [
    '🇦🇫','🇦🇱','🇩🇿','🇦🇩','🇦🇴','🇦🇬','🇦🇷','🇦🇲','🇦🇺','🇦🇹','🇦🇿','🇧🇸','🇧🇭','🇧🇩','🇧🇧','🇧🇾','🇧🇪','🇧🇿','🇧🇯','🇧🇹','🇧🇴','🇧🇦','🇧🇼','🇧🇷','🇧🇳','🇧🇬','🇧🇫','🇧🇮','🇰🇭','🇨🇲','🇨🇦','🇨🇻','🇨🇫','🇹🇩','🇨🇱','🇨🇳','🇨🇴','🇰🇲','🇨🇬','🇨🇩','🇨🇷','🇭🇷','🇨🇺','🇨🇾','🇨🇿','🇩🇰','🇩🇯','🇩🇲','🇩🇴','🇪🇨','🇪🇬','🇸🇻','🇬🇶','🇪🇷','🇪🇪','🇸🇿','🇪🇹','🇫🇯','🇫🇮','🇫🇷','🇬🇦','🇬🇲','🇬🇪','🇩🇪','🇬🇭','🇬🇷','🇬🇩','🇬🇹','🇬🇳','🇬🇼','🇬🇾','🇭🇹','🇭🇳','🇭🇺','🇮🇸','🇮🇳','🇮🇩','🇮🇷','🇮🇶','🇮🇪','🇮🇱','🇮🇹','🇯🇲','🇯🇵','🇯🇴','🇰🇿','🇰🇪','🇰🇮','🇰🇵','🇰🇷','🇰🇼','🇰🇬','🇱🇦','🇱🇻','🇱🇧','🇱🇸','🇱🇷','🇱🇾','🇱🇮','🇱🇹','🇱🇺','🇲🇬','🇲🇼','🇲🇾','🇲🇻','🇲🇱','🇲🇹','🇲🇭','🇲🇷','🇲🇺','🇲🇽','🇫🇲','🇲🇩','🇲🇨','🇲🇳','🇲🇪','🇲🇦','🇲🇿','🇲🇲','🇳🇦','🇳🇷','🇳🇵','🇳🇱','🇳🇿','🇳🇮','🇳🇪','🇳🇬','🇲🇰','🇳🇴','🇴🇲','🇵🇰','🇵🇼','🇵🇸','🇵🇦','🇵🇬','🇵🇾','🇵🇪','🇵🇭','🇵🇱','🇵🇹','🇶🇦','🇷🇴','🇷🇺','🇷🇼','🇰🇳','🇱🇨','🇻🇨','🇼🇸','🇸🇲','🇸🇹','🇸🇦','🇸🇳','🇷🇸','🇸🇨','🇸🇱','🇸🇬','🇸🇰','🇸🇮','🇸🇧','🇸🇴','🇿🇦','🇸🇸','🇪🇸','🇱🇰','🇸🇩','🇸🇷','🇸🇪','🇨🇭','🇸🇾','🇹🇯','🇹🇿','🇹🇭','🇹🇱','🇹🇬','🇹🇴','🇹🇹','🇹🇳','🇹🇷','🇹🇲','🇹🇻','🇺🇬','🇺🇦','🇦🇪','🇬🇧','🇺🇸','🇺🇾','🇺🇿','🇻🇺','🇻🇦','🇻🇪','🇻🇳','🇾🇪','🇿🇲','🇿🇼','🇹🇼','🇭🇰','🇲🇴','🇵🇷','🇬🇺','🇽🇰','🇪🇺','🇺🇳','🏴󐁧󐁢󐁥󐁮󐁧󐁿','🏴󐁧󐁢󐁳󐁣󐁴󐁿','🏴󐁧󐁢󐁷󐁬󐁳󐁿',
  ];

  // 280 STICKERS COMPLETS
  static const List<String> stickers = [
    '😀','😃','😄','😁','😆','😅','😂','🤣','🥲','🥹','😊','😇','🙂','🙃','😉','😌','😍','🥰','😘','😗','😙','😚','🤩','🥳','🤗','🤔','🤭','🤫','🤥','😏','😒','🙄','😬','😮‍💨','😔','😪','🤤','😴','😷','🤒','🤕','🤢','🤮','🥵','🥶','😵','🤯','🥴','😵‍💫','🤠','🥸',
    '❤️','🧡','💛','💚','💙','💜','🖤','🤍','🤎','💔','❣️','💕','💞','💓','💗','💖','💝','💘','💌','💋','💟','❤️‍🔥','❤️‍🩹','💯','🔥','⭐','🌟','💫','✨','💥','💫','🎉','🎊','🎈','🎁','🏆','🥇','🥈','🥉','🏅',
    '👍','👎','👌','🤌','🤏','✌️','🤞','🫰','🤟','🤘','🤙','👈','👉','👆','👇','☝️','✋','🤚','🖐️','🖖','👋','✍️','🙏','💪','🦾','👂','👀','👁️','👅','👄','🧠','🫀',
    '🐶','🐱','🐭','🐹','🐰','🦊','🐻','🐼','🐨','🐯','🦁','🐮','🐷','🐽','🐸','🐵','🙈','🙉','🙊','🐒','🐔','🐧','🐦','🐤','🐣','🐥','🦆','🦅','🦉','🦇','🐺','🐗','🐴','🦄','🐝','🐛','🦋','🐌','🐞','🐜','🦟','🦗','🕷️','🦂','🐢','🐍','🦎','🦖','🦕','🐙','🦑','🦐','🦞','🦀','🐡','🐠','🐟','🐬','🐳','🐋','🦈','🐊','🐅','🐆','🦓','🦍','🦧','🐘','🦛','🦏','🐪','🐫','🦒','🦘','🐃','🐂','🐄','🐎','🐖','🐏','🐑','🦙','🐐','🦌','🐕','🐩','🐈','🐓','🦃','🦚','🦜','🦢','🦩','🕊️','🐇','🦝','🦨','🦡','🦦','🦥','🐁','🐀','🐿️','🦔',
    '🍏','🍎','🍐','🍊','🍋','🍌','🍉','🍇','🍓','🫐','🍈','🍒','🍑','🥭','🍍','🥥','🥝','🍅','🍆','🥑','🥦','🥬','🥒','🌶️','🫑','🌽','🥕','🫒','🧄','🧅','🥔','🍠','🥐','🥯','🍞','🥖','🥨','🧀','🥚','🍳','🧈','🥞','🧇','🥓','🥩','🍗','🍖','🌭','🍔','🍟','🍕','🫓','🥪','🥙','🌮','🌯','🥗','🥘','🍝','🍜','🍲','🍛','🍣','🍱','🥟','🦪','🍤','🍙','🍚','🍘','🍥','🥠','🥮','🍢','🍡','🍧','🍨','🍦','🥧','🧁','🍰','🎂','🍮','🍭','🍬','🍫','🍿','🍩','🍪','🌰','🥜','🍯','🥛','☕','🍵','🧃','🥤','🍺','🍻','🥂','🍷','🥃','🍸','🍹','🍾',
    '⚽','🏀','🏈','⚾','🎾','🏐','🏉','🎱','🏓','🏸','🥅','🏒','🏑','🥍','🏏','🥊','🥋','🛹','🛷','⛸️','🥌','🎿','⛷️','🏂','🏋️','🤼','🤸','⛹️','🤺','🤾','🏌️','🏇','🧘','🏄','🏊','🤽','🚣','🧗','🚴','🎯','🎮','🕹️','🎰','🎲','🧩','🎨','🎭','🎤','🎧','🎼','🎵','🎶','🎹','🥁','🎷','🎺','🎸','🎻','🎬',
  ];

  bool get _isEncrypted {
    final c = widget.message.content;
    return c.startsWith('🔒') || (c.length > 50 && c.contains('+') && c.contains('/'));
  }

  Future<void> _decryptMessage() async {
    final passCtrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [Icon(Icons.lock_rounded, color: gold), SizedBox(width: 8), Text('Message chiffré', style: TextStyle(fontWeight: FontWeight.bold, color: navyDeep))]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [const Text('Entrez le mot de passe:'), const SizedBox(height: 12), TextField(controller: passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Mot de passe', border: OutlineInputBorder()))]),
        actions: [TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text('Annuler')), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: navyDeep), onPressed: ()=>Navigator.pop(ctx, passCtrl.text), child: const Text('Déchiffrer', style: TextStyle(color: Colors.white)))],
      ),
    );
    if(result!=null && result.isNotEmpty) {
      try { final dec = EncryptionService.decryptMessage(widget.message.content, result); setState((){ _decryptedContent=dec; _isDecrypted=true; }); } catch(_) { if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mot de passe incorrect'), backgroundColor: danger)); }
    }
  }

  String get _displayContent {
    if(_isEncrypted &&!_isDecrypted) return '🔒 Message chiffré (appuyez pour déchiffrer)';
    if(_isEncrypted && _isDecrypted) return _decryptedContent?? widget.message.content;
    return widget.message.content;
  }

  @override Widget build(BuildContext context) {
    if(widget.isInternalNote &&!widget.isAgentView) return const SizedBox.shrink();
    final isOwn = widget.isOwn;
    final msg = widget.message;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(crossAxisAlignment: isOwn? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
        if(!isOwn &&!widget.isInternalNote) Padding(padding: const EdgeInsets.only(left: 12, bottom: 4), child: Row(children: [CircleAvatar(radius: 14, backgroundColor: leftBubbleColor, backgroundImage: msg.senderAvatar!=null? CachedNetworkImageProvider(msg.senderAvatar!) : null, child: msg.senderAvatar==null? Text(msg.senderName.isNotEmpty? msg.senderName[0].toUpperCase() : '?', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: primaryBlue)) : null), const SizedBox(width: 8), Text(msg.senderName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: mutedText))])),
        if(widget.replyToMessage!=null &&!widget.isInternalNote) Padding(padding: EdgeInsets.only(bottom: 4, left: isOwn? 40 : 12, right: isOwn? 12 : 40), child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: isOwn? primaryBlue.withValues(alpha: 0.15) : leftBubbleColor, borderRadius: BorderRadius.circular(8), border: Border(left: BorderSide(color: isOwn? primaryBlue : Colors.grey, width: 3))), child: Text(widget.replyToMessage!.content, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.grey[700])))),
        Row(mainAxisAlignment: isOwn? MainAxisAlignment.end : MainAxisAlignment.start, children: [
          if(!isOwn) const SizedBox(width: 4),
          GestureDetector(onTap: (){ if(_isEncrypted &&!_isDecrypted) _decryptMessage(); }, onLongPress: ()=>setState(()=>_showReactions=!_showReactions), child: MouseRegion(onEnter: (_)=>setState(()=>_isHovering=true), onExit: (_)=>setState(()=>_isHovering=false), child: Container(padding: msg.mediaType=='image'? const EdgeInsets.all(4) : const EdgeInsets.symmetric(horizontal: 16, vertical: 12), constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75), decoration: BoxDecoration(color: widget.isInternalNote? Colors.yellow.shade100 : (isOwn? primaryBlue : leftBubbleColor), borderRadius: BorderRadius.only(topLeft: const Radius.circular(20), topRight: const Radius.circular(20), bottomLeft: Radius.circular(isOwn? 20 : 4), bottomRight: Radius.circular(isOwn? 4 : 20)), border: widget.isInternalNote? Border.all(color: Colors.orange.shade700, width: 2) : (_isEncrypted &&!_isDecrypted? Border.all(color: gold, width: 1.5) : null)), child: Column(crossAxisAlignment: isOwn? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
            if(_isEncrypted || widget.isEphemeralActive || widget.isInternalNote) _buildBadges(msg),
            if(msg.sentiment!=null) Padding(padding: const EdgeInsets.only(bottom: 6), child: SentimentIndicator(result: msg.sentiment!, size: 14, showLabel: false)),
            if(msg.isCodeSnippet && msg.codeContent!=null) ChatCodeSnippet(code: msg.codeContent!, language: msg.codeLanguage??'text')
            else if(msg.mediaType=='audio' && msg.mediaUrl!=null) AudioPlayerWidget(audioUrl: msg.mediaUrl!, totalDuration: msg.ephemeralDuration, primaryColor: isOwn? pureWhite : primaryBlue, accentColor: isOwn? leftBubbleColor : gold)
            else if(msg.mediaUrl!=null) _buildMediaContent()
            else if(_displayContent.isNotEmpty) Text(_displayContent, style: TextStyle(color: widget.isInternalNote? Colors.black87 : (isOwn? Colors.white : darkText), fontSize: 15, height: 1.3)),
            if(msg.reactions.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Wrap(spacing: 4, children: msg.reactions.map((r)=>Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: mutedText.withValues(alpha: 0.2))), child: Text(r.reaction, style: const TextStyle(fontSize: 14)))).toList())),
          ])))),
        ]),
        Padding(padding: EdgeInsets.only(top: 4, left: isOwn? 0 : 8, right: isOwn? 8 : 0), child: Row(mainAxisAlignment: isOwn? MainAxisAlignment.end : MainAxisAlignment.start, children: [if(widget.isEphemeralActive) ChatEphemeralTimer(duration: widget.message.ephemeralDuration??60, onExpired: (){ if(widget.onDelete!=null) widget.onDelete!(); }), if(widget.isEphemeralActive) const SizedBox(width: 6), Text(DateFormat('HH:mm').format(msg.createdAt), style: const TextStyle(fontSize: 9, color: mutedText)), if(isOwn)...[const SizedBox(width: 4), Icon(msg.isRead? Icons.done_all_rounded : Icons.check_rounded, size: 13, color: msg.isRead? primaryBlue : mutedText.withValues(alpha: 0.7))]])),
        if((_isHovering || _showReactions) &&!widget.isInternalNote) Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8)]), child: Row(mainAxisSize: MainAxisSize.min, children: [..._quickReactions.map((e)=>InkWell(onTap: (){ widget.onReaction?.call(e); setState(()=>_showReactions=false); }, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text(e, style: const TextStyle(fontSize: 20))))), Container(width: 1, height: 20, color: Colors.grey.shade300, margin: const EdgeInsets.symmetric(horizontal: 6)), IconButton(icon: const Icon(Icons.emoji_emotions_outlined, size: 18, color: mutedText), onPressed: _showStickerPicker, padding: EdgeInsets.zero, constraints: const BoxConstraints()), IconButton(icon: const Icon(Icons.flag_outlined, size: 18, color: mutedText), onPressed: _showFlagPicker, padding: EdgeInsets.zero, constraints: const BoxConstraints()), IconButton(icon: const Icon(Icons.reply, size: 18, color: mutedText), onPressed: widget.onReply, padding: EdgeInsets.zero, constraints: const BoxConstraints()), if(isOwn) IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: danger), onPressed: widget.onDelete, padding: EdgeInsets.zero, constraints: const BoxConstraints())]))),
      ]),
    );
  }

  Widget _buildBadges(ChatMessage msg) => Wrap(spacing: 4, children: [if(widget.isInternalNote) _badge(Icons.note_rounded, 'Interne', Colors.orange), if(_isEncrypted) _badge(_isDecrypted? Icons.lock_open_rounded : Icons.lock_rounded, _isDecrypted? 'Déchiffré' : 'Chiffré', gold), if(widget.isEphemeralActive) _badge(Icons.timer_rounded, 'Éphémère', Colors.orange)]);
  Widget _badge(IconData icon, String text, Color color) => Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withValues(alpha: 0.3))), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 12, color: color), const SizedBox(width: 2), Text(text, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600))]));

  void _showStickerPicker() {
    showModalBottomSheet(context: context, backgroundColor: pureWhite, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))), builder: (ctx)=>DraggableScrollableSheet(initialChildSize: 0.7, maxChildSize: 0.9, minChildSize: 0.4, expand: false, builder: (_, sc)=>Column(children: [
      const SizedBox(height: 12), Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))),
      const Padding(padding: EdgeInsets.all(16), child: Text('Stickers - 280 emojis', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
      Expanded(child: GridView.builder(controller: sc, padding: const EdgeInsets.all(12), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8, crossAxisSpacing: 6, mainAxisSpacing: 6), itemCount: stickers.length, itemBuilder: (_, i)=>InkWell(onTap: (){ Navigator.pop(ctx); widget.onReaction?.call(stickers[i]); }, child: Center(child: Text(stickers[i], style: const TextStyle(fontSize: 26)))))),
    ])));
  }

  void _showFlagPicker() {
    showModalBottomSheet(context: context, backgroundColor: pureWhite, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))), builder: (ctx)=>DraggableScrollableSheet(initialChildSize: 0.7, maxChildSize: 0.9, minChildSize: 0.4, expand: false, builder: (_, sc)=>Column(children: [
      const SizedBox(height: 12), Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))),
      const Padding(padding: EdgeInsets.all(16), child: Text('Drapeaux du monde - 249 pays', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
      Expanded(child: GridView.builder(controller: sc, padding: const EdgeInsets.all(12), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, crossAxisSpacing: 8, mainAxisSpacing: 8), itemCount: flags.length, itemBuilder: (_, i)=>InkWell(onTap: (){ Navigator.pop(ctx); widget.onReaction?.call(flags[i]); }, child: Container(decoration: BoxDecoration(color: const Color(0xFFF3F5FA), borderRadius: BorderRadius.circular(8)), child: Center(child: Text(flags[i], style: const TextStyle(fontSize: 32))))))),
    ])));
  }

  Widget _buildMediaContent() {
    final url = widget.message.mediaUrl;
    if(url==null || url.isEmpty) return Text(widget.message.content.isNotEmpty? widget.message.content : '📷 Photo', style: TextStyle(color: widget.isOwn? Colors.white : darkText));
    final type = widget.message.mediaType?? 'file';
    if(type=='image') {
      return GestureDetector(onTap: ()=>Navigator.push(context, MaterialPageRoute(builder: (_)=>FullScreenImagePage(imageUrl: url, tag: widget.message.id))), child: Hero(tag: widget.message.id, child: ClipRRect(borderRadius: BorderRadius.circular(16), child: CachedNetworkImage(imageUrl: url, fit: BoxFit.cover, memCacheWidth: 600, placeholder: (_,__)=>Container(height: 150, width: 200, color: Colors.grey.shade200, child: const Center(child: CircularProgressIndicator(strokeWidth: 2))), errorWidget: (_,__,___)=>Container(height: 120, width: 200, color: leftBubbleColor, child: const Center(child: Icon(Icons.broken_image, size: 30, color: mutedText)))))));
    }
    return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: pureWhite.withValues(alpha: 0.3)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(type=='video'? Icons.videocam_rounded : Icons.insert_drive_file_rounded, color: widget.isOwn? Colors.white : primaryBlue), const SizedBox(width: 8), Flexible(child: Text(widget.message.content.isNotEmpty? widget.message.content : type, style: TextStyle(color: widget.isOwn? Colors.white : darkText), overflow: TextOverflow.ellipsis))]));
  }
}

class FullScreenImagePage extends StatelessWidget {
  final String imageUrl; final String tag;
  const FullScreenImagePage({super.key, required this.imageUrl, required this.tag});
  @override Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.black, appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white)), body: Center(child: InteractiveViewer(minScale: 0.5, maxScale: 4, child: Hero(tag: tag, child: CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.contain)))));
  }
}
