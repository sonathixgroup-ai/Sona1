import 'package:flutter/material.dart';

class ChatInputBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final bool isSending;
  final VoidCallback onAttach;
  final VoidCallback onAudio; // 🎙️ Enregistrement audio (micro)
  final VoidCallback onSecureMessage; // 🔒 Message protégé par mot de passe
  final VoidCallback onEphemeralToggle;
  final bool isEphemeral;
  final ValueChanged<String>? onTyping;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.isSending,
    required this.onAttach,
    required this.onAudio,
    required this.onSecureMessage,
    required this.onEphemeralToggle,
    required this.isEphemeral,
    this.onTyping,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  // Couleurs de la charte THIX ID
  static const Color navyDeep = Color(0xFF0A1F44);
  static const Color gold = Color(0xFFE3B23C);
  static const Color navy = Color(0xFF123B7A);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // 1. Bouton Timer (message éphémère)
            IconButton(
              icon: Icon(
                widget.isEphemeral ? Icons.timer_rounded : Icons.timer_outlined,
                color: widget.isEphemeral ? gold : Colors.grey.shade600,
              ),
              onPressed: widget.onEphemeralToggle,
              tooltip: 'Message éphémère',
            ),

            // 2. Bouton Attachement (pièce jointe)
            IconButton(
              icon: Icon(Icons.add_circle_outline_rounded, color: Colors.grey.shade600),
              onPressed: widget.onAttach,
              tooltip: 'Pièce jointe',
            ),

            // 3. Champ de saisie
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                onChanged: widget.onTyping,
                decoration: InputDecoration(
                  hintText: 'Écrire un message...',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),

            // 4. Bouton Cadenas (message protégé par mot de passe)
            IconButton(
              icon: const Icon(Icons.lock_outline_rounded, color: Colors.grey),
              onPressed: widget.onSecureMessage,
              tooltip: 'Message protégé par mot de passe',
            ),

            // 5. Bouton Micro (enregistrement audio)
            IconButton(
              icon: const Icon(Icons.mic_none_rounded, color: Colors.grey),
              onPressed: widget.onAudio,
              tooltip: 'Message vocal',
            ),

            // 6. Bouton Envoi
            IconButton(
              icon: widget.isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: navyDeep),
                    )
                  : const Icon(Icons.send_rounded, color: navyDeep),
              onPressed: widget.isSending ? null : widget.onSend,
              tooltip: 'Envoyer',
            ),
          ],
        ),
      ),
    );
  }
}
