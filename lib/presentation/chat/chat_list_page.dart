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

  // ─── CHARTE HOMEPAGE (alignée sur AppColors) ─────────────
  static const primaryBlue = Color(0xFF1877F2);
  static const darkNavy = Color(0xFF111827);
  static const white = Color(0xFFFFFFFF);
  static const lightGrayBg = Color(0xFFF0F2F5);
  static const textSecondary = Color(0xFF4B5563);
  static const cardBorder = Color(0xFFE5E7EB);
  static const goldBadge = Color(0xFFFBBF24);
  static const successGreen = Color(0xFF059669);
  static const dangerRed = Color(0xFFFF3B30);
  static const darkText = Color(0xFF111827);
  static const shadowLight = Color(0x0F000000);
  static const shadowSecondary = Color(0x0A000000);

  static List<BoxShadow> shadowMain = [
    BoxShadow(color: shadowLight, blurRadius: 20, offset: const Offset(0, 4)),
  ];
  static List<BoxShadow> shadowSec = [
    BoxShadow(color: shadowSecondary, blurRadius: 8, offset: const Offset(0, 2)),
  ];

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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: darkNavy));
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
      backgroundColor: lightGrayBg,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryBlue, strokeWidth: 2))
          : RefreshIndicator(color: primaryBlue, onRefresh: _load, child: CustomScrollView(slivers: [
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
  // HEADER — dégradé primaryBlue → darkNavy (cohérent Homepage)
  // ─────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return SliverAppBar(
      pinned: true,
      floating: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      toolbarHeight: 68,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [primaryBlue, darkNavy]),
        ),
      ),
      title: Row(children: [
        Container(width: 38, height: 38, decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(11)), child: const Center(child: Text('T', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: primaryBlue)))),
        const SizedBox(width: 10),
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Text('THIX CHAT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5)), SizedBox(width: 6), Icon(Icons.verified_rounded, size: 12, color: goldBadge)]),
          Text('chiffré de bout en bout', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500)),
        ]),
        const Spacer(),
        _headerBtn(Icons.search_rounded, () => FocusScope.of(context).requestFocus()),
        const SizedBox(width: 8),
        Stack(clipBehavior: Clip.none, children: [
          _headerBtn(Icons.person_rounded, () {}),
          Positioned(bottom: 0, right: 0, child: Container(width: 10, height: 10, decoration: BoxDecoration(color: goldBadge, shape: BoxShape.circle, border: Border.all(color: darkNavy, width: 2)))),
        ]),
      ]),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Container(
            height: 44,
            decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(22), boxShadow: shadowSec),
            child: Row(children: [
              const SizedBox(width: 14), const Icon(Icons.search_rounded, size: 18, color: textSecondary), const SizedBox(width: 8),
              Expanded(child: TextField(controller: _searchController, onChanged: _onSearch, style: const TextStyle(color: darkText, fontSize: 13.5), decoration: const InputDecoration(hintText: 'Rechercher, filtrer, @mention...', hintStyle: TextStyle(color: textSecondary, fontSize: 13), border: InputBorder.none, isDense: true))),
              if (_searchController.text.isNotEmpty) InkWell(onTap: () { _searchController.clear(); _onSearch(''); }, child: Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: lightGrayBg, shape: BoxShape.circle), child: const Icon(Icons.close_rounded, size: 12, color: darkText))),
              Container(width: 1, height: 20, color: cardBorder), const SizedBox(width: 8),
              InkWell(onTap: () {}, child: const Padding(padding: EdgeInsets.only(right: 14), child: Icon(Icons.tune_rounded, size: 18, color: textSecondary))),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _headerBtn(IconData i, VoidCallback t) => InkWell(
        onTap: t,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white.withOpacity(0.2))),
          child: Icon(i, size: 18, color: Colors.white),
        ),
      );

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
      decoration: BoxDecoration(
        color: isAccent ? goldBadge : success ? const Color(0xFFE8F5E9) : white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isAccent ? goldBadge : cardBorder),
        boxShadow: shadowSec,
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 10, color: isAccent ? darkText : success ? successGreen : textSecondary),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isAccent ? darkText : textSecondary)),
      ]),
    );
  }

  // ── SECTION TITLE ──
  Widget _buildSectionTitle(String t, {String? action, int? count}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: darkText)),
        if (count != null) ...[const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: lightGrayBg, borderRadius: BorderRadius.circular(20)), child: Text('$count', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textSecondary)))],
        const Spacer(),
        if (action != null) Text(action, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: primaryBlue)),
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
                child: Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(18), border: Border.all(color: cardBorder, width: 1.2), boxShadow: shadowSec),
                  child: const Icon(Icons.add_rounded, color: primaryBlue),
                ),
              ),
              const SizedBox(height: 6), const Text('Nouveau', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textSecondary)),
            ]);
          }
          final c = _quickContacts[i - 1];
          return InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(conversationId: c.id, conversation: c))),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [goldBadge, primaryBlue])),
                child: Stack(clipBehavior: Clip.none, children: [
                  CircleAvatar(radius: 24, backgroundColor: lightGrayBg, backgroundImage: c.displayAvatar != null ? NetworkImage(c.displayAvatar!) : null, child: c.displayAvatar == null ? Text(c.displayName.isNotEmpty ? c.displayName[0].toUpperCase() : '?', style: const TextStyle(color: darkText, fontWeight: FontWeight.w800)) : null),
                  Positioned(bottom: 0, right: 0, child: Container(width: 12, height: 12, decoration: BoxDecoration(color: successGreen, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))),
                ]),
              ),
              const SizedBox(height: 6),
              SizedBox(width: 58, child: Text(c.displayName.split(' ').first, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: darkText))),
            ]),
          );
        },
      ),
    );
  }

  // ── CONVERSATIONS ──
  Widget _buildConversations() {
    final list = _searchController.text.isEmpty ? _conversations : _filtered;
    if (list.isEmpty) return const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Aucune conversation', style: TextStyle(color: textSecondary))));
    return ListView.separated(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 12), itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
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
            margin: const EdgeInsets.symmetric(vertical: 3),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: hasUnread ? primaryBlue.withOpacity(0.25) : cardBorder, width: hasUnread ? 1.1 : 0.7),
              boxShadow: shadowSec,
            ),
            child: Row(children: [
              Stack(clipBehavior: Clip.none, children: [
                isGroup
                    ? Container(width: 48, height: 48, decoration: BoxDecoration(gradient: const LinearGradient(colors: [primaryBlue, darkNavy]), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.groups_rounded, color: goldBadge, size: 22))
                    : CircleAvatar(radius: 24, backgroundColor: lightGrayBg, backgroundImage: avatar != null ? NetworkImage(avatar) : null, child: avatar == null ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(color: darkText, fontWeight: FontWeight.w800)) : null),
                if (!isGroup && hasUnread) Positioned(top: -2, right: -2, child: Container(width: 12, height: 12, decoration: BoxDecoration(color: goldBadge, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))),
              ]),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w600, fontSize: 14, color: darkText))),
                  const SizedBox(width: 6),
                  if (isGroup) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: lightGrayBg, borderRadius: BorderRadius.circular(6)), child: const Text('GROUPE', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: textSecondary))),
                ]),
                const SizedBox(height: 3),
                Row(children: [
                  if (!isGroup && last != null) ...[Icon(last.isRead ? Icons.done_all_rounded : Icons.done_rounded, size: 14, color: last.isRead ? primaryBlue : textSecondary), const SizedBox(width: 3)],
                  Expanded(child: Text(isGroup && last != null ? '${last.senderName.split(' ').first}: ${last.content}' : (last?.content ?? 'Nouvelle conversation'), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: hasUnread ? darkText : textSecondary, fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400))),
                ]),
              ])),
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(_formatTime(time), style: TextStyle(fontSize: 11, fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500, color: hasUnread ? primaryBlue : textSecondary)),
                const SizedBox(height: 6),
                if (hasUnread) Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: goldBadge, borderRadius: BorderRadius.circular(20)), child: Text('$unread', style: const TextStyle(color: darkText, fontSize: 11, fontWeight: FontWeight.w800)))
                else const Icon(Icons.chevron_right_rounded, size: 16, color: cardBorder),
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
          Container(width: 36, height: 4, decoration: BoxDecoration(color: cardBorder, borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 16),
          _sheetItem(Icons.chat_bubble_rounded, 'Nouvelle discussion', '1-à-1 chiffrée', () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => NewConversationPage())); }),
          _sheetItem(Icons.group_add_rounded, 'Nouveau groupe', 'Jusqu’à 256 membres', () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => GroupCreatePage())); }),
        ]))),
      ),
      backgroundColor: primaryBlue, elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      icon: const Icon(Icons.edit_rounded, color: goldBadge, size: 18), label: const Text('Nouveau', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
    );
  }

  Widget _sheetItem(IconData i, String t, String s, VoidCallback tap) => ListTile(
        leading: Container(width: 44, height: 44, decoration: BoxDecoration(gradient: const LinearGradient(colors: [primaryBlue, darkNavy]), borderRadius: BorderRadius.circular(12)), child: Icon(i, color: goldBadge)),
        title: Text(t, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: darkText)),
        subtitle: Text(s, style: const TextStyle(fontSize: 12, color: textSecondary)),
        onTap: tap,
      );

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(color: white, boxShadow: [BoxShadow(color: shadowLight, blurRadius: 14, offset: const Offset(0, -4))]),
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
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: sel ? const LinearGradient(colors: [primaryBlue, darkNavy]) : null,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: sel ? Colors.white : textSecondary),
          ),
          if (badge != null && badge > 0) Positioned(top: -4, right: -6, child: Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2), decoration: BoxDecoration(color: goldBadge, borderRadius: BorderRadius.circular(20)), child: Text('$badge', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: darkText)))),
        ]),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: sel ? FontWeight.w800 : FontWeight.w500, color: sel ? primaryBlue : textSecondary)),
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
