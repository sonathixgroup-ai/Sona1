// lib/presentation/chat/thix_chat_page.dart
// Page d'accueil du module THIX Chat : conversations, statuts, filtres

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'core/chat_bloc.dart';
import 'core/chat_states.dart';
import 'core/chat_events.dart';
import 'core/chat_models.dart';

class ThixChatColors {
  static const Color primary = Color(0xFF1877F2);
  static const Color darkText = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color bg = Color(0xFFF7F8FA);
  static const Color online = Color(0xFF22C55E);
  static const Color badge = Color(0xFF4338CA);
}

class ThixChatPage extends StatefulWidget {
  const ThixChatPage({Key? key}) : super(key: key);

  @override
  State<ThixChatPage> createState() => _ThixChatPageState();
}

class _ThixChatPageState extends State<ThixChatPage> {
  late ChatBloc _chatBloc;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const List<Map<String, dynamic>> _tabs = [
    {'label': 'Tous', 'icon': Icons.forum_rounded, 'filter': 'Tous'},
    {'label': 'Équipes', 'icon': Icons.groups_rounded, 'filter': 'Équipes'},
    {'label': 'Appels', 'icon': Icons.call_rounded, 'filter': 'Appels'},
    {'label': 'Favoris', 'icon': Icons.star_rounded, 'filter': 'Favoris'},
    {'label': 'Rendez-vous', 'icon': Icons.event_rounded, 'filter': 'Rendez-vous'},
  ];

