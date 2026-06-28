import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/message_model.dart';
import '../../models/conversation_model.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/messages/message_bubble.dart';
import '../../widgets/input/message_input.dart';
import '../../widgets/appbar/chat_appbar.dart';

class ConversationScreen extends ConsumerStatefulWidget {
  final String conversationId;

  const ConversationScreen({Key? key, required this.conversationId}) : super(key: key);

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  late ScrollController _scrollController;
  String? _replyingToId;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(messagesProvider);
    final conversation = ref.watch(currentConversationProvider);

    return Scaffold(
      appBar: ChatAppBar(
        title: conversation?.name ?? 'Conversation',
        subtitle: conversation?.description,
        avatarUrl: conversation?.avatarUrl,
        isGroup: conversation?.isGroup ?? false,
        memberCount: conversation?.memberIds.length ?? 0,
        onCall: () {},
        onVideoCall: () {},
        onInfo: () {},
        onMore: () {},
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 48,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun message',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isCurrentUser = message.senderId == 'current_user_id';

                      return MessageBubble(
                        message: message,
                        isCurrentUser: isCurrentUser,
                        onReply: () {
                          setState(() => _replyingToId = message.id);
                        },
                        onDelete: () {
                          ref.read(messagesProvider.notifier).deleteMessage(message.id);
                        },
                        onPin: () {
                          ref.read(messagesProvider.notifier).togglePin(message.id);
                        },
                        onReact: (emoji) {
                          ref.read(messagesProvider.notifier).addReaction(message.id, emoji);
                        },
                      );
                    },
                  ),
          ),
          MessageInput(
            replyingToName: _replyingToId != null
                ? messages.firstWhere((m) => m.id == _replyingToId).senderName
                : null,
            onCancelReply: () => setState(() => _replyingToId = null),
            onSend: (message) {
              final newMessage = Message(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                conversationId: widget.conversationId,
                senderId: 'current_user_id',
                senderName: 'Current User',
                content: message,
                type: MessageType.text,
                status: MessageStatus.sending,
                timestamp: DateTime.now(),
                replyToId: _replyingToId,
              );
              ref.read(messagesProvider.notifier).addMessage(newMessage);
              setState(() => _replyingToId = null);
              _scrollToBottom();
            },
            onAttachMedia: () {},
            onStartRecording: () {},
          ),
        ],
      ),
    );
  }
}
