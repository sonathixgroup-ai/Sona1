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
  static const blue = Color(0xFF2D6CDF);
  static const blueDark = Color(0xFF123B7A);
  static const blueSoft = Color(0xFFEAF1FF);
  static const bg = Color(0xFFF6F7FB);
  static const white = Colors.white;
  static const textDark = Color(0xFF0F172A);
  static const textMuted = Color(0xFF8A93A6);
  static const border = Color(0xFFEDF0F5);
  static const green = Color(0xFF22C55E);
  static const red = Color(0xFFEF4444);
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
  final ScrollController _scrollController = ScrollController(); // 🔥 SCROLL CONTROLLER POUR INFINITE SCROLL

  List<ChatConversation> _all = [];
  List<ChatConversation> _filtered = [];
  
  // États de chargement et pagination
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  final int _limit = 20;
  
  // Compteurs globaux
  int _totalUnreadCount = 0;
  int _pendingEscalationsCount = 0;
  
  // UI States
  int _selectedFilter = 0;
  int _selectedNav = 1;
  bool _showSearchField = false;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService(Supabase.instance.client);
    _presenceService = PresenceService(Supabase.instance.client);
    
    // 🔥 Écouteur pour charger la suite en arrivant en bas de l'écran
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
      // 🔥 Exécution parallèle pour ne pas bloquer l'UI
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
        _hasMore = convs.length == _limit; // Si on reçoit 20 items, c'est qu'il y en a potentiellement d'autres
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(color: _C.border, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(children: const [
                Icon(Icons.notifications_rounded, color: _C.blue, size: 18),
                SizedBox(width: 8),
                Text('Notifications',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _C.textDark)),
              ]),
            ),
            Flexible(
              child: _pendingEscalationsCount > 0
                  ? ListTile(
                      leading: const Icon(Icons.swap_vert_rounded, color: _C.blue),
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
          ? const Center(child: CircularProgressIndicator(color: _C.blue, strokeWidth: 2.4))
          : RefreshIndicator(
              onRefresh: _loadInitialData,
              color: _C.blue,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                slivers: [
                  SliverToBoxAdapter(child: _headerTHIX(_totalUnreadCount)),
                  SliverToBoxAdapter(child: _searchBarFixed()),
                  SliverToBoxAdapter(child: _filters()),
                  const SliverToBoxAdapter(child: SizedBox(height: 4)),
                  _chatList(),
                  // 🔥 Affichage du loader tout en bas quand on scrolle pour charger la suite
                  if (_isLoadingMore)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: CircularProgressIndicator(color: _C.blue, strokeWidth: 2)),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),
            ),
    );
  }

  Widget _headerTHIX(int unread) {
    return Container(
      color: _C.white,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Text('THIX CHAT',
                    style: TextStyle(
                        fontSize: 21, fontWeight: FontWeight.w800, color: _C.textDark, letterSpacing: -.3)),
                const Spacer(),
                InkWell(
                  onTap: _toggleSearch,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: _showSearchField ? _C.blue : _C.bg,
                      shape: BoxShape.circle,
                    ),
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
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(color: _C.bg, shape: BoxShape.circle),
                      child: const Icon(Icons.swap_vert_rounded, size: 17, color: _C.textDark),
                    ),
                  ),
                  if (_pendingEscalationsCount > 0)
                    Positioned(
                      right: -2,
                      top: -3,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: _C.red,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _C.white, width: 1.4),
                        ),
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
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(color: _C.bg, shape: BoxShape.circle),
                    child: const Icon(Icons.notifications_none_rounded, color: _C.textDark, size: 17),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                _statChip(icon: Icons.mark_chat_unread_rounded, label: 'Non lus', value: unread, color: _C.blue),
                const SizedBox(width: 8),
                _statChip(
                    icon: Icons.swap_vert_rounded,
                    label: 'Escalades',
                    value: _pendingEscalationsCount,
                    color: _C.red),
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
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(10),
      ),
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
          height: 40,
          decoration: BoxDecoration(color: _C.bg, borderRadius: BorderRadius.circular(12)),
          child: TextField(
            controller: _searchCtrl,
            autofocus: true,
            onChanged: _onSearch,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _C.textDark),
            decoration: const InputDecoration(
              hintText: 'Rechercher une conversation...',
              hintStyle: TextStyle(fontSize: 12.5, color: _C.textMuted),
              prefixIcon: Icon(Icons.search_rounded, size: 18, color: _C.textMuted),
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
        height: 32,
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
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: sel ? _C.blue : _C.bg,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(tabs[i],
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w600,
                          color: sel ? Colors.white : _C.textDark)),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _chatList() {
    if (_filtered.isEmpty && !_isLoadingMore) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Center(
            child: Text('Aucune conversation', style: TextStyle(color: _C.textMuted, fontSize: 12.5)),
          ),
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
                  Stack(children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: _C.blueSoft,
                      backgroundImage: conv.displayAvatar != null ? NetworkImage(conv.displayAvatar!) : null,
                      child: conv.displayAvatar == null
                          ? Text(
                              conv.displayName.isNotEmpty ? conv.displayName[0].toUpperCase() : '?',
                              style: const TextStyle(fontWeight: FontWeight.w800, color: _C.blue, fontSize: 15),
                            )
                          : null,
                    ),
                  ]),
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
                              fontWeight: unread ? FontWeight.w700 : FontWeight.w600,
                              color: _C.textDark),
                        ),
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
                      Text(_fmt(t),
                          style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: unread ? _C.blue : _C.textMuted)),
                      const SizedBox(height: 6),
                      if (unread)
                        Container(
                          constraints: const BoxConstraints(minWidth: 19, minHeight: 19),
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(color: _C.blue, shape: BoxShape.circle),
                          child: Text('${conv.unreadCount}',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                        )
                      else
                        const SizedBox(height: 19),
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

  Widget _bottomNotchPro(int unread) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      height: 70,
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Stack(clipBehavior: Clip.none, alignment: Alignment.topCenter, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _navItem(Icons.people_rounded, 'Connexions', 0, false),
          _navItem(Icons.chat_bubble_rounded, 'Chats', 1, unread > 0, badge: unread),
          const SizedBox(width: 56),
          _navItem(Icons.workspaces_rounded, 'Spaces', 2, false),
          _navItem(Icons.settings_rounded, 'Paramètres', 3, false),
        ]),
        Positioned(
          top: -14,
          child: GestureDetector(
            onTap: _showCreateMenu,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_C.blue, _C.blueDark]),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: _C.blue.withOpacity(.30), blurRadius: 12, offset: const Offset(0, 5))],
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
            ),
          ),
        ),
      ]),
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
              Icon(ic, size: 19, color: sel ? _C.blue : _C.textMuted),
              if (hasBadge)
                Positioned(
                  right: -6,
                  top: -4,
                  child: Container(width: 7, height: 7, decoration: const BoxDecoration(color: _C.red, shape: BoxShape.circle)),
                ),
            ]),
            const SizedBox(height: 3),
            Text(lb,
                style: TextStyle(
                    fontSize: 9, fontWeight: sel ? FontWeight.w700 : FontWeight.w600, color: sel ? _C.blue : _C.textMuted)),
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
        decoration: const BoxDecoration(color: _C.white, borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 32, height: 4, decoration: BoxDecoration(color: _C.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 14),
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
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(border: Border.all(color: _C.border), borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: _C.blue, borderRadius: BorderRadius.circular(9)),
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
