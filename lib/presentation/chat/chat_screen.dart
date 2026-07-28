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

// ── THEME WHITE ENTREPRISE ──
class _C {
  static const bg = Color(0xFFF0F2F5);
  static const surface = Colors.white;
  static const surfaceAlt = Color(0xFFF8FAFC);
  static const border = Color(0xFFE2E8F0);
  static const primary = Color(0xFF0A66C2);
  static const primaryLight = Color(0xFFEFF6FF);
  static const textMain = Color(0xFF0F172A);
  static const textMuted = Color(0xFF64748B);
  static const red = Color(0xFFEF4444);
  static const green = Color(0xFF22C55E);
  static const orange = Color(0xFFF59E0B);
}

// ── Providers Riverpod & CallProvider global ──
final chatServiceProvider = Provider((ref) => ChatService(Supabase.instance.client));
final presenceServiceProvider = Provider((ref) => PresenceService(Supabase.instance.client));
final audioServiceProvider = Provider((ref) => AudioService(Supabase.instance.client));
final groupServiceProvider = Provider((ref) => GroupService(Supabase.instance.client));
final connectionServiceProvider = Provider((ref) => ConnectionService());

// Déclaration explicite du callProvider pour corriger l'erreur de getter introuvable
final callProvider = ChangeNotifierProvider<CallProvider>((ref) => CallProvider());

final chatMessagesProvider = StateNotifierProvider.family<ChatMsgNotifier, List<ChatMessage>, String>((ref, conversationId) {
  return ChatMsgNotifier(ref.read(chatServiceProvider), conversationId);
});

class ChatMsgNotifier extends StateNotifier<List<ChatMessage>> {
  final ChatService svc;
  final String convId;
  int page = 0;
  static const pageSize = 30;
  bool hasMore = true;
  bool loadingMore = false;

  ChatMsgNotifier(this.svc, this.convId) : super([]) {
    loadInitial();
  }

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

  void upsertRealtime(List<ChatMessage> updated) {
    var current = [...state];
    for (var msg in updated) {
      final idx = current.indexWhere((m) => m.id == msg.id);
      if (idx != -1) {
        if (msg.isDeleted) {
          current.removeAt(idx);
        } else {
          current[idx] = msg;
        }
      } else if (!msg.isDeleted) {
        current.add(msg);
      }
    }
    state = current;
  }

  void addLocal(ChatMessage msg) {
    if (!state.any((m) => m.id == msg.id)) {
      state = [...state, msg];
    }
  }

