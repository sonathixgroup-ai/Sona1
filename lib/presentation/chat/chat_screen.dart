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

  // ============================================================
  // CHARTE THIX ID — Design Institutionnel Premium (Navy / Bleu / Or)
  // ============================================================
  static const Color navyDeep = Color(0xFF0A1F44);
  static const Color navy = Color(0xFF123B7A);
  static const Color primaryBlue = Color(0xFF2D6CDF);
  static const Color gold = Color(0xFFE3B23C);
  static const Color ivory = Color(0xFFF3F5FA);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color darkText = Color(0xFF10182B);
  static const Color mutedText = Color(0xFF6B7690);
  static const Color success = Color(0xFF1FA971);
  static const Color danger = Color(0xFFD64545);
  static const Color hairline = Color(0xFFE7EAF3);

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

    // Écoute en temps réel pour synchroniser les suppressions des deux côtés
    _subscribeToRealtimeMessages();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _inputController.dispose();
    _inputFocus.dispose();
    _typingTimer?.cancel();
    _messageSubscription?.cancel();
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

  // Synchronisation en temps réel (Suppression double côté)
  void _subscribeToRealtimeMessages() {
    _messageSubscription = _chatService.subscribeToMessages(widget.conversationId).listen((updatedMsgs) {
      if (!mounted) return;
      setState(() {
        for (var msg in updatedMsgs) {
          final index = _messages.indexWhere((m) => m.id == msg.id);
          if (index != -1) {
            if (msg.isDeleted) {
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
        SnackBar(content: Text('Erreur: $e'), backgroundColor: danger),
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

  // ---- DIALOGUE DE PROTECTION PAR MOT DE PASSE (AJOUTÉ) ----
  void _showPasswordProtectDialog() {
    final TextEditingController msgController = TextEditingController();
    final TextEditingController passController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.lock_rounded, color: gold),
            SizedBox(width: 8),
            Text("Message chiffré", style: TextStyle(color: navyDeep, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: msgController,
              decoration: const InputDecoration(
                labelText: "Votre message",
                labelStyle: TextStyle(color: mutedText),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: navy),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: passController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Mot de passe de sécurité",
                labelStyle: TextStyle(color: mutedText),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: navy),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Annuler", style: TextStyle(color: mutedText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: navyDeep,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              if (msgController.text.isNotEmpty && passController.text.isNotEmpty) {
                // Ici, vous appliquez le chiffrement (ex: EncryptionService)
                // final encrypted = EncryptionService.encrypt(msgController.text, passController.text);
                // Pour l'exemple, on envoie le message en clair avec un indicateur
                final content = "🔒 Message protégé par mot de passe";
                
                await _chatService.sendMessage(
                  conversationId: widget.conversationId,
                  content: content,
                  replyToId: _replyToId.isEmpty ? null : _replyToId,
                  isEphemeral: _isEphemeral,
                  ephemeralDuration: _isEphemeral ? _ephemeralDuration : null,
                );
                Navigator.pop(ctx);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Veuillez remplir les deux champs"), backgroundColor: danger),
                );
              }
            },
            child: const Text("Envoyer", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ---- MENU ÉPHÉMÈRE ----
  void _showEphemeralTimerDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 4),
                    decoration: BoxDecoration(color: hairline, borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(color: navyDeep, borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.timer_rounded, size: 16, color: gold),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "Délai d'autodestruction",
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: darkText),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.timer_off_rounded, color: mutedText),
                  title: const Text("Désactiver l'autodestruction", style: TextStyle(color: mutedText, fontWeight: FontWeight.w600)),
                  onTap: () {
                    setState(() {
                      _isEphemeral = false;
                      _ephemeralDuration = null;
                    });
                    Navigator.pop(ctx);
                  },
                ),
                Container(height: 1, color: hairline, margin: const EdgeInsets.symmetric(horizontal: 16)),
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

  Widget _buildTimeOption(BuildContext ctx, int seconds, String label) {
    final isSelected = _isEphemeral && _ephemeralDuration == seconds;
    return ListTile(
      leading: Icon(
        Icons.timer_rounded,
        color: isSelected ? navy : darkText,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
          color: isSelected ? navy : darkText,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: gold) : null,
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

  // ---- GESTION DES MÉDIAS (remplacée par le chiffrement) ----
  // L'ancienne méthode _pickAudio est désormais remplacée par _showPasswordProtectDialog

  // ---- WIDGETS ----
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ivory,
      appBar: _buildAppBar(),
      body: Container(
        decoration: const BoxDecoration(color: ivory),
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: primaryBlue))
                  : Stack(
                      children: [
                        ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                          itemCount: _messages.length + (_isLoadingMore ? 1 : 0),
                          itemBuilder: (ctx, index) {
                            if (index == _messages.length && _isLoadingMore) {
                              return const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: navy)),
                              );
                            }
                            final msg = _messages[index];
                            final isOwn = msg.senderId == _chatService.currentUserId;

                            return ChatMessageBubble(
                              message: msg,
                              isOwn: isOwn,
                              onReply: () => setState(() => _replyToId = msg.id),
                              onDelete: () async {
                                setState(() {
                                  _messages.removeWhere((m) => m.id == msg.id);
                                });
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
              onAttach: () {
                // Implémentez la sélection d'image
              },
              // 👇 Le bouton "code" devient le bouton "cadenas" pour message protégé
              onCode: _showPasswordProtectDialog,
              onEphemeralToggle: _showEphemeralTimerDialog,
              isEphemeral: _isEphemeral,
              onTyping: _onTypingChanged,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // APP BAR — dégradé navy institutionnel
  // ============================================================
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: navyDeep,
      elevation: 0,
      titleSpacing: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [navyDeep, navy],
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: gold, width: 1.6),
            ),
            child: CircleAvatar(
              radius: 19,
              backgroundColor: navy,
              backgroundImage: widget.conversation.isGroup
                  ? null
                  : const NetworkImage('https://i.pravatar.cc/150?img=11'),
              child: widget.conversation.isGroup ? const Icon(Icons.groups_rounded, color: Colors.white, size: 18) : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.conversation.displayName,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!widget.conversation.isGroup && _otherParticipant != null)
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (_otherParticipant!.status == 'online') ? success : Colors.white38,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        (_otherParticipant!.status == 'online')
                            ? 'En ligne'
                            : 'Vu ${_formatLastSeen(_otherParticipant!.lastSeenAt ?? DateTime.now())}',
                        style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        _appBarIconButton(Icons.videocam_rounded, () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appel vidéo non disponible')));
        }),
        _appBarIconButton(Icons.call_rounded, () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appel vocal non disponible')));
        }),
        _appBarIconButton(Icons.more_vert_rounded, () {
          // Menu options (supprimer, voir participants, etc.)
        }),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _appBarIconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.16)),
        ),
        child: Icon(icon, size: 16, color: gold),
      ),
    );
  }

  // ============================================================
  // INDICATEUR DE RÉPONSE — accent or
  // ============================================================
  Widget _buildReplyIndicator() {
    final reply = _messages.firstWhere(
      (m) => m.id == _replyToId,
      orElse: () => _messages.first,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: pureWhite,
        border: Border(top: BorderSide(color: hairline, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: gold,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reply.senderId == _chatService.currentUserId ? 'Vous' : reply.senderName,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: navy,
                  ),
                ),
                Text(
                  reply.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, color: darkText),
                ),
              ],
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: _cancelReply,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(color: ivory, shape: BoxShape.circle),
              child: const Icon(Icons.close_rounded, size: 15, color: mutedText),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INDICATEUR DE SAISIE — bulle navy/or
  // ============================================================
  Widget _buildTypingIndicator() {
    return Positioned(
      bottom: 8,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: navyDeep,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: navyDeep.withOpacity(0.20),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text("En train d'écrire", style: TextStyle(fontSize: 11.5, color: Colors.white70, fontStyle: FontStyle.italic, fontWeight: FontWeight.w500)),
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
                  color: Color(0xFFE3B23C),
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
