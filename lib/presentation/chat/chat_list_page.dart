import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/chat/chat_service.dart';
import '../../services/chat/presence_service.dart';
import '../../models/chat/chat_conversation.dart';
import 'chat_screen.dart';
import 'new_conversation_page.dart';
import 'package:thix_id/presentation/chat/screens/group_create_page.dart';

class _ChatColors {
  static const bg = Color(0xFFF8FAFC);
  static const surface = Colors.white;
  static const textDark = Color(0xFF0F172A);
  static const textMuted = Color(0xFF64748B);
  static const primary = Color(0xFF4F46E5);
  static const border = Color(0xFFE2E8F0);
  static const online = Color(0xFF10B981);
  static const alert = Color(0xFFEF4444);
}

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  late ChatService _chatService;
  late PresenceService _presenceService;
  final TextEditingController _searchCtrl = TextEditingController();

  List<ChatConversation> _all = [];
  List<ChatConversation> _filtered = [];
  bool _isLoading = true;
  int _selectedFilter = 0;
  int _selectedNav = 1;
  int _pendingEscalationsCount = 0;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService(Supabase.instance.client);
    _presenceService = PresenceService(Supabase.instance.client);
    _load();
    _presenceService.initPresence();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _presenceService.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final convs = await _chatService.getConversations();
      final user = Supabase.instance.client.auth.currentUser;
      int pending = 0;
      if (user != null) {
        try {
          final res = await Supabase.instance.client
              .from('escalation_steps')
              .select('id')
              .eq('to_agent_id', user.id)
              .eq('status', 0)
              .count();
          pending = (res.count as int?) ?? 0;
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _all = convs;
        _filtered = convs;
        _pendingEscalationsCount = pending;
        _isLoading = false;
      });
      _applyFilter();
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearch(String v) {
    final q = v.trim().toLowerCase();
    setState(() {
      _filtered = _all.where((c) {
        final name = c.displayName.toLowerCase();
        final msg = (c.lastMessage?.content ?? '').toLowerCase();
        return name.contains(q) || msg.contains(q);
      }).toList();
    });
    _applyFilter();
  }

  void _applyFilter() {
    final base = _searchCtrl.text.trim().isEmpty ? _all : _filtered;
    List<ChatConversation> result = base;
    switch (_selectedFilter) {
      case 1:
        result = base.where((c) => c.isGroup).toList();
        break;
      case 2:
        result = base.where((c) => !c.isGroup).toList();
        break;
      case 3:
        result = base.where((c) => c.unreadCount > 0).toList();
        break;
      case 4:
        result = base;
        break;
      default:
        result = base;
    }
    if (!mounted) return;
    setState(() {
      _filtered = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final onlineCount = _all.where((c) => !c.isGroup).length;
    final unreadCount = _all.fold<int>(0, (s, c) => s + c.unreadCount);

    return Scaffold(
      backgroundColor: _ChatColors.bg,
      bottomNavigationBar: _buildBottomNav(unreadCount),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _ChatColors.primary),
            )
          : RefreshIndicator(
              onRefresh: _load,
              color: _ChatColors.primary,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  _buildHeader(),
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        _buildSearchBar(),
                        _buildMiniStats(onlineCount, unreadCount),
                        _buildCompactFilters(),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  _buildChatList(),
                  const SliverToBoxAdapter(child: SizedBox(height: 110)),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      toolbarHeight: 58,
      backgroundColor: _ChatColors.bg,
      surfaceTintColor: _ChatColors.bg,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _ChatColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _ChatColors.border),
              ),
              child: const Icon(
                Icons.forum_rounded,
                size: 20,
                color: _ChatColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'THIX CHAT',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _ChatColors.textDark,
                    ),
                  ),
                  SizedBox(height: 1),
                  Text(
                    'Discussions rapides',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _ChatColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => context.pushNamed('chatEscalationReceived'),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _ChatColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _ChatColors.border),
                    ),
                    child: const Icon(
                      Icons.swap_vert_rounded,
                      size: 20,
                      color: _ChatColors.textDark,
                    ),
                  ),
                ),
                if (_pendingEscalationsCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: const BoxDecoration(
                        color: _ChatColors.alert,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$_pendingEscalationsCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: _ChatColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _ChatColors.border, width: 1),
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged: _onSearch,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: _ChatColors.textDark,
          ),
          decoration: InputDecoration(
            hintText: 'Rechercher un chat...',
            hintStyle: const TextStyle(
              fontSize: 13,
              color: _ChatColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: const Icon(Icons.search_rounded, size: 19, color: _ChatColors.textMuted),
            suffixIcon: IconButton(
              icon: const Icon(Icons.tune_rounded, size: 18, color: _ChatColors.primary),
              onPressed: () {},
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 11),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStats(int onlineCount, int unreadCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _miniStat(Icons.fiber_manual_record, '$onlineCount en ligne', _ChatColors.online),
          const SizedBox(width: 14),
          _miniStat(Icons.mark_chat_unread_rounded, '$unreadCount non lus', _ChatColors.primary),
          const Spacer(),
          _miniStat(Icons.groups_rounded, '${_all.where((c) => c.isGroup).length} groupes', _ChatColors.textMuted),
        ],
      ),
    );
  }

  Widget _miniStat(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.8,
            fontWeight: FontWeight.w700,
            color: _ChatColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactFilters() {
    final tabs = ['Tous', 'Groupes', 'Persos', 'Non lus', 'Rdv'];
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        itemCount: tabs.length,
        itemBuilder: (context, i) {
          final sel = _selectedFilter == i;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                setState(() => _selectedFilter = i);
                _applyFilter();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                decoration: BoxDecoration(
                  color: sel ? _ChatColors.primary : _ChatColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: sel ? _ChatColors.primary : _ChatColors.border),
                ),
                child: Center(
                  child: Text(
                    tabs[i],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
                      color: sel ? Colors.white : _ChatColors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChatList() {
    if (_filtered.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(36),
          child: Center(
            child: Text(
              'Aucune conversation trouvée.',
              style: TextStyle(color: _ChatColors.textMuted, fontSize: 13),
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, idx) {
          final conv = _filtered[idx];
          final last = conv.lastMessage;
          final time = last != null ? last.createdAt : conv.updatedAt;
          final unread = conv.unreadCount;
          final isUnread = unread > 0;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    conversationId: conv.id,
                    conversation: conv,
                  ),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isUnread ? _ChatColors.primary.withOpacity(0.04) : _ChatColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isUnread ? _ChatColors.primary.withOpacity(0.12) : _ChatColors.border),
                ),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: _ChatColors.border,
                          backgroundImage: conv.displayAvatar != null ? NetworkImage(conv.displayAvatar!) : null,
                          child: conv.displayAvatar == null
                              ? Text(
                                  conv.displayName.isNotEmpty ? conv.displayName[0].toUpperCase() : '?',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: _ChatColors.primary,
                                    fontSize: 16,
                                  ),
                                )
                              : null,
                        ),
                        if (conv.isGroup)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: _ChatColors.surface,
                                shape: BoxShape.circle,
                                border: Border.all(color: _ChatColors.border, width: 1),
                              ),
                              child: const Icon(
                                Icons.groups_rounded,
                                size: 10,
                                color: _ChatColors.textDark,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            conv.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: isUnread ? FontWeight.w800 : FontWeight.w700,
                              color: _ChatColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            last?.content ?? 'Commencez à discuter...',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
                              color: isUnread ? _ChatColors.textDark : _ChatColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _fmt(time),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: isUnread ? FontWeight.w800 : FontWeight.w600,
                            color: isUnread ? _ChatColors.primary : _ChatColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 7),
                        if (isUnread)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: _ChatColors.primary,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '$unread',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          )
                        else
                          const SizedBox(height: 16),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        childCount: _filtered.length,
      ),
    );
  }

  Widget _buildBottomNav(int unreadCount) {
    return Container(
      decoration: BoxDecoration(
        color: _ChatColors.surface,
        border: Border(top: BorderSide(color: _ChatColors.border)),
        boxShadow: [
          BoxShadow(
            color: _ChatColors.textDark.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navIcon(Icons.home_rounded, 'Accueil', 0),
              _navIcon(Icons.chat_bubble_rounded, 'Chats', 1, badge: unreadCount),
              GestureDetector(
                onTap: _showCreateMenu,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _ChatColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _ChatColors.primary.withOpacity(0.30),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
                ),
              ),
              _navIcon(Icons.workspaces_rounded, 'Spaces', 2),
              _navIcon(Icons.person_rounded, 'Profil', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navIcon(IconData icon, String label, int idx, {int badge = 0}) {
    final sel = _selectedNav == idx;
    return InkWell(
      onTap: () => setState(() => _selectedNav = idx),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: sel ? _ChatColors.primary : _ChatColors.textMuted.withOpacity(0.72),
                ),
                if (badge > 0)
                  Positioned(
                    right: -7,
                    top: -5,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: _ChatColors.alert,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$badge',
                        style: const TextStyle(
                          fontSize: 8.5,
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
                color: sel ? _ChatColors.primary : _ChatColors.textMuted.withOpacity(0.78),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(18),
        decoration: const BoxDecoration(
          color: _ChatColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: _ChatColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            _sheetOpt(
              Icons.chat_bubble_rounded,
              'Nouvelle discussion',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NewConversationPage()),
              ),
            ),
            const SizedBox(height: 10),
            _sheetOpt(
              Icons.group_add_rounded,
              'Nouveau groupe',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GroupCreatePage()),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _sheetOpt(IconData icon, String title, VoidCallback tap) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        tap();
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: _ChatColors.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _ChatColors.bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: _ChatColors.primary),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: _ChatColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime t) {
    final now = DateTime.now();
    final d = DateTime(t.year, t.month, t.day);
    final today = DateTime(now.year, now.month, now.day);
    if (d == today) return DateFormat('HH:mm').format(t);
    if (d == today.subtract(const Duration(days: 1))) return 'Hier';
    if (now.difference(t).inDays < 7) return DateFormat('E', 'fr_FR').format(t);
    return DateFormat('dd/MM').format(t);
  }
}
