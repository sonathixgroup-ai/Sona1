// lib/presentation/chat/conversation_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../providers/chat_provider.dart';
import '../../models/chat_models.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/chat_input_bar.dart';
import 'widgets/pinned_message.dart';
import 'widgets/reaction_picker.dart';
import 'widgets/attachment_picker.dart';

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
  late ChatProvider _chatProvider;

  @override
  void initState() {
    super.initState();
    _chatProvider = context.read<ChatProvider>();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    await _chatProvider.loadMessages(widget.chatId);
    _scrollToBottom();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage(String content, {String? mediaUrl, String? type}) {
    if (content.trim().isEmpty && mediaUrl == null) return;
    _chatProvider.sendMessage(
      conversationId: widget.chatId,
      content: content.trim(),
      type: _stringToMessageType(type ?? 'text'),
      mediaURL: mediaUrl,
    );
    _messageController.clear();
    _scrollToBottom();
  }

  MessageType _stringToMessageType(String type) {
    switch (type) {
      case 'image':
        return MessageType.image;
      case 'audio':
        return MessageType.audio;
      case 'video':
        return MessageType.video;
      case 'file':
        return MessageType.file;
      default:
        return MessageType.text;
    }
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

  void _showAttachmentPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => AttachmentPicker(
        onImageSelected: (file) {
          // Implémenter l'envoi d'image
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image sélectionnée (à implémenter)')),
          );
        },
        onFileSelected: (file) {
          // Implémenter l'envoi de fichier
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fichier sélectionné (à implémenter)')),
          );
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
          _chatProvider.reactToMessage(messageId, emoji);
        },
      ),
    );
  }

  void _togglePinMessage(String messageId) {
    _chatProvider.pinMessage(widget.chatId, messageId);
  }

  void _replyToMessage(String messageId) {
    // Implémenter la réponse à un message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Répondre au message $messageId (à implémenter)')),
    );
  }

  void _deleteMessage(String messageId) {
    // Implémenter la suppression
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Supprimer le message $messageId (à implémenter)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final messages = chatProvider.messages;
    final isLoading = chatProvider.isLoading;
    final pinnedMessage = messages.firstWhere((m) => m.isPinned, orElse: () => null as ChatMessage);

    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          if (pinnedMessage != null)
            PinnedMessage(
              message: pinnedMessage,
              onTap: () => _scrollToBottom(),
              onUnpin: () => _togglePinMessage(pinnedMessage.id),
            ),
          Expanded(
            child: isLoading && messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                    ? const Center(child: Text('Aucun message'))
                    : _buildMessageList(messages),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    // Récupérer le statut du contact (simplifié)
    final isOnline = false; // À remplacer par la logique réelle

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
            style: TextStyle(fontSize: 10, color: isOnline ? Colors.green : Colors.grey[500]),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.phone, size: 20),
          onPressed: () {
            // Implémenter appel audio
          },
        ),
        IconButton(
          icon: const Icon(Icons.videocam, size: 20),
          onPressed: () {
            // Implémenter appel vidéo
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

  Widget _buildMessageList(List<ChatMessage> messages) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMe = message.senderId == _chatProvider._chatService.currentUserId;
        return ChatBubble(
          message: message,
          isMe: isMe,
          onLongPress: () => _showMessageOptions(message),
          onReactionTap: () => _showReactionPicker(message.id),
          onReplyTap: () => _replyToMessage(message.id),
          isFirstInGroup: index == 0 || messages[index - 1].senderId != message.senderId,
          isLastInGroup: index == messages.length - 1 || messages[index + 1].senderId != message.senderId,
        );
      },
    );
  }

  Widget _buildInputBar() {
    return ChatInputBar(
      onSendMessage: _sendMessage,
      controller: _messageController,
      onTyping: (isTyping) {
        // Implémenter l'indicateur de saisie
      },
      onAttachmentPressed: _showAttachmentPicker,
      onPollPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Créer un sondage (à implémenter)')),
        );
      },
      onMicrophonePressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enregistrement vocal (à implémenter)')),
        );
      },
      isSending: false,
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
                // Copier le texte
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
              title: const Text('Supprimer', style: TextStyle(fontSize: 13, color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteMessage(message.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}
