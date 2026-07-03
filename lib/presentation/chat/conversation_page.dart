// lib/presentation/chat/conversation_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/chat_bloc.dart';
import 'core/chat_states.dart';
import 'core/chat_events.dart';
import 'core/chat_models.dart';
import 'core/chat_constants.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/pinned_message.dart';
import 'widgets/reaction_picker.dart';

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
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  late ChatBloc _chatBloc;

  @override
  void initState() {
    super.initState();
    _chatBloc = context.read<ChatBloc>();
    _chatBloc.add(LoadMessages(widget.chatId));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage(String content) {
    if (content.trim().isEmpty) return;
    _chatBloc.add(SendMessage(
      conversationId: widget.chatId,
      type: ChatConstants.messageTypeText,
      content: content.trim(),
    ));
    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.minScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showAttachmentPicker() {
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
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _attachmentButton(Icons.image, 'Image', () {
                  Navigator.pop(context);
                  // TODO : envoi d'image
                }),
                _attachmentButton(Icons.insert_drive_file, 'Fichier', () {
                  Navigator.pop(context);
                  // TODO : envoi de fichier
                }),
                _attachmentButton(Icons.location_on, 'Position', () {
                  Navigator.pop(context);
                  // TODO : envoi de position
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _attachmentButton(IconData icon, String label, VoidCallback onTap) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 24, color: Colors.grey[700]),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  void _showReactionPicker(String messageId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ReactionPicker(
        onReactionSelected: (emoji) {
          _chatBloc.add(AddReaction(messageId, emoji));
        },
      ),
    );
  }

  void _togglePinMessage(String messageId, {required bool isPinned}) {
    if (isPinned) {
      _chatBloc.add(UnpinMessage(widget.chatId, messageId));
    } else {
      _chatBloc.add(PinMessage(widget.chatId, messageId));
    }
  }

  void _deleteMessage(String messageId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le message'),
        content: const Text('Voulez-vous vraiment supprimer ce message ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              _chatBloc.add(DeleteMessage(messageId));
              Navigator.pop(context);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showMessageOptions(Message message, {required bool isPinned}) {
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
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            _optionTile(Icons.reply, 'Répondre', () {
              Navigator.pop(context);
              // TODO : répondre
            }),
            _optionTile(Icons.emoji_emotions, 'Réagir', () {
              Navigator.pop(context);
              _showReactionPicker(message.id);
            }),
            _optionTile(isPinned ? Icons.push_pin_outlined : Icons.push_pin, isPinned ? 'Désépingler' : 'Épingler', () {
              Navigator.pop(context);
              _togglePinMessage(message.id, isPinned: isPinned);
            }),
            _optionTile(Icons.content_copy, 'Copier', () {
              Navigator.pop(context);
              // TODO : copier
            }),
            _optionTile(Icons.delete_outline, 'Supprimer', () {
              Navigator.pop(context);
              _deleteMessage(message.id);
            }, color: Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _optionTile(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, size: 20, color: color ?? Colors.grey[700]),
      title: Text(title, style: TextStyle(fontSize: 13, color: color ?? Colors.black87)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: BlocConsumer<ChatBloc, ChatState>(
        listener: (context, state) {
          if (state is MessageSentSuccess) {
            _scrollToBottom();
          }
        },
        builder: (context, state) {
          if (state is ChatLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ChatError) {
            return Center(child: Text('Erreur: ${state.message}'));
          }
          if (state is MessagesLoaded && state.conversationId == widget.chatId) {
            return Column(
              children: [
                if (state.pinnedMessage != null)
                  PinnedMessage(
                    message: state.pinnedMessage!,
                    onTap: _scrollToBottom,
                    onUnpin: () => _togglePinMessage(state.pinnedMessage!.id, isPinned: true),
                  ),
                Expanded(
                  child: state.messages.isEmpty
                      ? const Center(child: Text('Aucun message'))
                      : _buildMessageList(state.messages),
                ),
                _buildInputBar(),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final isOnline = false; // À remplacer par la logique réelle (présence)

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
            isOnline ? 'En ligne' : 'Hors ligne',
            style: TextStyle(
              fontSize: 10,
              color: isOnline ? Colors.green : Colors.grey[500],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.phone, size: 20),
          onPressed: () {
            // TODO : appel audio
          },
        ),
        IconButton(
          icon: const Icon(Icons.videocam, size: 20),
          onPressed: () {
            // TODO : appel vidéo
          },
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

  Widget _buildMessageList(List<Message> messages) {
    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMe = message.senderId == _chatBloc.currentUserId;
        final isPinned = message.metadata?['pinned'] == true;

        return ChatBubble(
          message: message,
          isMe: isMe,
          onLongPress: () => _showMessageOptions(message, isPinned: isPinned),
          onReactionTap: () => _showReactionPicker(message.id),
          onReplyTap: () {
            // TODO : répondre
          },
          isFirstInGroup: index == messages.length - 1 ||
              messages[index + 1].senderId != message.senderId,
          isLastInGroup: index == 0 ||
              messages[index - 1].senderId != message.senderId,
        );
      },
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file, size: 20),
            onPressed: _showAttachmentPicker,
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Tapez un message...',
                hintStyle: const TextStyle(fontSize: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              style: const TextStyle(fontSize: 13),
              onChanged: (text) {
                // TODO : indicateur de saisie
              },
              onSubmitted: (text) => _sendMessage(text),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, size: 20, color: Color(0xFFD4AF37)),
            onPressed: () => _sendMessage(_messageController.text),
          ),
        ],
      ),
    );
  }
}
