// lib/presentation/chat/thix_chat_page.dart
// Page d'accueil du module THIX Chat – DONNÉES RÉELLES

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/chat_bloc.dart';
import 'core/chat_states.dart';
import 'core/chat_events.dart';
import 'core/chat_models.dart';

// Couleurs de la charte THIX
const _navy = Color(0xFF1B2A4A);
const _blue = Color(0xFF2F5CF0);
const _gold = Color(0xFFC9962C);
const _bgGrey = Color(0xFFF5F6FA);

class ThixChatPage extends StatefulWidget {
  const ThixChatPage({Key? key}) : super(key: key);

  @override
  State<ThixChatPage> createState() => _ThixChatPageState();
}

class _ThixChatPageState extends State<ThixChatPage> {
  late ChatBloc _chatBloc;
  int _bottomNavIndex = 1; // onglet "Chats" actif par défaut
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _chatBloc = context.read<ChatBloc>();
    _loadConversationsIfAuthenticated();
  }

  void _loadConversationsIfAuthenticated() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _chatBloc.add(LoadConversations());
    } else {
      debugPrint('⚠️ ThixChatPage: utilisateur non authentifié');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGrey,
      body: SafeArea(
        child: BlocBuilder<ChatBloc, ChatState>(
          bloc: _chatBloc,
          builder: (context, state) {
            if (state is ChatLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ChatError) {
              return Center(child: Text('Erreur : ${state.message}'));
            }
            if (state is ConversationsLoaded) {
              final filteredConversations = _searchQuery.isEmpty
                  ? state.filteredConversations
                  : state.filteredConversations
                      .where((conv) => conv.name
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase()))
                      .toList();

              return RefreshIndicator(
                onRefresh: () async => _chatBloc.add(LoadConversations()),
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildHeader(context, state),
                    _buildSearchBar(context),
                    _buildStatsCard(state, context),
                    _buildOnlineSection(state, context),
                    _buildTabs(state, context),
                    _buildConversationsHeader(context),
                    if (filteredConversations.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: Text('Aucune conversation')),
                      )
                    else
                      ...filteredConversations.map(
                        (conv) => _ConversationTile(
                          conversation: conv,
                          onTap: () => context.push(
                            '/chat/${Uri.encodeComponent(conv.id)}',
                            extra: {
                              'title': conv.name,
                              'type': conv.isGroup ? 'group' : 'direct',
                            },
                          ),
                        ),
                      ),
                    const SizedBox(height: 90),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _blue,
        onPressed: () => context.push('/chat/new'),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // ---------- HEADER ----------
  Widget _buildHeader(BuildContext context, ConversationsLoaded state) {
    final user = Supabase.instance.client.auth.currentUser;
    final avatarUrl = user?.userMetadata?['avatar_url'] as String? ?? '';
    final displayName = user?.userMetadata?['display_name'] as String? ?? 'Profil';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: _navy, size: 28),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                      children: [
                        TextSpan(text: 'THIX ', style: TextStyle(color: _navy)),
                        TextSpan(text: 'CHAT', style: TextStyle(color: _blue)),
                      ],
                    ),
                  ),
                  const Text(
                    'Connectez-vous. Échangez. Avancez.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search, color: _navy, size: 26),
            onPressed: () => context.push('/chat/search'),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: _navy, size: 26),
                onPressed: () => context.push('/chat/notifications'),
              ),
              if (state.stats.newMessagesCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: _Badge(count: state.stats.newMessagesCount),
                ),
            ],
          ),
          GestureDetector(
            onTap: () => context.push('/user-dashboard'),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundImage: avatarUrl.isNotEmpty
                      ? NetworkImage(avatarUrl)
                      : const AssetImage('assets/default_avatar.png') as ImageProvider,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- SEARCH BAR ----------
  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFEDEEF3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: const InputDecoration(
                  hintText: 'Rechercher un chat, contact, groupe...',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.tune, color: Colors.grey),
              onPressed: () => context.push('/chat/filters'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- STATS CARD ----------
  Widget _buildStatsCard(ConversationsLoaded state, BuildContext context) {
    final stats = state.stats;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            _StatItem(
              icon: Icons.people_alt_rounded,
              iconColor: Colors.green,
              value: '${stats.onlineCount}',
              label: 'En ligne',
              onTap: () => context.push('/chat/online'),
            ),
            _StatItem(
              icon: Icons.chat_bubble_rounded,
              iconColor: _blue,
              value: '${stats.newMessagesCount}',
              label: 'Nouveaux\nmessages',
              onTap: () {},
            ),
            _StatItem(
              icon: Icons.videocam_rounded,
              iconColor: Colors.blueAccent,
              value: '${stats.activeMeetingsCount}',
              label: 'Réunions\nactives',
              onTap: () => context.push('/chat/spaces'),
            ),
            _StatItem(
              icon: Icons.shield_rounded,
              iconColor: Colors.deepOrange,
              value: '${stats.securityAlertsCount}',
              label: 'Alertes\nsécurité',
              onTap: () => context.push('/chat/notifications'),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.grey),
              onPressed: () => context.push('/chat/stats'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- ONLINE / STORIES ----------
  Widget _buildOnlineSection(ConversationsLoaded state, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'En ligne',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              GestureDetector(
                onTap: () => context.push('/chat/online'),
                child: const Row(
                  children: [
                    Text('Voir tout',
                        style: TextStyle(color: _blue, fontWeight: FontWeight.w600)),
                    Icon(Icons.chevron_right, color: _blue, size: 18),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: state.stories.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _StoryAvatar(
                    isAddButton: true,
                    label: 'Nouvelle\nhistoire',
                    onTap: () => context.push('/chat/story/new'),
                  );
                }
                final story = state.stories[index - 1];
                return _StoryAvatar(
                  avatarUrl: story.avatarUrl,
                  label: story.name,
                  onTap: () => context.push('/chat/story/${story.id}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---------- TABS ----------
  Widget _buildTabs(ConversationsLoaded state, BuildContext context) {
    final tabs = [
      _TabData('Tous', Icons.chat_bubble_outline, 'Tous'),
      _TabData('Équipes', Icons.groups_outlined, 'Équipes'),
      _TabData('Appels', Icons.call_outlined, 'Appels'),
      _TabData('Favoris', Icons.star_border, 'Favoris'),
      _TabData('Rendez-vous', Icons.calendar_today_outlined, 'Rendez-vous'),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: tabs.map((tab) {
          final isSelected = state.selectedFilter == tab.filter;
          final color = isSelected ? _blue : Colors.grey.shade600;
          return GestureDetector(
            onTap: () => _chatBloc.add(FilterConversations(tab.filter)),
            child: Column(
              children: [
                Icon(tab.icon, color: color, size: 24),
                const SizedBox(height: 4),
                Text(
                  tab.label,
                  style: TextStyle(
                    color: color,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 24,
                  height: 3,
                  decoration: BoxDecoration(
                    color: isSelected ? _blue : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ---------- CONVERSATIONS HEADER ----------
  Widget _buildConversationsHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Conversations récentes',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          GestureDetector(
            onTap: () => context.push('/chat/filters'),
            child: const Row(
              children: [
                Text('Filtres',
                    style: TextStyle(color: _blue, fontWeight: FontWeight.w600)),
                SizedBox(width: 4),
                Icon(Icons.tune, color: _blue, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- BOTTOM NAV (corrigé) ----------
  Widget _buildBottomNav(BuildContext context) {
    final state = context.watch<ChatBloc>().state;
    int unreadCount = 0;
    if (state is ConversationsLoaded) {
      unreadCount = state.stats.newMessagesCount;
    }

    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.home_rounded,
            label: 'Accueil',
            isSelected: _bottomNavIndex == 0,
            onTap: () {
              setState(() => _bottomNavIndex = 0);
              context.go('/'); // ✅ CORRECTION : '/home' → '/'
            },
          ),
          _NavItem(
            icon: Icons.chat_bubble_outline,
            label: 'Chats',
            badgeCount: unreadCount > 0 ? unreadCount : null,
            isSelected: _bottomNavIndex == 1,
            onTap: () {
              setState(() => _bottomNavIndex = 1);
              // déjà sur la page
            },
          ),
          const SizedBox(width: 40),
          _NavItem(
            icon: Icons.graphic_eq,
            label: 'Spaces',
            isSelected: _bottomNavIndex == 2,
            onTap: () {
              setState(() => _bottomNavIndex = 2);
              context.push('/chat/spaces');
            },
          ),
          _NavItem(
            icon: Icons.person_outline,
            label: 'Profil',
            isSelected: _bottomNavIndex == 3,
            onTap: () {
              setState(() => _bottomNavIndex = 3);
              context.push('/user-dashboard');
            },
          ),
        ],
      ),
    );
  }
}

// ================= WIDGETS AUXILIAIRES =================
// (inchangés)
class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final VoidCallback onTap;

  const _StatItem({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryAvatar extends StatelessWidget {
  final bool isAddButton;
  final String? avatarUrl;
  final String label;
  final bool isOnline;
  final VoidCallback onTap;

  const _StoryAvatar({
    this.isAddButton = false,
    this.avatarUrl,
    required this.label,
    this.isOnline = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 64,
        child: Column(
          children: [
            if (isAddButton)
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDEEF3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: _navy),
              )
            else
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _blue, width: 2),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: CircleAvatar(
                      backgroundImage:
                          avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                    ),
                  ),
                  if (isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabData {
  final String label;
  final IconData icon;
  final String filter;
  _TabData(this.label, this.icon, this.filter);
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;

  const _ConversationTile({required this.conversation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final conv = conversation;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 6, 20, 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: conv.isGroup ? _blue : Colors.grey.shade200,
                  backgroundImage: (!conv.isGroup && conv.avatarUrl != null)
                      ? NetworkImage(conv.avatarUrl!)
                      : null,
                  child: conv.isGroup
                      ? const Icon(Icons.groups, color: Colors.white)
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
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                if (conv.metadata?['pinned'] == true)
                  Positioned(
                    left: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: _blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.push_pin,
                          color: Colors.white, size: 10),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          conv.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (conv.metadata?['certified'] == true) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, color: _blue, size: 16),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    conv.lastMessage ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (conv.metadata?['pinned'] == true)
                  const Icon(Icons.push_pin, size: 14, color: Colors.grey)
                else
                  const SizedBox(height: 14),
                const SizedBox(height: 4),
                Text(_formatTime(conv.lastMessageTime),
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 6),
                if (conv.unreadCount > 0) _Badge(count: conv.unreadCount),
              ],
            ),
          ],
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
}

class _Badge extends StatelessWidget {
  final int count;
  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: const BoxDecoration(
        color: _blue,
        shape: BoxShape.circle,
      ),
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      child: Center(
        child: Text(
          '$count',
          style: const TextStyle(
              color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final int? badgeCount;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? _blue : Colors.grey.shade500;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, color: color, size: 24),
              if (badgeCount != null && badgeCount! > 0)
                Positioned(
                  right: -8,
                  top: -6,
                  child: _Badge(count: badgeCount!),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: color, fontSize: 11)),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: _blue,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
