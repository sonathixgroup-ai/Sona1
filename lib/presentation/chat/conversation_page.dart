// lib/presentation/chat/conversation_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'core/chat_bloc.dart';
import 'core/chat_states.dart';
import 'core/chat_events.dart';
import 'core/chat_models.dart';
import 'core/chat_constants.dart';
import 'widgets/reaction_picker.dart';

const _navy = Color(0xFF1B2A4A);
const _blue = Color(0xFF2F5CF0);
const _gold = Color(0xFFC9962C);
const _bgGrey = Color(0xFFF3F5FB);

class ConversationPage extends StatefulWidget {
  final String chatId;
  final String title;
  final String type;
  final String? avatarUrl;
  final bool isVerified;
  final bool isOnline;

  const ConversationPage({
    super.key,
    required this.chatId,
    required this.title,
    this.type = 'direct',
    this.avatarUrl,
    this.isVerified = false,
    this.isOnline = false,
  });

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  late ChatBloc _chatBloc;

  // Suggestions de réponses rapides (à terme, générées dynamiquement / IA)
  final List<String> _quickReplies = const ['Parfait !', 'Merci !', 'Je regarde ça', '👍'];

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
            _optionTile(
              isPinned ? Icons.push_pin_outlined : Icons.push_pin,
              isPinned ? 'Désépingler' : 'Épingler',
              () {
                Navigator.pop(context);
                _togglePinMessage(message.id, isPinned: isPinned);
              },
            ),
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
      backgroundColor: _bgGrey,
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
            return Center(child: Text('Erreur : ${state.message}'));
          }
          if (state is MessagesLoaded && state.conversationId == widget.chatId) {
            return Column(
              children: [
                if (state.pinnedMessage != null)
                  _PinnedBanner(
                    message: state.pinnedMessage!,
                    onTap: _scrollToBottom,
                  ),
                Expanded(
                  child: state.messages.isEmpty
                      ? const Center(child: Text('Aucun message'))
                      : _buildMessageList(state.messages),
                ),
                if (_quickReplies.isNotEmpty) _buildQuickReplies(),
                _buildInputBar(),
                _buildQuickAccessToolbar(),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  // ---------- APP BAR ----------
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leadingWidth: 40,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: _navy, size: 22),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage:
                    widget.avatarUrl != null ? NetworkImage(widget.avatarUrl!) : null,
                backgroundColor: Colors.grey.shade200,
              ),
              if (widget.isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _navy,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified, color: _blue, size: 16),
                    ],
                  ],
                ),
                Text(
                  widget.isOnline ? 'En ligne' : 'Hors ligne',
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.isOnline ? Colors.green : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.phone, color: _navy, size: 22),
          onPressed: () {
            // TODO : appel audio
          },
        ),
        IconButton(
          icon: const Icon(Icons.videocam, color: _navy, size: 24),
          onPressed: () {
            // TODO : appel vidéo
          },
        ),
        PopupMenuButton(
          icon: const Icon(Icons.more_vert, color: _navy, size: 22),
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

  // ---------- MESSAGE LIST WITH DATE SEPARATORS ----------
  Widget _buildMessageList(List<Message> messages) {
    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMe = message.senderId == _chatBloc.currentUserId;
        final isPinned = message.metadata?['pinned'] == true;

        final showDateSeparator = index == messages.length - 1 ||
            !_isSameDay(messages[index + 1].createdAt, message.createdAt);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MessageBubble(
              message: message,
              isMe: isMe,
              avatarUrl: widget.avatarUrl,
              onLongPress: () => _showMessageOptions(message, isPinned: isPinned),
              onReactionAdd: () => _showReactionPicker(message.id),
            ),
            if (showDateSeparator) _DateSeparator(date: message.createdAt),
          ],
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // ---------- QUICK REPLIES ----------
  Widget _buildQuickReplies() {
    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _quickReplies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final reply = _quickReplies[index];
          return GestureDetector(
            onTap: () => _sendMessage(reply),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              alignment: Alignment.center,
              child: Text(reply, style: const TextStyle(fontSize: 13, color: _navy)),
            ),
          );
        },
      ),
    );
  }

  // ---------- INPUT BAR ----------
  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              // TODO : ouvrir menu d'actions rapides (+)
            },
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(color: _blue, shape: BoxShape.circle),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F1F5),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Tapez un message...',
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      style: const TextStyle(fontSize: 13),
                      onChanged: (text) {
                        // TODO : indicateur de saisie
                      },
                      onSubmitted: (text) => _sendMessage(text),
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.emoji_emotions_outlined,
                        size: 20, color: Colors.grey),
                    onPressed: () {
                      // TODO : sélecteur d'emoji
                    },
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.attach_file, size: 20, color: Colors.grey),
                    onPressed: () {
                      // TODO : pièce jointe
                    },
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.camera_alt_outlined, size: 20, color: Colors.grey),
                    onPressed: () {
                      // TODO : caméra
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              if (_messageController.text.trim().isEmpty) {
                // TODO : démarrer l'enregistrement vocal
              } else {
                _sendMessage(_messageController.text);
              }
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: _blue, shape: BoxShape.circle),
              child: Icon(
                _messageController.text.trim().isEmpty ? Icons.mic : Icons.send,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- QUICK ACCESS TOOLBAR ----------
  Widget _buildQuickAccessToolbar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _quickAccessItem(Icons.image_outlined, 'Galerie', () {
            // TODO : galerie
          }),
          _quickAccessItem(Icons.insert_drive_file_outlined, 'Document', () {
            // TODO : document
          }),
          _quickAccessItem(Icons.location_on_outlined, 'Localisation', () {
            // TODO : localisation
          }),
          _quickAccessItem(Icons.person_outline, 'Contact', () {
            // TODO : contact
          }),
          _quickAccessItem(Icons.credit_card_outlined, 'Paiement', () {
            // TODO : paiement THIX Money
          }),
        ],
      ),
    );
  }

  Widget _quickAccessItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _navy, size: 22),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}

