import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/message_model.dart';
import '../../models/ai_models.dart';
import '../../providers/ai_chat_provider.dart';

class MessageBubble extends StatefulWidget {
  final Message message;
  final bool isCurrentUser;
  final String conversationId;
  final VoidCallback? onReply;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onPin;
  final Function(String emoji)? onReact;
  final VoidCallback? onForward;
  final VoidCallback? onTranslate;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isCurrentUser,
    required this.conversationId,
    this.onReply,
    this.onEdit,
    this.onDelete,
    this.onPin,
    this.onReact,
    this.onForward,
    this.onTranslate,
  }) : super(key: key);

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _showActions = false;
  bool _showInlineAi = false;
  bool _loadingAi = false;
  AIChatResult? _aiResult;
  String _translateLang = 'fr';

  List<String> _conversationPreview() {
    final content = widget.message.content.trim();
    return content.isEmpty ? const [] : [content];
  }

  Future<void> _translateCurrentMessage() async {
    setState(() {
      _loadingAi = true;
      _showInlineAi = true;
    });

    try {
      final service = context.read(aiChatServiceProvider);
      final result = await service.translateMessage(
        conversationId: widget.conversationId,
        message: widget.message.content,
        targetLanguage: _translateLang,
      );
      if (!mounted) return;
      setState(() {
        _aiResult = result;
        _loadingAi = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingAi = false);
    }
  }

  Future<void> _suggestContextReplies() async {
    setState(() {
      _loadingAi = true;
      _showInlineAi = true;
    });

    try {
      final service = context.read(aiChatServiceProvider);
      final result = await service.generateSmartReplies(
        conversationId: widget.conversationId,
        messages: _conversationPreview(),
      );
      if (!mounted) return;
      setState(() {
        _aiResult = result;
        _loadingAi = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingAi = false);
    }
  }

  Widget _buildInlineAiPanel() {
    if (!_showInlineAi) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Card(
        elevation: 0,
        color: Colors.grey.shade100,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: _loadingAi
              ? const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Analyse IA en cours...'),
                  ],
                )
              : _aiResult == null
                  ? const Text('Aucun résultat IA.')
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_aiResult!.translation != null) ...[
                          const Text(
                            'Traduction',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(_aiResult!.translation!),
                          const SizedBox(height: 8),
                        ],
                        if (_aiResult!.summary != null) ...[
                          const Text(
                            'Résumé',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(_aiResult!.summary!),
                          const SizedBox(height: 8),
                        ],
                        if (_aiResult!.sentiment != null) ...[
                          Row(
                            children: [
                              const Text(
                                'Sentiment: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${_aiResult!.sentiment} '
                                '(${(_aiResult!.confidence ?? 0).toStringAsFixed(2)})',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (_aiResult!.smartReplies.isNotEmpty) ...[
                          const Text(
                            'Réponses suggérées',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _aiResult!.smartReplies.map((reply) {
                              return ActionChip(
                                label: Text(reply),
                                onPressed: () {},
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        crossAxisAlignment:
            widget.isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          MouseRegion(
            onEnter: (_) => setState(() => _showActions = true),
            onExit: (_) => setState(() => _showActions = false),
            child: GestureDetector(
              onLongPress: () => setState(() => _showActions = !_showActions),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                decoration: BoxDecoration(
                  color: widget.isCurrentUser
                      ? const Color(0xFF5A67D8)
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(12),
                child: _buildMessageContent(),
              ),
            ),
          ),
          if (_showActions)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _buildActionButtons(),
            ),
          if (widget.message.reactionCounts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: _buildReactions(),
            ),
          _buildInlineAiPanel(),
        ],
      ),
    );
  }

  Widget _buildMessageContent() {
    switch (widget.message.type) {
      case MessageType.text:
        return Text(
          widget.message.content,
          style: TextStyle(
            color: widget.isCurrentUser ? Colors.white : Colors.black,
            fontSize: 14,
          ),
        );
      case MessageType.image:
        return Image.network(
          widget.message.attachments.isNotEmpty
              ? widget.message.attachments[0].url
              : '',
          fit: BoxFit.cover,
          width: 200,
          height: 200,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 200,
              height: 200,
              color: Colors.grey[300],
              child: const Icon(Icons.error),
            );
          },
        );
      case MessageType.video:
        return Container(
          width: 200,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Icon(Icons.play_circle, size: 48, color: Colors.white),
          ),
        );
      case MessageType.audio:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.play_circle,
              color: widget.isCurrentUser ? Colors.white : Colors.black,
            ),
            const SizedBox(width: 8),
            Text(
              'Audio Message',
              style: TextStyle(
                color: widget.isCurrentUser ? Colors.white : Colors.black,
              ),
            ),
          ],
        );
      case MessageType.file:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.attachment,
              color: widget.isCurrentUser ? Colors.white : Colors.black,
            ),
            const SizedBox(width: 8),
            Text(
              widget.message.attachments.isNotEmpty
                  ? widget.message.attachments[0].fileName
                  : 'File',
              style: TextStyle(
                color: widget.isCurrentUser ? Colors.white : Colors.black,
              ),
            ),
          ],
        );
      default:
        return Text(
          widget.message.content,
          style: TextStyle(
            color: widget.isCurrentUser ? Colors.white : Colors.black,
          ),
        );
    }
  }

  Widget _buildActionButtons() {
    return Wrap(
      spacing: 8,
      children: [
        _buildActionButton(Icons.reply, 'Répondre', widget.onReply),
        if (widget.isCurrentUser)
          _buildActionButton(Icons.edit, 'Modifier', widget.onEdit),
        _buildActionButton(Icons.push_pin, 'Épingler', widget.onPin),
        _buildActionButton(Icons.add_reaction, 'Réagir', () {}),
        _buildActionButton(Icons.forward, 'Transférer', widget.onForward),
        if (!widget.isCurrentUser)
          _buildActionButton(Icons.translate, 'Traduire', () {
            setState(() {
              _showInlineAi = true;
            });
            _translateCurrentMessage();
          }),
        _buildActionButton(Icons.auto_awesome, 'AI', () {
          setState(() {
            _showInlineAi = true;
          });
          _suggestContextReplies();
        }),
        if (widget.isCurrentUser)
          _buildActionButton(Icons.delete, 'Supprimer', widget.onDelete,
              color: Colors.red),
      ],
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    VoidCallback? onTap, {
    Color color = const Color(0xFF5A67D8),
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Chip(
        avatar: Icon(icon, size: 16, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
        backgroundColor: color,
      ),
    );
  }

  Widget _buildReactions() {
    return Wrap(
      spacing: 4,
      children: widget.message.reactionCounts.entries.map((e) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${e.key} ${e.value}',
            style: const TextStyle(fontSize: 12),
          ),
        );
      }).toList(),
    );
  }
}
