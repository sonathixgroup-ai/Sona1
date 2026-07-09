// lib/presentation/chat/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  bool _isSending = false;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocus = FocusNode();
  ChatParticipant? _otherParticipant;
  String _replyToId = '';
  bool _isEphemeral = false;
  int? _ephemeralDuration;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService(Provider.of<SupabaseClient>(context, listen: false));
    _presenceService = PresenceService(Provider.of<SupabaseClient>(context, listen: false));
    WidgetsBinding.instance.addObserver(this);
    _loadMessages();
    _getParticipantInfo();
    _markAsRead();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _inputController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _markAsRead();
    }
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final msgs = await _chatService.getMessages(widget.conversationId);
      setState(() {
        _messages = msgs.reversed.toList(); // ordre chronologique
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _getParticipantInfo() async {
    if (widget.conversation.isGroup) return;
    final otherId = widget.conversation.participantIds.firstWhere(
      (id) => id != _chatService.currentUserId,
      orElse: () => '',
    );
    if (otherId.isNotEmpty) {
      final participant = await _presenceService.getUserStatus(otherId);
      setState(() => _otherParticipant = participant);
    }
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

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty && !_isSending) return;

    setState(() => _isSending = true);

    try {
      final message = await _chatService.sendMessage(
        conversationId: widget.conversationId,
        content: text,
        replyToId: _replyToId.isEmpty ? null : _replyToId,
        isEphemeral: _isEphemeral,
        ephemeralDuration: _isEphemeral ? _ephemeralDuration : null,
        // Pour le code snippet, on pourrait ajouter une logique ici
      );

      setState(() {
        _messages.add(message);
        _inputController.clear();
        _replyToId = '';
        _isSending = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _isSending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _onReply(String messageId) {
    setState(() => _replyToId = messageId);
    _inputFocus.requestFocus();
  }

  void _cancelReply() {
    setState(() => _replyToId = '');
  }

  void _toggleEphemeral() {
    setState(() {
      _isEphemeral = !_isEphemeral;
      if (_isEphemeral) {
        _ephemeralDuration = 60; // 1 minute par défaut
      } else {
        _ephemeralDuration = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isGroup = widget.conversation.isGroup;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: isGroup && widget.conversation.groupAvatar != null
                  ? NetworkImage(widget.conversation.groupAvatar!)
                  : (!isGroup && _otherParticipant?.avatarUrl != null
                      ? NetworkImage(_otherParticipant!.avatarUrl!)
                      : null),
              child: (!isGroup && _otherParticipant?.avatarUrl == null)
                  ? const Icon(Icons.person, size: 18, color: Colors.grey)
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isGroup ? (widget.conversation.groupName ?? 'Groupe') : (_otherParticipant?.displayName ?? 'Utilisateur'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  if (!isGroup && _otherParticipant != null)
                    Row(
                      children: [
                        UserStatus.presenceIndicator(_otherParticipant!.status, size: 8),
                        const SizedBox(width: 4),
                        Text(
                          UserStatus.getLabel(_otherParticipant!.status),
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        if (_otherParticipant?.customStatus != null)
                          Text(
                            ' • ${_otherParticipant!.customStatus}',
                            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                          ),
                      ],
                    ),
                  if (isGroup)
                    Text(
                      '${widget.conversation.participantIds.length} participants',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () => _showChatOptions(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[_messages.length - 1 - index];
                          final isOwn = msg.senderId == _chatService.currentUserId;
                          final showDate = index == 0 ||
                              _messages[_messages.length - 1 - index + 1].createdAt.day != msg.createdAt.day;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (showDate)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: Center(
                                    child: Text(
                                      _formatDateHeader(msg.createdAt),
                                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                    ),
                                  ),
                                ),
                              ChatMessageBubble(
                                message: msg,
                                isOwn: isOwn,
                                onReply: () => _onReply(msg.id),
                                onReaction: (reaction) => _chatService.toggleReaction(msg.id, reaction),
                                onDelete: () async {
                                  await _chatService.deleteMessage(msg.id);
                                  setState(() => _messages.removeWhere((m) => m.id == msg.id));
                                },
                                replyToMessage: msg.replyToId != null
                                    ? _messages.firstWhere(
                                        (m) => m.id == msg.replyToId,
                                        orElse: () => msg,
                                      )
                                    : null,
                                isEphemeralActive: msg.isEphemeral,
                              ),
                            ],
                          );
                        },
                      ),
          ),
          if (_replyToId.isNotEmpty)
            _buildReplyIndicator(),
          ChatInputBar(
            controller: _inputController,
            focusNode: _inputFocus,
            onSend: _sendMessage,
            isSending: _isSending,
            onAttach: () => _showAttachmentOptions(),
            onCode: () => _showCodeSnippetDialog(),
            onEphemeralToggle: _toggleEphemeral,
            isEphemeral: _isEphemeral,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('Aucun message', style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text('Envoyez le premier message !', style: TextStyle(color: Colors.grey[400])),
        ],
      ),
    );
  }

  Widget _buildReplyIndicator() {
    final replyMsg = _messages.firstWhere(
      (m) => m.id == _replyToId,
      orElse: () => _messages.first,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Réponse à ${replyMsg.senderId == _chatService.currentUserId ? 'vous' : '...'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  replyMsg.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: _cancelReply,
          ),
        ],
      ),
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    if (date.day == now.day && date.month == now.month && date.year == now.year) {
      return "Aujourd'hui";
    } else if (date.day == now.day - 1) {
      return 'Hier';
    } else {
      return DateFormat('d MMM yyyy').format(date);
    }
  }

  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Ajouter un participant'),
              onTap: () {
                Navigator.pop(context);
                // Implémenter l'ajout
              },
            ),
            ListTile(
              leading: const Icon(Icons.push_pin_outlined),
              title: const Text('Épingler la conversation'),
              onTap: () {
                Navigator.pop(context);
                _chatService.togglePinned(widget.conversationId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Supprimer la conversation'),
              onTap: () {
                Navigator.pop(context);
                // Implémenter la suppression
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachmentOptions() {
    // Implémenter la sélection d'images/documents
    showModalBottomSheet(
      context: context,
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Photo depuis la galerie'),
            onTap: () {
              Navigator.pop(context);
              // Implémenter
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Prendre une photo'),
            onTap: () {
              Navigator.pop(context);
              // Implémenter
            },
          ),
          ListTile(
            leading: const Icon(Icons.insert_drive_file),
            title: const Text('Document'),
            onTap: () {
              Navigator.pop(context);
              // Implémenter
            },
          ),
        ],
      ),
    );
  }

  void _showCodeSnippetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('💻 Code snippet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: 'dart',
              items: const [
                DropdownMenuItem(value: 'dart', child: Text('Dart')),
                DropdownMenuItem(value: 'python', child: Text('Python')),
                DropdownMenuItem(value: 'javascript', child: Text('JavaScript')),
                DropdownMenuItem(value: 'html', child: Text('HTML')),
                DropdownMenuItem(value: 'json', child: Text('JSON')),
              ],
              onChanged: (value) {},
              decoration: const InputDecoration(labelText: 'Langage'),
            ),
            const SizedBox(height: 8),
            TextField(
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Collez votre code ici...',
                border: OutlineInputBorder(),
              ),
              controller: TextEditingController(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Envoyer le code en message
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
            ),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }
}
