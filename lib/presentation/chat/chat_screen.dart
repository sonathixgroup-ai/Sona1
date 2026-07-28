// lib/presentation/chat/chat_screen.dart
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart' as prov;
import 'package:cached_network_image/cached_network_image.dart';

import 'package:thix_id/services/chat/chat_service.dart';
import 'package:thix_id/services/chat/presence_service.dart';
import 'package:thix_id/services/chat/audio_service.dart';
import 'package:thix_id/services/chat/group_service.dart';
import 'package:thix_id/services/chat/connection_service.dart';

import 'package:thix_id/models/chat/chat_message.dart';
import 'package:thix_id/models/chat/chat_conversation.dart';
import 'package:thix_id/models/chat/user_status.dart';
import 'package:thix_id/models/chat/group_info.dart';

import 'package:thix_id/presentation/chat/widgets/chat_message_bubble.dart';
import 'package:thix_id/presentation/chat/widgets/chat_input_bar.dart';
import 'package:thix_id/presentation/chat/widgets/audio_recorder.dart';
import 'package:thix_id/presentation/chat/group/group_info_panel.dart';
import 'package:thix_id/presentation/chat/encryption_service.dart';
import 'package:thix_id/models/chat/call_status.dart';
import 'package:thix_id/presentation/chat/call/call_page.dart';
import 'package:thix_id/presentation/chat/call/providers/call_provider.dart';

// ─── NOUVEAU DESIGN CLAIR "GRANDEUR ENTREPRISE" ───
class _C {
  static const bg = Color(0xFFF0F2F5); // Fond de chat style WhatsApp/Telegram
  static const surface = Colors.white; // Fond des barres et menus
  static const surfaceAlt = Color(0xFFF8FAFC);
  static const border = Color(0xFFE2E8F0);
  static const primary = Color(0xFF0A66C2); // Bleu Trust
  static const primaryLight = Color(0xFFEFF6FF);
  static const textMain = Color(0xFF0F172A);
  static const textMuted = Color(0xFF64748B);
  static const red = Color(0xFFEF4444);
  static const green = Color(0xFF22C55E);
  static const orange = Color(0xFFF59E0B);
}

// Provider scalable messages paginé
final chatMessagesProvider = StateNotifierProvider.family<ChatMsgNotifier, List<ChatMessage>, String>((ref, conversationId) {
  return ChatMsgNotifier(ChatService(Supabase.instance.client), conversationId);
});

class ChatMsgNotifier extends StateNotifier<List<ChatMessage>> {
  final ChatService svc;
  final String convId;
  int page = 0;
  static const pageSize = 30;
  bool hasMore = true;
  bool loadingMore = false;
  
  ChatMsgNotifier(this.svc, this.convId) : super([]);
  
  Future<void> loadInitial() async {
    page = 0;
    final msgs = await svc.getMessages(convId, limit: pageSize, offset: 0);
    hasMore = msgs.length >= pageSize;
    state = msgs;
  }
  
