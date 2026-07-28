import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _C {
  static const bg = Colors.white;
  static const searchBg = Color(0xFFF8FAFC);
  static const border = Color(0xFFE2E8F0);
  static const primary = Color(0xFF1D4ED8);
  static const primaryLight = Color(0xFFEFF6FF);
  static const textMain = Color(0xFF0F172A);
  static const textMuted = Color(0xFF64748B);
}

class ChatInputBar extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final bool isSending;
  final VoidCallback onAttach;
  final VoidCallback onAudio;
  final VoidCallback onSecureMessage;
  final VoidCallback onEphemeralToggle;
  final bool isEphemeral;
  final ValueChanged<String>? onTyping;
  final VoidCallback? onInternalNoteToggle;
  final VoidCallback? onStickerTap;
  final bool isInternalNote;

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
    this.onInternalNoteToggle,
    this.onStickerTap,
    this.isInternalNote = false,
  });

  @override
  ConsumerState<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends ConsumerState<ChatInputBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _hasText = widget.controller.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final has = widget.controller.text.trim().isNotEmpty;
    if (_hasText != has) setState(() => _hasText = has);
  }

  @override
  Widget build(BuildContext context) {
    final isNote = widget.isInternalNote;

    return Container(
      decoration: BoxDecoration(
        color: isNote ? const Color(0xFFFFF7ED) : _C.bg,
        border: Border(top: BorderSide(color: isNote ? const Color(0xFFFED7AA) : _C.border)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  _btn(icon: Icons.attach_file_rounded, label: 'Fichier', onTap: widget.onAttach),
                  _btn(icon: Icons.emoji_emotions_outlined, label: 'Sticker', onTap: widget.onStickerTap ?? () {}, isActive: widget.onStickerTap != null ? false : false),
                  _btn(icon: widget.isEphemeral ? Icons.timer_rounded : Icons.timer_outlined, label: 'Éphémère', onTap: widget.onEphemeralToggle, isActive: widget.isEphemeral),
                  _btn(icon: Icons.lock_outline_rounded, label: 'Protégé', onTap: widget.onSecureMessage),
                  _btn(icon: Icons.mic_none_rounded, label: 'Audio', onTap: widget.onAudio),
                  if (widget.onInternalNoteToggle != null)
                    _btn(icon: Icons.speaker_notes_outlined, label: 'Note', onTap: widget.onInternalNoteToggle!, isActive: isNote, activeColor: const Color(0xFFEA580C)),
                  if (_hasText)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text('${widget.controller.text.length}', style: const TextStyle(fontSize: 10, color: _C.textMuted, fontWeight: FontWeight.w500)),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 42, maxHeight: 110),
                      child: TextField(
                        controller: widget.controller,
                        focusNode: widget.focusNode,
                        onChanged: widget.onTyping,
                        maxLines: null,
                        minLines: 1,
                        style: const TextStyle(color: _C.textMain, fontSize: 14, fontWeight: FontWeight.w500),
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          hintText: isNote ? 'Note interne...' : 'Écrire un message...',
                          hintStyle: const TextStyle(color: _C.textMuted, fontSize: 13),
                          filled: true,
                          fillColor: isNote ? Colors.white : _C.searchBg,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: _C.border)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: _C.border)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: isNote ? const Color(0xFFFDBA74) : _C.primary, width: 1.2)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: (widget.isSending || !_hasText) ? null : widget.onSend,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: (_hasText && !widget.isSending) ? (isNote ? const Color(0xFFEA580C) : _C.primary) : _C.searchBg,
                        shape: BoxShape.circle,
                        border: Border.all(color: (_hasText && !widget.isSending) ? Colors.transparent : _C.border),
                      ),
                      child: Center(
                        child: widget.isSending
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Icon(Icons.send_rounded, size: 18, color: _hasText ? Colors.white : _C.textMuted),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _btn({required IconData icon, required String label, required VoidCallback onTap, bool isActive = false, Color? activeColor}) {
    final c = isActive ? (activeColor ?? _C.primary) : _C.textMuted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        margin: const EdgeInsets.only(right: 2),
        decoration: isActive ? BoxDecoration(color: (activeColor ?? _C.primary).withOpacity(0.1), borderRadius: BorderRadius.circular(8)) : null,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: c),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: isActive ? FontWeight.w700 : FontWeight.w500, color: c)),
        ]),
      ),
    );
  }
}
