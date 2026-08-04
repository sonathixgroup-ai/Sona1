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
import 'package:thix_id/presentation/chat/providers/chat_list_provider.dart';
import 'package:thix_id/presentation/chat/photo_preview_edit_page.dart';

// ── PALETTE — harmonisée Charte THIX ID ──
class _C {
  static const bg = Color(0xFFF6F7FB); // ivoire de la charte, plus la teinte beige WhatsApp
  static const surface = Colors.white;
  static const surfaceAlt = Color(0xFFF1F5F9);
  static const border = Color(0xFFE2E8F0);
  static const navyDeep = Color(0xFF0A1F44);
  static const primaryDeep = Color(0xFF123B7A);
  static const primary = Color(0xFF2D6CDF);
  static const primaryLight = Color(0xFFEFF6FF);
  static const textMain = Color(0xFF0F172A);
  static const textMuted = Color(0xFF64748B);
  static const red = Color(0xFFEF4444);
  static const green = Color(0xFF22C55E);
  static const orange = Color(0xFFF59E0B);
  static const gold = Color(0xFFE3B23C);
  static const ivory = Color(0xFFF3F5FA);

  static const gradientHeader = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [navyDeep, primaryDeep, primary],
  );
}

final chatServiceProvider = Provider((ref) => ChatService(Supabase.instance.client));
final presenceServiceProvider = Provider((ref) => PresenceService(Supabase.instance.client));
final audioServiceProvider = Provider((ref) => AudioService(Supabase.instance.client));
final groupServiceProvider = Provider((ref) => GroupService(Supabase.instance.client));
final connectionServiceProvider = Provider((ref) => ConnectionService());



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
    msgs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    state = msgs;
  }

  Future<void> loadMore() async {
    if (loadingMore || !hasMore) return;
    loadingMore = true;
    page++;
    final msgs = await svc.getMessages(convId, limit: pageSize, offset: page * pageSize);
    hasMore = msgs.length >= pageSize;

    var current = [...state, ...msgs];
    final seen = <String>{};
    current = current.where((m) => seen.add(m.id)).toList();
    current.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    state = current;
    loadingMore = false;
  }

  void upsertRealtime(List<ChatMessage> updated) {
    var current = [...state];
    bool changed = false;

    for (var msg in updated) {
      final idx = current.indexWhere((m) => m.id == msg.id);
      if (idx != -1) {
        current[idx] = msg;
        changed = true;
      } else if (!msg.isDeleted) {
        current.insert(0, msg);
        changed = true;
      }
    }

    if (changed) {
      current.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = current;
    }
  }

  void addLocal(ChatMessage msg) {
    if (!state.any((m) => m.id == msg.id)) {
      var current = [msg, ...state];
      current.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = current;
    }
  }

  void removeLocal(String id) {
    state = state.where((m) => m.id != id).toList();
  }
}

/// Fichier local en attente d'envoi, avec les bytes potentiellement modifiés
/// (rotation) via l'écran de preview/édition — distinct du PlatformFile brut
/// pour ne pas perdre la sélection d'origine si l'édition est annulée.
class _PendingAttachment {
  final PlatformFile original;
  Uint8List? editedBytes;
  int rotationQuarterTurns;

  _PendingAttachment(this.original) : rotationQuarterTurns = 0;

  Uint8List get bytesToSend => editedBytes ?? original.bytes ?? Uint8List(0);
  String get extension => original.extension ?? 'jpg';
  String get name => original.name;
  int get size => editedBytes?.length ?? original.size;