  Future<void> loadMore() async {
    if (loadingMore || !hasMore) return;
    loadingMore = true;
    page++;
    final msgs = await svc.getMessages(convId, limit: pageSize, offset: page * pageSize);
    hasMore = msgs.length >= pageSize;
    final merged = [...msgs.reversed, ...state];
    final seen = <String>{};
    state = merged.where((m) => seen.add(m.id)).toList();
    loadingMore = false;
  }
}

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final ChatConversation conversation;
  
  const ChatScreen({super.key, required this.conversationId, required this.conversation});
  
  @override 
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> with WidgetsBindingObserver {
  late ChatService _chatService;
  late PresenceService _presenceService;
  late AudioService _audioService;
  late GroupService _groupService;
  late ConnectionService _connectionService;

  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreMessages = true;
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
  RealtimeChannel? _typingChannel;

  bool _isAgent = false;
  bool _isInternalNoteMode = false;
  bool _isConversationEscalated = false;

  StreamSubscription<List<ChatMessage>>? _messageSubscription;

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
    _setupScrollListener();
    _subscribeToPresence();
    _subscribeToRealtimeMessages();
    _subscribeToTypingChannel();
    _loadGroupMembersIfGroup();
  }

  Future<void> _loadUserRole() async {
    final user = _chatService.currentUser;
    if (user != null) { 
      _isAgent = user.role == 'agent' || user.role == 'admin' || user.role == 'support'; 
      if (mounted) setState(() {}); 
    }
  }

  @override 
  void dispose() { 
    WidgetsBinding.instance.removeObserver(this); 
    _scrollController.dispose(); 
    _inputController.dispose(); 
    _inputFocus.dispose(); 
    _typingTimer?.cancel(); 
    _messageSubscription?.cancel(); 
    _typingChannel?.unsubscribe(); 
    _audioService.dispose(); 
    super.dispose(); 
  }

  Future<void> _loadMessages({bool loadMore = false}) async {
    if (loadMore) { 
      if (_isLoadingMore || !_hasMoreMessages) return; 
      setState(() => _isLoadingMore = true); 
    } else { 
      setState(() => _isLoading = true); 
      _page = 0; 
    }
    
    try {
      final msgs = await _chatService.getMessages(widget.conversationId, limit: _pageSize, offset: _page * _pageSize);
      if (!mounted) return;
      
      setState(() { 
        if (loadMore) { 
          _messages = [...msgs.reversed, ..._messages]; 
          _hasMoreMessages = msgs.length >= _pageSize; 
        } else { 
          _messages = msgs; 
          _hasMoreMessages = msgs.length >= _pageSize; 
        } 
        _isLoading = false; 
        _isLoadingMore = false; 
      });
      
      if (!loadMore) _scrollToBottom();
    } catch (_) { 
      if (mounted) setState(() => _isLoading = _isLoadingMore = false); 
    }
  }

  Future<void> _loadGroupMembersIfGroup() async { 
    if (!widget.conversation.isGroup) return; 
    try { 
      final m = await _chatService.getGroupMembers(widget.conversationId); 
      if (mounted) setState(() => _groupMembers = m); 
    } catch (e) { 
      debugPrint('members $e'); 
    } 
  }

  void _setupScrollListener() { 
    _scrollController.addListener(() { 
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) { 
        if (_hasMoreMessages && !_isLoadingMore) { 
          _page++; 
          _loadMessages(loadMore: true); 
        } 
      } 
    }); 
  }

  Future<void> _markAsRead() async => await _chatService.markAsRead(widget.conversationId);
  
  void _scrollToBottom() { 
    if (_scrollController.hasClients) {
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut); 
    }
  }

  void _subscribeToPresence() {
    if (widget.conversation.isGroup) return;
    final otherId = widget.conversation.participantIds.firstWhere((id) => id != _chatService.currentUserId, orElse: () => '');
    if (otherId.isNotEmpty) {
      _chatService.subscribeToPresence([otherId]).listen((list) { 
        if (mounted && list.isNotEmpty) setState(() => _otherParticipant = list.first); 
      });
    }
  }

  Future<void> _getParticipantInfo() async { 
    if (widget.conversation.isGroup) return; 
    final otherId = widget.conversation.participantIds.firstWhere((id) => id != _chatService.currentUserId, orElse: () => ''); 
    if (otherId.isNotEmpty) { 
      final p = await _chatService.getUserPresence(otherId); 
      if (mounted) setState(() => _otherParticipant = p); 
    } 
  }

  void _subscribeToRealtimeMessages() {
    _messageSubscription = _chatService.subscribeToMessages(widget.conversationId).listen((updated) {
      if (!mounted) return;
      setState(() { 
        for (var msg in updated) { 
          final idx = _messages.indexWhere((m) => m.id == msg.id); 
          if (idx != -1) { 
            if (msg.isDeleted) _messages.removeAt(idx); 
            else _messages[idx] = msg; 
          } else if (!msg.isDeleted) { 
            _messages.add(msg); 
          } 
        } 
      });
      _scrollToBottom(); 
      _markAsRead();
    });
  }

  void _subscribeToTypingChannel() {
    final cur = _chatService.currentUserId;
    _typingChannel = Supabase.instance.client.channel('typing:${widget.conversationId}').onBroadcast(
      event: 'typing', 
      callback: (p) { 
        final sid = p['senderId'] as String?; 
        final typing = p['isTyping'] as bool? ?? false; 
        if (sid != null && sid != cur && mounted) setState(() => _otherUserTyping = typing); 
      }
    ).subscribe();
  }

  void _sendTypingStatus(bool t) { 
    final cur = _chatService.currentUserId; 
    if (cur == null || _typingChannel == null) return; 
    _typingChannel!.sendBroadcastMessage(event: 'typing', payload: {'senderId': cur, 'isTyping': t}); 
  }

  void _startCall(CallType type) {
    final otherId = widget.conversation.participantIds.firstWhere((id) => id != _chatService.currentUserId, orElse: () => '');
    final provv = prov.Provider.of<CallProvider>(context, listen: false); 
    provv.start(channel: widget.conversationId, calleeId: otherId, callType: type);
    Navigator.push(context, MaterialPageRoute(builder: (_) => CallPage(channel: widget.conversationId, name: widget.conversation.displayName, type: type, isCaller: true)));
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim(); 
    if (text.isEmpty || _isSending) return;
    
    if (!widget.conversation.isGroup && !_isInternalNoteMode) {
      final cur = _chatService.currentUserId;
      if (cur != null) { 
        final otherId = widget.conversation.participantIds.firstWhere((id) => id != cur, orElse: () => ''); 
        if (otherId.isNotEmpty) { 
          final ok = await _connectionService.checkConnection(cur, otherId); 
          if (!ok) { 
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vous devez être connecté pour envoyer un message'), backgroundColor: _C.orange)); 
            return; 
          } 
        } 
      }
    }
    
    _isTyping = false; 
    _sendTypingStatus(false); 
    setState(() => _isSending = true);
    
    try {
      final msg = await _chatService.sendMessage(
        conversationId: widget.conversationId, 
        content: text, 
        replyToId: _replyToId.isEmpty ? null : _replyToId, 
        isEphemeral: _isEphemeral, 
        ephemeralDuration: _isEphemeral ? _ephemeralDuration : null
      );
      
      if (mounted) {
        setState(() { 
          if (!_messages.any((m) => m.id == msg.id)) _messages.add(msg); 
          _inputController.clear(); 
          _replyToId = ''; 
          _isSending = false; 
          if (_isInternalNoteMode) _isInternalNoteMode = false; 
        });
      }
      _scrollToBottom();
    } catch (e) { 
      if (mounted) setState(() => _isSending = false); 
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: _C.red)); 
    }
  }

  void _showEphemeralTimerDialog() {
    final customCtrl = TextEditingController();
    showModalBottomSheet(
      context: context, 
      backgroundColor: Colors.transparent, 
      isScrollControlled: true, 
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        decoration: const BoxDecoration(
          color: _C.surface, 
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)), 
          boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 20, offset: Offset(0, -5))]
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, 
          children: [
            Container(width: 40, height: 5, decoration: BoxDecoration(color: _C.border, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: _C.primaryLight, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.timer_rounded, size: 20, color: _C.primary)
                ), 
                const SizedBox(width: 12), 
                const Text("Messages éphémères", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: _C.textMain))
              ]
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.timer_off_rounded, color: !_isEphemeral ? _C.primary : _C.textMuted), 
              title: Text("Désactiver - Envoyer sans éphémère", style: TextStyle(fontSize: 15, fontWeight: !_isEphemeral ? FontWeight.bold : FontWeight.w500, color: !_isEphemeral ? _C.primary : _C.textMain)), 
              trailing: !_isEphemeral ? const Icon(Icons.check_circle_rounded, color: _C.primary) : null, 
              onTap: () { 
                setState(() { _isEphemeral = false; _ephemeralDuration = null; }); 
                Navigator.pop(ctx); 
              }
            ),
            const Divider(color: _C.border),
            ...[[10, '10 secondes'], [30, '30 secondes'], [60, '1 minute'], [300, '5 minutes'], [3600, '1 heure'], [86400, '24 heures']].map((e) {
              final sec = e[0] as int; 
              final label = e[1] as String; 
              final sel = _isEphemeral && _ephemeralDuration == sec;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.timer_rounded, color: sel ? _C.primary : _C.textMuted), 
                title: Text(label, style: TextStyle(fontSize: 15, fontWeight: sel ? FontWeight.bold : FontWeight.w500, color: sel ? _C.primary : _C.textMain)), 
                trailing: sel ? const Icon(Icons.check_circle_rounded, color: _C.primary) : null, 
                onTap: () { 
                  setState(() { _isEphemeral = true; _ephemeralDuration = sec; }); 
                  Navigator.pop(ctx); 
                }
              );
            }),
            const Divider(color: _C.border), 
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: customCtrl, 
                    keyboardType: TextInputType.number, 
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly], 
                    style: const TextStyle(color: _C.textMain, fontSize: 14), 
                    decoration: InputDecoration(
                      hintText: 'Personnalisé (sec)', 
                      hintStyle: const TextStyle(color: _C.textMuted, fontSize: 14), 
                      filled: true, 
                      fillColor: _C.surfaceAlt, 
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _C.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _C.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _C.primary))
                    )
                  )
                ), 
                const SizedBox(width: 12), 
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.primary, 
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ), 
                  onPressed: () { 
                    final v = int.tryParse(customCtrl.text); 
                    if (v != null && v > 0) { 
                      setState(() { _isEphemeral = true; _ephemeralDuration = v; }); 
                      Navigator.pop(ctx); 
                    } 
                  }, 
                  child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold))
                )
              ]
            ),
          ]
        ),
      )
    );
  }

  void _showPasswordProtectDialog() {
    final msgCtrl = TextEditingController(); 
    final passCtrl = TextEditingController();
    
    showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.surface, 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: _C.border)), 
        title: Row(
          children: const [
            Icon(Icons.lock_rounded, color: _C.primary),
            SizedBox(width: 10),
            Text('Message Protégé', style: TextStyle(color: _C.textMain, fontWeight: FontWeight.bold, fontSize: 18))
          ]
        ), 
        content: Column(
          mainAxisSize: MainAxisSize.min, 
          children: [
            TextField(
              controller: msgCtrl,
              maxLines: 4,
              style: const TextStyle(color: _C.textMain, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Écrivez votre message secret...',
                hintStyle: const TextStyle(color: _C.textMuted),
                filled: true,
                fillColor: _C.surfaceAlt,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _C.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _C.border))
              )
            ), 
            const SizedBox(height: 16), 
            TextField(
              controller: passCtrl,
              obscureText: true,
              style: const TextStyle(color: _C.textMain, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Mot de passe requis pour lire',
                hintStyle: const TextStyle(color: _C.textMuted),
                prefixIcon: const Icon(Icons.key_rounded, color: _C.primary),
                filled: true,
                fillColor: _C.surfaceAlt,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _C.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _C.border))
              )
            )
          ]
        ), 
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text('Annuler', style: TextStyle(color: _C.textMuted, fontWeight: FontWeight.bold))
          ), 
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
            ), 
            onPressed: () async { 
              if (msgCtrl.text.isNotEmpty && passCtrl.text.isNotEmpty) { 
                final enc = EncryptionService.encryptMessage(msgCtrl.text, passCtrl.text); 
                await _chatService.sendMessage(
                  conversationId: widget.conversationId, 
                  content: enc, 
                  replyToId: _replyToId.isEmpty ? null : _replyToId, 
                  isEphemeral: _isEphemeral, 
                  ephemeralDuration: _ephemeralDuration
                ); 
                if (mounted) Navigator.pop(ctx); 
              } 
            }, 
            child: const Text('Envoyer crypté', style: TextStyle(fontWeight: FontWeight.bold))
          )
        ]
      )
    );
  }

  void _startAudioRecording() async { 
    final st = await Permission.microphone.request(); 
    if (st.isGranted) { 
      showModalBottomSheet(
        context: context, 
        isScrollControlled: true, 
        backgroundColor: Colors.transparent, 
        builder: (ctx) => Container(
          decoration: const BoxDecoration(
            color: _C.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22))
          ), 
          padding: const EdgeInsets.all(24), 
          child: AudioRecorderWidget(
            audioService: _audioService, 
            onRecordingComplete: (p, d) { Navigator.pop(ctx); _sendAudio(p, d); }, 
            onRecordingCanceled: () => Navigator.pop(ctx), 
            maxDuration: 120
          )
        )
      ); 
    } else if (st.isPermanentlyDenied) { 
      openAppSettings(); 
    } 
  }

  Future<void> _sendAudio(String path, int dur) async { 
    try { 
      final bytes = await File(path).readAsBytes(); 
      final msg = await _chatService.sendAudioMessage(
        conversationId: widget.conversationId, 
        audioData: Uint8List.fromList(bytes), 
        duration: dur, 
        isEphemeral: _isEphemeral, 
        ephemeralDuration: _ephemeralDuration, 
        replyToId: _replyToId.isEmpty ? null : _replyToId
      ); 
      if (mounted) {
        setState(() { _messages.add(msg); _replyToId = ''; }); 
      }
      _scrollToBottom(); 
    } catch (e) { 
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur audio: $e'), backgroundColor: _C.red)); 
    } 
  }

  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context, 
      backgroundColor: Colors.transparent, 
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: _C.surface, 
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 20, offset: Offset(0, -5))]
        ), 
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min, 
            children: [
              const SizedBox(height: 12), 
              Container(width: 40, height: 5, decoration: BoxDecoration(color: _C.border, borderRadius: BorderRadius.circular(4))),
              const Padding(
                padding: EdgeInsets.all(20), 
                child: Row(
                  children: [
                    Icon(Icons.attach_file_rounded, color: _C.primary, size: 24),
                    SizedBox(width: 12),
                    Text('Envoyer une pièce jointe', style: TextStyle(color: _C.textMain, fontWeight: FontWeight.bold, fontSize: 18))
                  ]
                )
              ),
              _attachmentOption(Icons.image_rounded, 'Photo / Galerie', () => _pickFile(type: FileType.image)),
              _attachmentOption(Icons.videocam_rounded, 'Vidéo', () => _pickFile(type: FileType.video)),
              _attachmentOption(Icons.insert_drive_file_rounded, 'Document / Fichier', () => _pickFile(type: FileType.any)),
              const SizedBox(height: 20),
            ]
          )
        )
      )
    );
  }

  Widget _attachmentOption(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: _C.primaryLight, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: _C.primary, size: 24)
      ), 
      title: Text(title, style: const TextStyle(color: _C.textMain, fontSize: 16, fontWeight: FontWeight.w500)), 
      onTap: () { Navigator.pop(context); onTap(); }
    );
  }

  Future<void> _pickFile({FileType type = FileType.any}) async {
    try {
      final result = await FilePicker.platform.pickFiles(allowMultiple: false, type: type, withData: true);
      if (result == null || result.files.isEmpty) return;
      
      final f = result.files.first; 
      final bytes = f.bytes ?? (f.path != null ? await File(f.path!).readAsBytes() : null); 
      if (bytes == null) return;
      
      final ext = f.extension ?? 'file'; 
      final size = f.size;
      final url = await _chatService.uploadFileWithUniqueName('chat-media', 'messages/${widget.conversationId}', Uint8List.fromList(bytes), ext);
      
      if (url != null) { 
        final msg = await _chatService.sendMessage(
          conversationId: widget.conversationId, 
          content: f.name, 
          mediaUrl: url, 
          mediaType: _getMediaType(ext), 
          mediaName: f.name, 
          mediaSize: size, 
          isEphemeral: _isEphemeral, 
          ephemeralDuration: _ephemeralDuration
        ); 
        if (mounted) setState(() => _messages.add(msg)); 
        _scrollToBottom(); 
      }
    } catch (e) { 
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur fichier: $e'), backgroundColor: _C.red)); 
    }
  }

  String _getMediaType(String ext) { 
    const img = {'jpg', 'jpeg', 'png', 'gif', 'webp'}; 
    const vid = {'mp4', 'mov', 'avi', 'mkv'}; 
    const aud = {'mp3', 'wav', 'm4a'}; 
    final e = ext.toLowerCase(); 
    if (img.contains(e)) return 'image'; 
    if (vid.contains(e)) return 'video'; 
    if (aud.contains(e)) return 'audio'; 
    return 'file'; 
  }

  void _escalateConversation() { 
    context.pushNamed('chatEscalate', pathParameters: {'conversationId': widget.conversationId}, queryParameters: {'agentId': _chatService.currentUserId ?? '', 'agentName': _chatService.currentUser?.userMetadata?['full_name'] ?? 'Agent'}); 
  }
  
  void _viewEscalationHistory() { 
    context.pushNamed('chatEscalationHistory', pathParameters: {'conversationId': widget.conversationId}); 
  }
  
  void _toggleInternalNoteMode() { 
    setState(() => _isInternalNoteMode = !_isInternalNoteMode); 
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(_isInternalNoteMode ? 'Mode note interne ACTIVÉ' : 'Mode note interne DÉSACTIVÉ', style: const TextStyle(fontWeight: FontWeight.bold)), 
      backgroundColor: _isInternalNoteMode ? _C.orange : _C.textMuted
    )); 
  }

  void _onTypingChanged(String t) { 
    if (t.isNotEmpty && !_isTyping) { 
      _isTyping = true; 
      _sendTypingStatus(true); 
    } else if (t.isEmpty && _isTyping) { 
      _isTyping = false; 
      _sendTypingStatus(false); 
    } 
    _typingTimer?.cancel(); 
    _typingTimer = Timer(const Duration(seconds: 2), () { 
      if (_isTyping) { 
        _isTyping = false; 
        _sendTypingStatus(false); 
      } 
    }); 
  }

  @override 
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black12,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _C.textMain, size: 24),
          onPressed: () => Navigator.pop(context),
          splashRadius: 24,
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: _C.surfaceAlt, 
              child: widget.conversation.isGroup
                ? const Icon(Icons.groups_rounded, color: _C.textMuted, size: 24)
                : ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: widget.conversation.displayAvatar ?? 'https://i.pravatar.cc/150?img=11',
                      width: 40, 
                      height: 40, 
                      fit: BoxFit.cover
                    )
                  )
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  Text(
                    widget.conversation.displayName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _C.textMain),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis
                  ), 
                  if (!widget.conversation.isGroup && _otherParticipant != null) 
                    Row(
                      children: [
                        Container(
                          width: 8, 
                          height: 8, 
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _otherParticipant!.status == 'online' ? _C.green : _C.textMuted.withOpacity(0.5)
                          )
                        ), 
                        const SizedBox(width: 6), 
                        Text(
                          _otherParticipant!.status == 'online' ? 'En ligne' : 'Vu ${_formatLastSeen(_otherParticipant!.lastSeenAt ?? DateTime.now())}',
                          style: const TextStyle(fontSize: 12, color: _C.textMuted, fontWeight: FontWeight.w500)
                        )
                      ]
                    )
                ]
              )
            ),
          ]
        ),
        actions: [
          IconButton(icon: const Icon(Icons.videocam_outlined, color: _C.primary, size: 26), onPressed: () => _startCall(CallType.video), splashRadius: 24),
          IconButton(icon: const Icon(Icons.call_outlined, color: _C.primary, size: 24), onPressed: () => _startCall(CallType.audio), splashRadius: 24),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: _C.textMain, size: 24), 
            color: Colors.white, 
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (v) { 
              if (v == 'escalate') _escalateConversation(); 
              else if (v == 'history') _viewEscalationHistory(); 
              else if (v == 'group') GoRouter.of(context).go('/group/${widget.conversationId}'); 
            }, 
            itemBuilder: (c) => [
              const PopupMenuItem(
                value: 'escalate',
                child: Row(children: [Icon(Icons.arrow_upward, color: _C.orange, size: 20), SizedBox(width: 10), Text('Escalader le cas', style: TextStyle(color: _C.textMain, fontSize: 14))])
              ), 
              const PopupMenuItem(
                value: 'history',
                child: Row(children: [Icon(Icons.history, color: _C.primary, size: 20), SizedBox(width: 10), Text('Historique', style: TextStyle(color: _C.textMain, fontSize: 14))])
              ), 
              if (widget.conversation.isGroup) 
                const PopupMenuItem(
                  value: 'group',
                  child: Row(children: [Icon(Icons.info_outline, color: _C.textMain, size: 20), SizedBox(width: 10), Text('Infos du groupe', style: TextStyle(color: _C.textMain, fontSize: 14))])
                )
            ]
          ),
          const SizedBox(width: 4),
        ]
      ),
      body: SafeArea(
        bottom: false, 
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(color: _C.bg), 
                child: ClipRRect(
                  child: Column(
                    children: [
                      if (widget.conversation.isGroup) 
                        GroupInfoPanel(
                          conversation: widget.conversation,
                          members: _groupMembers,
                          onViewAllMembers: () => GoRouter.of(context).go('/group/${widget.conversationId}'),
                          onEditGroup: () {},
                          onLeaveGroup: () {},
                          onDeleteGroup: () {}
                        ),
                      if (_isConversationEscalated) 
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          color: const Color(0xFFFFF7ED),
                          child: Row(
                            children: const [
                              Icon(Icons.warning_amber_rounded, color: _C.orange, size: 20),
                              SizedBox(width: 12),
                              Expanded(child: Text('Cette conversation a été escaladée.', style: TextStyle(color: _C.orange, fontSize: 14, fontWeight: FontWeight.bold)))
                            ]
                          )
                        ),
                      Expanded(
                        child: _isLoading 
                          ? const Center(child: CircularProgressIndicator(color: _C.primary, strokeWidth: 3))
                          : Stack(
                              children: [
                                ListView.builder(
                                  controller: _scrollController,
                                  reverse: true,
                                  addAutomaticKeepAlives: false,
                                  addRepaintBoundaries: true,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  itemCount: _messages.length + (_isLoadingMore ? 1 : 0),
                                  itemBuilder: (ctx, i) {
                                    if (i == _messages.length && _isLoadingMore) {
                                      return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator(strokeWidth: 3, color: _C.primary)));
                                    }
                                    final msg = _messages[_messages.length - 1 - i];
                                    final isOwn = msg.senderId == _chatService.currentUserId;
                                    
                                    return ChatMessageBubble(
                                      message: msg,
                                      isOwn: isOwn,
                                      onReply: () => setState(() => _replyToId = msg.id),
                                      onDelete: () async { 
                                        setState(() => _messages.removeWhere((m) => m.id == msg.id)); 
                                        if (isOwn) {
                                          try { await _chatService.deleteMessage(msg.id); } catch (_) {}
                                        }
                                      },
                                      onReaction: (r) => _chatService.toggleReaction(msg.id, r),
                                      replyToMessage: msg.replyToId != null ? _messages.where((m) => m.id == msg.replyToId).firstOrNull : null,
                                      isEphemeralActive: msg.isEphemeral,
                                      isInternalNote: msg.isInternalNote,
                                      isAgentView: _isAgent
                                    );
                                  }
                                ), 
                                if (_otherUserTyping) 
                                  Positioned(
                                    bottom: 12,
                                    left: 16,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 10, offset: Offset(0, 4))]
                                      ),
                                      child: const Text("En train d'écrire...", style: TextStyle(fontSize: 12, color: _C.primary, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold))
                                    )
                                  )
                              ]
                            )
                      ),
                      
                      // Barre de réponse active
                      if (_replyToId.isNotEmpty) 
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            border: Border(top: BorderSide(color: _C.border))
                          ),
                          child: Row(
                            children: [
                              Container(width: 4, height: 40, decoration: BoxDecoration(color: _C.primary, borderRadius: BorderRadius.circular(4))),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Répondre à', style: TextStyle(color: _C.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 2),
                                    Text(
                                      _messages.firstWhere((m) => m.id == _replyToId, orElse: () => _messages.first).content,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: _C.textMuted, fontSize: 14)
                                    ),
                                  ]
                                )
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 20, color: _C.textMuted),
                                onPressed: () => setState(() => _replyToId = ''),
                                splashRadius: 20,
                              )
                            ]
                          )
                        ),
                        
                      // Barre d'entrée (Message input)
                      Container(
                        color: Colors.white, 
                        padding: const EdgeInsets.only(top: 8),
                        child: ChatInputBar(
                          controller: _inputController,
                          focusNode: _inputFocus,
                          onSend: _sendMessage,
                          isSending: _isSending,
                          onAttach: _showAttachmentMenu,
                          onAudio: _startAudioRecording,
                          onSecureMessage: _showPasswordProtectDialog,
                          onEphemeralToggle: _showEphemeralTimerDialog,
                          isEphemeral: _isEphemeral,
                          onTyping: _onTypingChanged,
                          onInternalNoteToggle: _isAgent ? _toggleInternalNoteMode : null,
                          isInternalNote: _isInternalNoteMode
                        )
                      ),
                    ]
                  )
                )
              )
            ),
          ]
        )
      ),
    );
  }

  String _formatLastSeen(DateTime d) { 
    final diff = DateTime.now().difference(d); 
    if (diff.inDays == 0) return 'à ${DateFormat('HH:mm').format(d)}'; 
    if (diff.inDays == 1) return 'hier à ${DateFormat('HH:mm').format(d)}'; 
    return 'le ${DateFormat('dd/MM/yyyy').format(d)}'; 
  }
}
