// lib/presentation/chat/widgets/chat_input_bar.dart
import 'package:flutter/material.dart';

class ChatInputBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final bool isSending;
  final VoidCallback? onAttach;
  final VoidCallback? onCode;
  final VoidCallback? onEphemeralToggle;
  final bool isEphemeral;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.isSending,
    this.onAttach,
    this.onCode,
    this.onEphemeralToggle,
    this.isEphemeral = false,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          // Pièce jointe
          IconButton(
            icon: const Icon(Icons.attach_file, color: Colors.grey),
            onPressed: widget.onAttach,
          ),
          // Code snippet
          IconButton(
            icon: const Icon(Icons.code, color: Colors.grey),
            onPressed: widget.onCode,
          ),
          // Éphémère
          IconButton(
            icon: Icon(
              widget.isEphemeral ? Icons.timer : Icons.timer_outlined,
              color: widget.isEphemeral ? Colors.orange : Colors.grey,
            ),
            onPressed: widget.onEphemeralToggle,
          ),
          // Champ de saisie
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
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
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => widget.onSend(),
            ),
          ),
          // Bouton d'envoi
          IconButton(
            icon: widget.isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded, color: Color(0xFFD4AF37)),
            onPressed: widget.isSending ? null : widget.onSend,
          ),
        ],
      ),
    );
  }
}
