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
  static const bgTop = Color(0xFFE3F0FF);
  static const bgBottom = Color(0xFFF7FAFF);
  static const cardBlueLight = Color(0xFF5B9CF6);
  static const cardBlueDark = Color(0xFF2D6CDF);
  static const navy = Color(0xFF0A1F44);
  static const surface = Colors.white;
  static const textDark = Color(0xFF0F172A);
  static const textMuted = Color(0xFF64748B);
  static const primary = Color(0xFF2D6CDF);
  static const border = Color(0xFFE7EEFB);
  static const online = Color(0xFF22C55E);
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
    final unreadCount = _all.fold<int>(0, (s, c) => s + c.unreadCount);
    final groupCount = _all.where((c) => c.isGroup).length;
    final pinned = _all.where((c) => c.unreadCount > 0).take(2).toList();
    final rest = _filtered.where((c) => !pinned.contains(c)).toList();

    return Scaffold(
      backgroundColor: _ChatColors.bgBottom,
      bottomNavigationBar: _buildBottomNav(unreadCount),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _ChatColors.primary),
            )
          : RefreshIndicator(
              onRefresh: _load,
              color: _ChatColors.primary,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_ChatColors.bgTop, _ChatColors.bgBottom],
                    stops: [0.0, 0.28],
                  ),
                ),
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          _buildHeader(),
                          _buildTopCard(),
                          const SizedBox(height: 14),
                          _buildCompactFilters(groupCount, unreadCount),
                          const SizedBox(height: 10),
                          if (pinned.isNotEmpty) ...[
                            _sectionTitle('Épinglés', pinned.length),
                            ...pinned.map((c) => _chatTile(c)),
                            const SizedBox(height: 6),
                          ],
                          _sectionTitle('Discussions', rest.length),
                        ],
                      ),
                    ),
                    _buildChatList(rest),
                    const SliverToBoxAdapter(child: SizedBox(height: 110)),
                  ],
                ),
              ),
            ),
    );
  }

  // ---------- HEADER ----------
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'THIX CHAT.',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: _ChatColors.navy,
                letterSpacing: -0.5,
              ),
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => context.pushNamed('chatEscalationReceived'),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _ChatColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _ChatColors.navy.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.notifications_rounded,
                    size: 21,
                    color: _ChatColors.navy,
                  ),
                ),
              ),
              if (_pendingEscalationsCount > 0)
                Positioned(
                  right: -3,
                  top: -3,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
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
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------- TOP CARD (strip contacts + recherche) ----------
  Widget _buildTopCard() {
    final quickAccess = _all.take(8).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_ChatColors.cardBlueLight, _ChatColors.cardBlueDark],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: _ChatColors.cardBlueDark.withOpacity(0.35),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Accès rapide',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 74,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: quickAccess.length + 1,
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(30),
                            onTap: _showCreateMenu,
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.8),
                                  width: 1.4,
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Nouveau',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ],
                      ),
                    );
                  }
                  final conv = quickAccess[i - 1];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(conversationId: conv.id, conversation: conv),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: CircleAvatar(
                              backgroundColor: Colors.white24,
                              backgroundImage:
                                  conv.displayAvatar != null ? NetworkImage(conv.displayAvatar!) : null,
                              child: conv.displayAvatar == null
                                  ? Text(
                                      conv.displayName.isNotEmpty ? conv.displayName[0].toUpperCase() : '?',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: 56,
                            child: Text(
                              conv.displayName.split(' ').first,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            Container(
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _onSearch,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: _ChatColors.textDark),
                decoration: InputDecoration(
                  hintText: 'Rechercher un chat...',
                  hintStyle: const TextStyle(fontSize: 13, color: _ChatColors.textMuted, fontWeight: FontWeight.w500),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: _ChatColors.primary),
                  suffixIcon: Container(
                    margin: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _ChatColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.tune_rounded, size: 17, color: Colors.white),
                      onPressed: () {},
                    ),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- FILTRES ----------
  Widget _buildCompactFilters(int groupCount, int unreadCount) {
    final tabs = <String>['Tous', 'Groupes', 'Persos', 'Non lus', 'Rdv'];
    final counts = <int?>[_all.length, groupCount, _all.length - groupCount, unreadCount, null];

    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tabs.length,
        itemBuilder: (context, i) {
          final sel = _selectedFilter == i;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                setState(() => _selectedFilter = i);
                _applyFilter();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                decoration: BoxDecoration(
                  color: sel ? _ChatColors.navy : _ChatColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: sel ? _ChatColors.navy : _ChatColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tabs[i],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
                        color: sel ? Colors.white : _ChatColors.textDark,
                      ),
                    ),
                    if (counts[i] != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: sel ? Colors.white.withOpacity(0.2) : _ChatColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${counts[i]}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: sel ? Colors.white : _ChatColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _ChatColors.textDark),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _ChatColors.navy,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- LISTE ----------
  Widget _buildChatList(List<ChatConversation> data) {
    if (data.isEmpty) {
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
        (context, idx) => _chatTile(data[idx]),
        childCount: data.length,
      ),
    );
  }

  Widget _chatTile(ChatConversation conv) {
    final last = conv.lastMessage;
    final time = last != null ? last.createdAt : conv.updatedAt;
    final unread = conv.unreadCount;
    final isUnread = unread > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(conversationId: conv.id, conversation: conv),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _ChatColors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _ChatColors.navy.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: isUnread ? Border.all(color: _ChatColors.primary.withOpacity(0.18)) : null,
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: _ChatColors.border,
                    backgroundImage: conv.displayAvatar != null ? NetworkImage(conv.displayAvatar!) : null,
                    child: conv.displayAvatar == null
                        ? Text(
                            conv.displayName.isNotEmpty ? conv.displayName[0].toUpperCase() : '?',
                            style: const TextStyle(fontWeight: FontWeight.w800, color: _ChatColors.primary, fontSize: 16),
                          )
                        : null,
                  ),
                  if (conv.isGroup)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 17,
                        height: 17,
                        decoration: BoxDecoration(
                          color: _ChatColors.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: _ChatColors.border, width: 1),
                        ),
                        child: const Icon(Icons.groups_rounded, size: 10, color: _ChatColors.navy),
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
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
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
  }

  // ---------- BOTTOM NAV ----------
  Widget _buildBottomNav(int unreadCount) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: _ChatColors.surface,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: _ChatColors.navy.withOpacity(0.10),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
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
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_ChatColors.cardBlueLight, _ChatColors.cardBlueDark],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _ChatColors.primary.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
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
                  size: 23,
                  color: sel ? _ChatColors.primary : _ChatColors.textMuted.withOpacity(0.7),
                ),
                if (badge > 0)
                  Positioned(
                    right: -7,
                    top: -5,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(color: _ChatColors.alert, shape: BoxShape.circle),
                      child: Text(
                        '$badge',
                        style: const TextStyle(fontSize: 8.5, color: Colors.white, fontWeight: FontWeight.w800),
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
                color: sel ? _ChatColors.primary : _ChatColors.textMuted.withOpacity(0.76),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- CREATE MENU ----------
  void _showCreateMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(18),
        decoration: const BoxDecoration(
          color: _ChatColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: _ChatColors.border, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 18),
            _sheetOpt(
              Icons.chat_bubble_rounded,
              'Nouvelle discussion',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewConversationPage())),
            ),
            const SizedBox(height: 10),
            _sheetOpt(
              Icons.group_add_rounded,
              'Nouveau groupe',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupCreatePage())),
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: _ChatColors.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_ChatColors.cardBlueLight, _ChatColors.cardBlueDark]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 19, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: _ChatColors.textDark),
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