  bool get isImage {
    const img = {'jpg', 'jpeg', 'png', 'webp', 'gif'};
    return img.contains(extension.toLowerCase());
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
  bool _isSending = false;

  final List<_PendingAttachment> _pendingAttachments = [];

  Timer? _typingTimer;
  RealtimeChannel? _typingChannel;
  bool _isAgent = false;
  bool _isInternalNoteMode = false;
  StreamSubscription<List<ChatMessage>>? _messageSub;

  static const List<String> _stickers = [
    '😀','😃','😄','😁','😆','😅','😂','🤣','🥲','🥹','😊','😇','🙂','🙃','😉','😌','😍','🥰','😘','😗','😙','😚','🤩','🥳','🤗','🤔','🤭','🤫','🤥','😏','😒','🙄','😬','😮‍💨','😔','😪','🤤','😴','😷','🤒','🤕','🤢','🤮','🥵','🥶','😵','🤯','🥴','😵‍💫','🤠','🥸',
    '❤️','🧡','💛','💚','💙','💜','🖤','🤍','🤎','💔','❣️','💕','💞','💓','💗','💖','💝','💘','💌','💋','💟','❤️‍🔥','❤️‍🩹','💯','🔥','⭐','🌟','💫','✨','💥','💫','🎉','🎊','🎈','🎁','🏆','🥇','🥈','🥉','🏅',
    '👍','👎','👌','🤌','🤏','✌️','🤞','🫰','🤟','🤘','🤙','👈','👉','👆','👇','☝️','✋','🤚','🖐️','🖖','👋','✍️','🙏','💪','🦾','👂','👀','👁️','👅','👄','🧠','🫀',
    '🐶','🐱','🐭','🐹','🐰','🦊','🐻','🐼','koala','🐯','🦁','🐮','🐷','🐽','🐸','🐵','🙈','🙉','🙊','🐒','🐔','🐧','🐦','🐤','🐣','🐥','🦆','🦅','🦉','🦇','🐺','🐗','🐴','🦄','🐝','🐛','🦋','🐌','🐞','🐜','🦟','🦗','🕷️','🦂','🐢','🐍','lizard','🦖','🦕','🐙','🦑','shrimp','🦞','🦀','🐡','🐠','🐟','dolphin','🐳','🐋','shark','🐊','🐅','🐆','zebra','gorilla','orangutan','elephant','hippo','rhino','camel','🐫','giraffe','kangaroo','buffalo','ox','cow','horse','pig','ram','sheep','llama','goat','deer','dog','poodle','cat','rooster','turkey','peacock','parrot','swan','flamingo','dove','rabbit','raccoon','skunk','badger','otter','sloth','mouse','rat','squirrel','hedgehog',
    '🍏','🍎','🍐','🍊','🍋','🍌','🍉','🍇','🍓','🫐','🍈','🍒','🍑','🥭','🍍','🥥','🥝','🍅','eggplant','🥑','broccoli','🥬','cucumber','🌶️','🫑','corn','carrot','olive','garlic','onion','potato','🍠','croissant','bagel','bread','🥖','pretzel','cheese','egg','🍳','butter','pancakes','waffle','bacon','🥩','poultry','meat','hotdog','hamburger','fries','pizza','flatbread','sandwich','🥙','taco','burrito','salad','🥘','🍝','ramen','stew','curry','sushi','bento','dumpling','oyster','🍤','onigiri','rice','cracker','🍥','fortune','mooncake','oden','dango','shaved','ice cream','🍦','pie','cupcake','cake','birthday','pudding','lollipop','candy','chocolate','popcorn','doughnut','cookie','chestnut','peanut','honey','milk','coffee','tea','juice','soda','beer','beers','champagne','wine','whiskey','cocktail','tropical','🍾',
    '🏁','🚩','🎌','🏴','🏳️','🏳️‍🌈','🏳️‍⚧️','🏴‍☠️','🇦🇫','🇿🇦','🇦🇱','🇩🇿','🇩🇪','🇦🇩','🇦🇴','🇦🇮','🇦🇶','🇦🇬','🇸🇦','🇦🇷','🇦🇲','🇦🇼','🇦🇺','🇦🇹','🇦🇿','🇧🇸','🇧🇭','🇧🇩','🇧🇧','🇧🇪','🇧🇿','🇧🇯','🇧🇲','bhutan','🇧🇾','🇲🇲','🇧🇴','🇧🇦','🇧🇼','🇧🇷','🇧🇳','🇧🇬','🇧🇫','🇧🇮','🇰🇭','🇨🇲','🇨🇦','🇨🇻','🇨🇱','🇨🇳','🇨🇾','🇨🇴','🇰🇲','🇨🇬','🇨🇩','🇰🇵','🇰🇷','🇨🇷','🇨🇮','🇭🇷','🇨🇺','🇩🇰','🇩🇯','🇩🇲','🇪🇬','🇸🇻','🇦🇪','🇪🇨','🇪🇷','🇪🇸','🇪🇪','🇺🇸','🇪🇹','🇫🇯','🇫🇮','🇫🇷','🇬🇦','🇬🇲','🇬🇪','🇬🇭','🇬🇮','🇬🇷','🇬🇩','🇬🇱','🇬🇹','🇬🇳','🇬🇶','🇬🇼','🇬🇾','🇭🇹','🇭🇳','🇭🇰','🇭🇺','🇮🇳','🇮🇩','🇮🇷','🇮🇶','🇮🇪','🇮🇸','🇮🇱','🇮🇹','🇯🇲','🇯🇵','🇯🇴','🇰🇿','🇰🇪','🇰🇬','🇰🇮','🇽🇰','🇰🇼','🇱🇦','🇱🇸','🇱🇻','🇱🇧','🇱🇷','🇱🇾','🇱🇮','🇱🇹','🇱🇺','🇲🇴','🇲🇰','🇲🇬','🇲🇾','🇲🇼','🇲🇻','🇲🇱','🇲🇹','🇲🇦','🇲🇺','🇲🇷','🇲🇽','🇫🇲','🇲🇩','🇲🇨','🇲🇳','🇲🇪','🇲🇿','🇳🇦','🇳🇷','🇳🇵','🇳🇮','🇳🇪','🇳🇬','🇳🇺','🇳🇴','🇳🇿','🇴🇲','🇺🇬','🇺🇿','🇵🇰','🇵🇼','🇵🇸','🇵🇦','🇵🇬','🇵🇾','🇳🇱','🇵🇪','🇵🇭','🇵🇱','🇵🇷','🇵🇹','🇶🇦','🇨🇫','🇩🇴','🇷🇴','🇬🇧','🇷🇺','🇷🇼','🇸🇳','🇷🇸','🇸🇨','🇸🇱','🇸🇬','🇸🇰','🇸🇮','🇸🇴','🇸🇩','🇸🇸','🇱🇰','🇸🇪','🇨🇭','🇸🇷','🇸🇾','🇹🇯','🇹🇼','🇹🇿','🇹🇩','🇨🇿','🇹🇭','🇹🇱','🇹🇬','🇹🇴','🇹🇹','🇹🇳','🇹🇲','🇹🇷','🇹🇻','🇺🇦','🇺🇾','🇻🇺','🇻🇦','🇻🇪','🇻🇳','🇾🇪','🇿🇲','🇿🇼'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    ref.read(chatServiceProvider).startPresenceHeartbeat();

    _loadUserRole();
    _getParticipantInfo();
    _markAsRead();
    _subscribeToPresence();
    _subscribeToRealtime();
    _subscribeToTyping();
    _loadGroupMembers();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final svc = ref.read(chatServiceProvider);
    switch (state) {
      case AppLifecycleState.resumed:
        svc.startPresenceHeartbeat();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        svc.stopPresenceHeartbeat();
        break;
    }
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
      if (mounted) setState(() => _groupMembers = members);
    } catch (e) {
      debugPrint('Error loading group members: $e');
    }
  }

