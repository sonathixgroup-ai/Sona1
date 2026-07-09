import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/chat/chat_service.dart';
import '../../services/chat/presence_service.dart';
import '../../models/chat/chat_conversation.dart';
import '../../models/chat/chat_message.dart';
import '../../models/chat/user_status.dart';
import 'chat_screen.dart';
import 'new_conversation_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  late ChatService _chatService;
  late PresenceService _presenceService;
  List<ChatConversation> _conversations = [];
  List<ChatConversation> _filteredConversations = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showOnlyUnread = false;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService(Supabase.instance.client);
    _presenceService = PresenceService(Supabase.instance.client);
    _loadConversations();
    _initPresence();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _presenceService.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);
    try {
      final convs = await _chatService.getConversations();
      setState(() {
        _conversations = convs;
        _applyFilter();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _initPresence() async {
    await _presenceService.initPresence();
  }

  void _applyFilter() {
    setState(() {
      _filteredConversations = _conversations.where((conv) {
        final matchSearch = _searchQuery.isEmpty ||
            conv.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (conv.lastMessage?.content ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
        final matchUnread = !_showOnlyUnread || conv.unreadCount > 0;
        return matchSearch && matchUnread;
      }).toList();
    });
  }

  void _onSearchChanged(String value) {
    _searchQuery = value;
    _applyFilter();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('THIX CHAT'), backgroundColor: Colors.white),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredConversations.isEmpty
              ? const Center(child: Text('Aucune conversation'))
              : ListView.builder(
                  itemCount: _filteredConversations.length,
                  itemBuilder: (context, index) {
                    final conv = _filteredConversations[index];
                    return ListTile(
                      title: Text(conv.displayName),
                      subtitle: Text(conv.lastMessage?.content ?? ''),
                      trailing: conv.unreadCount > 0
                          ? CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.blue,
                              child: Text('${conv.unreadCount}'),
                            )
                          : null,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              conversationId: conv.id,
                              conversation: conv,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NewConversationPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