  @override
  void initState() {
    super.initState();
    _chatBloc = context.read<ChatBloc>();
    _chatBloc.add(LoadConversations());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Conversation> _applySearch(List<Conversation> conversations) {
    if (_searchQuery.trim().isEmpty) return conversations;
    final q = _searchQuery.trim().toLowerCase();
    return conversations.where((c) => c.name.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThixChatColors.bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _chatBloc.add(LoadConversations()),
          child: BlocBuilder<ChatBloc, ChatState>(
            bloc: _chatBloc,
            builder: (context, state) {
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader(context)),
                  SliverToBoxAdapter(child: _buildSearchBar()),
                  if (state is ConversationsLoaded) ...[
                    SliverToBoxAdapter(child: _buildStatsRow(state.stats)),
                    if (state.stories.isNotEmpty)
                      SliverToBoxAdapter(child: _buildOnlineRow(state.stories)),
                    SliverToBoxAdapter(child: _buildTabsRow(state.selectedFilter)),
                    SliverToBoxAdapter(child: _buildConversationsHeader()),
                    _buildConversationsList(_applySearch(state.filteredConversations)),
                  ] else if (state is ChatLoading) ...[
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ] else if (state is ChatError) ...[
                    SliverFillRemaining(
                      child: Center(child: Text('Erreur : ${state.message}')),
                    ),
                  ] else
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: ThixChatColors.primary,
        onPressed: () {
          // TODO : démarrer une nouvelle conversation
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // ---------------- HEADER ----------------
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: ThixChatColors.darkText),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(text: 'THIX ', style: TextStyle(color: ThixChatColors.darkText, fontSize: 22, fontWeight: FontWeight.w900)),
                      TextSpan(text: 'CHAT', style: TextStyle(color: ThixChatColors.primary, fontSize: 22, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
                const Text(
                  'Connectez-vous. Échangez. Avancez.',
                  style: TextStyle(color: ThixChatColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search, color: ThixChatColors.darkText),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: ThixChatColors.darkText),
            onPressed: () {},
          ),
          GestureDetector(
            onTap: () => context.push('/user-dashboard'),
            child: const CircleAvatar(radius: 18, backgroundColor: Color(0xFFE5E7EB)),
          ),
        ],
      ),
    );
  }

  // ---------------- SEARCH BAR ----------------
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, size: 20, color: ThixChatColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Rechercher un chat, contact, groupe...',
                  hintStyle: TextStyle(fontSize: 13, color: ThixChatColors.textSecondary),
                  isDense: true,
                ),
              ),
            ),
            const Icon(Icons.tune_rounded, size: 20, color: ThixChatColors.textSecondary),
          ],
        ),
      ),
    );
  }

  // ---------------- STATS ROW ----------------
  Widget _buildStatsRow(ChatStats stats) {
    final items = [
      {'icon': Icons.people_alt_rounded, 'value': stats.onlineCount, 'label': 'En ligne', 'color': ThixChatColors.online},
      {'icon': Icons.chat_bubble_rounded, 'value': stats.newMessagesCount, 'label': 'Nouveaux\nmessages', 'color': ThixChatColors.badge},
      {'icon': Icons.videocam_rounded, 'value': stats.activeMeetingsCount, 'label': 'Réunions\nactives', 'color': ThixChatColors.primary},
      {'icon': Icons.shield_rounded, 'value': stats.securityAlertsCount, 'label': 'Alertes\nsécurité', 'color': const Color(0xFFF97316)},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: items.map((item) {
          return Expanded(
            child: Column(
              children: [
                Icon(item['icon'] as IconData, color: item['color'] as Color, size: 22),
                const SizedBox(height: 6),
                Text('${item['value']}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: ThixChatColors.darkText)),
                const SizedBox(height: 2),
                Text(
                  item['label'] as String,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10, color: ThixChatColors.textSecondary, height: 1.2),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ---------------- ONLINE ROW ----------------
  Widget _buildOnlineRow(List<Story> stories) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('En ligne', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: ThixChatColors.darkText)),
              TextButton(
                onPressed: () {},
                child: const Text('Voir tout', style: TextStyle(color: ThixChatColors.primary, fontSize: 13)),
              ),
            ],
          ),
          SizedBox(
            height: 88,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: stories.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildOnlineAvatar(
                    onTap: () {},
                    child: const Icon(Icons.add, color: ThixChatColors.primary),
                    backgroundColor: const Color(0xFFEFF3FF),
                    label: 'Nouvelle\nhistoire',
                    showDot: false,
                  );
                }
                final story = stories[index - 1];
                return _buildOnlineAvatar(
                  onTap: () {},
                  imageUrl: story.avatarUrl,
                  initial: story.name.isNotEmpty ? story.name[0].toUpperCase() : '?',
                  label: story.name,
                  showDot: true,
                  ringColor: story.hasNewStory ? ThixChatColors.primary : Colors.transparent,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineAvatar({
    required VoidCallback onTap,
    String? imageUrl,
    String? initial,
    Widget? child,
    Color? backgroundColor,
    required String label,
    bool showDot = false,
    Color ringColor = Colors.transparent,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 68,
        margin: const EdgeInsets.only(right: 10),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: ringColor, width: 2)),
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: backgroundColor ?? const Color(0xFFE5E7EB),
                    backgroundImage: imageUrl != null ? CachedNetworkImageProvider(imageUrl) : null,
                    child: child ?? (imageUrl == null ? Text(initial ?? '?') : null),
                  ),
                  if (showDot)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: ThixChatColors.online,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: ThixChatColors.darkText),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- TABS ----------------
  Widget _buildTabsRow(String selectedFilter) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: _tabs.map((tab) {
            final isSelected = selectedFilter == tab['filter'];
            return Expanded(
              child: GestureDetector(
                onTap: () => _chatBloc.add(FilterConversations(tab['filter'] as String)),
                child: Column(
                  children: [
                    Icon(
                      tab['icon'] as IconData,
                      size: 20,
                      color: isSelected ? ThixChatColors.primary : ThixChatColors.textSecondary,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tab['label'] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? ThixChatColors.primary : ThixChatColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (isSelected)
                      Container(width: 24, height: 2, color: ThixChatColors.primary)
                    else
                      const SizedBox(height: 2),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ---------------- CONVERSATIONS HEADER ----------------
  Widget _buildConversationsHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Conversations récentes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: ThixChatColors.darkText)),
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.tune_rounded, size: 16, color: ThixChatColors.primary),
            label: const Text('Filtres', style: TextStyle(color: ThixChatColors.primary, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // ---------------- CONVERSATIONS LIST ----------------
  Widget _buildConversationsList(List<Conversation> conversations) {
    if (conversations.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('Aucune conversation', style: TextStyle(color: ThixChatColors.textSecondary))),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final conv = conversations[index];
            final isPinned = conv.metadata?['pinned'] == true;
            final isVerified = conv.metadata?['certified'] == true;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                leading: Stack(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: conv.isGroup ? ThixChatColors.badge.withOpacity(0.15) : const Color(0xFFE5E7EB),
                      backgroundImage: conv.avatarUrl != null ? CachedNetworkImageProvider(conv.avatarUrl!) : null,
                      child: conv.avatarUrl == null
                          ? Icon(
                              conv.isGroup ? Icons.groups_rounded : Icons.person,
                              color: conv.isGroup ? ThixChatColors.badge : ThixChatColors.textSecondary,
                            )
                          : null,
                    ),
                    if (conv.isOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: ThixChatColors.online,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                title: Row(
                  children: [
                    Flexible(
                      child: Text(
                        conv.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ThixChatColors.darkText),
                      ),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified_rounded, size: 14, color: ThixChatColors.primary),
                    ],
                  ],
                ),
                subtitle: Text(
                  conv.lastMessage ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: ThixChatColors.textSecondary),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        if (isPinned) const Icon(Icons.push_pin, size: 12, color: ThixChatColors.textSecondary),
                        if (isPinned) const SizedBox(width: 4),
                        Text(
                          _formatTime(conv.lastMessageTime),
                          style: const TextStyle(fontSize: 11, color: ThixChatColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (conv.unreadCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(color: ThixChatColors.badge, borderRadius: BorderRadius.circular(10)),
                        child: Text(
                          '${conv.unreadCount}',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),
                onTap: () => context.push(
                  '/chat/${Uri.encodeComponent(conv.id)}',
                  extra: {'title': conv.name, 'type': conv.isGroup ? 'group' : 'direct'},
                ),
              ),
            );
          },
          childCount: conversations.length,
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inDays == 0) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Hier';
    } else if (diff.inDays < 7) {
      const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
      return days[time.weekday - 1];
    }
    return '${time.day}/${time.month}';
  }

  // ---------------- BOTTOM NAV ----------------
  Widget _buildBottomNav(BuildContext context) {
    return BottomAppBar(
      color: Colors.white,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(Icons.home_rounded, 'Accueil', active: true, onTap: () => context.go('/')),
            _navItem(Icons.chat_bubble_rounded, 'Chats', onTap: () {}),
            const SizedBox(width: 40),
            _navItem(Icons.graphic_eq_rounded, 'Spaces', onTap: () => context.push('/chat/spaces')),
            _navItem(Icons.person_outline_rounded, 'Profil', onTap: () => context.push('/user-dashboard')),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, {bool active = false, required VoidCallback onTap}) {
    final color = active ? ThixChatColors.primary : ThixChatColors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
        ],
      ),
    );
  }
}
