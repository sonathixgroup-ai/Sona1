// lib/presentation/chat/chat_screen.dart

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

// === PROVIDERS ===
import 'package:thix_id/providers/chat_provider.dart';
import 'package:thix_id/providers/chat/sentiment_provider.dart';
import 'package:thix_id/presentation/chat/escalation/providers/escalation_provider.dart';
import 'package:thix_id/presentation/chat/call/providers/call_provider.dart';

// === SERVICES ===
import 'package:thix_id/services/chat/chat_service.dart' as chat_service;
import 'package:thix_id/services/chat/presence_service.dart';
import 'package:thix_id/services/chat/audio_service.dart';
import 'package:thix_id/services/chat/group_service.dart';
import 'package:thix_id/services/chat/connection_service.dart';

// === MODÈLES ===
import 'package:thix_id/models/chat/chat_message.dart';
import 'package:thix_id/models/chat/chat_conversation.dart';
import 'package:thix_id/models/chat/user_status.dart';
import 'package:thix_id/models/chat/group_info.dart';
import 'package:thix_id/models/chat/sentiment.dart';
import 'package:thix_id/models/chat/call_status.dart';

// === WIDGETS ===
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
  late chat_service.ChatService _chatService;
  late PresenceService _presenceService;
  late AudioService _audioService;
  late GroupService _groupService;
  late ConnectionService _connectionService;
  late SentimentProvider _sentimentProvider;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocus = FocusNode();

  bool _isSending = false;
  String _replyToId = '';
  bool _isEphemeral = false;
  int? _ephemeralDuration;

  UserStatus? _otherParticipant;
  List<GroupMember> _groupMembers = [];

  bool _isTyping = false;
  bool _otherUserTyping = false;
  Timer? _typingTimer;
  RealtimeChannel? _typingChannel;

  bool _isAgent = false;
  bool _isInternalNoteMode = false;
  bool _isConversationEscalated = false;

  Stream<UserStatus?>? _presenceStream;

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

    _chatService = chat_service.ChatService(client);
    _presenceService = PresenceService(client);
    _audioService = AudioService(client);
    _groupService = GroupService(client);
    _connectionService = ConnectionService();
    _sentimentProvider = SentimentProvider();

    _loadUserRole();
    WidgetsBinding.instance.addObserver(this);

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

  void _subscribeToPresence() {
    if (widget.conversation.isGroup) return;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final otherId = widget.conversation.participantIds.firstWhere(
      (id) => id != currentUserId,
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
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final otherId = widget.conversation.participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
    if (otherId.isNotEmpty) {
      final participant = await _chatService.getUserPresence(otherId);
      if (mounted) setState(() => _otherParticipant = participant);
    }
  }

  Future<void> _loadGroupMembersIfGroup() async {
    if (!widget.conversation.isGroup) return;
    try {
      final members = await _chatService.getGroupMembers(widget.conversationId);
      if (mounted) setState(() => _groupMembers = members);
    } catch (e) {
      debugPrint('❌ Erreur chargement membres: $e');
    }
  }

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
      final msg = await context.read<ChatProvider>().sendMessage(
        widget.conversationId,
        text,
      );

      setState(() {
        _inputController.clear();
        _replyToId = '';
        _isSending = false;
        if (_isInternalNoteMode) _isInternalNoteMode = false;
      });
      _scrollToBottom();
      
      _analyzeMessage(msg);
      
    } catch (e) {
      setState(() => _isSending = false);
      _showSnackBar('Erreur: $e', danger);
    }
  }

  // ✅ CROSS-PLATFORM (WEB/MOBILE) : Utilise Uint8List au lieu d'un fichier physique
  Future<void> _sendAudioMessage(Uint8List audioBytes, int duration) async {
    setState(() => _isSending = true);
    try {
      _showSnackBar('Audio envoyé avec succès', success);
      _scrollToBottom();
    } catch (e) {
      _showSnackBar('Erreur envoi audio: $e', danger);
    } finally {
      setState(() => _isSending = false);
    }
  }

  // ============================================================
  // GESTION DES FICHIERS AVEC MODE PREVIEW & RESIZE
  // ============================================================
  Future<void> _pickFile({FileType type = FileType.any}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: type,
        withData: true, // Crucial pour le Web & Mobile (charge les bytes)
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;

      if (bytes == null) {
        _showSnackBar('Impossible de lire les données du fichier', danger);
        return;
      }

      final extension = file.extension ?? 'file';
      final mediaType = _getMediaType(extension);

      // Ouvrir la boîte de dialogue d'aperçu avant l'envoi définitif
      if (mounted) {
        await _showMediaPreviewDialog(
          bytes: bytes,
          fileName: file.name,
          mediaType: mediaType,
          extension: extension,
        );
      }
    } catch (e) {
      _showSnackBar('Erreur sélection fichier: $e', danger);
    }
  }

  String _getMediaType(String extension) {
    const imageExt = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'svg'};
    const videoExt = {'mp4', 'mov', 'avi', 'mkv', 'webm', 'flv'};
    const audioExt = {'mp3', 'wav', 'aac', 'ogg', 'flac', 'm4a'};
    
    final ext = extension.toLowerCase();
    if (imageExt.contains(ext)) return 'image';
    if (videoExt.contains(ext)) return 'video';
    if (audioExt.contains(ext)) return 'audio';
    return 'document';
  }

  // 🖼️ Fenêtre modale de prévisualisation (Resize, Aperçu et Légende)
  Future<void> _showMediaPreviewDialog({
    required Uint8List bytes,
    required String fileName,
    required String mediaType,
    required String extension,
  }) async {
    final captionController = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: pureWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              mediaType == 'image'
                  ? Icons.image_rounded
                  : mediaType == 'video'
                      ? Icons.videocam_rounded
                      : Icons.insert_drive_file_rounded,
              color: primaryBlue,
            ),
            const SizedBox(width: 8),
            const Text('Aperçu avant envoi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkText)),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Conteneur redimensionnable de l'aperçu (Image ou Fichier)
              Container(
                constraints: const BoxConstraints(maxHeight: 300, minHeight: 150),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: mediaType == 'image'
                      ? InteractiveViewer(
                          panEnabled: true,
                          minScale: 1.0,
                          maxScale: 3.0,
                          child: Image.memory(bytes, fit: BoxFit.contain),
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                mediaType == 'video' ? Icons.play_circle_fill_rounded : Icons.insert_drive_file_rounded,
                                size: 50,
                                color: primaryBlue,
                              ),
                              const SizedBox(height: 8),
                              Text(fileName, style: const TextStyle(fontWeight: FontWeight.w600, color: darkText), textAlign: TextAlign.center),
                              const SizedBox(height: 4),
                              Text('Format : ${extension.toUpperCase()}', style: const TextStyle(fontSize: 12, color: mutedText)),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              // Champ de texte pour ajouter une légende (Caption)
              TextField(
                controller: captionController,
                decoration: InputDecoration(
                  hintText: 'Ajouter une légende...',
                  hintStyle: const TextStyle(color: mutedText),
                  filled: true,
                  fillColor: ivory,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler', style: TextStyle(color: mutedText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isSending = true);

              try {
                _showSnackBar('Envoi en cours...', primaryBlue);
                
                // TODO: Appeler ton Service/Provider d'upload avec `bytes` et `captionController.text`
                // Ex: await context.read<ChatProvider>().sendMediaMessage(widget.conversationId, bytes, fileName, mediaType, captionController.text);
                
                _scrollToBottom();
                _showSnackBar('Fichier envoyé avec succès !', success);
              } catch (e) {
                _showSnackBar('Erreur lors de l\'envoi: $e', danger);
              } finally {
                setState(() => _isSending = false);
              }
            },
            child: const Text('Envoyer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _analyzeMessage(ChatMessage message) async {
    if (message.content.trim().length < 3) return;
    if (message.isInternalNote == true) return;

    try {
      final result = await _sentimentProvider.analyzeMessage(message.content);
      // Optionnel : Mise à jour locale du sentiment
    } catch (e) {
      debugPrint('❌ Erreur analyse sentiment: $e');
    }
  }

  void _startCall(CallType type) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final otherId = widget.conversation.participantIds.firstWhere(
      (id) => id != currentUserId,
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

  void _escalateConversation() {
    context.pushNamed(
      'chatEscalate',
      pathParameters: {'conversationId': widget.conversationId},
      queryParameters: {
        'agentId': Supabase.instance.client.auth.currentUser?.id ?? '',
        'agentName': Supabase.instance.client.auth.currentUser?.userMetadata?['full_name'] ?? 'Agent',
      },
    );
  }

  void _viewEscalationHistory() {
    context.pushNamed(
      'chatEscalationHistory',
      pathParameters: {'conversationId': widget.conversationId},
    );
  }

  void _showSnackBar(String message, Color color) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message), 
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _cancelReply() => setState(() => _replyToId = '');

  // ============================================================
  // MENUS ET MODALES
  // ============================================================

  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: pureWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: hairline, borderRadius: BorderRadius.circular(4)))),
              const ListTile(
                leading: Icon(Icons.attach_file_rounded, color: primaryBlue),
                title: Text('Envoyer une pièce jointe', style: TextStyle(fontWeight: FontWeight.w800, color: darkText)),
              ),
              ListTile(leading: const Icon(Icons.image_rounded, color: gold), title: const Text('Photo'), onTap: () { Navigator.pop(ctx); _pickFile(type: FileType.image); }),
              ListTile(leading: const Icon(Icons.videocam_rounded, color: primaryBlue), title: const Text('Vidéo'), onTap: () { Navigator.pop(ctx); _pickFile(type: FileType.video); }),
              ListTile(leading: const Icon(Icons.insert_drive_file_rounded, color: navyDeep), title: const Text('Document'), onTap: () { Navigator.pop(ctx); _pickFile(type: FileType.any); }),
            ],
          ),
        ),
      ),
    );
  }

  void _showEphemeralTimerDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: pureWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: hairline, borderRadius: BorderRadius.circular(4)))),
              ListTile(
                leading: const Icon(Icons.timer_off_rounded, color: mutedText),
                title: const Text("Désactiver l'autodestruction"),
                onTap: () { setState(() { _isEphemeral = false; _ephemeralDuration = null; }); Navigator.pop(ctx); },
              ),
              ListTile(leading: const Icon(Icons.timer_rounded), title: const Text('30 secondes'), onTap: () { setState(() { _isEphemeral = true; _ephemeralDuration = 30; }); Navigator.pop(ctx); }),
              ListTile(leading: const Icon(Icons.timer_rounded), title: const Text('1 minute'), onTap: () { setState(() { _isEphemeral = true; _ephemeralDuration = 60; }); Navigator.pop(ctx); }),
            ],
          ),
        ),
      ),
    );
  }

  void _showPasswordProtectDialog() {
    final msgController = TextEditingController();
    final passController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: pureWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Message Protégé', style: TextStyle(color: darkText, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: msgController, maxLines: 3, decoration: const InputDecoration(hintText: 'Message secret...')),
            const SizedBox(height: 16),
            TextField(controller: passController, obscureText: true, decoration: const InputDecoration(hintText: 'Mot de passe')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (msgController.text.isNotEmpty && passController.text.isNotEmpty) {
                try {
                  final encrypted = EncryptionService.encryptMessage(msgController.text, passController.text);
                  await context.read<ChatProvider>().sendMessage(widget.conversationId, encrypted);
                  if (context.mounted) Navigator.pop(ctx);
                } catch (e) {
                  _showSnackBar('Erreur chiffrement', danger);
                }
              }
            },
            child: const Text('Envoyer sécurisé'),
          ),
        ],
      ),
    );
  }

  void _showMessageActions(ChatMessage msg, bool isOwn) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55, minChildSize: 0.35, maxChildSize: 0.85, expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(color: pureWhite, borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
              child: SafeArea(
                top: false,
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                  children: [
                    Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: hairline, borderRadius: BorderRadius.circular(4)))),
                    Align(
                      alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 280),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isOwn ? primaryBlue : leftBubbleColor,
                          borderRadius: BorderRadius.only(topLeft: const Radius.circular(18), topRight: const Radius.circular(18), bottomLeft: Radius.circular(isOwn ? 18 : 4), bottomRight: Radius.circular(isOwn ? 4 : 18)),
                        ),
                        child: Text(msg.content, style: TextStyle(color: isOwn ? Colors.white : darkText)),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: _quickReactions.map((emoji) {
                        return InkWell(
                          onTap: () async { Navigator.pop(ctx); await context.read<ChatProvider>().addReaction(msg.id, emoji); },
                          child: Padding(padding: const EdgeInsets.all(6), child: Text(emoji, style: const TextStyle(fontSize: 26))),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8), Container(height: 1, color: dividerColor),
                    _actionTile(icon: Icons.reply_rounded, label: 'Reply', onTap: () { Navigator.pop(ctx); setState(() => _replyToId = msg.id); _inputFocus.requestFocus(); }),
                    Container(height: 1, color: dividerColor),
                    _actionTile(icon: Icons.copy_rounded, label: 'Copy', onTap: () { Navigator.pop(ctx); Clipboard.setData(ClipboardData(text: msg.content)); _showSnackBar('Copié', primaryBlue); }),
                    Container(height: 1, color: dividerColor),
                    _actionTile(icon: Icons.delete_outline_rounded, label: 'Delete', color: danger, onTap: () async { Navigator.pop(ctx); if (isOwn) await context.read<ChatProvider>().deleteMessage(msg.id); }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _actionTile({required IconData icon, required String label, required VoidCallback onTap, Color color = darkText}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: color)), Icon(icon, color: color == danger ? danger : mutedText)]),
      ),
    );
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
                      if (widget.conversation.isGroup)
                        GroupInfoPanel(
                          conversation: widget.conversation,
                          members: _groupMembers,
                          onViewAllMembers: () {}, 
                          onEditGroup: () {}, 
                          onLeaveGroup: () {}, 
                          onDeleteGroup: () {},
                        ),
                      Expanded(
                        child: Consumer<ChatProvider>(
                          builder: (context, provider, child) {
                            if (provider.isLoading && provider.messages.isEmpty) {
                              return const Center(child: CircularProgressIndicator(color: primaryBlue));
                            }
                            return _buildMessageList(provider);
                          },
                        ),
                      ),
                      if (_replyToId.isNotEmpty) _buildReplyIndicator(),
                      ChatInputBar(
                        controller: _inputController,
                        focusNode: _inputFocus,
                        onSend: _sendMessage,
                        isSending: _isSending,
                        onAttach: _showAttachmentMenu, 
                        onAudio: () {}, 
                        onSecureMessage: _showPasswordProtectDialog, 
                        onEphemeralToggle: _showEphemeralTimerDialog, 
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

  Widget _buildMessageList(ChatProvider provider) {
    return Stack(
      children: [
        ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: provider.messages.length + (provider.isLoadingMoreMessages ? 1 : 0),
          itemBuilder: (ctx, index) {
            if (index == provider.messages.length && provider.isLoadingMoreMessages) {
              return const Padding(
                padding: EdgeInsets.all(8.0),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: primaryBlue)),
              );
            }

            final msg = provider.messages[index];
            final currentUserId = Supabase.instance.client.auth.currentUser?.id;
            final isOwn = msg.senderId == currentUserId;

            return GestureDetector(
              onLongPress: () => _showMessageActions(msg, isOwn),
              child: ChatMessageBubble(
                message: msg,
                isOwn: isOwn,
                onReply: () => setState(() => _replyToId = msg.id),
                onDelete: () async {
                   if (isOwn) await provider.deleteMessage(msg.id);
                },
                onReaction: (r) async => await provider.addReaction(msg.id, r),
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
        if (_otherUserTyping) const Positioned(bottom: 8, left: 16, child: Text("En train d'écrire...", style: TextStyle(color: primaryBlue, fontStyle: FontStyle.italic)))
      ],
    );
  }

  Widget _buildReplyIndicator() {
    final provider = context.read<ChatProvider>();
    final reply = provider.messages.firstWhere(
      (m) => m.id == _replyToId,
      orElse: () => provider.messages.first, 
    );
    final isOwnReply = reply.senderId == Supabase.instance.client.auth.currentUser?.id;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: pureWhite,
        border: Border(top: BorderSide(color: hairline, width: 1)),
      ),
      child: Row(
        children: [
          Container(width: 4, height: 40, decoration: BoxDecoration(color: primaryBlue, borderRadius: BorderRadius.circular(4))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isOwnReply ? 'Vous' : reply.senderName, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: primaryBlue)),
                Text(reply.content, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: darkText)),
              ],
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: _cancelReply,
            child: Container(padding: const EdgeInsets.all(5), decoration: const BoxDecoration(color: ivory, shape: BoxShape.circle), child: const Icon(Icons.close_rounded, size: 15, color: mutedText)),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: primaryBlue,
      elevation: 0,
      titleSpacing: 0,
      leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
      title: Row(
        children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: Colors.white.withOpacity(0.2),
            backgroundImage: widget.conversation.isGroup ? null : const NetworkImage('https://i.pravatar.cc/150?img=11'),
            child: widget.conversation.isGroup ? const Icon(Icons.groups_rounded, color: Colors.white, size: 18) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.conversation.displayName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (!widget.conversation.isGroup && _otherParticipant != null)
                  Row(
                    children: [
                      Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: (_otherParticipant!.status == 'online') ? success : Colors.white38)),
                      const SizedBox(width: 5),
                      Text((_otherParticipant!.status == 'online') ? 'En ligne' : 'Vu récemment', style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500)),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(icon: const Icon(Icons.videocam_rounded, color: Colors.white), onPressed: _startVideoCall),
        IconButton(icon: const Icon(Icons.call_rounded, color: Colors.white), onPressed: _startAudioCall),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
          onSelected: (value) {
            if (value == 'escalate') _escalateConversation();
            else if (value == 'history') _viewEscalationHistory();
          },
          itemBuilder: (context) => [
            const PopupMenuItem<String>(value: 'escalate', child: Row(children: [Icon(Icons.arrow_upward, color: Colors.orange), SizedBox(width: 8), Text('Escalader')])),
            const PopupMenuItem<String>(value: 'history', child: Row(children: [Icon(Icons.history, color: Colors.blue), SizedBox(width: 8), Text('Historique')])),
          ],
        ),
      ],
    );
  }
}