  @override
  void dispose() {
    ref.read(chatServiceProvider).stopPresenceHeartbeat();
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

  Future<void> _markAsRead() async {
    await ref.read(chatServiceProvider).markAsRead(widget.conversationId);
    try {
      ref.read(chatListProvider.notifier).refresh();
    } catch (_) {}
  }

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
      _markAsRead();
    });
  }

  void _subscribeToTyping() {
    final cur = ref.read(chatServiceProvider).currentUserId;
    if (cur.isEmpty) return;

    _typingChannel = Supabase.instance.client
        .channel('typing:${widget.conversationId}')
        .onBroadcast(
          event: 'typing',
          callback: (payload) {
            final sid = payload['senderId'] as String?;
            final typing = payload['isTyping'] as bool? ?? false;
            if (sid != null && sid != cur && mounted) {
              setState(() => _otherUserTyping = typing);
            }
          },
        )
        .subscribe((status, [error]) {
          if (status == RealtimeSubscribeStatus.subscribed) {
            debugPrint('✅ Typing channel subscribed: ${widget.conversationId}');
          } else if (error != null) {
            debugPrint('❌ Typing channel error: $error');
          }
        });
  }

  void _sendTypingStatus(bool t) {
    final cur = ref.read(chatServiceProvider).currentUserId;
    if (cur.isEmpty || _typingChannel == null) return;

    _typingChannel!.sendBroadcastMessage(
      event: 'typing',
      payload: {'senderId': cur, 'isTyping': t},
    );
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

  Future<void> _startCall(CallType type) async {
    final svc = ref.read(chatServiceProvider);
    final currentUserId = svc.currentUserId;

    debugPrint('📞 _startCall type=$type');
    debugPrint('📞 currentUserId=$currentUserId');
    debugPrint('📞 participants=${widget.conversation.participantIds}');
    debugPrint('📞 conversationId=${widget.conversationId}');

    if (currentUserId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Non authentifié')),
      );
      return;
    }

    final otherId = widget.conversation.participantIds
        .firstWhere((id) => id != currentUserId, orElse: () => '');

    debugPrint('📞 otherId=$otherId');

    if (otherId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Destinataire introuvable')),
      );
      return;
    }

    try {
      await ref.read(callProvider.notifier).start(
            channel: widget.conversationId,
            calleeId: otherId,
            callType: type,
          );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CallPage(
            channel: widget.conversationId,
            name: widget.conversation.displayName,
            type: type,
            isCaller: true,
          ),
        ),
      );
    } catch (e, st) {
      debugPrint('❌ _startCall error: $e');
      debugPrint('$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur appel: $e')),
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty && _pendingAttachments.isEmpty) return;
    if (_isSending) return;

    final svc = ref.read(chatServiceProvider);

    if (!widget.conversation.isGroup && !_isInternalNoteMode) {
      final cur = svc.currentUserId;
      if (cur.isNotEmpty) {
        final otherId = widget.conversation.participantIds.firstWhere((id) => id != cur, orElse: () => '');
        if (otherId.isNotEmpty) {
          final ok = await ref.read(connectionServiceProvider).checkConnection(cur, otherId);
          if (!ok) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Vous devez être connecté pour interagir'), backgroundColor: _C.orange),
              );
            }
            return;
          }
        }
      }
    }

    _isTyping = false;
    _sendTypingStatus(false);
    setState(() => _isSending = true);

    try {
      bool textSentAsCaption = false;

      if (_pendingAttachments.isNotEmpty) {
        final filesToSend = List<_PendingAttachment>.from(_pendingAttachments);
        setState(() => _pendingAttachments.clear());

        for (int i = 0; i < filesToSend.length; i++) {
          final f = filesToSend[i];
          final bytes = f.bytesToSend;
          if (bytes.isEmpty) continue;

          final url = await svc.uploadFileWithUniqueName(
            'chat-media',
            'messages/${widget.conversationId}',
            bytes,
            f.extension,
          );

          if (url != null) {
            final isLastFile = i == filesToSend.length - 1;
            String messageContent = '';

            if (isLastFile && text.isNotEmpty) {
              messageContent = text;
              textSentAsCaption = true;
            }

            final msg = await svc.sendMessage(
              conversationId: widget.conversationId,
              content: messageContent,
              mediaUrl: url,
              mediaType: _getMediaType(f.extension),
              mediaName: f.name,
              mediaSize: f.size,
              isEphemeral: _isEphemeral,
              ephemeralDuration: _ephemeralDuration,
              replyToId: _replyToId.isEmpty ? null : _replyToId,
            );
            ref.read(chatMessagesProvider(widget.conversationId).notifier).addLocal(msg);
          }
        }
      }

      if (text.isNotEmpty && !textSentAsCaption) {
        final msg = await svc.sendMessage(
          conversationId: widget.conversationId,
          content: text,
          replyToId: _replyToId.isEmpty ? null : _replyToId,
          isEphemeral: _isEphemeral,
          ephemeralDuration: _isEphemeral ? _ephemeralDuration : null,
        );
        ref.read(chatMessagesProvider(widget.conversationId).notifier).addLocal(msg);
      }

      if (mounted) {
        setState(() {
          _inputController.clear();
          _replyToId = '';
          _isSending = false;
          if (_isInternalNoteMode) _isInternalNoteMode = false;
        });
      }
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: _C.red),
        );
      }
    }
  }

  void _showStickerPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (_, sc) => Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: _C.border, borderRadius: BorderRadius.circular(4))),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Stickers & Drapeaux', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
            Expanded(
              child: GridView.builder(
                controller: sc,
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemCount: _stickers.length,
                itemBuilder: (_, i) => InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    _inputController.text += _stickers[i];
                  },
                  child: Center(
                    child: Text(_stickers[i], style: const TextStyle(fontSize: 26)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEphemeralTimerDialog() {
    final customCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: _C.border, borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 16),
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(color: _C.primary, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.timer_rounded, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 10),
                const Text("Messages éphémères", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ]),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.timer_off_rounded, color: !_isEphemeral ? _C.primary : _C.textMuted),
                title: Text(
                  "Désactiver - Envoyer sans éphémère",
                  style: TextStyle(
                    fontWeight: !_isEphemeral ? FontWeight.w800 : FontWeight.w500,
                    color: !_isEphemeral ? _C.primary : _C.textMain,
                  ),
                ),
                trailing: !_isEphemeral ? const Icon(Icons.check_circle_rounded, color: _C.primary) : null,
                onTap: () {
                  setState(() {
                    _isEphemeral = false;
                    _ephemeralDuration = null;
                  });
                  Navigator.pop(ctx);
                },
              ),
              const Divider(),
              ...[[10, '10 secondes'], [30, '30 secondes'], [60, '1 minute'], [300, '5 minutes'], [3600, '1 heure'], [86400, '24 heures']].map((e) {
                final sec = e[0] as int;
                final label = e[1] as String;
                final sel = _isEphemeral && _ephemeralDuration == sec;
                return ListTile(
                  leading: Icon(Icons.timer_rounded, color: sel ? _C.primary : _C.textMain),
                  title: Text(label, style: TextStyle(fontWeight: sel ? FontWeight.w800 : FontWeight.w500, color: sel ? _C.primary : _C.textMain)),
                  trailing: sel ? const Icon(Icons.check_circle_rounded, color: _C.primary) : null,
                  onTap: () {
                    setState(() {
                      _isEphemeral = true;
                      _ephemeralDuration = sec;
                    });
                    Navigator.pop(ctx);
                  },
                );
              }),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: customCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        hintText: 'Temps perso en sec (ex: 120)',
                        filled: true,
                        fillColor: _C.ivory,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: _C.primary),
                    onPressed: () {
                      final v = int.tryParse(customCtrl.text);
                      if (v != null && v > 0) {
                        setState(() {
                          _isEphemeral = true;
                          _ephemeralDuration = v;
                        });
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text('OK', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPasswordProtectDialog() {
    final msgCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.lock_rounded, color: _C.primary),
          SizedBox(width: 8),
          Text('Message Protégé', style: TextStyle(fontWeight: FontWeight.bold)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: msgCtrl,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Message secret...',
                filled: true,
                fillColor: _C.ivory,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Mot de passe',
                prefixIcon: const Icon(Icons.key_rounded, color: _C.primary),
                filled: true,
                fillColor: _C.ivory,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _C.primary),
            onPressed: () async {
              if (msgCtrl.text.isNotEmpty && passCtrl.text.isNotEmpty) {
                final enc = EncryptionService.encryptMessage(msgCtrl.text, passCtrl.text);
                Navigator.pop(ctx);
                try {
                  final msg = await ref.read(chatServiceProvider).sendMessage(
                    conversationId: widget.conversationId,
                    content: enc,
                    replyToId: _replyToId.isEmpty ? null : _replyToId,
                    isEphemeral: _isEphemeral,
                    ephemeralDuration: _ephemeralDuration,
                  );
                  ref.read(chatMessagesProvider(widget.conversationId).notifier).addLocal(msg);
                  if (mounted) setState(() => _replyToId = '');
                  _scrollToBottom();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur: $e'), backgroundColor: _C.red),
                    );
                  }
                }
              }
            },
            child: const Text('Envoyer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
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
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          padding: const EdgeInsets.all(20),
          child: AudioRecorderWidget(
            audioService: ref.read(audioServiceProvider),
            onRecordingComplete: (p, d) {
              Navigator.pop(ctx);
              _sendAudio(p, d);
            },
            onRecordingCanceled: () => Navigator.pop(ctx),
            maxDuration: 120,
          ),
        ),
      );
    } else if (st.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  Future<void> _sendAudio(String path, int dur) async {
    try {
      final bytes = await File(path).readAsBytes();
      final msg = await ref.read(chatServiceProvider).sendAudioMessage(
        conversationId: widget.conversationId,
        audioData: Uint8List.fromList(bytes),
        duration: dur,
        isEphemeral: _isEphemeral,
        ephemeralDuration: _ephemeralDuration,
        replyToId: _replyToId.isEmpty ? null : _replyToId,
      );
      ref.read(chatMessagesProvider(widget.conversationId).notifier).addLocal(msg);
      if (mounted) setState(() => _replyToId = '');
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur audio: $e'), backgroundColor: _C.red),
        );
      }
    }
  }

  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _C.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: _C.border, borderRadius: BorderRadius.circular(4))),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Row(children: [
                Icon(Icons.attach_file_rounded, color: _C.primary),
                SizedBox(width: 10),
                Text('Envoyer (Multiples autorisés)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ]),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: _C.gold.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.image_rounded, color: _C.gold),
              ),
              title: const Text('Photo(s)'),
              onTap: () {
                Navigator.pop(ctx);
                _pickFile(type: FileType.image);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: _C.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.videocam_rounded, color: _C.primary),
              ),
              title: const Text('Vidéo(s)'),
              onTap: () {
                Navigator.pop(ctx);
                _pickFile(type: FileType.video);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: _C.textMain.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.insert_drive_file_rounded, color: _C.textMain),
              ),
              title: const Text('Document(s)'),
              onTap: () {
                Navigator.pop(ctx);
                _pickFile(type: FileType.any);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile({FileType type = FileType.any}) async {
    try {
      final result = await FilePicker.platform.pickFiles(allowMultiple: true, type: type, withData: true);
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _pendingAttachments.addAll(result.files.map((f) => _PendingAttachment(f)));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de sélection : $e'), backgroundColor: _C.red),
        );
      }
    }
  }

  void _removeAttachment(int index) {
    setState(() => _pendingAttachments.removeAt(index));
  }

  /// Ouvre l'aperçu plein écran d'une photo sélectionnée, avec rotation et
  /// suppression. Le crop n'est pas inclus — nécessiterait le package
  /// image_cropper (permissions natives supplémentaires).
  Future<void> _openPhotoPreview(int startIndex) async {
    final images = _pendingAttachments.where((a) => a.isImage).toList();
    if (images.isEmpty) return;
    final adjustedStart = images.indexOf(_pendingAttachments[startIndex]).clamp(0, images.length - 1);

    final result = await Navigator.push<List<_PendingAttachment>>(
      context,
      MaterialPageRoute(
        builder: (_) => PhotoPreviewEditPage(
          attachments: images,
          initialIndex: adjustedStart,
        ),
        fullscreenDialog: true,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        // Remplace uniquement les images éditées, conserve le reste (vidéos, docs) intact.
        for (final edited in result) {
          final idx = _pendingAttachments.indexWhere((a) => a.original.identifier == edited.original.identifier);
          if (idx != -1) _pendingAttachments[idx] = edited;
        }
        _pendingAttachments.removeWhere((a) =>
            a.isImage && !result.any((r) => r.original.identifier == a.original.identifier));
      });
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
    context.pushNamed(
      'chatEscalate',
      pathParameters: {'conversationId': widget.conversationId},
      queryParameters: {
        'agentId': ref.read(chatServiceProvider).currentUserId,
        'agentName': 'Agent',
      },
    );
  }

  void _viewEscalationHistory() {
    context.pushNamed('chatEscalationHistory', pathParameters: {'conversationId': widget.conversationId});
  }

  void _toggleInternalNoteMode() {
    setState(() => _isInternalNoteMode = !_isInternalNoteMode);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isInternalNoteMode ? 'Mode note interne ON' : 'Mode note interne OFF'),
        backgroundColor: _isInternalNoteMode ? _C.orange : _C.textMuted,
      ),
    );
  }

  String _getPresenceText(UserStatus status) {
    final lastSeen = status.lastSeenAt ?? DateTime.now();
    final diff = DateTime.now().difference(lastSeen);

    if (status.status == 'online' && diff.inMinutes <= 2) {
      return 'En ligne';
    }
    return 'Vu ${_formatLastSeen(lastSeen)}';
  }

  String _formatLastSeen(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(d.year, d.month, d.day);
    final diffInDays = today.difference(date).inDays;
    final timeStr = DateFormat('HH:mm').format(d);

    if (diffInDays == 0) return "aujourd'hui à $timeStr";
    if (diffInDays == 1) return "hier à $timeStr";
    if (diffInDays < 7) return "${DateFormat('EEEE', 'fr_FR').format(d)} à $timeStr";
    return "le ${DateFormat('dd/MM/yyyy').format(d)} à $timeStr";
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider(widget.conversationId));
    final msgNotifier = ref.watch(chatMessagesProvider(widget.conversationId).notifier);

    return Scaffold(
      backgroundColor: _C.bg,
      extendBodyBehindAppBar: false,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: const BoxDecoration(gradient: _C.gradientHeader),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            titleSpacing: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () {
                _markAsRead();
                context.pop();
              },
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.2)),
                  child: CircleAvatar(
                    radius: 19,
                    backgroundColor: Colors.white24,
                    child: widget.conversation.isGroup
                        ? const Icon(Icons.groups_rounded, color: Colors.white)
                        : ClipOval(
                            child: Image.network(
                              widget.conversation.displayAvatar ?? 'https://i.pravatar.cc/150?img=11',
                              width: 38,
                              height: 38,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Colors.white),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.conversation.displayName,
                        style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_otherUserTyping)
                        const Text("en train d'écrire...", style: TextStyle(fontSize: 12, color: Colors.white70, fontStyle: FontStyle.italic))
                      else if (!widget.conversation.isGroup && _otherParticipant != null)
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: (_otherParticipant!.status == 'online' &&
                                        DateTime.now().difference(_otherParticipant!.lastSeenAt ?? DateTime.now()).inMinutes <= 2)
                                    ? _C.green
                                    : Colors.white38,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _getPresenceText(_otherParticipant!),
                                style: const TextStyle(fontSize: 12, color: Colors.white70),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.videocam_outlined, color: Colors.white, size: 24),
                onPressed: () => _startCall(CallType.video),
              ),
              IconButton(
                icon: const Icon(Icons.call_outlined, color: Colors.white, size: 22),
                onPressed: () => _startCall(CallType.audio),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (v) {
                  if (v == 'escalate') _escalateConversation();
                  else if (v == 'history') _viewEscalationHistory();
                  else if (v == 'group') GoRouter.of(context).go('/chat/group/${widget.conversationId}/info');
                },
                itemBuilder: (c) => [
                  const PopupMenuItem(
                    value: 'escalate',
                    child: Row(children: [
                      Icon(Icons.arrow_upward, color: _C.orange, size: 20),
                      SizedBox(width: 10),
                      Text('Escalader'),
                    ]),
                  ),
                  const PopupMenuItem(
                    value: 'history',
                    child: Row(children: [
                      Icon(Icons.history, color: _C.primary, size: 20),
                      SizedBox(width: 10),
                      Text('Historique'),
                    ]),
                  ),
                  if (widget.conversation.isGroup)
                    const PopupMenuItem(
                      value: 'group',
                      child: Row(children: [
                        Icon(Icons.info_outline, color: _C.textMuted, size: 20),
                        SizedBox(width: 10),
                        Text('Infos groupe'),
                      ]),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Fond propre : ivoire uni + très léger effet de profondeur en
            // haut de l'écran (pas de motif chargé, pas de beige WhatsApp).
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_C.primaryLight.withValues(alpha: 0.35), _C.bg],
                    stops: const [0.0, 0.18],
                  ),
                ),
              ),
            ),
            Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        itemCount: messages.length + (msgNotifier.loadingMore ? 1 : 0),
                        itemBuilder: (ctx, i) {
                          if (i == messages.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: _C.primary)),
                            );
                          }

                          final msg = messages[i];
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
                            isAgentView: _isAgent,
                          );
                        },
                      ),
                      if (_otherUserTyping)
                        const Positioned(
                          bottom: 8,
                          left: 16,
                          child: _TypingBubble(),
                        ),
                    ],
                  ),
                ),

                if (_replyToId.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: _C.border)),
                    ),
                    child: Row(
                      children: [
                        Container(width: 4, height: 40, decoration: BoxDecoration(gradient: _C.gradientHeader, borderRadius: BorderRadius.circular(4))),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            messages.firstWhere((m) => m.id == _replyToId, orElse: () => messages.first).content,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: _C.textMuted),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20, color: _C.textMuted),
                          onPressed: () => setState(() => _replyToId = ''),
                        ),
                      ],
                    ),
                  ),

                if (_pendingAttachments.isNotEmpty) _buildAttachmentsPanel(),

                ChatInputBar(
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
                  onStickerTap: _showStickerPicker,
                  isInternalNote: _isInternalNoteMode,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Panneau des pièces jointes en attente : grille compacte type
  /// "photos groupées" — jusqu'à 4 vignettes visibles, la 4ᵉ affiche "+N"
  /// si plus de fichiers sont sélectionnés. Tap sur une image → preview/édition.
  Widget _buildAttachmentsPanel() {
    const maxVisible = 4;
    final total = _pendingAttachments.length;
    final visibleCount = total > maxVisible ? maxVisible : total;
    final remaining = total - maxVisible;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _C.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attach_file_rounded, size: 15, color: _C.primary),
              const SizedBox(width: 6),
              Text('$total fichier${total > 1 ? 's' : ''} sélectionné${total > 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _C.textMuted)),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 76,
            child: Row(
              children: List.generate(visibleCount, (i) {
                final att = _pendingAttachments[i];
                final isLastVisible = i == visibleCount - 1;
                final showOverlay = isLastVisible && remaining > 0;

                return Padding(
                  padding: EdgeInsets.only(right: i == visibleCount - 1 ? 0 : 8),
                  child: GestureDetector(
                    onTap: () {
                      if (att.isImage) {
                        _openPhotoPreview(i);
                      }
                    },
                    child: Stack(
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: _C.surfaceAlt,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _C.border),
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: att.isImage && att.bytesToSend.isNotEmpty
                              ? Image.memory(att.bytesToSend, fit: BoxFit.cover)
                              : Center(child: Icon(Icons.insert_drive_file_rounded, color: _C.primary, size: 26)),
                        ),
                        if (showOverlay)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                              alignment: Alignment.center,
                              child: Text('+$remaining', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                            ),
                          ),
                        Positioned(
                          top: -4, right: -4,
                          child: GestureDetector(
                            onTap: () => _removeAttachment(i),
                            child: const CircleAvatar(
                              radius: 11,
                              backgroundColor: Colors.black87,
                              child: Icon(Icons.close, size: 13, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

/// Indicateur "en train d'écrire" — trois points animés dans une bulle,
/// remplace le texte statique par un pattern visuel reconnu (comme les
/// messageries entreprise/grand public).
class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.border),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final t = (_controller.value - (i * 0.2)) % 1.0;
              final scale = t < 0.5 ? 0.6 + (t * 1.6) : 1.4 - ((t - 0.5) * 1.6);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Transform.scale(
                  scale: scale.clamp(0.6, 1.0),
                  child: Container(width: 7, height: 7, decoration: const BoxDecoration(shape: BoxShape.circle, color: _C.primary)),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
