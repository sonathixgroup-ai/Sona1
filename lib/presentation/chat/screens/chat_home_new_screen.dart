import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/chat_home_provider.dart';

class ChatHomeNewScreen extends StatefulWidget {
  const ChatHomeNewScreen({super.key});

  @override
  State<ChatHomeNewScreen> createState() => _ChatHomeNewScreenState();
}

class _ChatHomeNewScreenState extends State<ChatHomeNewScreen> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatHomeProvider(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: _buildAppBar(),
        body: Consumer<ChatHomeProvider>(
          builder: (context, provider, _) {
            return Column(
              children: [
                // Search Bar
                _buildSearchBar(provider),
                // Statistics Cards
                _buildStatisticsCards(provider),
                // Online Users Section
                _buildOnlineUsersSection(provider),
                // Navigation Tabs
                _buildNavigationTabs(provider),
                // Conversations List
                Expanded(
                  child: _buildConversationsList(provider),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'THIX CHAT',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      leading: const Padding(
        padding: EdgeInsets.only(left: 16),
        child: Icon(Icons.menu, color: Colors.black, size: 24),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search_outlined, color: Colors.black),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.black),
          onPressed: () {},
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE0E0E0),
              ),
              child: const Icon(Icons.person, color: Colors.grey, size: 24),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(ChatHomeProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        onChanged: provider.searchConversations,
        decoration: InputDecoration(
          hintText: 'Rechercher un chat, contact, groupe...',
          prefixIcon: const Icon(Icons.search_outlined, color: Colors.grey),
          suffixIcon: const Icon(Icons.tune, color: Colors.grey),
          filled: true,
          fillColor: const Color(0xFFEFEFF2),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildStatisticsCards(ChatHomeProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildStatCard(
              icon: Icons.people_outline,
              label: 'En ligne',
              value: provider.totalOnlineCount.toString(),
              color: const Color(0xFF1ABC9C),
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              icon: Icons.message_outlined,
              label: 'Nouveaux\nmessages',
              value: provider.totalNewMessages.toString(),
              color: const Color(0xFF4A73E1),
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              icon: Icons.videocam_outlined,
              label: 'Réunions\nactives',
              value: provider.totalActiveMeetings.toString(),
              color: const Color(0xFF0084FF),
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              icon: Icons.security,
              label: 'Alertes\nsécurité',
              value: provider.totalSecurityAlerts.toString(),
              color: const Color(0xFFFF6B6B),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF888888),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineUsersSection(ChatHomeProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'En ligne',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: const Row(
                  children: [
                    Text(
                      'Voir tout',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF4A73E1),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.chevron_right, color: Color(0xFF4A73E1), size: 20),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // New conversation button
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: 80,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, size: 32, color: Color(0xFF1ABC9C)),
                        SizedBox(height: 8),
                        Text(
                          'Nouvelle\nhistoire',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Online users
                ...provider.onlineUsers.map((user) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildUserAvatar(user),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserAvatar(ChatUser user) {
    return GestureDetector(
      onTap: () {},
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF4A73E1), width: 3),
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: NetworkImage(user.avatar),
                  fit: BoxFit.cover,
                ),
              ),
              child: Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1ABC9C),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 70,
            child: Text(
              user.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationTabs(ChatHomeProvider provider) {
    const tabs = [
      ('all', 'Tous', Icons.message_outlined),
      ('teams', 'Équipes', Icons.people_outline),
      ('calls', 'Appels', Icons.call_outlined),
      ('favorites', 'Favoris', Icons.star_outline),
      ('appointments', 'Rendez-vous', Icons.calendar_today_outlined),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.map((tab) {
            final isSelected = provider.selectedTab == tab.$1;
            return GestureDetector(
              onTap: () => provider.selectTab(tab.$1),
              child: Padding(
                padding: const EdgeInsets.only(right: 24),
                child: Column(
                  children: [
                    Icon(
                      tab.$3,
                      color: isSelected ? const Color(0xFF4A73E1) : Colors.grey,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tab.$2,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? const Color(0xFF4A73E1) : Colors.grey,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    if (isSelected)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        width: 24,
                        height: 3,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A73E1),
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildConversationsList(ChatHomeProvider provider) {
    final conversations = provider.getFilteredConversations();

    if (provider.isLoading && conversations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Aucune conversation',
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        return _buildConversationTile(conversation, provider);
      },
    );
  }

  Widget _buildConversationTile(Conversation conversation, ChatHomeProvider provider) {
    return GestureDetector(
      onTap: () {
        provider.markConversationAsRead(conversation.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: NetworkImage(conversation.avatar),
                  fit: BoxFit.cover,
                ),
              ),
              child: Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1ABC9C),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          conversation.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(conversation.lastMessageTime),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFA0A0A0),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          conversation.lastMessage,
                          style: TextStyle(
                            fontSize: 13,
                            color: conversation.unreadCount > 0
                                ? Colors.black
                                : const Color(0xFF888888),
                            fontWeight: conversation.unreadCount > 0
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (conversation.unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4A73E1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            conversation.unreadCount.toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}j';
    } else {
      return DateFormat('dd/MM').format(dateTime);
    }
  }
}

// Export pour utilisation facile
class ChatUser {
  final String id;
  final String name;
  final String avatar;
  final bool isOnline;

  ChatUser({
    required this.id,
    required this.name,
    required this.avatar,
    required this.isOnline,
  });
}

class Conversation {
  final String id;
  final String name;
  final String lastMessage;
  final String avatar;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool isGroup;

  Conversation({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.avatar,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.isGroup,
  });
}
