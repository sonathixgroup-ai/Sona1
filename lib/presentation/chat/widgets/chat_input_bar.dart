import 'package:flutter/material.dart';

class ChatInputBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final bool isSending;
  final VoidCallback onAttach;
  final VoidCallback onCode;
  final VoidCallback onEphemeralToggle;
  final bool isEphemeral;
  final ValueChanged<String>? onTyping; // 👈 Ajouté

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.isSending,
    required this.onAttach,
    required this.onCode,
    required this.onEphemeralToggle,
    required this.isEphemeral,
    this.onTyping, // 👈 Ajouté
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              widget.isEphemeral ? Icons.timer : Icons.timer_outlined,
              color: widget.isEphemeral ? Colors.orange : Colors.grey,
            ),
            onPressed: widget.onEphemeralToggle,
          ),
          IconButton(
            icon: const Icon(Icons.attach_file, color: Colors.grey),
            onPressed: widget.onAttach,
          ),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              onChanged: widget.onTyping, // 👈 Appel du callback
              decoration: InputDecoration(
                hintText: 'Écrire un message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.code, color: Colors.grey),
            onPressed: widget.onCode,
          ),
          IconButton(
            icon: widget.isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send, color: Colors.blue),
            onPressed: widget.isSending ? null : widget.onSend,
          ),
        ],
      ),
    );
  }
}
