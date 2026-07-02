// lib/presentation/chat/widgets/chat_input_bar.dart
import 'package:flutter/material.dart';

class ChatInputBar extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSendText;
  final ValueChanged<String> onSendVoice;
  final ValueChanged<dynamic> onAttachment;
  final VoidCallback onEphemeral;
  final VoidCallback onConfidential;

  const ChatInputBar({
    Key? key,
    required this.controller,
    required this.onSendText,
    required this.onSendVoice,
    required this.onAttachment,
    required this.onEphemeral,
    required this.onConfidential,
  }) : super(key: key);

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  bool _isRecording = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 2)],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file, size: 22),
            onPressed: () => widget.onAttachment(null),
          ),
          IconButton(
            icon: const Icon(Icons.timer_outlined, size: 22),
            onPressed: widget.onEphemeral,
          ),
          IconButton(
            icon: const Icon(Icons.lock_outline, size: 22),
            onPressed: widget.onConfidential,
          ),
          Expanded(
            child: TextField(
              controller: widget.controller,
              decoration: const InputDecoration(
                hintText: 'Tapez un message...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
              ),
              onSubmitted: widget.onSendText,
            ),
          ),
          if (!_isRecording)
            IconButton(
              icon: const Icon(Icons.send, size: 22),
              onPressed: () => widget.onSendText(widget.controller.text),
            )
          else
            IconButton(
              icon: const Icon(Icons.stop, size: 22, color: Colors.red),
              onPressed: () {
                setState(() => _isRecording = false);
                widget.onSendVoice('/temp/voice.opus');
              },
            ),
          IconButton(
            icon: Icon(_isRecording ? Icons.mic_off : Icons.mic, size: 22),
            onPressed: () => setState(() => _isRecording = !_isRecording),
          ),
        ],
      ),
    );
  }
}
