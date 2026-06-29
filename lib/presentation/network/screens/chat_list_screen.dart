// lib/presentation/network/screens/chat_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thix_id/presentation/network/services/message_service.dart';
import 'package:thix_id/presentation/network/models/conversation_model.dart';
import 'package:thix_id/presentation/network/screens/chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<ConversationModel> _conversations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await context.read<MessageService>().fetchConversations();
      if (mounted) setState(() => _conversations = items);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? const Center(child: Text('Aucune conversation'))
              : ListView.separated(
                  itemCount: _conversations.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final c = _conversations[i];
                    return ListTile(
                      title: Text(c.title ?? 'Conversation'),
                      subtitle: Text('ID: ${c.id}'),
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen(conversationId: c.id)));
                      },
                    );
                  },
                ),
    );
  }
}
