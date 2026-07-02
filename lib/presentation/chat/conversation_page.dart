// lib/presentation/chat/conversation_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

// State Management
import 'core/chat_bloc.dart';
import 'core/chat_states.dart';
import 'core/chat_events.dart';

// Widgets
import 'widgets/chat_bubble.dart';
import 'widgets/chat_input_bar.dart';
import 'widgets/pinned_message.dart';
import 'widgets/reaction_picker.dart';
import 'widgets/attachment_picker.dart';
import 'polls/inline_poll_widget.dart';
import 'polls/poll_creator_sheet.dart';
import 'location/location_share_bubble.dart';
import 'voice/voice_message_bubble.dart';

class ConversationPage extends StatefulWidget {
  final String chatId;
  final String title;
  final String type;

  const ConversationPage({
    super.key,
    required this.chatId,
    required this.title,
    this.type = 'direct',
  });

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  late ChatBloc _chatBloc;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _chatBloc = context.read<ChatBloc>();
    _chatBloc.add(LoadMessages(widget.chatId));
    _chatBloc.add(LoadConversationDetails(widget.chatId));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    _chatBloc.add(ClearTyping(widget.chatId));
    super.dispose();
  }

  void _sendMessage(String content, {String? mediaUrl, String? type}) {
    if (content.trim().isEmpty && mediaUrl == null) return;
    _chatBloc.add(
      SendMessage(
        conversationId: widget.chatId,
        content: content.trim(),
        type: type ?? 'text',
        mediaUrl: mediaUrl,
      ),
    );
    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showPollCreator() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PollCreatorSheet(
        conversationId: widget.chatId,
        onPollCreated: (poll) {
          _chatBloc.add(SendPollMessage(
            conversationId: widget.chatId,
            poll: poll,
          ));
        },
      ),
    );
  }

  void _showAttachmentPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => AttachmentPicker(
        onImageSelected: (file) {
          _chatBloc.add(SendMediaMessage(
            conversationId: widget.chatId,
            file: file,
            type: 'image',
          ));
        },
        onFileSelected: (file) {
          _chatBloc.add(SendMediaMessage(
            conversationId: widget.chatId,
            file: file,
            type: 'file',
          ));
        },
      ),
    );
  }

  void _showReactionPicker(String messageId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ReactionPicker(
        onReactionSelected: (emoji) {
          _chatBloc.add(AddReaction(
            messageId: messageId,
            emoji: emoji,
          ));
        },
      ),
    );
  }

  void _togglePinMessage(String messageId) {
    _chatBloc.add(TogglePinMessage(
      conversationId: widget.chatId,
      messageId: messageId,
    ));
  }

  void _replyToMessage(String messageId) {
    _chatBloc.add(ReplyToMessage(
      conversationId: widget.chatId,
      messageId: messageId,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChatBloc, ChatState>(
      listener: (context, state) {
        if (state is MessageSent || state is MessagesLoaded) {
          _scrollToBottom();
        }
        if (state is ChatError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: _buildAppBar(state),
          body: Column(
            children: [
              if (state is MessagesLoaded && state.pinnedMessage != null)
                PinnedMessage(
                  message: state.pinnedMessage!,
                  onTap: () => _scrollToBottom(),
                  onUnpin: () => _togglePinMessage(state.pinnedMessage!.id),
                ),
              Expanded(
                child: state is MessagesLoading
                    ? const Center(child: CircularProgressIndicator())
                    : state is MessagesLoaded
                        ? _buildMessageList(state)
                        : const Center(child: Text('Aucun message')),
              ),
              _buildInputBar(state),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(ChatState state) {
    String subtitle = 'En ligne';
    if (state is ConversationDetailsLoaded) {
      subtitle = state.isOnline ? 'En ligne' : 'Dernière connexion: ${_formatLastSeen(state.lastSeen)}';
    }
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.phone, size: 20),
          onPressed: () => _chatBloc.add(InitiateCall(
            conversationId: widget.chatId,
            type: 'audio',
          )),
        ),
        IconButton(
          icon: const Icon(Icons.videocam, size: 20),
          onPressed: () => _chatBloc.add(InitiateCall(
            conversationId: widget.chatId,
            type: 'video',
          )),
        ),
        PopupMenuButton(
          icon: const Icon(Icons.more_vert, size: 20),
          itemBuilder: (context) => [
            const PopupMenuItem(child: Text('Voir le profil')),
            const PopupMenuItem(child: Text('Rechercher')),
            const PopupMenuItem(child: Text('Médias, liens et docs')),
            const PopupMenuItem(child: Text('Notifications')),
            const PopupMenuItem(child: Text('Épingler la conversation')),
            const PopupMenuItem(child: Text('Supprimer')),
          ],
        ),
      ],
    );
  }

  Widget _buildMessageList(MessagesLoaded state) {
    final messages = state.messages;
    final typingUsers = state.typingUsers ?? [];

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      itemCount: messages.length + (typingUsers.isNotEmpty ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length && typingUsers.isNotEmpty) {
          return _buildTypingIndicator(typingUsers);
        }
        final message = messages[index];
        return ChatBubble(
          message: message,
          onLongPress: () => _showMessageOptions(message),
          onReactionTap: () => _showReactionPicker(message.id),
          onReplyTap: () => _replyToMessage(message.id),
          isFirstInGroup: index == 0 || messages[index - 1].senderId != message.senderId,
          isLastInGroup: index == messages.length - 1 || messages[index + 1].senderId != message.senderId,
        );
      },
    );
  }

  Widget _buildTypingIndicator(List<String> users) {
    final names = users.map((id) => 'Utilisateur').join(', ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        children: [
          const SizedBox(
            width: 40,
            height: 20,
            child: Row(
              children: [
                _Dot(delay: 0),
                SizedBox(width: 4),
                _Dot(delay: 1),
                SizedBox(width: 4),
                _Dot(delay: 2),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$names est en train d\'écrire...',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(ChatState state) {
    return ChatInputBar(
      onSendMessage: _sendMessage,
      controller: _messageController,
      onTyping: (isTyping) {
        if (isTyping) {
          _chatBloc.add(StartTyping(widget.chatId));
        } else {
          _chatBloc.add(StopTyping(widget.chatId));
        }
      },
      onAttachmentPressed: _showAttachmentPicker,
      onPollPressed: _showPollCreator,
      onMicrophonePressed: () {
        _chatBloc.add(StartVoiceRecording(widget.chatId));
      },
      isSending: state is MessageSending,
    );
  }

  void _showMessageOptions(ChatMessage message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.reply, size: 20),
              title: const Text('Répondre', style: TextStyle(fontSize: 13)),
              onTap: () {
                Navigator.pop(context);
                _replyToMessage(message.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.emoji_emotions, size: 20),
              title: const Text('Réagir', style: TextStyle(fontSize: 13)),
              onTap: () {
                Navigator.pop(context);
                _showReactionPicker(message.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.push_pin, size: 20),
              title: const Text('Épingler', style: TextStyle(fontSize: 13)),
              onTap: () {
                Navigator.pop(context);
                _togglePinMessage(message.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.content_copy, size: 20),
              title: const Text('Copier', style: TextStyle(fontSize: 13)),
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: message.content));
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
              title: const Text('Supprimer', style: TextStyle(fontSize: 13, color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _chatBloc.add(DeleteMessage(messageId: message.id));
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatLastSeen(DateTime? lastSeen) {
    if (lastSeen == null) return 'inconnue';
    return timeago.format(lastSeen, locale: 'fr');
  }
}

class _Dot extends StatelessWidget {
  final int delay;
  const _Dot({required this.delay});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 400 + (delay * 200)),
      curve: Curves.easeInOut,
      width: 6,
      height: 6,
      decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle),
    );
  }
}
