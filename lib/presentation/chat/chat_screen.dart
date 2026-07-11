// lib/presentation/chat/chat_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/chat/chat_service.dart';
import '../../services/chat/presence_service.dart';
import '../../models/chat/chat_message.dart';
import '../../models/chat/chat_conversation.dart';
import '../../models/chat/user_status.dart';
import 'widgets/chat_message_bubble.dart';
import 'widgets/chat_input_bar.dart';

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
  late ChatService _chatService;
  late PresenceService _presenceService;
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreMessages = true;
  bool _isSending = false;
  int _page = 0;
  static const int _pageSize = 30;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocus = FocusNode();

  // Utilisation de UserStatus au lieu de ChatParticipant
  UserStatus? _otherParticipant; 
  
  String _replyToId = '';
  bool _isEphemeral = false;
  int? _ephemeralDuration;
  bool _isTyping = false;
  Timer? _typingTimer;

  // Stream de présence
  Stream<UserStatus?>? _presenceStream;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService(Supabase.instance.client);
    _presenceService = PresenceService(Supabase.instance.client);
    WidgetsBinding.instance.addObserver(this);

    _loadMessages();
    _getParticipantInfo();
    _markAsRead();
    _setupScrollListener();
    _subscribeToPresence();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _inputController.dispose();
    _inputFocus.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  // ---- GESTION DE LA PRÉSENCE ----
  void _subscribeToPresence() {
    if (widget.conversation.isGroup) return;
    final otherId = widget.conversation.participantIds.firstWhere(
      (id) => id != _chatService.currentUserId,
      orElse: () => '',
    );
    if (otherId.isNotEmpty) {
      // ✅ CORRECTION : Utilisation de _chatService au lieu de _presenceService
      _presenceStream = _chatService.subscribeToPresence([otherId]).map(
        (list) => list.isNotEmpty ? list.first : null
      );
      _presenceStream?.listen((status) {
        if (mounted) {
          setState(() => _otherParticipant = status);
        }
      });
    }
  }

  Future<void> _getParticipantInfo() async {
    if (widget.conversation.isGroup) return;
    final otherId = widget.conversation.participantIds.firstWhere(
      (id) => id != _chatService.currentUserId,
      orElse: () => '',
    );
    if (otherId.isNotEmpty) {
      // ✅ CORRECTION : Utilisation de _chatService au lieu de _presenceService
      final participant = await _chatService.getUserPresence(otherId);
      if (mounted) setState(() => _otherParticipant = participant);
    }
  }

  // ---- CHARGEMENT DES MESSAGES ----
  Future<void> _loadMessages({bool loadMore = false}) async {
    if (loadMore) {
      if (_isLoadingMore || !_hasMoreMessages) return;
      setState(() => _isLoadingMore = true);
    } else {
      setState(() => _isLoading = true);
      _page = 0;
    }

    try {
      final msgs = await _chatService.getMessages(
        widget.conversationId,
        limit: _pageSize,
        offset: _page * _pageSize,
      );

      setState(() {
        if (loadMore) {
          _messages = [...msgs, ..._messages];
          _hasMoreMessages = msgs.length >= _pageSize;
        } else {
          _messages = msgs;
          _hasMoreMessages = msgs.length >= _pageSize;
        }
        _isLoading = false;
        _isLoadingMore = false;
      });

      if (!loadMore) {
        _scrollToBottom();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        if (_hasMoreMessages && !_isLoadingMore) {
          _page++;
          _loadMessages(loadMore: true);
        }
      }
    });
  }

  Future<void> _markAsRead() async {
    await _chatService.markAsRead(widget.conversationId);
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

  // ---- ENVOI DE MESSAGE ----
  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isSending) return;

    // Stop typing indicator
    _sendTypingStatus(false);

    setState(() => _isSending = true);
    try {
      final msg = await _chatService.sendMessage(
        conversationId: widget.conversationId,
        content: text,
        replyToId: _replyToId.isEmpty ? null : _replyToId,
        isEphemeral: _isEphemeral,
        ephemeralDuration: _isEphemeral ? _ephemeralDuration : null,
      );

      setState(() {
        _messages.add(msg);
        _inputController.clear();
        _replyToId = '';
        _isSending = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ---- INDICATEUR DE SAISIE ----
  void _onTypingChanged(String text) {
    if (text.isNotEmpty && !_isTyping) {
      _isTyping = true;
      _sendTypingStatus(true);
    } else if (text.isEmpty && _isTyping) {
      _isTyping = false;
      _sendTypingStatus(false);
    }

    // Reset timer after 2 seconds of inactivity
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (_isTyping) {
        _isTyping = false;
        _sendTypingStatus(false);
      }
    });
  }

  void _sendTypingStatus(bool typing) {
    // Implémentez ici l'envoi du statut via WebSocket ou autre
  }

  // ---- MESSAGES ÉPHÉMÈRES ----
  void _toggleEphemeral() {
    setState(() {
      _isEphemeral = !_isEphemeral;
      _ephemeralDuration = _isEphemeral ? 60 : null;
    });
  }

  void _cancelReply() => setState(() => _replyToId = '');

  // ---- GESTION DES MÉDIAS ----
  Future<void> _pickImage() async {
    // Implémentez la sélection d'image
  }

  Future<void> _pickAudio() async {
    // Implémentez l'enregistrement audio ou sélection
  }

  // ---- WIDGETS ----
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Stack(
                    children: [
                      ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        itemCount: _messages.length + (_isLoadingMore ? 1 : 0),
                        itemBuilder: (ctx, index) {
                          if (index == _messages.length && _isLoadingMore) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final msg = _messages[_messages.length - 1 - index];
                          final isOwn = msg.senderId == _chatService.currentUserId;
                          return ChatMessageBubble(
                            message: msg,
                            isOwn: isOwn,
                            onReply: () => setState(() => _replyToId = msg.id),
                            onDelete: () async {
                              await _chatService.deleteMessage(msg.id);
                              setState(() => _messages.removeWhere((m) => m.id == msg.id));
                            },
                            onReaction: (r) => _chatService.toggleReaction(msg.id, r),
                            replyToMessage: msg.replyToId != null
                                ? _messages.firstWhere(
                                    (m) => m.id == msg.replyToId,
                                    orElse: () => msg,
                                  )
                                : null,
                            isEphemeralActive: msg.isEphemeral,
                          );
                        },
                      ),
                      // Typing indicator (à afficher en bas)
                      if (_isTyping) _buildTypingIndicator(),
                    ],
                  ),
          ),
          if (_replyToId.isNotEmpty) _buildReplyIndicator(),
          ChatInputBar(
            controller: _inputController,
            focusNode: _inputFocus,
            onSend: _sendMessage,
            isSending: _isSending,
            onAttach: _pickImage,
            onCode: () {
              // Ouvrir un dialogue pour le code
            },
            onEphemeralToggle: _toggleEphemeral,
            isEphemeral: _isEphemeral,
            onTyping: _onTypingChanged,
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.conversation.displayName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (!widget.conversation.isGroup && _otherParticipant != null)
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (_otherParticipant!.status == 'online') 
                        ? Colors.green
                        : Colors.grey,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  (_otherParticipant!.status == 'online')
                      ? 'En ligne'
                      : 'Dernière connexion ${_formatLastSeen(_otherParticipant!.lastSeenAt ?? DateTime.now())}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {
            // Menu options (supprimer, voir participants, etc.)
          },
        ),
      ],
    );
  }

  Widget _buildReplyIndicator() {
    final reply = _messages.firstWhere(
      (m) => m.id == _replyToId,
      orElse: () => _messages.first,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.grey[100],
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Réponse à ${reply.senderId == _chatService.currentUserId ? 'vous-même' : reply.senderName}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
                Text(
                  reply.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _cancelReply,
            icon: const Icon(Icons.close, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Positioned(
      bottom: 10,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: const [
            Text('En train d\'écrire', style: TextStyle(fontSize: 12)),
            SizedBox(width: 6),
            SizedBox(
              width: 40,
              child: Row(
                children: [
                  _Dot(delay: 0),
                  _Dot(delay: 0.3),
                  _Dot(delay: 0.6),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final diff = now.difference(lastSeen);
    if (diff.inDays == 0) {
      return 'aujourd\'hui à ${DateFormat('HH:mm').format(lastSeen)}';
    } else if (diff.inDays == 1) {
      return 'hier à ${DateFormat('HH:mm').format(lastSeen)}';
    } else {
      return 'le ${DateFormat('dd/MM/yyyy').format(lastSeen)}';
    }
  }
}

class _Dot extends StatelessWidget {
  final double delay;
  const _Dot({this.delay = 0});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 600),
      opacity: 1.0,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: Colors.grey,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
