import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/chat/chat_service.dart';
import '../../services/chat/presence_service.dart';
import '../../models/chat/chat_message.dart';
import '../../models/chat/chat_conversation.dart';
import '../../models/chat/user_status.dart';
import '../../models/chat/chat_participant.dart';
import 'widgets/chat_message_bubble.dart';
import 'widgets/chat_input_bar.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final ChatConversation conversation;

  const ChatScreen({super.key, required this.conversationId, required this.conversation});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
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
    _chatService = ChatService(Supabase.instance.client);
    _presenceService = PresenceService(Supabase.instance.client);
    _loadMessages();
    _getParticipantInfo();
    _markAsRead();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _inputController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final msgs = await _chatService.getMessages(widget.conversationId);
      setState(() {
        _messages = msgs.reversed.toList();
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _isLoading = false);
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
      _scrollController.animateTo(0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isSending) return;
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
    }
  }

  void _toggleEphemeral() {
    setState(() {
      _isEphemeral = !_isEphemeral;
      _ephemeralDuration = _isEphemeral ? 60 : null;
    });
  }

  void _cancelReply() => setState(() => _replyToId = '');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.conversation.displayName),
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    itemCount: _messages.length,
                    itemBuilder: (ctx, index) {
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
                            ? _messages.firstWhere((m) => m.id == msg.replyToId,
                                orElse: () => msg)
                            : null,
                        isEphemeralActive: msg.isEphemeral,
                      );
                    },
                  ),
          ),
          if (_replyToId.isNotEmpty) _buildReplyIndicator(),
          ChatInputBar(
            controller: _inputController,
            focusNode: _inputFocus,
            onSend: _sendMessage,
            isSending: _isSending,
            onAttach: () {},
            onCode: () {},
            onEphemeralToggle: _toggleEphemeral,
            isEphemeral: _isEphemeral,
          ),
        ],
      ),
    );
  }

  Widget _buildReplyIndicator() {
    final reply = _messages.firstWhere((m) => m.id == _replyToId, orElse: () => _messages.first);
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.grey[100],
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Réponse à ${reply.senderId == _chatService.currentUserId ? 'vous' : '...'}'),
              Text(reply.content, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        IconButton(onPressed: _cancelReply, icon: const Icon(Icons.close)),
      ]),
    );
  }
}
