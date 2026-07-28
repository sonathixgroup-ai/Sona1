import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/chat/chat_conversation.dart';
import '../providers/chat_list_provider.dart';
import 'chat_screen.dart';
import 'new_conversation_page.dart';
import 'package:thix_id/presentation/chat/screens/group_create_page.dart';
import 'settings/chat_settings_page.dart';

class _C {
  static const bg = Color(0xFF050508);
  static const surface = Color(0xFF0C0C12);
  static const surfaceAlt = Color(0xFF111118);
  static const cardBorder = Color(0x14FFFFFF);
  static const violet = Color(0xFF7C5CFF);
  static const violetDark = Color(0xFF6B4EFF);
  static const violetSoft = Color(0x247C5CFF);
  static const white = Colors.white;
  static const textSecondary = Color(0x99FFFFFF);
  static const textMuted = Color(0x66FFFFFF);
  static const red = Color(0xFFFF0A54);
}

class ChatListPage extends ConsumerStatefulWidget {
  const ChatListPage({super.key});
  @override ConsumerState<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends ConsumerState<ChatListPage> {
  final _searchCtrl = TextEditingController();
  final _scroll = ScrollController();
  bool _showSearch = false;
  int _selectedNav = 1;

  @override void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300) {
        ref.read(chatListProvider.notifier).loadMore();
      }
    });
  }

  @override void dispose() { _searchCtrl.dispose(); _scroll.dispose(); super.dispose(); }

  void _toggleSearch() {
    setState(() {
      _showSearch =!_showSearch;
      if (!_showSearch) {
        _searchCtrl.clear();
        ref.read(chatListProvider.notifier).search('');
      }
    });
  }

  void _openNotifications(int pending) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.6),
        decoration: const BoxDecoration(color: _C.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(24)), border: Border(top: BorderSide(color: _C.cardBorder))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 10),
          Container(width: 34, height: 4, decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(3))),
          Padding(padding: const EdgeInsets.fromLTRB(18,16,18,8), child: Row(children: const [Icon(Icons.notifications_rounded, color: _C.violet, size: 18), SizedBox(width: 8), Text('Notifications', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800))])),
          Flexible(child: pending > 0? ListTile(
            leading: Container(width: 34, height: 34, decoration: BoxDecoration(color: _C.violetSoft, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.swap_vert_rounded, color: _C.violet, size: 17)),
            title: Text('$pending escalade(s) en attente', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
            onTap: () { Navigator.pop(ctx); context.pushNamed('chatEscalationReceived'); },
          ) : const Padding(padding: EdgeInsets.symmetric(vertical: 30), child: Center(child: Text('Aucune nouvelle notification', style: TextStyle(color: _C.textMuted, fontSize: 12))))),
          const SizedBox(height: 12),
        ]),
      ),
    );
  }

  @override Widget build(BuildContext context) {
    final state = ref.watch(chatListProvider);
    final notifier = ref.read(chatListProvider.notifier);

    return Scaffold(
      backgroundColor: _C.bg,
      bottomNavigationBar: _bottomNotch(state.totalUnread),
      body: state.isLoading? const Center(child: CircularProgressIndicator(color: _C.violet, strokeWidth: 2)) : RefreshIndicator(
        color: Colors.white, backgroundColor: _C.surface,
        onRefresh: () async => notifier.refresh(),
        child: CustomScrollView(
          controller: _scroll,
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(child: _header(state.totalUnread, state.pendingEscalations)),
            SliverToBoxAdapter(child: _searchBar()),
            SliverToBoxAdapter(child: _filters(state.filterIndex)),
            const SliverToBoxAdapter(child: SizedBox(height: 4)),
            _chatList(state.filtered),
            if (state.isLoadingMore) const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Center(child: CircularProgressIndicator(color: _C.violet, strokeWidth: 2)))),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  Widget _header(int unread, int pending) {
    return Container(
      color: _C.bg,
      child: SafeArea(bottom: false, child: Padding(
        padding: const EdgeInsets.fromLTRB(18,12,14,10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 32, height: 32, decoration: BoxDecoration(color: _C.violet, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: _C.violet.withOpacity(0.4), blurRadius: 14, offset: const Offset(0,6))]), alignment: Alignment.center, child: const Text('T', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15))),
            const SizedBox(width: 9),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [const Text('THIX CHAT', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.3)), const SizedBox(width: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: const Text('ENTERPRISE', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.black)))]),
              Row(children: const [Icon(Icons.shield_rounded, size: 10, color: _C.violet), SizedBox(width: 3), Text('Chiffre bout en bout', style: TextStyle(fontSize: 10, color: _C.textMuted, fontWeight: FontWeight.w600))]),
            ]),
            const Spacer(),
            InkWell(onTap: _toggleSearch, borderRadius: BorderRadius.circular(20), child: Container(width: 34, height: 34, decoration: BoxDecoration(color: _showSearch? _C.violet : _C.surface, shape: BoxShape.circle, border: Border.all(color: _C.cardBorder)), child: Icon(_showSearch? Icons.close_rounded : Icons.search_rounded, color: Colors.white, size: 17))),
            const SizedBox(width: 8),
            Stack(clipBehavior: Clip.none, children: [
              InkWell(onTap: () => context.pushNamed('chatEscalationReceived'), borderRadius: BorderRadius.circular(20), child: Container(width: 34, height: 34, decoration: BoxDecoration(color: _C.surface, shape: BoxShape.circle, border: Border.all(color: _C.cardBorder)), child: const Icon(Icons.swap_vert_rounded, size: 17, color: Colors.white))),
              if (pending > 0) Positioned(right: -2, top: -3, child: Container(constraints: const BoxConstraints(minWidth: 15, minHeight: 15), padding: const EdgeInsets.symmetric(horizontal: 3), decoration: BoxDecoration(color: _C.red, borderRadius: BorderRadius.circular(8), border: Border.all(color: _C.bg, width: 1.4)), child: Text('$pending', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800)))),
            ]),
            const SizedBox(width: 8),
            InkWell(onTap: () => _openNotifications(pending), borderRadius: BorderRadius.circular(20), child: Container(width: 34, height: 34, decoration: BoxDecoration(color: _C.surface, shape: BoxShape.circle, border: Border.all(color: _C.cardBorder)), child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 17))),
          ]),
          const SizedBox(height: 12),
          Row(children: [_statChip(icon: Icons.mark_chat_unread_rounded, label: 'Non lus', value: unread, color: _C.violet), const SizedBox(width: 8), _statChip(icon: Icons.swap_vert_rounded, label: 'Escalades', value: pending, color: _C.red)]),
        ]),
      )),
    );
  }

  Widget _statChip({required IconData icon, required String label, required int value, required Color color}) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.2))), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 12, color: color), const SizedBox(width: 5), Text('$label: ', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _C.textMuted)), Text('$value', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color))]));

  Widget _searchBar() => Container(color: _C.bg, padding: const EdgeInsets.fromLTRB(16,0,16,10), child: AnimatedCrossFade(duration: const Duration(milliseconds: 180), crossFadeState: _showSearch? CrossFadeState.showFirst : CrossFadeState.showSecond, firstChild: Container(height: 42, decoration: BoxDecoration(color: _C.surface, borderRadius: BorderRadius.circular(21), border: Border.all(color: _C.cardBorder)), child: TextField(controller: _searchCtrl, autofocus: true, onChanged: (v) => ref.read(chatListProvider.notifier).search(v), style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600), decoration: const InputDecoration(hintText: 'Rechercher...', hintStyle: TextStyle(fontSize: 11, color: _C.textMuted), prefixIcon: Icon(Icons.search_rounded, size: 16, color: _C.textMuted), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 10)))), secondChild: const SizedBox(height: 0)));

  Widget _filters(int selected) {
    final tabs = ['Tous','Groupes','Persos','Non lus'];
    return Container(color: _C.bg, padding: const EdgeInsets.fromLTRB(0,2,0,10), child: SizedBox(height: 34, child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 16), scrollDirection: Axis.horizontal, itemCount: tabs.length, itemBuilder: (ctx,i) { final sel = selected == i; return Padding(padding: const EdgeInsets.only(right: 8), child: InkWell(onTap: () => ref.read(chatListProvider.notifier).setFilter(i), borderRadius: BorderRadius.circular(18), child: AnimatedContainer(duration: const Duration(milliseconds: 160), padding: const EdgeInsets.symmetric(horizontal: 14), alignment: Alignment.center, decoration: BoxDecoration(color: sel? Colors.white : _C.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: sel? Colors.white : _C.cardBorder)), child: Text(tabs[i], style: TextStyle(fontSize: 11, fontWeight: sel? FontWeight.w800 : FontWeight.w600, color: sel? Colors.black : _C.textSecondary))))); })));
  }

  Widget _chatList(List<ChatConversation> list) {
    if (list.isEmpty) return const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(40), child: Center(child: Text('Aucune conversation', style: TextStyle(color: _C.textMuted, fontSize: 11)))));
    return SliverList(delegate: SliverChildBuilderDelegate((ctx, idx) {
      final conv = list[idx];
      final last = conv.lastMessage;
      final t = last!= null? last.createdAt : conv.updatedAt;
      final unread = conv.unreadCount > 0;
      return InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(conversationId: conv.id, conversation: conv))),
        child: Container(
          color: _C.bg,
          padding: const EdgeInsets.fromLTRB(16,10,16,10),
          child: Row(children: [
            Container(width: 48, height: 48, padding: const EdgeInsets.all(2), decoration: BoxDecoration(shape: BoxShape.circle, color: unread? _C.violetSoft : Colors.transparent), child: CircleAvatar(radius: 22, backgroundColor: _C.surfaceAlt, backgroundImage: conv.displayAvatar!= null? NetworkImage(conv.displayAvatar!) : null, child: conv.displayAvatar == null? Text(conv.displayName.isNotEmpty? conv.displayName[0].toUpperCase() : '?', style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 13)) : null)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Flexible(child: Text(conv.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: unread? FontWeight.w800 : FontWeight.w600, color: Colors.white))), if (conv.isGroup) const Padding(padding: EdgeInsets.only(left: 5), child: Icon(Icons.groups_rounded, size: 12, color: _C.textMuted))]),
              const SizedBox(height: 3),
              Text(last?.content?? 'Commencez a discuter...', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: unread? FontWeight.w600 : FontWeight.w400, color: unread? _C.textSecondary : _C.textMuted)),
            ])),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(_fmt(t), style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: unread? _C.violet : _C.textMuted)),
              const SizedBox(height: 6),
              if (unread) Container(constraints: const BoxConstraints(minWidth: 18, minHeight: 18), padding: const EdgeInsets.symmetric(horizontal: 5), alignment: Alignment.center, decoration: const BoxDecoration(color: _C.violet, shape: BoxShape.circle), child: Text('${conv.unreadCount}', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800))) else Icon(Icons.done_all_rounded, size: 14, color: _C.textMuted.withOpacity(0.4)),
            ]),
          ]),
        ),
      );
    }, childCount: list.length));
  }

  Widget _bottomNotch(int unread) {
    return Padding(padding: const EdgeInsets.fromLTRB(10,0,10,10), child: SizedBox(height: 78, child: Stack(clipBehavior: Clip.none, alignment: Alignment.bottomCenter, children: [
      Container(height: 66, decoration: BoxDecoration(color: _C.surface, borderRadius: BorderRadius.circular(28), border: Border.all(color: _C.cardBorder), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 24, offset: const Offset(0,10))]), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_navItem(Icons.people_rounded, 'Connexions', 0, false), _navItem(Icons.chat_bubble_rounded, 'Chats', 1, unread > 0), const SizedBox(width: 56), _navItem(Icons.workspaces_rounded, 'Spaces', 2, false), _navItem(Icons.settings_rounded, 'Parametres', 3, false)])),
      Positioned(top: -12, child: GestureDetector(onTap: _showCreateMenu, child: Container(width: 54, height: 54, decoration: BoxDecoration(gradient: const LinearGradient(colors: [_C.violet, _C.violetDark], begin: Alignment.topLeft, end: Alignment.bottomRight), shape: BoxShape.circle, boxShadow: [BoxShadow(color: _C.violet.withOpacity(0.4), blurRadius: 16, offset: const Offset(0,6))], border: Border.all(color: _C.bg, width: 4)), child: const Icon(Icons.add_rounded, color: Colors.white, size: 24)))),
    ])));
  }

  Widget _navItem(IconData ic, String lb, int idx, bool hasBadge, {int badge = 0}) {
    final sel = _selectedNav == idx;
    return InkWell(onTap: () { if (idx == 0) context.pushNamed('connections'); else if (idx == 3) Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatSettingsPage())); else setState(() => _selectedNav = idx); }, child: SizedBox(width: 56, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Stack(clipBehavior: Clip.none, children: [Icon(ic, size: 18, color: sel? Colors.white : _C.textMuted), if (hasBadge) Positioned(right: -6, top: -4, child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: _C.red, shape: BoxShape.circle)))]), const SizedBox(height: 3), Text(lb, style: TextStyle(fontSize: 8.5, fontWeight: sel? FontWeight.w800 : FontWeight.w600, color: sel? Colors.white : _C.textMuted))])));
  }

  void _showCreateMenu() {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (ctx) => Container(padding: const EdgeInsets.all(16), decoration: const BoxDecoration(color: _C.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(24)), border: Border(top: BorderSide(color: _C.cardBorder))), child: Column(mainAxisSize: MainAxisSize.min, children: [Container(width: 34, height: 4, decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(3))), const SizedBox(height: 16), _sheetOpt(Icons.chat_bubble_rounded, 'Nouvelle discussion', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewConversationPage()))), const SizedBox(height: 8), _sheetOpt(Icons.group_add_rounded, 'Nouveau groupe', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupCreatePage())))])));
  }

  Widget _sheetOpt(IconData i, String t, VoidCallback tap) => InkWell(onTap: () { Navigator.pop(context); tap(); }, borderRadius: BorderRadius.circular(14), child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _C.bg, border: Border.all(color: _C.cardBorder), borderRadius: BorderRadius.circular(14)), child: Row(children: [Container(width: 32, height: 32, decoration: BoxDecoration(color: _C.violet, borderRadius: BorderRadius.circular(10)), child: Icon(i, size: 16, color: Colors.white)), const SizedBox(width: 10), Text(t, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700))])));

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
