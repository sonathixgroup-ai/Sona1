import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/chat/chat_service.dart';
import '../../services/chat/presence_service.dart';
import '../../models/chat/chat_conversation.dart';
import 'chat_screen.dart';
import 'new_conversation_page.dart';
import 'package:thix_id/presentation/chat/screens/group_create_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});
  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> with TickerProviderStateMixin {
  late ChatService _chatService;
  late PresenceService _presenceService;
  List<ChatConversation> _conversations = [];
  List<ChatConversation> _filtered = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();
  int _selectedIndex = 1;

  // ─── CHARTE GRAPHITE ELITE ───────────────────────────────
  static const graphite900 = Color(0xFF0E0E10);
  static const graphite800 = Color(0xFF18181B);
  static const graphite700 = Color(0xFF27272A);
  static const graphite600 = Color(0xFF3F3F46);
  static const graphite500 = Color(0xFF71717A);
  static const graphite300 = Color(0xFFE4E4E7);
  static const graphite100 = Color(0xFFF4F4F5);
  static const lime = Color(0xFFE9FF70);
  static const limeDeep = Color(0xFFD4FF32);
  static const white = Colors.white;

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
    _searchController.dispose();
    _presenceService.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final convs = await _chatService.getConversations();
      setState(() {
        _conversations = convs;
        _filtered = convs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: graphite900));
    }
  }

  void _onSearch(String v) {
    final q = v.toLowerCase();
    setState(() => _filtered = _conversations.where((c) => c.displayName.toLowerCase().contains(q) || (c.lastMessage?.content ?? '').toLowerCase().contains(q)).toList());
  }

  List<ChatConversation> get _quickContacts => _conversations.where((c) => !c.isGroup).take(8).toList();
  int get _onlineCount => _conversations.where((c) => !c.isGroup).length;
  int get _groupCount => _conversations.where((c) => c.isGroup).length;
  int get _unread => _conversations.fold(0, (s, c) => s + c.unreadCount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: graphite900, strokeWidth: 2))
          : RefreshIndicator(color: graphite900, onRefresh: _load, child: CustomScrollView(slivers: [
              _buildHeader(),
              SliverToBoxAdapter(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 14),
                _buildMetrics(),
                const SizedBox(height: 20),
                if (_quickContacts.isNotEmpty) ...[
                  _buildSectionTitle('Stories actives', action: 'Voir tout'),
                  const SizedBox(height: 12),
                  _buildStories(),
                  const SizedBox(height: 20),
                ],
                _buildSectionTitle('Messages', count: _filtered.length),
                const SizedBox(height: 10),
                _buildConversations(),
                const SizedBox(height: 110),
              ])),
            ])),
      floatingActionButton: _buildFabElite(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ─────────────────────────────────────────────────────────
  // HEADER ELITE - Verre + Graphite
  // ─────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return SliverAppBar(
      pinned: true, floating: true, elevation: 0, backgroundColor: graphite900, toolbarHeight: 68,
      title: Row(children: [
        Container(width: 38, height: 38, decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(11)), child: const Center(child: Text('T', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: graphite900)))),
        const SizedBox(width: 10),
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Text('THIX CHAT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5)), SizedBox(width: 6), Icon(Icons.verified_rounded, size: 12, color: lime)]),
          Text('chiffré de bout en bout', style: TextStyle(color: graphite500, fontSize: 10, fontWeight: FontWeight.w500)),
        ]),
        const Spacer(),
        _headerBtn(Icons.search_rounded, () => FocusScope.of(context).requestFocus()),
        const SizedBox(width: 8),
        Stack(clipBehavior: Clip.none, children: [
          _headerBtn(Icons.person_rounded, () {}),
          Positioned(bottom: 0, right: 0, child: Container(width: 10, height: 10, decoration: BoxDecoration(color: lime, shape: BoxShape.circle, border: Border.all(color: graphite900, width: 2)))),
        ]),
      ]),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Container(
            height: 42,
            decoration: BoxDecoration(color: graphite800, borderRadius: BorderRadius.circular(14), border: Border.all(color: graphite700)),
            child: Row(children: [
              const SizedBox(width: 12), const Icon(Icons.search_rounded, size: 18, color: graphite500), const SizedBox(width: 8),
              Expanded(child: TextField(controller: _searchController, onChanged: _onSearch, style: const TextStyle(color: Colors.white, fontSize: 13.5), decoration: const InputDecoration(hintText: 'Rechercher, filtrer, @mention...', hintStyle: TextStyle(color: graphite500, fontSize: 13), border: InputBorder.none, isDense: true))),
              if (_searchController.text.isNotEmpty) InkWell(onTap: () { _searchController.clear(); _onSearch(''); }, child: Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: graphite700, shape: BoxShape.circle), child: const Icon(Icons.close_rounded, size: 12, color: Colors.white))),
              Container(width: 1, height: 20, color: graphite700), const SizedBox(width: 8),
              InkWell(onTap: () {}, child: const Padding(padding: EdgeInsets.only(right: 12), child: Icon(Icons.tune_rounded, size: 18, color: graphite300))),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _headerBtn(IconData i, VoidCallback t) => InkWell(onTap: t, borderRadius: BorderRadius.circular(10), child: Container(width: 36, height: 36, decoration: BoxDecoration(color: graphite800, borderRadius: BorderRadius.circular(10), border: Border.all(color: graphite700)), child: Icon(i, size: 18, color: Colors.white)));

  // ── METRICS CHIPS ──
  Widget _buildMetrics() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        _metricChip('$_onlineCount en ligne', Icons.circle, success: true),
        const SizedBox(width: 8),
        _metricChip('$_groupCount groupes', Icons.group_outlined),
        const SizedBox(width: 8),
        _metricChip('$_unread non lus', Icons.bolt_rounded, isAccent: _unread > 0),
      ]),
    );
  }

  Widget _metricChip(String label, IconData icon, {bool success = false, bool isAccent = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: isAccent ? lime : success ? const Color(0xFFE8F5E9) : white, borderRadius: BorderRadius.circular(20), border: Border.all(color: isAccent ? lime : graphite300)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 10, color: isAccent ? graphite900 : success ? const Color(0xFF22C55E) : graphite600),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isAccent ? graphite900 : graphite700)),
      ]),
    );
  }

  // ── SECTION TITLE ──
  Widget _buildSectionTitle(String t, {String? action, int? count}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: graphite900)),
        if (count != null) ...[const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: graphite100, borderRadius: BorderRadius.circular(20)), child: Text('$count', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: graphite600)))],
        const Spacer(),
        if (action != null) Text(action, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: graphite500)),
      ]),
    );
  }

  // ── STORIES STYLE CONTACTS RAPIDES ──
  Widget _buildStories() {
    return SizedBox(
      height: 88,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16), scrollDirection: Axis.horizontal, itemCount: _quickContacts.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          if (i == 0) {
            return Column(children: [
              InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NewConversationPage())),
                borderRadius: BorderRadius.circular(24),
                child: Container(width: 56, height: 56, decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(18), border: Border.all(color: graphite300, width: 1.2, style: BorderStyle.solid)), child: const Icon(Icons.add_rounded, color: graphite900)),
              ),
              const SizedBox(height: 6), const Text('Nouveau', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: graphite600)),
            ]);
          }
          final c = _quickContacts[i - 1];
          return InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(conversationId: c.id, conversation: c))),
            child: Column(children: [
              Container(padding: const EdgeInsets.all(2), decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [lime, Color(0xFFBFFF00), graphite900]), border: Border.all(color: Colors.transparent))),
              Stack(clipBehavior: Clip.none, children: [
                CircleAvatar(radius: 26, backgroundColor: graphite800, backgroundImage: c.displayAvatar != null ? NetworkImage(c.displayAvatar!) : null, child: c.displayAvatar == null ? Text(c.displayName.isNotEmpty ? c.displayName[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)) : null),
                Positioned(bottom: 1, right: 1, child: Container(width: 12, height: 12, decoration: BoxDecoration(color: const Color(0xFF22C55E), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))),
              ]),
              const SizedBox(height: 6),
              SizedBox(width: 58, child: Text(c.displayName.split(' ').first, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: graphite700))),
            ]),
          );
        },
      ),
    );
  }

  // ── CONVERSATIONS - DESIGN INTERNATIONAL ──
  Widget _buildConversations() {
    final list = _searchController.text.isEmpty ? _conversations : _filtered;
    if (list.isEmpty) return const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Aucune conversation', style: TextStyle(color: graphite500))));
    return ListView.separated(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 12), itemCount: list.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF0F0F0), indent: 62),
      itemBuilder: (context, i) {
        final conv = list[i];
        final isGroup = conv.isGroup;
        final name = conv.displayName;
        final avatar = conv.displayAvatar;
        final last = conv.lastMessage;
        final time = last?.createdAt ?? conv.updatedAt;
        final unread = conv.unreadCount;
        final hasUnread = unread > 0;

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(conversationId: conv.id, conversation: conv))),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(color: hasUnread ? white : Colors.transparent, borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              Stack(clipBehavior: Clip.none, children: [
                isGroup
                    ? Container(width: 48, height: 48, decoration: BoxDecoration(color: graphite900, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.groups_rounded, color: lime, size: 22))
                    : CircleAvatar(radius: 24, backgroundColor: graphite800, backgroundImage: avatar != null ? NetworkImage(avatar) : null, child: avatar == null ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)) : null),
                if (!isGroup && hasUnread) Positioned(top: -2, right: -2, child: Container(width: 12, height: 12, decoration: BoxDecoration(color: lime, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))),
              ]),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w600, fontSize: 14, color: graphite900))),
                  const SizedBox(width: 6),
                  if (isGroup) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: graphite100, borderRadius: BorderRadius.circular(6)), child: const Text('GROUPE', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: graphite600))),
                ]),
                const SizedBox(height: 3),
                Row(children: [
                  if (!isGroup && last != null) ...[Icon(last.isRead ? Icons.done_all_rounded : Icons.done_rounded, size: 14, color: last.isRead ? const Color(0xFF0EA5E9) : graphite500), const SizedBox(width: 3)],
                  Expanded(child: Text(isGroup && last != null ? '${last.senderName.split(' ').first}: ${last.content}' : (last?.content ?? 'Nouvelle conversation'), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: hasUnread ? graphite900 : graphite500, fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400))),
                ]),
              ])),
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(_formatTime(time), style: TextStyle(fontSize: 11, fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500, color: hasUnread ? graphite900 : graphite500)),
                const SizedBox(height: 6),
                if (hasUnread) Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: graphite900, borderRadius: BorderRadius.circular(20)), child: Text('$unread', style: const TextStyle(color: lime, fontSize: 11, fontWeight: FontWeight.w800)))
                else const Icon(Icons.chevron_right_rounded, size: 16, color: graphite300),
              ]),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildFabElite() {
    return FloatingActionButton.extended(
      onPressed: () => showModalBottomSheet(
        context: context, backgroundColor: white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) => SafeArea(child: Padding(padding: const EdgeInsets.all(16), child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4, decoration: BoxDecoration(color: graphite300, borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 16),
          _sheetItem(Icons.chat_bubble_rounded, 'Nouvelle discussion', '1-à-1 chiffrée', () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => NewConversationPage())); }),
          _sheetItem(Icons.group_add_rounded, 'Nouveau groupe', 'Jusqu’à 256 membres', () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => GroupCreatePage())); }),
        ]))),
      ),
      backgroundColor: graphite900, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      icon: const Icon(Icons.edit_rounded, color: lime, size: 18), label: const Text('Nouveau', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
    );
  }

  Widget _sheetItem(IconData i, String t, String s, VoidCallback tap) => ListTile(leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: graphite900, borderRadius: BorderRadius.circular(12)), child: Icon(i, color: lime)), title: Text(t, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)), subtitle: Text(s, style: const TextStyle(fontSize: 12, color: graphite500)), onTap: tap);

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(color: white, border: Border(top: BorderSide(color: Color(0xFFEDEDED)))),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _nav(Icons.home_rounded, 'Accueil', 0),
            _nav(Icons.chat_bubble_rounded, 'Chats', 1, badge: _unread),
            _nav(Icons.explore_outlined, 'Espaces', 2),
            _nav(Icons.settings_outlined, 'Réglages', 3),
          ]),
        ),
      ),
    );
  }

  Widget _nav(IconData icon, String label, int idx, {int? badge}) {
    final sel = _selectedIndex == idx;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = idx),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Stack(clipBehavior: Clip.none, children: [
          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: sel ? graphite900 : Colors.transparent, borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 20, color: sel ? Colors.white : graphite500)),
          if (badge != null && badge > 0) Positioned(top: -4, right: -6, child: Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2), decoration: BoxDecoration(color: lime, borderRadius: BorderRadius.circular(20)), child: Text('$badge', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: graphite900)))),
        ]),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: sel ? FontWeight.w800 : FontWeight.w500, color: sel ? graphite900 : graphite500)),
      ]),
    );
  }

  String _formatTime(DateTime t) {
    final now = DateTime.now();
    if (DateUtils.isSameDay(t, now)) return DateFormat('HH:mm').format(t);
    if (DateUtils.isSameDay(t, now.subtract(const Duration(days: 1)))) return 'hier';
    if (now.difference(t).inDays < 7) return DateFormat('EEE', 'fr_FR').format(t);
    return DateFormat('dd/MM').format(t);
  }
}