  void removeLocal(String id) {
    state = state.where((m) => m.id != id).toList();
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
  StreamSubscription<List<ChatMessage>>? _messageSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserRole();
    _getParticipantInfo();
    _markAsRead();
    _subscribeToPresence();
    _subscribeToRealtime();
    _subscribeToTyping();
    _loadGroupMembers();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(chatMessagesProvider(widget.conversationId).notifier).loadMore();
    }
  }

  Future<void> _loadUserRole() async {
    final svc = ref.read(chatServiceProvider);
    final user = svc.currentUser;
    if (user != null) {
      setState(() => _isAgent = user.role == 'agent' || user.role == 'admin' || user.role == 'support');
    }
  }

  Future<void> _loadGroupMembers() async {
    if (!widget.conversation.isGroup) return;
    try {
      final members = await ref.read(chatServiceProvider).getGroupMembers(widget.conversationId);
      if (mounted) {
        setState(() {
          _groupMembers = members;
        });
      }
    } catch (e) {
      debugPrint('Error loading group members: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _inputController.dispose();
    _inputFocus.dispose();
    _typingTimer?.cancel();
    _messageSub?.cancel();
    _typingChannel?.unsubscribe();
    ref.read(audioServiceProvider).dispose();
    super.dispose();
  }

  Future<void> _markAsRead() => ref.read(chatServiceProvider).markAsRead(widget.conversationId);

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  void _subscribeToPresence() {
    if (widget.conversation.isGroup) return;
    final svc = ref.read(chatServiceProvider);
    final otherId = widget.conversation.participantIds.firstWhere((id) => id != svc.currentUserId, orElse: () => '');
    if (otherId.isNotEmpty) {
      svc.subscribeToPresence([otherId]).listen((list) { 
        if (mounted && list.isNotEmpty) setState(() => _otherParticipant = list.first); 
      });
    }
  }

  Future<void> _getParticipantInfo() async {
    if (widget.conversation.isGroup) return;
    final svc = ref.read(chatServiceProvider);
    final otherId = widget.conversation.participantIds.firstWhere((id) => id != svc.currentUserId, orElse: () => '');
    if (otherId.isNotEmpty) {
      final p = await svc.getUserPresence(otherId);
      if (mounted) setState(() => _otherParticipant = p);
    }
  }

  void _subscribeToRealtime() {
    _messageSub = ref.read(chatServiceProvider).subscribeToMessages(widget.conversationId).listen((updated) {
      ref.read(chatMessagesProvider(widget.conversationId).notifier).upsertRealtime(updated);
      _scrollToBottom();
      _markAsRead();
    });
  }

  void _subscribeToTyping() {
    final cur = ref.read(chatServiceProvider).currentUserId;
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
    final cur = ref.read(chatServiceProvider).currentUserId;
    if (cur == null || _typingChannel == null) return;
    _typingChannel!.sendBroadcastMessage(event: 'typing', payload: {'senderId': cur, 'isTyping': t});
  }

  void _startCall(CallType type) {
    final svc = ref.read(chatServiceProvider);
    final otherId = widget.conversation.participantIds.firstWhere((id) => id != svc.currentUserId, orElse: () => '');
    
    // Appel sécurisé via Riverpod moderne
    ref.read(callProvider.notifier).start(channel: widget.conversationId, calleeId: otherId, callType: type);
    
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (_) => CallPage(channel: widget.conversationId, name: widget.conversation.displayName, type: type, isCaller: true))
    );
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    final svc = ref.read(chatServiceProvider);
    
    if (!widget.conversation.isGroup && !_isInternalNoteMode) {
      final cur = svc.currentUserId;
      if (cur != null) {
        final otherId = widget.conversation.participantIds.firstWhere((id) => id != cur, orElse: () => '');
        if (otherId.isNotEmpty) {
          final ok = await ref.read(connectionServiceProvider).checkConnection(cur, otherId);
          if (!ok) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vous devez être connecté pour envoyer un message'), backgroundColor: _C.orange));
            }
            return;
          }
        }
      }
    }
    
    _isTyping = false; 
    _sendTypingStatus(false);
    
    try {
      final msg = await svc.sendMessage(
        conversationId: widget.conversationId, 
        content: text, 
        replyToId: _replyToId.isEmpty ? null : _replyToId, 
        isEphemeral: _isEphemeral, 
        ephemeralDuration: _isEphemeral ? _ephemeralDuration : null
      );
      
      ref.read(chatMessagesProvider(widget.conversationId).notifier).addLocal(msg);
      
      if (mounted) {
        setState(() { 
          _inputController.clear(); 
          _replyToId = ''; 
          if (_isInternalNoteMode) _isInternalNoteMode = false; 
        });
      }
      _scrollToBottom();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: _C.red));
    }
  }

  void _showEphemeralTimerDialog() {}
  void _showPasswordProtectDialog() {}
  void _showAttachmentMenu() {}
  Future<void> _pickFile({FileType type = FileType.any}) async {}

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider(widget.conversationId));
    final msgNotifier = ref.watch(chatMessagesProvider(widget.conversationId).notifier);

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black12,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _C.textMain), 
          onPressed: () => context.pop()
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20, 
              backgroundColor: _C.surfaceAlt, 
              child: widget.conversation.isGroup
                ? const Icon(Icons.groups_rounded, color: _C.textMuted) 
                : ClipOval(
                    child: Image.network(
                      widget.conversation.displayAvatar ?? 'https://i.pravatar.cc/150?img=11', 
                      width: 40, 
                      height: 40, 
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: _C.textMuted),
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
                          _otherParticipant!.status == 'online' ? 'En ligne' : 'Vu ${_otherParticipant!.lastSeenAt}', 
                          style: const TextStyle(fontSize: 12, color: _C.textMuted)
                        )
                      ]
                    )
                ]
              )
            ),
          ]
        ),
        actions: [
          IconButton(icon: const Icon(Icons.videocam_outlined, color: _C.primary, size: 26), onPressed: () => _startCall(CallType.video)),
          IconButton(icon: const Icon(Icons.call_outlined, color: _C.primary, size: 24), onPressed: () => _startCall(CallType.audio)),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: _C.textMain), 
            color: Colors.white, 
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
            onSelected: (v) { 
              if (v == 'escalate') {
                context.pushNamed('chatEscalate', pathParameters: {'conversationId': widget.conversationId}, queryParameters: {'agentId': ref.read(chatServiceProvider).currentUserId ?? ''}); 
              } else if (v == 'history') {
                context.pushNamed('chatEscalationHistory', pathParameters: {'conversationId': widget.conversationId}); 
              }
            }, 
            itemBuilder: (c) => const [
              PopupMenuItem(
                value: 'escalate', 
                child: Row(children: [Icon(Icons.arrow_upward, color: _C.orange, size: 20), SizedBox(width: 10), Text('Escalader')])
              ), 
              PopupMenuItem(
                value: 'history', 
                child: Row(children: [Icon(Icons.history, color: _C.primary, size: 20), SizedBox(width: 10), Text('Historique')])
              )
            ]
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                reverse: true,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                itemCount: messages.length + (msgNotifier.loadingMore ? 1 : 0),
                itemBuilder: (ctx, i) {
                  if (i == messages.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16), 
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: _C.primary))
                    );
                  }
                  
                  final msg = messages[messages.length - 1 - i];
                  final isOwn = msg.senderId == ref.read(chatServiceProvider).currentUserId;
                  
                  return ChatMessageBubble(
                    message: msg, 
                    isOwn: isOwn, 
                    onReply: () => setState(() => _replyToId = msg.id), 
                    onDelete: () async { 
                      ref.read(chatMessagesProvider(widget.conversationId).notifier).removeLocal(msg.id); 
                      if (isOwn) { 
                        try { 
                          await ref.read(chatServiceProvider).deleteMessage(msg.id); 
                        } catch (_) {} 
                      } 
                    }, 
                    onReaction: (r) => ref.read(chatServiceProvider).toggleReaction(msg.id, r), 
                    replyToMessage: msg.replyToId != null 
                        ? messages.where((m) => m.id == msg.replyToId).firstOrNull 
                        : null, 
                    isEphemeralActive: msg.isEphemeral, 
                    isInternalNote: msg.isInternalNote, 
                    isAgentView: _isAgent
                  );
                },
              ),
            ),
            
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
                      child: Text(
                        messages.firstWhere((m) => m.id == _replyToId, orElse: () => messages.first).content, 
                        maxLines: 1, 
                        overflow: TextOverflow.ellipsis, 
                        style: const TextStyle(color: _C.textMuted)
                      )
                    ), 
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20, color: _C.textMuted), 
                      onPressed: () => setState(() => _replyToId = '')
                    )
                  ]
                )
              ),
              
            Container(
              color: Colors.white, 
              padding: const EdgeInsets.only(top: 8), 
              child: ChatInputBar(
                controller: _inputController, 
                focusNode: _inputFocus, 
                onSend: _sendMessage, 
                isSending: false, 
                onAttach: _showAttachmentMenu, 
                onAudio: () {}, 
                onSecureMessage: _showPasswordProtectDialog, 
                onEphemeralToggle: _showEphemeralTimerDialog, 
                isEphemeral: _isEphemeral, 
                onTyping: (t) { 
                  if (t.isNotEmpty && !_isTyping) { 
                    _isTyping = true; 
                    _sendTypingStatus(true); 
                  } else if (t.isEmpty && _isTyping) { 
                    _isTyping = false; 
                    _sendTypingStatus(false); 
                  } 
                }, 
                onInternalNoteToggle: _isAgent 
                    ? () => setState(() => _isInternalNoteMode = !_isInternalNoteMode) 
                    : null, 
                isInternalNote: _isInternalNoteMode
              )
            ),
          ]
        ),
      ),
    );
  }
}
