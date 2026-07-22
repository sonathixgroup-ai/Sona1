import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

// === PROVIDERS (MOTEUR OPTIMISÉ) ===
import 'package:thix_id/providers/chat_provider.dart'; // ✅ AJOUT : Ton Provider optimisé
import 'package:thix_id/providers/chat/sentiment_provider.dart';
import 'package:thix_id/presentation/chat/escalation/providers/escalation_provider.dart';
import 'package:thix_id/presentation/chat/call/providers/call_provider.dart';

// Services (Uniquement pour ce qui n'est pas géré par ChatProvider)
import 'package:thix_id/services/chat/presence_service.dart';
import 'package:thix_id/services/chat/audio_service.dart';
import 'package:thix_id/services/chat/group_service.dart';
import 'package:thix_id/services/chat/connection_service.dart';

// Modèles
import 'package:thix_id/models/chat/chat_message.dart';
import 'package:thix_id/models/chat/chat_conversation.dart';
import 'package:thix_id/models/chat/user_status.dart';
import 'package:thix_id/models/chat/group_info.dart';
import 'package:thix_id/models/chat/sentiment.dart';
import 'package:thix_id/models/chat/call_status.dart';

// Widgets
import 'package:thix_id/presentation/chat/widgets/chat_message_bubble.dart';
import 'package:thix_id/presentation/chat/widgets/chat_input_bar.dart';
import 'package:thix_id/presentation/chat/widgets/audio_recorder.dart';
import 'package:thix_id/presentation/chat/group/group_info_panel.dart';
import 'package:thix_id/presentation/chat/encryption_service.dart';
import 'package:thix_id/presentation/chat/call/call_page.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final ChatConversation conversation;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.conversation,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  // Services locaux (non liés à l'état des messages)
  late PresenceService _presenceService;
  late AudioService _audioService;
  late GroupService _groupService;
  late ConnectionService _connectionService;
  late SentimentProvider _sentimentProvider;

  // Contrôleurs
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocus = FocusNode();

  // État local (UI uniquement)
  bool _isSending = false;
  String _replyToId = '';
  bool _isEphemeral = false;
  int? _ephemeralDuration;

  // Participants
  UserStatus? _otherParticipant;
  List<GroupMember> _groupMembers = [];

  // === TYPING INDICATOR ===
  bool _isTyping = false;
  bool _otherUserTyping = false;
  Timer? _typingTimer;
  RealtimeChannel? _typingChannel;

  // === ESCALADE ET NOTES INTERNES ===
  bool _isAgent = false;
  bool _isInternalNoteMode = false;
  bool _isConversationEscalated = false;

  Stream<UserStatus?>? _presenceStream;

  // === COULEURS ===
  static const Color primaryBlue = Color(0xFF4A8BFF);
  static const Color leftBubbleColor = Color(0xFFE9F0FF);
  static const Color dividerColor = Color(0xFFE2E8F0);
  static const Color navyDeep = Color(0xFF0A1F44);
  static const Color gold = Color(0xFFE3B23C);
  static const Color ivory = Color(0xFFF3F5FA);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color darkText = Color(0xFF10182B);
  static const Color mutedText = Color(0xFF6B7690);
  static const Color success = Color(0xFF1FA971);
  static const Color danger = Color(0xFFD64545);
  static const Color hairline = Color(0xFFE7EAF3);

  static const List<String> _quickReactions = ['🔥', '🙌', '❤️', '😀', '😖', '👍'];

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;
    
    _presenceService = PresenceService(client);
    _audioService = AudioService(client);
    _groupService = GroupService(client);
    _connectionService = ConnectionService();
    _sentimentProvider = SentimentProvider();

    _loadUserRole();
    WidgetsBinding.instance.addObserver(this);
    
    // ✅ Le Provider prend le relais pour charger les données !
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ChatProvider>();
      provider.loadMessages(widget.conversationId);
      provider.markAsRead(widget.conversationId);
    });

    _setupScrollListener();
    _getParticipantInfo();
    _subscribeToPresence();
    _subscribeToTypingChannel();
    _loadGroupMembersIfGroup();
    _checkMicrophonePermission();
  }

  Future<void> _loadUserRole() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final metadata = user.userMetadata ?? {};
      final role = metadata['role'] as String?;
      _isAgent = role == 'agent' || role == 'admin' || role == 'support';
      if (mounted) setState(() {});
    }
  }

  Future<void> _checkMicrophonePermission() async {
    final status = await Permission.microphone.status;
    debugPrint('🎙 Statut permission microphone: $status');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _inputController.dispose();
    _inputFocus.dispose();
    _typingTimer?.cancel();
    _typingChannel?.unsubscribe();
    _audioService.dispose();
    _sentimentProvider.dispose();
    super.dispose();
  }

  // ✅ On écoute le défilement pour demander au Provider de charger la suite
  void _setupScrollListener() {
    _scrollController.addListener(() {
      final position = _scrollController.position;
      if (position.pixels >= position.maxScrollExtent - 200) {
        final provider = context.read<ChatProvider>();
        if (provider.hasMoreMessages && !provider.isLoadingMoreMessages) {
          provider.loadMoreMessages(widget.conversationId);
        }
      }
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // ============================================================
  // PRÉSENCE ET INFOS
  // ============================================================

  void _subscribeToPresence() {
    if (widget.conversation.isGroup) return;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final otherId = widget.conversation.participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
    if (otherId.isNotEmpty) {
      // NOTE: Si subscribeToPresence est toujours dans ChatService, 
      // il faudra l'extraire dans PresenceService ou garder une ref à ChatService
      _presenceStream = _presenceService.subscribeToPresence([otherId]).map(
        (list) => list.isNotEmpty ? list.first : null,
      );
      _presenceStream?.listen((status) {
        if (mounted) setState(() => _otherParticipant = status);
      });
    }
  }

  Future<void> _getParticipantInfo() async {
    if (widget.conversation.isGroup) return;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final otherId = widget.conversation.participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
    if (otherId.isNotEmpty) {
      final participant = await _presenceService.getUserPresence(otherId);
      if (mounted) setState(() => _otherParticipant = participant);
    }
  }

  Future<void> _loadGroupMembersIfGroup() async {
    if (!widget.conversation.isGroup) return;
    try {
      final members = await _groupService.getGroupMembers(widget.conversationId);
      if (mounted) setState(() => _groupMembers = members);
    } catch (e) {
      debugPrint('❌ Erreur chargement membres: $e');
    }
  }

  // ============================================================
  // REALTIME - TYPING INDICATOR
  // ============================================================

  void _subscribeToTypingChannel() {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    _typingChannel = Supabase.instance.client
        .channel('typing:${widget.conversationId}')
        .onBroadcast(
          event: 'typing',
          callback: (payload) {
            final senderId = payload['senderId'] as String?;
            final isTyping = (payload['isTyping'] as bool?) ?? false;

            if (senderId != null && senderId != currentUserId && mounted) {
              setState(() => _otherUserTyping = isTyping);
            }
          },
        )
        .subscribe();
  }

  void _sendTypingStatus(bool typing) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null || _typingChannel == null) return;

    _typingChannel!.sendBroadcastMessage(
      event: 'typing',
      payload: {'senderId': currentUserId, 'isTyping': typing},
    );
  }

  void _onTypingChanged(String text) {
    if (text.isNotEmpty && !_isTyping) {
      _isTyping = true;
      _sendTypingStatus(true);
    } else if (text.isEmpty && _isTyping) {
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

  // ============================================================
  // ENVOI DE MESSAGES (via le Provider)
  // ============================================================

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isSending) return;

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    if (!widget.conversation.isGroup && !_isInternalNoteMode && currentUserId != null) {
      final otherId = widget.conversation.participantIds.firstWhere(
        (id) => id != currentUserId,
        orElse: () => '',
      );
      if (otherId.isNotEmpty) {
        final isConnected = await _connectionService.checkConnection(currentUserId, otherId);
        if (!isConnected) {
          _showSnackBar('Vous devez être connecté avec cet utilisateur', Colors.orange);
          return;
        }
      }
    }

    _isTyping = false;
    _sendTypingStatus(false);
    setState(() => _isSending = true);

    try {
      // ✅ Délégation au Provider
      final msg = await context.read<ChatProvider>().sendMessage(
        widget.conversationId,
        text,
        // Si ton sendMessage dans le provider prend d'autres paramètres, adapte-les ici
        // replyToId: _replyToId.isEmpty ? null : _replyToId,
        // isEphemeral: _isEphemeral,
      );

      setState(() {
        _inputController.clear();
        _replyToId = '';
        _isSending = false;
        if (_isInternalNoteMode) _isInternalNoteMode = false;
      });
      _scrollToBottom();
      
      // Analyse du sentiment après envoi
      _analyzeMessage(msg);
      
    } catch (e) {
      setState(() => _isSending = false);
      _showSnackBar('Erreur: $e', danger);
    }
  }

  Future<void> _sendAudioMessage(String filePath, int duration) async {
    try {
       // ✅ Assure-toi d'avoir implémenté sendAudioMessage dans ton ChatProvider 
       // ou d'appeler ton ChatService puis de mettre à jour le Provider
      _showSnackBar('L\'envoi audio doit être ajouté au Provider', gold);
      _scrollToBottom();
    } catch (e) {
      _showSnackBar('Erreur envoi audio: $e', danger);
    }
  }

  // ============================================================
  // ANALYSE DE SENTIMENT
  // ============================================================

  Future<void> _analyzeMessage(ChatMessage message) async {
    if (message.content.trim().length < 3) return;
    if (message.isInternalNote == true) return;

    try {
      final result = await _sentimentProvider.analyzeMessage(message.content);
      if (result != null && mounted) {
        // Optionnel : Dire au Provider de mettre à jour le sentiment de ce message
        // context.read<ChatProvider>().updateMessageSentimentLocally(message.id, result);
      }
    } catch (e) {
      debugPrint('❌ Erreur analyse sentiment: $e');
    }
  }

  // ============================================================
  // ACTIONS SUR LES MESSAGES
  // ============================================================

  void _showMessageActions(ChatMessage msg, bool isOwn) {
      // Ton code d'UI reste identique
      // ...
      
      // Sauf pour la suppression :
      // onTap: () async {
      //   Navigator.pop(ctx);
      //   if (isOwn) {
      //     await context.read<ChatProvider>().deleteMessage(msg.id);
      //   }
      // }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBlue,
      appBar: _buildAppBar(),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: pureWhite,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                  child: Column(
                    children: [
                      // ... (GroupInfoPanel et EscalationIndicator) ...
                      Expanded(
                        // ✅ Écoute des données via le Consumer du Provider !
                        child: Consumer<ChatProvider>(
                          builder: (context, provider, child) {
                            if (provider.isLoading && provider.messages.isEmpty) {
                              return const Center(child: CircularProgressIndicator(color: primaryBlue));
                            }
                            return _buildMessageList(provider);
                          },
                        ),
                      ),
                      // ... (ReplyIndicator) ...
                      ChatInputBar(
                        controller: _inputController,
                        focusNode: _inputFocus,
                        onSend: _sendMessage,
                        isSending: _isSending,
                        onAttach: () {}, // _showAttachmentMenu,
                        onAudio: () {}, // _startAudioRecording,
                        onSecureMessage: () {}, // _showPasswordProtectDialog,
                        onEphemeralToggle: () {}, // _showEphemeralTimerDialog,
                        isEphemeral: _isEphemeral,
                        onTyping: _onTypingChanged,
                        onInternalNoteToggle: _isAgent ? () => setState(() => _isInternalNoteMode = !_isInternalNoteMode) : null,
                        isInternalNote: _isInternalNoteMode,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Injection du provider pour l'accès aux messages
  Widget _buildMessageList(ChatProvider provider) {
    return Stack(
      children: [
        ListView.builder(
          controller: _scrollController,
          reverse: true, // ✅ Important pour la pagination
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: provider.messages.length + (provider.isLoadingMoreMessages ? 1 : 0),
          itemBuilder: (ctx, index) {
            
            // Le loader en haut de la liste
            if (index == provider.messages.length && provider.isLoadingMoreMessages) {
              return const Padding(
                padding: EdgeInsets.all(8.0),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: primaryBlue)),
              );
            }

            final msg = provider.messages[index];
            final isOwn = msg.senderId == Supabase.instance.client.auth.currentUser?.id;

            return GestureDetector(
              onLongPress: () => _showMessageActions(msg, isOwn),
              child: ChatMessageBubble(
                message: msg,
                isOwn: isOwn,
                onReply: () => setState(() => _replyToId = msg.id),
                onDelete: () async {
                   if (isOwn) await provider.deleteMessage(msg.id);
                },
                onReaction: (r) => {}, // provider.toggleReaction(msg.id, r),
                replyToMessage: msg.replyToId != null
                    ? provider.messages.firstWhere((m) => m.id == msg.replyToId, orElse: () => msg)
                    : null,
                isEphemeralActive: msg.isEphemeral,
                isInternalNote: msg.isInternalNote ?? false,
                isAgentView: _isAgent,
              ),
            );
          },
        ),
        if (_otherUserTyping) const Positioned(bottom: 8, left: 16, child: Text("En train d'écrire..."))
      ],
    );
  }

  // --- RESTE DES WIDGETS (APP BAR, CHIPS, ETC.) ---
  PreferredSizeWidget _buildAppBar() {
      // Ton code d'AppBar reste identique.
      return AppBar(); 
  }
    // ============================================================
  // UTILITAIRES
  // ============================================================

  void _showSnackBar(String message, Color color) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message), 
          backgroundColor: color,
          behavior: SnackBarBehavior.floating, // Optionnel : rend le snackbar plus joli
        ),
      );
    }
  }

}
