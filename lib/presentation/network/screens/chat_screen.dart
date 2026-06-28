// lib/presentation/network/screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thix_id/presentation/network/services/message_service.dart';
import 'package:thix_id/presentation/network/models/message_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  const ChatScreen({Key? key, required this.conversationId}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  List<MessageModel> _messages = [];
  bool _loading = true;
  RealtimeChannel? _sub;

  @override
  void initState() {
    super.initState();
    _load();
    _sub = context.read<MessageService>().streamMessages(conversationId: widget.conversationId, onData: (items) {
      if (mounted) setState(() => _messages = items);
    });
  }

  @override
  void dispose() {
    _sub?.unsubscribe();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await context.read<MessageService>().fetchMessages(conversationId: widget.conversationId);
      if (mounted) setState(() => _messages = items);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final supabase = Supabase.instance.client;
    final profileId = supabase.auth.currentUser?.id ?? '';
    try {
      await context.read<MessageService>().sendMessage(conversationId: widget.conversationId, senderProfileId: profileId, content: text);
      _controller.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur envoi: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conversation')),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    reverse: false,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) {
                      final m = _messages[i];
                      final isMe = m.senderProfileId == Supabase.instance.client.auth.currentUser?.id;
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: isMe ? Colors.blue.shade100 : Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                          child: Text(m.content ?? ''),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
              child: Row(
                children: [
                  Expanded(child: TextField(controller: _controller, decoration: const InputDecoration(hintText: 'Message...'))),
                  const SizedBox(width: 8),
                  ElevatedButton(onPressed: _send, child: const Icon(Icons.send))
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