// ================= WIDGETS AUXILIAIRES =================

class _PinnedBanner extends StatelessWidget {
  final Message message;
  final VoidCallback onTap;

  const _PinnedBanner({required this.message, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.push_pin, color: _blue, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Message épinglé',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _navy),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message.content,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _DateSeparator extends StatelessWidget {
  final DateTime date;
  const _DateSeparator({required this.date});

  String _label() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return "Aujourd'hui";
    if (d == today.subtract(const Duration(days: 1))) return 'Hier';
    return DateFormat('dd MMM yyyy', 'fr_FR').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            _label(),
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final String? avatarUrl;
  final VoidCallback onLongPress;
  final VoidCallback onReactionAdd;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.onLongPress,
    required this.onReactionAdd,
    this.avatarUrl,
  });

  String get _time => DateFormat('HH:mm').format(message.createdAt);

  @override
  Widget build(BuildContext context) {
    final align = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final mainAlign = isMe ? MainAxisAlignment.end : MainAxisAlignment.start;

    Widget bubbleContent;
    switch (message.type) {
      case 'file':
        bubbleContent = _buildFileBubble();
        break;
      case 'audio':
        bubbleContent = _buildAudioBubble();
        break;
      default:
        bubbleContent = _buildTextBubble();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Row(
            mainAxisAlignment: mainAlign,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onLongPress: onLongPress,
                child: bubbleContent,
              ),
            ],
          ),
          if (message.reactions != null && message.reactions!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: _ReactionsRow(
                reactions: message.reactions!,
                onAdd: onReactionAdd,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextBubble() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isMe ? _blue : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMe ? 16 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            message.content,
            style: TextStyle(
              fontSize: 14,
              color: isMe ? Colors.white : _navy,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _time,
                style: TextStyle(
                  fontSize: 10,
                  color: isMe ? Colors.white70 : Colors.grey,
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 4),
                Icon(
                  message.status == 'read' ? Icons.done_all : Icons.done,
                  size: 14,
                  color: message.status == 'read' ? Colors.lightBlueAccent : Colors.white70,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFileBubble() {
    final fileName = message.metadata?['fileName'] ?? 'Fichier';
    final fileSize = message.metadata?['fileSize'] ?? '';
    final fileType = message.metadata?['fileType'] ?? 'PDF';

    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.red.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fileName,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text('$fileSize • $fileType',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              const Icon(Icons.more_vert, size: 18, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_time, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
              if (isMe) ...[
                const SizedBox(width: 4),
                const Icon(Icons.done_all, size: 14, color: _blue),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAudioBubble() {
    final duration = message.metadata?['audioDuration'] ?? '0:00';

    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? _blue : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              // TODO : lecture du message vocal
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isMe ? Colors.white : _blue,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.play_arrow,
                  color: isMe ? _blue : Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Placeholder waveform — remplace par un vrai composant waveform
                CustomPaint(
                  size: const Size(double.infinity, 24),
                  painter: _WaveformPainter(
                    color: isMe ? Colors.white : Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(duration,
                        style: TextStyle(
                            fontSize: 10,
                            color: isMe ? Colors.white70 : Colors.grey)),
                    Text(_time,
                        style: TextStyle(
                            fontSize: 10,
                            color: isMe ? Colors.white70 : Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 14,
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
            backgroundColor: Colors.grey.shade200,
          ),
        ],
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final Color color;
  _WaveformPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final barCount = 30;
    final barWidth = size.width / barCount;
    for (int i = 0; i < barCount; i++) {
      final heightFactor = (i % 4 == 0) ? 0.9 : (i % 3 == 0 ? 0.5 : 0.3);
      final x = i * barWidth;
      final barHeight = size.height * heightFactor;
      canvas.drawLine(
        Offset(x, size.height / 2 - barHeight / 2),
        Offset(x, size.height / 2 + barHeight / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ReactionsRow extends StatelessWidget {
  final Map<String, int> reactions;
  final VoidCallback onAdd;

  const _ReactionsRow({required this.reactions, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...reactions.entries.map((entry) => Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(entry.key, style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text('${entry.value}',
                      style: const TextStyle(
                          fontSize: 11, color: _blue, fontWeight: FontWeight.w600)),
                ],
              ),
            )),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(color: _blue, shape: BoxShape.circle),
            child: const Icon(Icons.add_reaction_outlined, size: 13, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
