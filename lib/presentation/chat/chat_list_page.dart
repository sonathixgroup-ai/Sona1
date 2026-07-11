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
  int _selectedIndex = 1; // 0: Accueil, 1: Chats, 2: +, 3: Espace, 4: Profil

  @override
  void initState() {
    super.initState();
    _chatService = ChatService(Supabase.instance.client);
    _presenceService = PresenceService(Supabase.instance.client);
    _loadConversations();
    _presenceService.initPresence();
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
        _filteredConversations = convs;
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

  void _onSearchChanged(String value) {
    final query = value.toLowerCase();
    setState(() {
      _filteredConversations = _conversations.where((conv) {
        return conv.displayName.toLowerCase().contains(query) ||
            (conv.lastMessage?.content ?? '').toLowerCase().contains(query);
      }).toList();
    });
  }

  // Récupérer les contacts rapides (les 5 conversations les plus récentes)
  List<ChatConversation> get _quickContacts {
    final list = _conversations.where((c) => !c.isGroup).toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'THIX CHAT',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              'Connectez-vous. Échangez. Avancez.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadConversations,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Barre de recherche
                    _buildSearchBar(),

                    const SizedBox(height: 20),

                    // Contacts rapides
                    if (_quickContacts.isNotEmpty) ...[
                      _buildSectionTitle('Contacts rapides'),
                      const SizedBox(height: 8),
                      _buildQuickContacts(),
                      const SizedBox(height: 24),
                    ],

                    // Accès rapides
                    _buildSectionTitle('Accès rapides'),
                    const SizedBox(height: 8),
                    _buildQuickAccessGrid(),
                    const SizedBox(height: 24),

                    // Conversations récentes
                    _buildSectionTitle('Conversations récentes'),
                    const SizedBox(height: 8),
                    _buildRecentConversations(),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NewConversationPage()),
          );
        },
        backgroundColor: const Color(0xFFD4AF37),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(30),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Rechercher un chat, contact, groupe...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
              onPressed: () {
                _searchController.clear();
                _onSearchChanged('');
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildQuickContacts() {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _quickContacts.length,
        itemBuilder: (context, index) {
          final conv = _quickContacts[index];
          final name = conv.displayName;
          final avatar = conv.displayAvatar;

          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                  child: avatar == null
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 24, color: Colors.white),
                        )
                      : null,
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 60,
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickAccessGrid() {
    final items = [
      {'icon': Icons.chat, 'label': 'Chats'},
      {'icon': Icons.group, 'label': 'Équipes'},
      {'icon': Icons.call, 'label': 'Appels'},
      {'icon': Icons.star, 'label': 'Favoris'},
      {'icon': Icons.event, 'label': 'Rendez-vous'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 1.2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return InkWell(
          onTap: () {
            // Actions à implémenter
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item['icon'] as IconData, color: const Color(0xFFD4AF37), size: 28),
                const SizedBox(height: 4),
                Text(
                  item['label'] as String,
                  style: const TextStyle(fontSize: 10, color: Colors.black87),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentConversations() {
    final list = _searchController.text.isEmpty
        ? _conversations
        : _filteredConversations;

    if (list.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('Aucune conversation trouvée'),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.grey),
      itemBuilder: (context, index) {
        final conv = list[index];
        final isGroup = conv.isGroup;
        final name = conv.displayName;
        final avatar = conv.displayAvatar;
        final lastMsg = conv.lastMessage;
        final time = lastMsg != null ? lastMsg.createdAt : conv.updatedAt;
        final unread = conv.unreadCount;

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            radius: 26,
            backgroundColor: Colors.grey[200],
            backgroundImage: avatar != null ? NetworkImage(avatar) : null,
            child: avatar == null
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 20, color: Colors.white),
                  )
                : null,
          ),
          title: Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isGroup && lastMsg != null)
                Text(
                  '${lastMsg.senderName}: ',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
              Text(
                lastMsg?.content ?? 'Aucun message',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: lastMsg == null ? Colors.grey : Colors.grey[600],
                ),
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatTime(time),
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              if (unread > 0) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: const BoxDecoration(
                    color: Color(0xFFD4AF37),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$unread',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
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
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFFD4AF37),
      unselectedItemColor: Colors.grey,
      currentIndex: _selectedIndex,
      onTap: (index) {
        setState(() => _selectedIndex = index);
        // Gérer les onglets
        if (index == 0) {
          // Accueil : déjà sur la page
        } else if (index == 1) {
          // Chats : déjà sur la page
        } else if (index == 2) {
          // Nouvelle conversation
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NewConversationPage()),
          );
        } else if (index == 3) {
          // Espace (à implémenter)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Page Espace en développement')),
          );
        } else if (index == 4) {
          // Profil (à implémenter)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Page Profil en développement')),
          );
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
        BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chats'),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_circle_outline, size: 32),
          label: '',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Espace'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(time.year, time.month, time.day);

    if (date == today) {
      return DateFormat('HH:mm').format(time);
    } else if (date == today.subtract(const Duration(days: 1))) {
      return 'Hier';
    } else if (now.difference(time).inDays < 7) {
      return DateFormat('E').format(time); // Lun, Mar, etc.
    } else {
      return DateFormat('dd/MM/yyyy').format(time);
    }
  }
}
