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
import 'settings/chat_settings_page.dart';

class _C {
  static const violet = Color(0xFF7C5CFF);
  static const violetDark = Color(0xFF6B4EFF);
  static const violetSoft = Color(0xFFEDE9FE);
  static const violetSofter = Color(0xFFF5F3FF);
  static const bg = Color(0xFFF9F8FF);
  static const white = Colors.white;
  static const textDark = Color(0xFF111827);
  static const textMuted = Color(0xFF6B7280);
  static const textFaint = Color(0xFF9CA3AF);
  static const border = Color(0xFFF3F0FF);
  static const borderStrong = Color(0xFFEDE9FE);
  static const green = Color(0xFF22C55E);
  static const red = Color(0xFFFF6B6B);
}

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});
  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  late ChatService _chatService;
  late PresenceService _presenceService;

  final _searchCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatConversation> _all = [];
  List<ChatConversation> _filtered = [];

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  final int _limit = 20;

  int _totalUnreadCount = 0;
  int _pendingEscalationsCount = 0;

  int _selectedFilter = 0;
  int _selectedNav = 1;
  bool _showSearchField = false;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService(Supabase.instance.client);
    _presenceService = PresenceService(Supabase.instance.client);
    _scrollController.addListener(_onScroll);
    _loadInitialData();
    _presenceService.initPresence();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollController.dispose();
    _presenceService.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadInitialData() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final futures = await Future.wait([
        _chatService.getConversations(limit: _limit, offset: 0),
        _chatService.getTotalUnreadCount(),
        _getPendingEscalations(),
      ]);

      final convs = futures[0] as List<ChatConversation>;

      if (!mounted) return;
      setState(() {
        _all = convs;
        _totalUnreadCount = futures[1] as int;
        _pendingEscalationsCount = futures[2] as int;
        _hasMore = convs.length == _limit;
        _isLoading = false;
      });
      _applyFilter();
    } catch (e) {
      debugPrint("Erreur _loadInitialData: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    try {
      final offset = _all.length;
      final newConvs = await _chatService.getConversations(limit: _limit, offset: offset);

      if (!mounted) return;
      setState(() {
        if (newConvs.isEmpty) {
          _hasMore = false;
        } else {
          _all.addAll(newConvs);
          _hasMore = newConvs.length == _limit;
        }
        _isLoadingMore = false;
      });
      _applyFilter();
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<int> _getPendingEscalations() async {
    final u = Supabase.instance.client.auth.currentUser;
    if (u == null) return 0;
    try {
      final r = await Supabase.instance.client
          .from('escalation_steps')
          .select('id')
          .eq('to_agent_id', u.id)
          .eq('status', 0)
          .count();
      return (r.count as int?) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  void _onSearch(String v) {
    final q = v.trim().toLowerCase();
    setState(() => _filtered = _all
        .where((c) =>
            c.displayName.toLowerCase().contains(q) ||
            (c.lastMessage?.content ?? '').toLowerCase().contains(q))
        .toList());
    _applyFilter();
  }

  void _applyFilter() {
    final base = _searchCtrl.text.trim().isEmpty ? _all : _filtered;
    List<ChatConversation> r = base;
    switch (_selectedFilter) {
      case 1:
        r = base.where((c) => c.isGroup).toList();
        break;
      case 2:
        r = base.where((c) => !c.isGroup).toList();
        break;
      case 3:
        r = base.where((c) => c.unreadCount > 0).toList();
        break;
    }
    if (!mounted) return;
    setState(() => _filtered = r);
  }

  void _toggleSearch() {
    setState(() {
      _showSearchField = !_showSearchField;
      if (!_showSearchField) {
        _searchCtrl.clear();
        _onSearch('');
      }
    });
  }

  void _openNotifications() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.6),
        decoration: const BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 34,
              height: 4,
              decoration: BoxDecoration(color: _C.borderStrong, borderRadius: BorderRadius.circular(3)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
              child: Row(children: const [
                Icon(Icons.notifications_rounded, color: _C.violet, size: 18),
                SizedBox(width: 8),
                Text('Notifications',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _C.textDark)),
              ]),
            ),
            Flexible(
              child: _pendingEscalationsCount > 0
                  ? ListTile(
                      leading: Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(color: _C.violetSoft, borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.swap_vert_rounded, color: _C.violet, size: 17),
                      ),
                      title: Text('$_pendingEscalationsCount escalade(s) en attente',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      onTap: () {
                        Navigator.pop(ctx);
                        context.pushNamed('chatEscalationReceived');
                      },
                    )
                  : const Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: Center(
                          child: Text('Aucune nouvelle notification',
                              style: TextStyle(color: _C.textMuted, fontSize: 12.5))),
                    ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      bottomNavigationBar: _bottomNotchPro(_totalUnreadCount),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _C.violet, strokeWidth: 2.4))
          : RefreshIndicator(
              onRefresh: _loadInitialData,
              color: _C.violet,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                slivers: [
                  SliverToBoxAdapter(child: _headerTHIX(_totalUnreadCount)),
                  SliverToBoxAdapter(child: _searchBarFixed()),
                  SliverToBoxAdapter(child: _filters()),
                  const SliverToBoxAdapter(child: SizedBox(height: 4)),
                  _chatList(),
                  if (_isLoadingMore)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: CircularProgressIndicator(color: _C.violet, strokeWidth: 2)),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),
            ),
    );
  }

  // ---------------- HEADER ----------------
  Widget _headerTHIX(int unread) {
    return Container(
      color: _C.white,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 14, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: _C.violet,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: _C.violet.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 6))],
                  ),
                  alignment: Alignment.center,
                  child: const Text('T', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
                ),
                const SizedBox(width: 9),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Text('THIX CHAT', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _C.textDark, letterSpacing: -0.3)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: _C.textDark, borderRadius: BorderRadius.circular(20)),
                        child: const Text('ENTERPRISE', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.4)),
                      ),
                    ]),
                    const SizedBox(height: 1),
                    Row(children: [
                      const Icon(Icons.shield_rounded, size: 10, color: _C.violet),
                      const SizedBox(width: 3),
                      const Text('Chiffré de bout en bout', style: TextStyle(fontSize: 10, color: _C.textMuted, fontWeight: FontWeight.w500)),
                    ]),
                  ],
                ),
                const Spacer(),
                InkWell(
                  onTap: _toggleSearch,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(color: _showSearchField ? _C.violet : _C.bg, shape: BoxShape.circle),
                    child: Icon(_showSearchField ? Icons.close_rounded : Icons.search_rounded,
                        color: _showSearchField ? Colors.white : _C.textDark, size: 17),
                  ),
                ),
                const SizedBox(width: 8),
                Stack(clipBehavior: Clip.none, children: [
                  InkWell(
                    onTap: () => context.pushNamed('chatEscalationReceived'),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 34, height: 34,
                      decoration: const BoxDecoration(color: _C.bg, shape: BoxShape.circle),
                      child: const Icon(Icons.swap_vert_rounded, size: 17, color: _C.textDark),
                    ),
                  ),
                  if (_pendingEscalationsCount > 0)
                    Positioned(
                      right: -2, top: -3,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(color: _C.red, borderRadius: BorderRadius.circular(8), border: Border.all(color: _C.white, width: 1.4)),
                        child: Text('$_pendingEscalationsCount',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800)),
                      ),
                    ),
                ]),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _openNotifications,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 34, height: 34,
                    decoration: const BoxDecoration(color: _C.bg, shape: BoxShape.circle),
                    child: const Icon(Icons.notifications_none_rounded, color: _C.textDark, size: 17),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                _statChip(icon: Icons.mark_chat_unread_rounded, label: 'Non lus', value: unread, color: _C.violet),
                const SizedBox(width: 8),
                _statChip(icon: Icons.swap_vert_rounded, label: 'Escalades', value: _pendingEscalationsCount, color: _C.red),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statChip({required IconData icon, required String label, required int value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(color: color.withOpacity(.08), borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Text('$label: ', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _C.textMuted)),
        Text('$value', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
      ]),
    );
  }

  Widget _searchBarFixed() {
    return Container(
      color: _C.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: AnimatedCrossFade(
        duration: const Duration(milliseconds: 180),
        crossFadeState: _showSearchField ? CrossFadeState.showFirst : CrossFadeState.showSecond,
        firstChild: Container(
          height: 42,
          decoration: BoxDecoration(color: _C.bg, borderRadius: BorderRadius.circular(21), border: Border.all(color: _C.border)),
          child: TextField(
            controller: _searchCtrl,
            autofocus: true,
            onChanged: _onSearch,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _C.textDark),
            decoration: const InputDecoration(
              hintText: 'Rechercher une conversation...',
              hintStyle: TextStyle(fontSize: 12.5, color: _C.textFaint),
              prefixIcon: Icon(Icons.search_rounded, size: 18, color: _C.textFaint),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        secondChild: const SizedBox(height: 0),
      ),
    );
  }

  Widget _filters() {
    final tabs = ['Tous', 'Groupes', 'Persos', 'Non lus'];
    return Container(
      color: _C.white,
      padding: const EdgeInsets.fromLTRB(0, 2, 0, 10),
      child: SizedBox(
        height: 34,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: tabs.length,
          itemBuilder: (ctx, i) {
            final sel = _selectedFilter == i;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () {
                  setState(() => _selectedFilter = i);
                  _applyFilter();
                },
                borderRadius: BorderRadius.circular(18),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: sel ? _C.violet : _C.bg,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: sel ? [BoxShadow(color: _C.violet.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4))] : [],
                  ),
                  child: Text(tabs[i],
                      style: TextStyle(fontSize: 12, fontWeight: sel ? FontWeight.w700 : FontWeight.w600, color: sel ? Colors.white : _C.textDark)),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ---------------- LISTE (avatars/densité type WhatsApp) ----------------
  Widget _chatList() {
    if (_filtered.isEmpty && !_isLoadingMore) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: Text('Aucune conversation', style: TextStyle(color: _C.textMuted, fontSize: 12.5))),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (ctx, idx) {
          final conv = _filtered[idx];
          final last = conv.lastMessage;
          final t = last != null ? last.createdAt : conv.updatedAt;
          final unread = conv.unreadCount > 0;

          return InkWell(
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => ChatScreen(conversationId: conv.id, conversation: conv))),
            child: Container(
              color: _C.white,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  Container(
                    width: 52, height: 52,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(shape: BoxShape.circle, color: unread ? _C.violetSoft : Colors.transparent),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: _C.violetSofter,
                      backgroundImage: conv.displayAvatar != null ? NetworkImage(conv.displayAvatar!) : null,
                      child: conv.displayAvatar == null
                          ? Text(
                              conv.displayName.isNotEmpty ? conv.displayName[0].toUpperCase() : '?',
                              style: const TextStyle(fontWeight: FontWeight.w800, color: _C.violet, fontSize: 15),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Flexible(
                            child: Text(
                              conv.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 14.5, fontWeight: unread ? FontWeight.w700 : FontWeight.w600, color: _C.textDark),
                            ),
                          ),
                          if (conv.isGroup) ...[
                            const SizedBox(width: 5),
                            Icon(Icons.groups_rounded, size: 13, color: _C.textFaint),
                          ],
                        ]),
                        const SizedBox(height: 3),
                        Text(
                          last?.content ?? 'Commencez à discuter...',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: unread ? FontWeight.w500 : FontWeight.w400,
                              color: unread ? _C.textDark.withOpacity(.75) : _C.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(_fmt(t), style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500, color: unread ? _C.violet : _C.textFaint)),
                      const SizedBox(height: 6),
                      if (unread)
                        Container(
                          constraints: const BoxConstraints(minWidth: 19, minHeight: 19),
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(color: _C.violet, shape: BoxShape.circle),
                          child: Text('${conv.unreadCount}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                        )
                      else
                        Icon(Icons.done_all_rounded, size: 15, color: _C.textFaint.withOpacity(0.5)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
        childCount: _filtered.length,
      ),
    );
  }

  // ---------------- NAV FLOTTANTE (encoche + FAB central, dégradé violet) ----------------
  Widget _bottomNotchPro(int unread) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: SizedBox(
        height: 78,
        child: Stack(clipBehavior: Clip.none, alignment: Alignment.bottomCenter, children: [
          Container(
            height: 70,
            decoration: BoxDecoration(
              color: _C.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [BoxShadow(color: _C.violet.withOpacity(0.12), blurRadius: 24, offset: const Offset(0, 10))],
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _navItem(Icons.people_rounded, 'Connexions', 0, false),
              _navItem(Icons.chat_bubble_rounded, 'Chats', 1, unread > 0, badge: unread),
              const SizedBox(width: 56),
              _navItem(Icons.workspaces_rounded, 'Spaces', 2, false),
              _navItem(Icons.settings_rounded, 'Paramètres', 3, false),
            ]),
          ),
          Positioned(
            top: -14,
            child: GestureDetector(
              onTap: _showCreateMenu,
              child: Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_C.violet, _C.violetDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: _C.violet.withOpacity(.4), blurRadius: 16, offset: const Offset(0, 6))],
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _navItem(IconData ic, String lb, int idx, bool hasBadge, {int badge = 0}) {
    final sel = _selectedNav == idx;
    return InkWell(
      onTap: () {
        if (idx == 0) {
          context.pushNamed('connections');
        } else if (idx == 3) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatSettingsPage()));
        } else {
          setState(() => _selectedNav = idx);
        }
      },
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(clipBehavior: Clip.none, children: [
              Icon(ic, size: 20, color: sel ? _C.violet : _C.textFaint),
              if (hasBadge)
                Positioned(
                  right: -6, top: -4,
                  child: Container(width: 7, height: 7, decoration: const BoxDecoration(color: _C.red, shape: BoxShape.circle)),
                ),
            ]),
            const SizedBox(height: 3),
            Text(lb, style: TextStyle(fontSize: 9, fontWeight: sel ? FontWeight.w700 : FontWeight.w600, color: sel ? _C.violet : _C.textFaint)),
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
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(color: _C.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 34, height: 4, decoration: BoxDecoration(color: _C.borderStrong, borderRadius: BorderRadius.circular(3))),
          const SizedBox(height: 16),
          _sheetOpt(Icons.chat_bubble_rounded, 'Nouvelle discussion',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewConversationPage()))),
          const SizedBox(height: 8),
          _sheetOpt(Icons.group_add_rounded, 'Nouveau groupe',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupCreatePage()))),
        ]),
      ),
    );
  }

  Widget _sheetOpt(IconData i, String t, VoidCallback tap) => InkWell(
        onTap: () {
          Navigator.pop(context);
          tap();
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(border: Border.all(color: _C.border), borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(color: _C.violet, borderRadius: BorderRadius.circular(10)),
              child: Icon(i, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _C.textDark)),
          ]),
        ),
      );

  String _fmt(DateTime d) {
    final now = DateTime.now();
    final day = DateTime(d.year, d.month, d.day);
    final today = DateTime(now.year, now.month, now.day);
    if (day == today) return DateFormat('HH:mm').format(d);
    if (day == today.subtract(const Duration(days: 1))) return 'Hier';
    if (now.difference(d).inDays < 7) return DateFormat('E', 'fr_FR').format(d);
    return DateFormat('dd/MM').format(d);
  }
}
