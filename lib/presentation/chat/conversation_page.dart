// lib/presentation/chat/conversation_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../providers/chat_provider.dart';
import '../../models/chat_models.dart';
import 'widgets/chat_bubble.dart';
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

  // ✅ Envoi de message
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

  // ✅ Pièces jointes
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
                  // TODO: implémenter l'envoi d'image
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Image (à implémenter)')),
                  );
                }),
                _attachmentButton(Icons.insert_drive_file, 'Fichier', () {
                  Navigator.pop(context);
                  // TODO: implémenter l'envoi de fichier
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fichier (à implémenter)')),
                  );
                }),
                _attachmentButton(Icons.location_on, 'Position', () {
                  Navigator.pop(context);
                  // TODO: partager position
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Position (à implémenter)')),
                  );
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

  // ✅ Réactions
  void _showReactionPicker(String messageId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ReactionPicker(
        onReactionSelected: (emoji) {
          _chatProvider.addReaction(messageId, emoji);
        },
      ),
    );
  }

  // ✅ Message épinglé
  void _togglePinMessage(String messageId) {
    _chatProvider.pinMessage(widget.chatId, messageId);
  }

  void _replyToMessage(String messageId) {
    // TODO: implémenter la réponse
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Répondre au message $messageId (à implémenter)')),
    );
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
              _chatProvider.deleteMessage(messageId);
              Navigator.pop(context);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  // ✅ Build principal
  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final messages = chatProvider.messages;
    final isLoading = chatProvider.isLoading;
    final pinnedMessage = messages.firstWhere(
      (m) => m.isPinned,
      orElse: () => null as ChatMessage,
    );

    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          if (pinnedMessage != null)
            PinnedMessage(
              message: pinnedMessage,
              onTap: _scrollToBottom,
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

  // ✅ AppBar
  PreferredSizeWidget _buildAppBar() {
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
            // TODO: appeler
          },
        ),
        IconButton(
          icon: const Icon(Icons.videocam, size: 20),
          onPressed: () {
            // TODO: appeler vidéo
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

  // ✅ Liste des messages
  Widget _buildMessageList(List<ChatMessage> messages) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMe = message.senderId == currentUserId;

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

  // ✅ Barre de saisie simplifiée
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
                // Indicateur de saisie (à implémenter)
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

  // ✅ Menu des options du message
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
              _replyToMessage(message.id);
            }),
            _optionTile(Icons.emoji_emotions, 'Réagir', () {
              Navigator.pop(context);
              _showReactionPicker(message.id);
            }),
            _optionTile(Icons.push_pin, 'Épingler', () {
              Navigator.pop(context);
              _togglePinMessage(message.id);
            }),
            _optionTile(Icons.content_copy, 'Copier', () {
              Navigator.pop(context);
              // Copier le contenu
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
}
