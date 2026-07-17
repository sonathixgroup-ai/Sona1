// Route: lib/presentation/chat/chat_screen.dart
// Version ULTRA COMPLÈTE - Aucune coupe - Avec Appel Audio/Video Agora + Menu Actions Message + Aperçu Photo + Chiffrement
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

// Services
import 'package:thix_id/services/chat/chat_service.dart';
import 'package:thix_id/services/chat/presence_service.dart';
import 'package:thix_id/services/chat/audio_service.dart';
import 'package:thix_id/services/chat/group_service.dart';

// Modèles
import 'package:thix_id/models/chat/chat_message.dart';
import 'package:thix_id/models/chat/chat_conversation.dart';
import 'package:thix_id/models/chat/user_status.dart';
import 'package:thix_id/models/chat/group_info.dart';

// Widgets
import 'package:thix_id/presentation/chat/widgets/chat_message_bubble.dart';
import 'package:thix_id/presentation/chat/widgets/chat_input_bar.dart';
import 'package:thix_id/presentation/chat/widgets/audio_recorder.dart';
import 'package:thix_id/presentation/chat/widgets/audio_player.dart';
import 'package:thix_id/presentation/chat/group/group_info_panel.dart';
import 'package:thix_id/presentation/chat/encryption_service.dart';

// ==================== ESCALADE ====================
import 'package:thix_id/presentation/chat/escalation/models/escalation_level.dart';
import 'package:thix_id/presentation/chat/escalation/providers/escalation_provider.dart';

