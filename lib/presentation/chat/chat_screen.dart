// lib/presentation/chat/screens/chat_screen.dart - VERSION 10/10 WEB FIX 3461
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

// Services
import 'package:thix_id/services/chat/chat_service.dart';
import 'package:thix_id/services/chat/presence_service.dart';
import 'package:thix_id/services/chat/audio_service.dart';
import 'package:thix_id/services/chat/group_service.dart';
import 'package:thix_id/services/chat/connection_service.dart';

// Modèles
import 'package:thix_id/models/chat/chat_message.dart';
import 'package:thix_id/models/chat/chat_conversation.dart';
import 'package:thix_id/models/chat/user_status.dart';
import 'package:thix_id/models/chat/group_info.dart';

// Widgets
import 'package:thix_id/presentation/chat/widgets/chat_message_bubble.dart';
import 'package:thix_id/presentation/chat/widgets/chat_input_bar.dart';
import 'package:thix_id/presentation/chat/widgets/audio_recorder.dart';
import 'package:thix_id/presentation/chat/group/group_info_panel.dart';
import 'package:thix_id/presentation/chat/encryption_service.dart';
import 'package:thix_id/models/chat/call_status.dart';
import 'package:thix_id/presentation/chat/call/call_page.dart';
import 'package:thix_id/presentation/chat/call/providers/call_provider.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final ChatConversation conversation;
  const ChatScreen({super.key, required this.conversationId, required this.conversation});
  @override State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  late ChatService _chatService;
  late PresenceService _presenceService;
  late AudioService _audioService;
  late GroupService _groupService;
  late ConnectionService _connectionService;

  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _isSending = false;
  int _page = 0;
  static const int _pageSize = 30;

  final _scrollController = ScrollController();
  final _inputController = TextEditingController();
  final _inputFocus = FocusNode();

  UserStatus? _otherParticipant;
  List<GroupMember> _groupMembers = [];
  String _replyToId = '';
  bool _isEphemeral = false;
  int? _ephemeralDuration;
  bool _isTyping = false;
  bool _otherUserTyping = false;
  Timer? _typingTimer;
  RealtimeChannel? _realtimeChannel;
  RealtimeChannel? _typingChannel;
  bool _isAgent = false;
  bool _isInternalNoteMode = false;

  static const primaryBlue = Color(0xFF4A8BFF);
  static const leftBubbleColor = Color(0xFFE9F0FF);
  static const pureWhite = Color(0xFFFFFFFF);
  static const darkText = Color(0xFF10182B);
  static const mutedText = Color(0xFF6B7690);
  static const success = Color(0xFF1FA971);
  static const danger = Color(0xFFD64545);
  static const hairline = Color(0xFFE7EAF3);
  static const ivory = Color(0xFFF3F5FA);
  static const navyDeep = Color(0xFF0A1F44);
  static const gold = Color(0xFFE3B23C);

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;
    _chatService = ChatService(client);
    _presenceService = PresenceService(client);
    _audioService = AudioService(client);
    _groupService = GroupService(client);
    _connectionService = ConnectionService();
    WidgetsBinding.instance.addObserver(this);
    _loadUserRole();
    _loadMessages();
    _getParticipantInfo();
    _markAsRead();
    _setupScroll();
    _subscribeRealtimeSingleMessage();
    _subscribeTyping();
    _loadGroupMembers();
  }

  Future<void> _loadUserRole() async {
    final role = Supabase.instance.client.auth.currentUser?.userMetadata?['role'];
    _isAgent = role == 'agent' || role == 'admin' || role == 'support';
    if(mounted) setState((){});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _inputController.dispose();
    _inputFocus.dispose();
    _typingTimer?.cancel();
    _realtimeChannel?.unsubscribe();
    _typingChannel?.unsubscribe();
    _audioService.dispose();
    super.dispose();
  }

  Future<void> _loadMessages({bool more = false}) async {
    if(more) { if(_isLoadingMore ||!_hasMore) return; setState(()=>_isLoadingMore=true); } else { setState(()=>_isLoading=true); _page=0; }
    try {
      final msgs = await _chatService.getMessages(widget.conversationId, limit: _pageSize, offset: _page*_pageSize);
      if(!mounted) return;
      setState(() { if(more) { _messages = [...msgs,..._messages]; } else { _messages = msgs; } _hasMore = msgs.length >= _pageSize; _isLoading=false; _isLoadingMore=false; });
      if(!more) _scrollToBottom();
    } catch(_) { if(mounted) setState(()=>_isLoading=_isLoadingMore=false); }
  }

  void _setupScroll() {
    _scrollController.addListener(() { if(_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) { if(_hasMore &&!_isLoadingMore) { _page++; _loadMessages(more: true); } } });
  }

  Future<void> _markAsRead() => _chatService.markAsRead(widget.conversationId);
  void _scrollToBottom() { if(_scrollController.hasClients) _scrollController.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut); }

  // FIX 3461: ajout type: PostgresChangeFilterType.eq
  void _subscribeRealtimeSingleMessage() {
    final myId = _chatService.currentUserId;
    _realtimeChannel = Supabase.instance.client.channel('msg_${widget.conversationId}')
   .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'conversation_id', value: widget.conversationId),
      callback: (payload) {
        if(payload.newRecord['sender_id']==myId) return;
        try {
          final msg = ChatMessage.fromJson({...payload.newRecord, 'profiles': {'full_name': payload.newRecord['sender_name']??'Utilisateur'}});
          if(mounted) { setState(()=>_messages.add(msg)); _scrollToBottom(); _markAsRead(); }
        } catch(_){}
      }
    )
   .onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'messages',
      filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'conversation_id', value: widget.conversationId),
      callback: (payload) {
        final idx = _messages.indexWhere((m)=>m.id==payload.newRecord['id']);
        if(idx!=-1 && mounted) { try{ setState(()=>_messages[idx]=ChatMessage.fromJson({..._messages[idx].toJson(),...payload.newRecord})); }catch(_){} }
      }
    ).subscribe();
  }

  void _subscribeTyping() {
    final myId = _chatService.currentUserId;
    _typingChannel = Supabase.instance.client.channel('typing_${widget.conversationId}').onBroadcast(event: 'typing', callback: (p) { if(p['senderId']!=myId && mounted) setState(()=>_otherUserTyping=p['isTyping']??false); }).subscribe();
  }

  void _sendTypingStatus(bool t) { _typingChannel?.sendBroadcastMessage(event: 'typing', payload: {'senderId': _chatService.currentUserId, 'isTyping': t}); }
  Future<void> _getParticipantInfo() async { if(widget.conversation.isGroup) return; final otherId = widget.conversation.participantIds.firstWhere((id)=>id!=_chatService.currentUserId, orElse:()=>''); if(otherId.isEmpty) return; final p = await _chatService.getUserPresence(otherId); if(mounted) setState(()=>_otherParticipant=p); }

  // FIX 3461: getGroupMembers vient de _chatService, pas _groupService
  Future<void> _loadGroupMembers() async {
    if(!widget.conversation.isGroup) return;
    try{
      final m = await _chatService.getGroupMembers(widget.conversationId);
      if(mounted) setState(()=>_groupMembers=m);
    }catch(e){
      debugPrint('group members error: $e');
      _groupMembers = [];
    }
  }

  // ================= MULTI-PHOTO + VIDEO + PREVIEW (WEB + MOBILE) =================
  Future<void> _pickMultiMedia() async {
    try {
      final result = await FilePicker.platform.pickFiles(allowMultiple: true, type: FileType.media, withData: true);
      if(result==null || result.files.isEmpty) return;
      if(result.files.length > 10) { if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Max 10 fichiers'))); return; }
      final confirmed = await _showMultiPreviewSheetWeb(result.files);
      if(confirmed!=true) return;
      setState(()=>_isSending=true);
      final uploadFutures = result.files.map((pf) async {
        final bytes = pf.bytes; if(bytes==null || bytes.isEmpty) throw Exception('${pf.name} vide');
        if(bytes.lengthInBytes > 15*1024*1024) throw Exception('${pf.name} >15MB');
        final ext = pf.extension?? 'jpg';
        final url = await _chatService.uploadFileWithUniqueName('chat-media', 'messages/${widget.conversationId}', bytes, ext);
        return {'name': pf.name, 'url': url, 'ext': ext, 'size': bytes.lengthInBytes};
      }).toList();
      final uploaded = await Future.wait(uploadFutures);
      for(var u in uploaded) {
        if(u['url']==null) continue;
        final ext = (u['ext'] as String).toLowerCase();
        final isImage = ['jpg','jpeg','png','webp','gif'].contains(ext);
        final isVideo = ['mp4','mov','avi','mkv','webm'].contains(ext);
        final msg = await _chatService.sendMessage(conversationId: widget.conversationId, content: isImage? '📷 Photo' : isVideo? '🎥 Vidéo' : '📎 ${u['name']}', mediaUrl: u['url'] as String, mediaType: isImage? 'image' : isVideo? 'video' : 'file', mediaName: u['name'] as String, mediaSize: u['size'] as int, replyToId: _replyToId.isEmpty? null : _replyToId, isEphemeral: _isEphemeral, ephemeralDuration: _ephemeralDuration);
        if(mounted) setState(()=>_messages.add(msg));
      }
      if(mounted) setState(()=>_replyToId='');
      _scrollToBottom();
    } catch(e) { if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: danger)); } finally { if(mounted) setState(()=>_isSending=false); }
  }

  Future<bool?> _showMultiPreviewSheetWeb(List<PlatformFile> files) {
    return showModalBottomSheet<bool>(
      context: context, isScrollControlled: true, backgroundColor: pureWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7, maxChildSize: 0.9, minChildSize: 0.5, expand: false,
        builder: (_, scroll) => Column(
          children: [
            const SizedBox(height: 12), Container(width: 40, height: 4, decoration: BoxDecoration(color: hairline, borderRadius: BorderRadius.circular(4))),
            Padding(padding: const EdgeInsets.all(16), child: Text('Envoyer ${files.length} fichiers?', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
            Expanded(child: GridView.builder(controller: scroll, padding: const EdgeInsets.all(12), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8), itemCount: files.length, itemBuilder: (_, i) { final f = files[i]; final isImage = ['jpg','jpeg','png','webp','gif'].contains((f.extension??'').toLowerCase()); return ClipRRect(borderRadius: BorderRadius.circular(12), child: isImage && f.bytes!=null? Image.memory(f.bytes!, fit: BoxFit.cover) : Container(color: ivory, child: Icon(f.extension=='mp4'? Icons.videocam_rounded : Icons.insert_drive_file_rounded, size: 30, color: primaryBlue))); })),
            Padding(padding: const EdgeInsets.all(16), child: Row(children: [Expanded(child: OutlinedButton(onPressed: ()=>Navigator.pop(ctx,false), child: const Text('Annuler'))), const SizedBox(width: 12), Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: primaryBlue), onPressed: ()=>Navigator.pop(ctx,true), child: const Text('Envoyer', style: TextStyle(color: Colors.white))))])),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim(); if(text.isEmpty || _isSending) return;
    if(!widget.conversation.isGroup &&!_isInternalNoteMode) {
      final otherId = widget.conversation.participantIds.firstWhere((id)=>id!=_chatService.currentUserId, orElse:()=>'');
      if(otherId.isNotEmpty) { final ok = await _connectionService.checkConnection(_chatService.currentUserId, otherId); if(!ok) { if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vous devez être connecté'), backgroundColor: Colors.orange)); return; } }
    }
    _sendTypingStatus(false); setState(()=>_isSending=true);
    try { final msg = await _chatService.sendMessage(conversationId: widget.conversationId, content: text, replyToId: _replyToId.isEmpty? null : _replyToId, isEphemeral: _isEphemeral, ephemeralDuration: _ephemeralDuration); if(mounted) { setState(()=>_messages.add(msg)); _inputController.clear(); _replyToId=''; _isSending=false; } _scrollToBottom(); } catch(e) { if(mounted) setState(()=>_isSending=false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBlue,
      appBar: AppBar(
        backgroundColor: primaryBlue, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), onPressed: ()=>Navigator.pop(context)),
        title: Row(children: [
          CircleAvatar(radius: 19, backgroundColor: Colors.white.withValues(alpha: 0.2), child: widget.conversation.isGroup? const Icon(Icons.groups_rounded, color: Colors.white) : ClipOval(child: CachedNetworkImage(imageUrl: widget.conversation.groupAvatar?? 'https://i.pravatar.cc/150?img=11', width: 38, height: 38, fit: BoxFit.cover, memCacheWidth: 76, errorWidget: (_,__,___)=>const Icon(Icons.person, color: Colors.white)))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.conversation.displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis), if(_otherParticipant!=null) Text(_otherParticipant!.status=='online'? 'En ligne' : 'Vu ${DateFormat('HH:mm').format(_otherParticipant!.lastSeenAt??DateTime.now())}', style: const TextStyle(color: Colors.white70, fontSize: 11))])),
        ]),
        actions: [IconButton(icon: const Icon(Icons.call_rounded, color: Colors.white), onPressed: ()=>_startCall(CallType.audio)), IconButton(icon: const Icon(Icons.videocam_rounded, color: Colors.white), onPressed: ()=>_startCall(CallType.video)), const SizedBox(width: 4)],
      ),
      body: Column(children: [
        Expanded(child: Container(decoration: const BoxDecoration(color: pureWhite, borderRadius: BorderRadius.vertical(top: Radius.circular(22))), child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(22)), child: Column(children: [
          if(widget.conversation.isGroup) GroupInfoPanel(conversation: widget.conversation, members: _groupMembers, onViewAllMembers: (){}, onEditGroup: (){}, onLeaveGroup: (){}, onDeleteGroup: (){}),
          Expanded(child: _isLoading? const Center(child: CircularProgressIndicator(color: primaryBlue)) : Stack(children: [
            ListView.builder(controller: _scrollController, reverse: true, padding: const EdgeInsets.all(12), itemCount: _messages.length + (_isLoadingMore?1:0), itemBuilder: (_, idx) { if(idx==_messages.length && _isLoadingMore) return const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2))); final msg = _messages[_messages.length-1-idx]; final isOwn = msg.senderId==_chatService.currentUserId; return GestureDetector(onLongPress: ()=>_showMessageActions(msg, isOwn), child: ChatMessageBubble(message: msg, isOwn: isOwn, onReply: ()=>setState(()=>_replyToId=msg.id), onDelete: () async { setState(()=>_messages.removeWhere((m)=>m.id==msg.id)); await _chatService.deleteMessage(msg.id); }, onReaction: (r)=>_chatService.toggleReaction(msg.id, r), replyToMessage: msg.replyToId!=null? _messages.where((m)=>m.id==msg.replyToId).firstOrNull : null, isEphemeralActive: msg.isEphemeral, isInternalNote: msg.isInternalNote, isAgentView: _isAgent)); }),
            if(_otherUserTyping) Positioned(bottom: 8, left: 16, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: leftBubbleColor, borderRadius: BorderRadius.circular(16)), child: const Text('En train d\'écrire...', style: TextStyle(fontSize: 11, color: primaryBlue, fontStyle: FontStyle.italic)))),
          ])),
          if(_replyToId.isNotEmpty) Container(padding: const EdgeInsets.all(8), color: ivory, child: Row(children: [Expanded(child: Text(_messages.firstWhere((m)=>m.id==_replyToId, orElse:()=>_messages.first).content, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12))), IconButton(icon: const Icon(Icons.close, size: 16), onPressed: ()=>setState(()=>_replyToId=''))])),
          ChatInputBar(controller: _inputController, focusNode: _inputFocus, onSend: _sendMessage, isSending: _isSending, onAttach: _pickMultiMedia, onAudio: _startAudio, onSecureMessage: _showSecureDialog, onEphemeralToggle: _showEphemeralDialog, isEphemeral: _isEphemeral, onTyping: (t){ if(t.isNotEmpty&&!_isTyping){ _isTyping=true; _sendTypingStatus(true);} _typingTimer?.cancel(); _typingTimer=Timer(const Duration(seconds: 2),(){ _isTyping=false; _sendTypingStatus(false);});}, onInternalNoteToggle: _isAgent? ()=>setState(()=>_isInternalNoteMode=!_isInternalNoteMode):null, isInternalNote: _isInternalNoteMode),
        ])))),
      ]),
    );
  }

  void _startCall(CallType type) { final otherId = widget.conversation.participantIds.firstWhere((id)=>id!=_chatService.currentUserId, orElse:()=>''); context.read<CallProvider>().start(channel: widget.conversationId, calleeId: otherId, callType: type); Navigator.push(context, MaterialPageRoute(builder: (_)=>CallPage(channel: widget.conversationId, name: widget.conversation.displayName, type: type, isCaller: true))); }
  void _startAudio() async { if(kIsWeb) { if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Audio non supporté sur web'))); return; } if(await Permission.microphone.request().isGranted) { if(!mounted) return; showModalBottomSheet(context: context, isScrollControlled: true, builder: (ctx)=>Container(padding: const EdgeInsets.all(20), child: AudioRecorderWidget(audioService: _audioService, onRecordingComplete: (p,d) async { Navigator.pop(ctx); try{ final file = await FilePicker.platform.pickFiles(); }catch(_){} }, onRecordingCanceled: ()=>Navigator.pop(ctx), maxDuration: 120))); } }
  void _showSecureDialog() { final m=TextEditingController(); final p=TextEditingController(); showDialog(context: context, builder: (_)=>AlertDialog(title: const Text('Message Protégé'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: m, maxLines: 4, decoration: const InputDecoration(hintText: 'Message secret')), TextField(controller: p, obscureText: true, decoration: const InputDecoration(hintText: 'Mot de passe'))]), actions: [TextButton(onPressed: ()=>Navigator.pop(context), child: const Text('Annuler')), ElevatedButton(onPressed: () async { final enc=EncryptionService.encryptMessage(m.text, p.text); await _chatService.sendMessage(conversationId: widget.conversationId, content: enc); if(mounted) Navigator.pop(context); }, child: const Text('Envoyer'))])); }
  void _showEphemeralDialog() { showModalBottomSheet(context: context, builder: (_)=>Column(mainAxisSize: MainAxisSize.min, children: [[10,'10 sec'], [30,'30 sec'], [60,'1 min'], [300,'5 min'], [3600,'1 heure']].map((e)=>ListTile(title: Text(e[1] as String), onTap: (){ setState(()=>_isEphemeral=true); _ephemeralDuration=e[0] as int; Navigator.pop(context); })).toList())); }
  void _showMessageActions(ChatMessage msg, bool isOwn) {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (ctx)=>Container(decoration: const BoxDecoration(color: pureWhite, borderRadius: BorderRadius.vertical(top: Radius.circular(26))), padding: const EdgeInsets.all(18), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 40, height: 4, decoration: BoxDecoration(color: hairline, borderRadius: BorderRadius.circular(4))), const SizedBox(height: 16),
      Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: ['❤️','😂','🔥','👍','😮','😢'].map((e)=>InkWell(onTap: (){ _chatService.toggleReaction(msg.id, e); Navigator.pop(ctx); }, child: Text(e, style: const TextStyle(fontSize: 28)))).toList()),
      const Divider(height: 24),
      ListTile(leading: const Icon(Icons.reply_rounded), title: const Text('Répondre'), onTap: (){ Navigator.pop(ctx); setState(()=>_replyToId=msg.id); }),
      ListTile(leading: const Icon(Icons.copy_rounded), title: const Text('Copier'), onTap: (){ Clipboard.setData(ClipboardData(text: msg.content)); Navigator.pop(ctx); }),
      if(isOwn) ListTile(leading: const Icon(Icons.delete_outline_rounded, color: danger), title: const Text('Supprimer', style: TextStyle(color: danger)), onTap: () async { Navigator.pop(ctx); setState(()=>_messages.removeWhere((m)=>m.id==msg.id)); await _chatService.deleteMessage(msg.id); }),
    ])));
  }
}
