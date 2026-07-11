// lib/presentation/chat/chat_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Utilisation de chemins absolus pour éviter les erreurs
import 'package:thix_id/services/chat/chat_service.dart';
import 'package:thix_id/services/chat/presence_service.dart';
import 'package:thix_id/models/chat/chat_message.dart';
import 'package:thix_id/models/chat/chat_conversation.dart';
import 'package:thix_id/models/chat/user_status.dart';

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

  UserStatus? _otherParticipant; 
  
  String _replyToId = '';
  bool _isEphemeral = false;
  int? _ephemeralDuration;
  bool _isTyping = false;
  Timer? _typingTimer;

  StreamSubscription<List<ChatMessage>>? _messageSubscription;
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
    
    // ✅ NOUVEAU : Écoute en temps réel pour synchroniser les suppressions des deux côtés
    _subscribeToRealtimeMessages();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _inputController.dispose();
    _inputFocus.dispose();
    _typingTimer?.cancel();
    _messageSubscription?.cancel(); // Ne pas oublier de fermer le flux
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

  // ✅ NOUVEAU : Synchronisation en temps réel (Suppression double côté)
  void _subscribeToRealtimeMessages() {
    _messageSubscription = _chatService.subscribeToMessages(widget.conversationId).listen((updatedMsgs) {
      if (!mounted) return;
      setState(() {
        for (var msg in updatedMsgs) {
          final index = _messages.indexWhere((m) => m.id == msg.id);
          if (index != -1) {
            if (msg.isDeleted) {
              // Si le message est marqué supprimé dans Supabase, on le retire de l'écran !
              _messages.removeAt(index); 
            } else {
              _messages[index] = msg;
            }
          } else if (!msg.isDeleted) {
            _messages.insert(0, msg);
          }
        }
      });
    });
  }

  // ---- ENVOI DE MESSAGE ----
  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isSending) return;

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
        // Le message sera aussi ajouté par le Realtime, on vérifie s'il y est déjà pour éviter les doublons
        if (!_messages.any((m) => m.id == msg.id)) {
           _messages.insert(0, msg);
        }
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

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (_isTyping) {
        _isTyping = false;
        _sendTypingStatus(false);
      }
    });
  }

  void _sendTypingStatus(bool typing) {
    // Logique WebSocket à venir
  }

  // ✅ NOUVEAU : Menu pour choisir le temps d'autodestruction
  void _showEphemeralTimerDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "Délai d'autodestruction",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.timer_off_rounded, color: Colors.grey),
                  title: const Text("Désactiver l'autodestruction", style: TextStyle(color: Colors.grey)),
                  onTap: () {
                    setState(() {
                      _isEphemeral = false;
                      _ephemeralDuration = null;
                    });
                    Navigator.pop(ctx);
                  },
                ),
                const Divider(height: 1),
                _buildTimeOption(ctx, 10, "10 secondes"),
                _buildTimeOption(ctx, 30, "30 secondes"),
                _buildTimeOption(ctx, 60, "1 minute"),
                _buildTimeOption(ctx, 300, "5 minutes"),
                _buildTimeOption(ctx, 3600, "1 heure"),
              ],
            ),
          ),
        );
      },
    );
  }

  // Sous-composant pour le menu d'autodestruction
  Widget _buildTimeOption(BuildContext ctx, int seconds, String label) {
    final isSelected = _isEphemeral && _ephemeralDuration == seconds;
    return ListTile(
      leading: Icon(
        Icons.timer_rounded, 
        color: isSelected ? const Color(0xFF1877F2) : Colors.black87
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? const Color(0xFF1877F2) : Colors.black87,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: Color(0xFF1877F2)) : null,
      onTap: () {
        setState(() {
          _isEphemeral = true;
          _ephemeralDuration = seconds;
        });
        Navigator.pop(ctx);
      },
    );
  }

  void _cancelReply() => setState(() => _replyToId = '');

  // ---- GESTION DES MÉDIAS ----
  Future<void> _pickImage() async {
    // Implémentez la sélection d'image
  }

  Future<void> _pickAudio() async {
    // Logique d'enregistrement audio (Remplacement du bouton code)
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enregistrement audio en préparation...')),
    );
  }

  // ---- WIDGETS ----
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5DDD5), // Fond classique messagerie
      appBar: _buildAppBar(),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFE5DDD5), 
        ),
        child: Column(
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
                              return const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                              );
                            }
                            final msg = _messages[index];
                            final isOwn = msg.senderId == _chatService.currentUserId;
                            
                            return ChatMessageBubble(
                              message: msg,
                              isOwn: isOwn,
                              onReply: () => setState(() => _replyToId = msg.id),
                              
                              // ✅ LOGIQUE DE SUPPRESSION PARFAITE (Auto-destruction & Manuelle)
                              onDelete: () async {
                                // 1. On l'efface instantanément de l'écran de l'utilisateur actuel
                                setState(() {
                                  _messages.removeWhere((m) => m.id == msg.id);
                                });
                                // 2. Si on est l'expéditeur, on l'efface dans Supabase.
                                // Le Realtime (_subscribeToRealtimeMessages) va capter ce changement 
                                // et l'effacer instantanément sur le téléphone de l'autre personne !
                                if (isOwn) {
                                  try {
                                    await _chatService.deleteMessage(msg.id);
                                  } catch (e) {
                                    debugPrint('Erreur suppression DB: $e');
                                  }
                                }
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
              onCode: _pickAudio, 
              
              // ✅ NOUVEAU : Appel du Menu pour régler le temps au lieu du simple On/Off
              onEphemeralToggle: _showEphemeralTimerDialog,
              isEphemeral: _isEphemeral,
              onTyping: _onTypingChanged,
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.2),
      titleSpacing: 0,
      title: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: widget.conversation.isGroup 
                ? null 
                : const NetworkImage('https://i.pravatar.cc/150?img=11'),
            child: widget.conversation.isGroup ? const Icon(Icons.group, color: Colors.white) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.conversation.displayName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                              : Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        (_otherParticipant!.status == 'online')
                            ? 'En ligne'
                            : 'Vu ${_formatLastSeen(_otherParticipant!.lastSeenAt ?? DateTime.now())}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
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
          icon: const Icon(Icons.videocam_rounded, color: Color(0xFF1877F2)),
          onPressed: () {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appel vidéo non disponible')));
          },
        ),
        IconButton(
          icon: const Icon(Icons.call_rounded, color: Color(0xFF1877F2)),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appel vocal non disponible')));
          },
        ),
        IconButton(
          icon: const Icon(Icons.more_vert_rounded, color: Colors.black54),
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
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1877F2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reply.senderId == _chatService.currentUserId ? 'Vous' : reply.senderName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1877F2),
                  ),
                ),
                Text(
                  reply.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _cancelReply,
            icon: const Icon(Icons.close_rounded, size: 20, color: Colors.grey),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Positioned(
      bottom: 8,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('En train d\'écrire', style: TextStyle(fontSize: 12, color: Colors.black54, fontStyle: FontStyle.italic)),
            SizedBox(width: 8),
            _TypingDots(),
          ],
        ),
      ),
    );
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final diff = now.difference(lastSeen);
    if (diff.inDays == 0) {
      return 'à ${DateFormat('HH:mm').format(lastSeen)}';
    } else if (diff.inDays == 1) {
      return 'hier à ${DateFormat('HH:mm').format(lastSeen)}';
    } else {
      return 'le ${DateFormat('dd/MM/yyyy').format(lastSeen)}';
    }
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            double offset = (index * 0.2);
            double value = (_controller.value + offset) % 1.0;
            double opacity = value < 0.5 ? value * 2 : 1 - ((value - 0.5) * 2);
            return Opacity(
              opacity: opacity,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: Color(0xFF1877F2),
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
