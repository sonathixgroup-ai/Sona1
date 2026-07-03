// lib/presentation/chat/home_widgets/widget_preview.dart
// Aperçu visuel du widget d'écran d'accueil (simulation, pas de rendu natif)

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/chat_bloc.dart';
import '../core/chat_states.dart';
import '../core/chat_events.dart';
import '../core/chat_models.dart';

class WidgetPreview extends StatefulWidget {
  final bool showConversations;
  final int conversationCount;
  final bool showShortcuts;
  final bool shortcutNewMessage;
  final bool shortcutNewCall;
  final bool shortcutCamera;

  const WidgetPreview({
    Key? key,
    this.showConversations = true,
    this.conversationCount = 3,
    this.showShortcuts = true,
    this.shortcutNewMessage = true,
    this.shortcutNewCall = true,
    this.shortcutCamera = false,
  }) : super(key: key);

  @override
  State<WidgetPreview> createState() => _WidgetPreviewState();
}

class _WidgetPreviewState extends State<WidgetPreview> {
  @override
  void initState() {
    super.initState();
    if (widget.showConversations) {
      context.read<ChatBloc>().add(LoadConversations());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(title: const Text('Aperçu du widget')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.chat_bubble, color: Color(0xFFC9962C), size: 20),
                    const SizedBox(width: 6),
                    const Text('THIX CHAT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 8),
                if (widget.showConversations) _buildConversationsPreview(),
                if (widget.showConversations && widget.showShortcuts) const Divider(height: 20),
                if (widget.showShortcuts) _buildShortcutsPreview(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConversationsPreview() {
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        List<Conversation> conversations = [];
        if (state is ConversationsLoaded) {
          conversations = state.allConversations.take(widget.conversationCount).toList();
        }

        if (conversations.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Aucune conversation à afficher',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          );
        }

        return Column(
          children: conversations.map((c) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: const Color(0xFF1B2A4A),
                    backgroundImage: c.avatarUrl != null ? NetworkImage(c.avatarUrl!) : null,
                    child: c.avatarUrl == null
                        ? Text(c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                            style: const TextStyle(color: Colors.white, fontSize: 12))
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        Text(
                          c.lastMessage ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  if (c.unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFFC9962C), borderRadius: BorderRadius.circular(10)),
                      child: Text('${c.unreadCount}', style: const TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildShortcutsPreview() {
    final shortcuts = <Widget>[];
    if (widget.shortcutNewMessage) {
      shortcuts.add(_shortcutIcon(Icons.edit_outlined, 'Message'));
    }
    if (widget.shortcutNewCall) {
      shortcuts.add(_shortcutIcon(Icons.call_outlined, 'Appel'));
    }
    if (widget.shortcutCamera) {
      shortcuts.add(_shortcutIcon(Icons.camera_alt_outlined, 'Photo'));
    }
    if (shortcuts.isEmpty) return const SizedBox.shrink();

    return Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: shortcuts);
  }

  Widget _shortcutIcon(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFF1B2A4A).withOpacity(0.08), shape: BoxShape.circle),
          child: Icon(icon, size: 18, color: const Color(0xFF1B2A4A)),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}
