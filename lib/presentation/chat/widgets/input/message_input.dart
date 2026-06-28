import 'package:flutter/material.dart';

class MessageInput extends StatefulWidget {
  final Function(String) onSend;
  final VoidCallback? onAttachMedia;
  final VoidCallback? onStartRecording;
  final Function(String emoji)? onEmojiSelect;
  final Function(String)? onMention;
  final String? replyingToName;
  final VoidCallback? onCancelReply;

  const MessageInput({
    Key? key,
    required this.onSend,
    this.onAttachMedia,
    this.onStartRecording,
    this.onEmojiSelect,
    this.onMention,
    this.replyingToName,
    this.onCancelReply,
  }) : super(key: key);

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  late TextEditingController _controller;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSend() {
    if (_controller.text.trim().isNotEmpty) {
      widget.onSend(_controller.text);
      _controller.clear();
      setState(() => _isTyping = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.replyingToName != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                const Icon(Icons.reply, color: Color(0xFF5A67D8), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Répondre à ${widget.replyingToName}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                GestureDetector(
                  onTap: widget.onCancelReply,
                  child: const Icon(Icons.close, size: 18),
                ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey[200]!)),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: widget.onAttachMedia,
                child: const Icon(
                  Icons.attachment,
                  color: Color(0xFF5A67D8),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _controller,
                    onChanged: (value) {
                      setState(() => _isTyping = value.isNotEmpty);
                    },
                    decoration: const InputDecoration(
                      hintText: 'Écrivez un message...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: widget.onStartRecording,
                child: const Icon(
                  Icons.mic,
                  color: Color(0xFF5A67D8),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _handleSend,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFF5A67D8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isTyping ? Icons.send : Icons.add,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