// ==================== CALL AGORA ====================
import 'package:thix_id/models/chat/call_status.dart';
import 'package:thix_id/presentation/chat/call/call_page.dart';
import 'package:thix_id/presentation/chat/call/providers/call_provider.dart';

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
  // Services
  late ChatService _chatService;
  late PresenceService _presenceService;
  late AudioService _audioService;
  late GroupService _groupService;

  // Messages
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreMessages = true;
  bool _isSending = false;
  int _page = 0;
  static const int _pageSize = 30;

  // Contrôleurs
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocus = FocusNode();

  // Participants
  UserStatus? _otherParticipant;
  List<GroupMember> _groupMembers = [];

  // État du message
  String _replyToId = '';
  bool _isEphemeral = false;
  int? _ephemeralDuration;

  // === APERÇU PHOTO EN ATTENTE D'ENVOI ===
  Uint8List? _pendingImageBytes;
  String? _pendingImageName;
  String? _pendingImageExtension;

  // === TYPING INDICATOR ===
  bool _isTyping = false;
  bool _otherUserTyping = false;
  Timer? _typingTimer;
  RealtimeChannel? _typingChannel;

  // === ESCALADE ET NOTES INTERNES ===
  bool _isAgent = false;
  bool _isInternalNoteMode = false;
  bool _isConversationEscalated = false;

  // Streams
  StreamSubscription<List<ChatMessage>>? _messageSubscription;
  Stream<UserStatus?>? _presenceStream;

  // Couleurs THIX ID
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

  // Préfixe utilisé pour marquer un contenu comme chiffré
  static const String _encPrefix = 'ENC::';

  // Réactions rapides (menu action message)
  static const List<String> _quickReactions = ['🔥', '🙌', '❤️', '😀', '😖', '👍'];

  // ============================================================
  // CYCLE DE VIE
  // ============================================================

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;
    _chatService = ChatService(client);
    _presenceService = PresenceService(client);
    _audioService = AudioService(client);
    _groupService = GroupService(client);

    _loadUserRole();

    WidgetsBinding.instance.addObserver(this);

    _loadMessages();
    _getParticipantInfo();
    _markAsRead();
    _setupScrollListener();
    _subscribeToPresence();
    _subscribeToRealtimeMessages();
    _subscribeToTypingChannel();
    _loadGroupMembersIfGroup();
    _checkMicrophonePermission();
  }

  Future<void> _loadUserRole() async {
    final user = _chatService.currentUser;
    if (user != null) {
      _isAgent = user.role == 'agent' || user.role == 'admin' || user.role == 'support';
      setState(() {});
    }
  }

  Future<void> _checkMicrophonePermission() async {
    final status = await Permission.microphone.status;
    debugPrint('🎙 Statut permission microphone au chargement: $status');
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

  // ============================================================
  // CHARGEMENT DES DONNÉES
  // ============================================================

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
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadGroupMembersIfGroup() async {
    if (!widget.conversation.isGroup) return;
    try {
      final members = await _chatService.getGroupMembers(widget.conversationId);
      setState(() => _groupMembers = members);
    } catch (e) {
      debugPrint('❌ Erreur chargement membres: $e');
    }
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      final position = _scrollController.position;
      if (position.pixels >= position.maxScrollExtent - 200) {
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

  // ============================================================
  // PRÉSENCE
  // ============================================================

  void _subscribeToPresence() {
    if (widget.conversation.isGroup) return;
    final otherId = widget.conversation.participantIds.firstWhere(
      (id) => id != _chatService.currentUserId,
      orElse: () => '',
    );
    if (otherId.isNotEmpty) {
      _presenceStream = _chatService.subscribeToPresence([otherId]).map(
        (list) => list.isNotEmpty ? list.first : null,
      );
      _presenceStream?.listen((status) {
        if (mounted) setState(() => _otherParticipant = status);
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

  // ============================================================
  // REALTIME - MESSAGES
  // ============================================================

  void _subscribeToRealtimeMessages() {
    _messageSubscription = _chatService
        .subscribeToMessages(widget.conversationId)
        .listen((updatedMsgs) {
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
            _messages.add(msg);
          }
        }
      });
      _scrollToBottom();
    });
  }

  // ============================================================
  // REALTIME - TYPING INDICATOR
  // ============================================================

  void _subscribeToTypingChannel() {
    final currentUserId = _chatService.currentUserId;

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
    final currentUserId = _chatService.currentUserId;

    if (currentUserId == null || _typingChannel == null) return;

    _typingChannel!.sendBroadcastMessage(
      event: 'typing',
      payload: {
        'senderId': currentUserId,
        'isTyping': typing,
      },
    );
  }

  // ============================================================
  // APPEL AUDIO / VIDEO - AGORA
  // ============================================================

  void _startCall(CallType type) {
    final otherId = widget.conversation.participantIds.firstWhere(
      (id) => id != _chatService.currentUserId,
      orElse: () => '',
    );
    if (otherId.isEmpty && !widget.conversation.isGroup) {
      _showSnackBar('Participant introuvable', danger);
      return;
    }
    final prov = context.read<CallProvider>();
    prov.start(
      channel: widget.conversationId,
      calleeId: otherId,
      callType: type,
    );
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
  }

  void _startAudioCall() => _startCall(CallType.audio);
  void _startVideoCall() => _startCall(CallType.video);

  // ============================================================
  // ENVOI DE MESSAGES (texte + photo en attente)
  // ============================================================

  Future<void> _sendMessage() async {
    // Si une image est en attente, on l'envoie en priorité (avec la légende éventuelle)
    if (_pendingImageBytes != null) {
      await _sendPendingImage();
      return;
    }

    final text = _inputController.text.trim();
    if (text.isEmpty || _isSending) return;

    _isTyping = false;
    _sendTypingStatus(false);
    setState(() => _isSending = true);

    try {
      final msg = await _chatService.sendMessage(
        conversationId: widget.conversationId,
        content: text,
        replyToId: _replyToId.isEmpty ? null : _replyToId,
        isEphemeral: _isEphemeral,
        ephemeralDuration: _isEphemeral ? _ephemeralDuration : null,
        isInternalNote: _isInternalNoteMode,
      );

      setState(() {
        if (!_messages.any((m) => m.id == msg.id)) {
          _messages.add(msg);
        }
        _inputController.clear();
        _replyToId = '';
        _isSending = false;
        if (_isInternalNoteMode) {
          _isInternalNoteMode = false;
        }
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _isSending = false);
      _showSnackBar('Erreur: $e', danger);
    }
  }

  Future<void> _sendAudioMessage(String filePath, int duration) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final msg = await _chatService.sendAudioMessage(
        conversationId: widget.conversationId,
        audioData: Uint8List.fromList(bytes),
        duration: duration,
        isEphemeral: _isEphemeral,
        ephemeralDuration: _isEphemeral ? _ephemeralDuration : null,
        replyToId: _replyToId.isEmpty ? null : _replyToId,
      );
      setState(() {
        _messages.add(msg);
        _replyToId = '';
        if (_isInternalNoteMode) _isInternalNoteMode = false;
      });
      _scrollToBottom();
    } catch (e) {
      _showSnackBar('Erreur envoi audio: $e', danger);
    }
  }

  // ============================================================
  // AUDIO RECORDING
  // ============================================================

  void _startAudioRecording() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      _openAudioRecorderSheet();
      return;
    }
    if (status.isPermanentlyDenied) {
      _showMicPermissionDeniedDialog();
      return;
    }
    _showSnackBar(
      '❌ Permission microphone refusée. Veuillez autoriser dans les paramètres.',
      danger,
    );
  }

  void _showMicPermissionDeniedDialog() {
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.mic_off_rounded, color: danger),
            SizedBox(width: 8),
            Text('Microphone désactivé',
                style: TextStyle(color: navyDeep, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          "L'accès au microphone est bloqué pour THIX CHAT. Active-le dans les paramètres de ton téléphone pour envoyer des messages vocaux.",
          style: TextStyle(color: mutedText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler', style: TextStyle(color: mutedText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: navyDeep,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('Ouvrir les paramètres', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _openAudioRecorderSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.all(20),
        child: AudioRecorderWidget(
          audioService: _audioService,
          onRecordingComplete: (filePath, duration) {
            Navigator.pop(ctx);
            _sendAudioMessage(filePath, duration);
          },
          onRecordingCanceled: () => Navigator.pop(ctx),
          maxDuration: 120,
        ),
      ),
    );
  }

  // ============================================================
  // CHIFFREMENT — envoi avec préfixe ENC::
  // ============================================================

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
            Text('Message chiffré',
                style: TextStyle(color: navyDeep, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: msgController,
              decoration: const InputDecoration(
                labelText: 'Votre message',
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
                labelText: 'Mot de passe de sécurité',
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
            child: const Text('Annuler', style: TextStyle(color: mutedText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: navyDeep,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              if (msgController.text.isNotEmpty &&
                  passController.text.isNotEmpty) {
                try {
                  final encrypted = EncryptionService.encryptMessage(
                      msgController.text, passController.text);

                  await _chatService.sendMessage(
                    conversationId: widget.conversationId,
                    content: '$_encPrefix$encrypted',
                    replyToId: _replyToId.isEmpty ? null : _replyToId,
                    isEphemeral: _isEphemeral,
                    ephemeralDuration:
                        _isEphemeral ? _ephemeralDuration : null,
                  );
                  if (context.mounted) Navigator.pop(ctx);
                } catch (e) {
                  _showSnackBar('Erreur chiffrement: $e', danger);
                }
              } else {
                _showSnackBar('Veuillez remplir les deux champs', danger);
              }
            },
            child: const Text('Envoyer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MENU ÉPHÉMÈRE
  // ============================================================

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
                    decoration: BoxDecoration(
                        color: hairline, borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                            color: navyDeep, borderRadius: BorderRadius.circular(10)),
                        child:
                            const Icon(Icons.timer_rounded, size: 16, color: gold),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "Délai d'autodestruction",
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: darkText),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading:
                      const Icon(Icons.timer_off_rounded, color: mutedText),
                  title: const Text(
                    "Désactiver l'autodestruction",
                    style: TextStyle(color: mutedText, fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    setState(() {
                      _isEphemeral = false;
                      _ephemeralDuration = null;
                    });
                    Navigator.pop(ctx);
                  },
                ),
                Container(
                    height: 1,
                    color: hairline,
                    margin: const EdgeInsets.symmetric(horizontal: 16)),
                _buildTimeOption(ctx, 10, '10 secondes'),
                _buildTimeOption(ctx, 30, '30 secondes'),
                _buildTimeOption(ctx, 60, '1 minute'),
                _buildTimeOption(ctx, 300, '5 minutes'),
                _buildTimeOption(ctx, 3600, '1 heure'),
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
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded, color: gold)
          : null,
      onTap: () {
        setState(() {
          _isEphemeral = true;
          _ephemeralDuration = seconds;
        });
        Navigator.pop(ctx);
      },
    );
  }

  // ============================================================
  // TYPING INDICATOR
  // ============================================================

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
  // RÉPONSE
  // ============================================================

  void _cancelReply() => setState(() => _replyToId = '');

  // ============================================================
  // MENU D'ACTIONS SUR UN MESSAGE (long-press)
  // ============================================================

  void _showMessageActions(ChatMessage msg, bool isOwn) {
    final isEncrypted = msg.content.startsWith(_encPrefix);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.32,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: pureWhite,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: SafeArea(
                top: false,
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: hairline,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    Align(
                      alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 280),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isOwn ? primaryBlue : ivory,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(18),
                            topRight: const Radius.circular(18),
                            bottomLeft: Radius.circular(isOwn ? 18 : 4),
                            bottomRight: Radius.circular(isOwn ? 4 : 18),
                          ),
                        ),
                        child: Text(
                          isEncrypted ? '🔒 Message chiffré' : msg.content,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.3,
                            fontWeight: FontWeight.w500,
                            color: isOwn ? Colors.white : darkText,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'React',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: darkText),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: _quickReactions.map((emoji) {
                        return InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            _chatService.toggleReaction(msg.id, emoji);
                            Navigator.pop(ctx);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Text(emoji, style: const TextStyle(fontSize: 26)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    Container(height: 1, color: hairline),
                    _actionTile(
                      icon: Icons.reply_rounded,
                      label: 'Reply',
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() => _replyToId = msg.id);
                        _inputFocus.requestFocus();
                      },
                    ),
                    Container(height: 1, color: hairline),
                    _actionTile(
                      icon: Icons.forward_rounded,
                      label: 'Forward',
                      onTap: () {
                        Navigator.pop(ctx);
                        _forwardMessage(msg);
                      },
                    ),
                    Container(height: 1, color: hairline),
                    _actionTile(
                      icon: Icons.copy_rounded,
                      label: 'Copy',
                      onTap: () {
                        Navigator.pop(ctx);
                        if (isEncrypted) {
                          _showSnackBar('Impossible de copier un message chiffré', danger);
                          return;
                        }
                        Clipboard.setData(ClipboardData(text: msg.content));
                        _showSnackBar('Message copié', navy);
                      },
                    ),
                    Container(height: 1, color: hairline),
                    _actionTile(
                      icon: Icons.delete_outline_rounded,
                      label: 'Delete',
                      color: danger,
                      onTap: () async {
                        Navigator.pop(ctx);
                        setState(() => _messages.removeWhere((m) => m.id == msg.id));
                        if (isOwn) {
                          try {
                            await _chatService.deleteMessage(msg.id);
                          } catch (_) {}
                        }
                      },
                    ),
                    Container(height: 1, color: hairline),
                    _actionTile(
                      icon: Icons.more_horiz_rounded,
                      label: 'More..',
                      onTap: () {
                        Navigator.pop(ctx);
                        _showMoreMessageOptions(msg, isOwn);
                      },
                      showDivider: false,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = darkText,
    bool showDivider = true,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: color),
            ),
            Icon(icon, size: 20, color: color == danger ? danger : mutedText),
          ],
        ),
      ),
    );
  }

  void _forwardMessage(ChatMessage msg) {
    Navigator.pushNamed(
      context,
      '/chat/forward',
      arguments: {'messageId': msg.id, 'content': msg.content},
    );
  }

  void _showMoreMessageOptions(ChatMessage msg, bool isOwn) {
    showModalBottomSheet(
      context: context,
      backgroundColor: pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: hairline, borderRadius: BorderRadius.circular(4)),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded, color: navy),
              title: const Text('Détails du message'),
              onTap: () => Navigator.pop(ctx),
            ),
            if (_isAgent)
              ListTile(
                leading: const Icon(Icons.sticky_note_2_outlined, color: Colors.orange),
                title: const Text('Marquer comme note interne'),
                onTap: () => Navigator.pop(ctx),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // GESTION DES MÉDIAS — MENU D'ATTACHEMENT
  // ============================================================

  void _showAttachmentMenu() {
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
                    decoration: BoxDecoration(
                        color: hairline, borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: const [
                      Icon(Icons.attach_file_rounded, color: navy),
                      SizedBox(width: 10),
                      Text(
                        'Envoyer une pièce jointe',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: darkText),
                      ),
                    ],
                  ),
                ),
                _attachmentOption(
                  ctx,
                  icon: Icons.image_rounded,
                  label: 'Photo',
                  color: gold,
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImageForPreview();
                  },
                ),
                _attachmentOption(
                  ctx,
                  icon: Icons.videocam_rounded,
                  label: 'Vidéo',
                  color: primaryBlue,
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickFile(type: FileType.video);
                  },
                ),
                _attachmentOption(
                  ctx,
                  icon: Icons.insert_drive_file_rounded,
                  label: 'Document',
                  color: navy,
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickFile(type: FileType.any);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _attachmentOption(
    BuildContext ctx, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, color: darkText),
      ),
      onTap: onTap,
    );
  }

  // ============================================================
  // PHOTO — SÉLECTION → APERÇU DANS LA BARRE → ENVOI AU TAP
  // ============================================================

  Future<void> _pickImageForPreview() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.image,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes ?? await File(file.path!).readAsBytes();

      setState(() {
        _pendingImageBytes = Uint8List.fromList(bytes);
        _pendingImageName = file.name;
        _pendingImageExtension = file.extension ?? 'jpg';
      });
    } catch (e) {
      _showSnackBar('Erreur sélection photo: $e', danger);
    }
  }

  void _removePendingImage() {
    setState(() {
      _pendingImageBytes = null;
      _pendingImageName = null;
      _pendingImageExtension = null;
    });
  }

  Future<void> _sendPendingImage() async {
    if (_pendingImageBytes == null) return;
    setState(() => _isSending = true);

    try {
      final caption = _inputController.text.trim();
      final extension = _pendingImageExtension ?? 'jpg';
      final mimeType = _getMimeType(extension);

      final url = await _chatService.uploadFileWithUniqueName(
        'chat-media',
        'messages/${widget.conversationId}',
        _pendingImageBytes!,
        extension,
      );

      if (url != null) {
        final msg = await _chatService.sendMessage(
          conversationId: widget.conversationId,
          content: caption.isNotEmpty ? caption : '📷 Photo',
          mediaUrl: url,
          mediaType: 'image',
          mediaName: _pendingImageName ?? 'photo.$extension',
          mediaSize: _pendingImageBytes!.length,
          mimeType: mimeType,
          isEphemeral: _isEphemeral,
          ephemeralDuration: _isEphemeral ? _ephemeralDuration : null,
          replyToId: _replyToId.isEmpty ? null : _replyToId,
        );

        setState(() {
          if (!_messages.any((m) => m.id == msg.id)) {
            _messages.add(msg);
          }
          _inputController.clear();
          _replyToId = '';
          _pendingImageBytes = null;
          _pendingImageName = null;
          _pendingImageExtension = null;
          _isSending = false;
        });
        _scrollToBottom();
      } else {
        setState(() => _isSending = false);
        _showSnackBar('Erreur upload photo', danger);
      }
    } catch (e) {
      setState(() => _isSending = false);
      _showSnackBar('Erreur envoi photo: $e', danger);
    }
  }

  // ============================================================
  // GESTION DES FICHIERS - INTEGRAL - AUCUNE COUPE
  // ============================================================

  Future<void> _pickFile({FileType type = FileType.any}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: type,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes ?? await File(file.path!).readAsBytes();
      final extension = file.extension ?? 'file';
      final size = file.size;

      String mimeType = _getMimeType(extension);
      String mediaType = _getMediaType(extension);

      final confirmed = await _showFilePreviewDialog(
        fileName: file.name,
        fileSize: size,
        fileBytes: Uint8List.fromList(bytes),
        mimeType: mimeType,
        extension: extension,
      );

      if (confirmed != true) return;

      final url = await _chatService.uploadFileWithUniqueName(
        'chat-media',
        'messages/${widget.conversationId}',
        Uint8List.fromList(bytes),
        extension,
      );

      if (url != null) {
        await _chatService.sendMessage(
          conversationId: widget.conversationId,
          content: '📎 ${file.name}',
          mediaUrl: url,
          mediaType: mediaType,
          mediaName: file.name,
          mediaSize: size,
          mimeType: mimeType,
          isEphemeral: _isEphemeral,
          ephemeralDuration: _isEphemeral ? _ephemeralDuration : null,
        );
        _scrollToBottom();
      }
    } catch (e) {
      _showSnackBar('Erreur fichier: $e', danger);
    }
  }

  String _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'txt':
        return 'text/plain';
      case 'zip':
        return 'application/zip';
      case 'rar':
        return 'application/x-rar-compressed';
      default:
        return 'application/octet-stream';
    }
  }

  String _getMediaType(String extension) {
    const imageExt = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'svg'};
    const videoExt = {'mp4', 'mov', 'avi', 'mkv', 'webm', 'flv'};
    const audioExt = {'mp3', 'wav', 'aac', 'ogg', 'flac', 'm4a'};
    const docExt = {'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt'};

    final ext = extension.toLowerCase();
    if (imageExt.contains(ext)) return 'image';
    if (videoExt.contains(ext)) return 'video';
    if (audioExt.contains(ext)) return 'audio';
    if (docExt.contains(ext)) return 'document';
    return 'file';
  }

  Future<bool?> _showFilePreviewDialog({
    required String fileName,
    required int fileSize,
    required Uint8List fileBytes,
    required String mimeType,
    required String extension,
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.attach_file, color: navy),
            const SizedBox(width: 8),
            const Text('Aperçu du fichier'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilePreviewThumbnail(fileBytes, mimeType, extension),
            const SizedBox(height: 12),
            Text(
              'Nom : $fileName',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Text(
              'Taille : ${_formatFileSize(fileSize)}',
              style: const TextStyle(color: Colors.grey),
            ),
            Text(
              'Type : $mimeType',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilePreviewThumbnail(Uint8List bytes, String mimeType, String extension) {
    if (mimeType.startsWith('image/')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          bytes,
          height: 150,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 60),
        ),
      );
    }
    if (mimeType.startsWith('video/')) {
      return Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(Icons.play_circle_filled, size: 60, color: Colors.blue),
        ),
      );
    }
    if (mimeType.startsWith('audio/')) {
      return Container(
        height: 80,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(Icons.audiotrack, size: 40, color: Colors.grey),
        ),
      );
    }
    return Container(
      height: 80,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_getFileIcon(extension), size: 40, color: Colors.blue),
            const SizedBox(height: 4),
            Text(
              extension.toUpperCase(),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'zip':
      case 'rar':
        return Icons.folder_zip;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // ============================================================
  // GROUPES - INTEGRAL
  // ============================================================

  void _navigateToGroupInfo() {
    Navigator.pushNamed(
      context,
      '/group/info',
      arguments: widget.conversationId,
    );
  }

  void _navigateToGroupSettings() {
    Navigator.pushNamed(
      context,
      '/group/settings',
      arguments: widget.conversationId,
    );
  }

  Future<void> _leaveGroup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitter le groupe'),
        content: const Text('Êtes-vous sûr de vouloir quitter ce groupe?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: danger),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _groupService.leaveGroup(widget.conversationId);
        if (context.mounted) Navigator.pop(context);
        _showSnackBar('Vous avez quitté le groupe', success);
      } catch (e) {
        _showSnackBar('Erreur: $e', danger);
      }
    }
  }

  Future<void> _deleteGroup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le groupe'),
        content: const Text(
            'Cette action est irréversible. Tous les messages seront perdus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: danger),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _groupService.deleteGroup(widget.conversationId);
        if (context.mounted) Navigator.pop(context);
        _showSnackBar('Groupe supprimé', success);
      } catch (e) {
        _showSnackBar('Erreur: $e', danger);
      }
    }
  }

  // ============================================================
  // ESCALADE + HISTORIQUE
  // ============================================================

  void _escalateConversation() {
    context.pushNamed(
      'chatEscalate',
      pathParameters: {'conversationId': widget.conversationId},
      queryParameters: {
        'agentId': _chatService.currentUserId ?? '',
        'agentName': _chatService.currentUser?.userMetadata?['full_name'] ?? 'Agent',
      },
    );
  }

  void _viewEscalationHistory() {
    context.pushNamed(
      'chatEscalationHistory',
      pathParameters: {'conversationId': widget.conversationId},
    );
  }

  void _toggleInternalNoteMode() {
    setState(() {
      _isInternalNoteMode = !_isInternalNoteMode;
    });
    _showSnackBar(
      _isInternalNoteMode ? 'Mode note interne activé' : 'Mode note interne désactivé',
      _isInternalNoteMode ? Colors.orange : mutedText,
    );
  }

  // ============================================================
  // UTILITAIRES
  // ============================================================

  void _showSnackBar(String message, Color color) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: color),
      );
    }
  }

  // ============================================================
  // BUILD - INTEGRAL
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ivory,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          if (widget.conversation.isGroup)
            GroupInfoPanel(
              conversation: widget.conversation,
              members: _groupMembers,
              onViewAllMembers: _navigateToGroupInfo,
              onEditGroup: _navigateToGroupSettings,
              onLeaveGroup: _leaveGroup,
              onDeleteGroup: _deleteGroup,
            ),
          if (_isConversationEscalated) _buildEscalationIndicator(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: primaryBlue))
                : _buildMessageList(),
          ),
          if (_replyToId.isNotEmpty) _buildReplyIndicator(),
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
            isInternalNote: _isInternalNoteMode,
            previewImageBytes: _pendingImageBytes,
            onRemovePreview: _removePendingImage,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return Stack(
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
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2, color: navy),
                ),
              );
            }
            final msg = _messages[_messages.length - 1 - index];
            final isOwn = msg.senderId == _chatService.currentUserId;

            return GestureDetector(
              onLongPress: () => _showMessageActions(msg, isOwn),
              child: ChatMessageBubble(
                message: msg,
                isOwn: isOwn,
                onReply: () => setState(() => _replyToId = msg.id),
                onDelete: () async {
                  setState(() => _messages.removeWhere((m) => m.id == msg.id));
                  if (isOwn) {
                    try {
                      await _chatService.deleteMessage(msg.id);
                    } catch (_) {}
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
                isInternalNote: msg.isInternalNote ?? false,
                isAgentView: _isAgent,
              ),
            );
          },
        ),
        if (_otherUserTyping) _buildTypingIndicator(),
      ],
    );
  }

  Widget _buildEscalationIndicator() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.orange.shade100,
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Cette conversation est en cours d\'escalade vers un niveau supérieur.',
              style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // APP BAR - AVEC CALLS + ESCALADE/HISTORIQUE
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
              child: widget.conversation.isGroup
                  ? const Icon(Icons.groups_rounded, color: Colors.white, size: 18)
                  : null,
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
        _appBarIconButton(Icons.videocam_rounded, _startVideoCall),
        _appBarIconButton(Icons.call_rounded, _startAudioCall),
        if (widget.conversation.isGroup)
          _appBarIconButton(Icons.info_outline_rounded, _navigateToGroupInfo),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: gold),
          onSelected: (value) {
            if (value == 'escalate') _escalateConversation();
            else if (value == 'history') _viewEscalationHistory();
          },
          itemBuilder: (context) => [
            const PopupMenuItem<String>(
              value: 'escalate',
              child: Row(
                children: [
                  Icon(Icons.arrow_upward, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Escalader'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'history',
              child: Row(
                children: [
                  Icon(Icons.history, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Historique escalades'),
                ],
              ),
            ),
          ],
        ),
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

  Widget _buildReplyIndicator() {
    final reply = _messages.firstWhere(
      (m) => m.id == _replyToId,
      orElse: () => _messages.first,
    );
    final isEncrypted = reply.content.startsWith(_encPrefix);
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
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: navy),
                ),
                Text(
                  isEncrypted ? '🔒 Message chiffré' : reply.content,
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
            Text(
              "En train d'écrire",
              style: TextStyle(fontSize: 11.5, color: Colors.white70, fontStyle: FontStyle.italic, fontWeight: FontWeight.w500),
            ),
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

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
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
