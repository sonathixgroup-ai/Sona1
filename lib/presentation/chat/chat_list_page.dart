// lib/presentation/chat/chat_list_page.dart
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

// 🎨 PALETTE DUOTONE 3.0 - COMPACT
class _C {
  static const bg = Color(0xFFF6F7F9);
  static const surface = Colors.white;
  static const dark = Color(0xFF0F172A);
  static const muted = Color(0xFF94A3B8);
  static const primary = Color(0xFF4F46E5);
  static const line = Color(0xFFE2E8F0);
  static const unreadBg = Color(0xFFEEF2FF);
}

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});
  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  late ChatService _chatService;
  late PresenceService _presenceService;
  List<ChatConversation> _all = [];
  List<ChatConversation> _filtered = [];
  bool _isLoading = true;
  final _searchCtrl = TextEditingController();

  int _selectedFilter = 0;
  int _pendingEscalationsCount = 0;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService(Supabase.instance.client);
    _presenceService = PresenceService(Supabase.instance.client);
    _load();
    _presenceService.initPresence();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final convs = await _chatService.getConversations();
      final user = Supabase.instance.client.auth.currentUser;
      int pending = 0;
      if (user!= null) {
        try {
          final res = await Supabase.instance.client
             .from('escalation_steps').select('id')
             .eq('to_agent_id', user.id).eq('status', 0).count();
          pending = (res.count as int?)?? 0;
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
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _onSearch(String v) {
    final q = v.toLowerCase();
    final base = _all.where((c) =>
      c.displayName.toLowerCase().contains(q) ||
      (c.lastMessage?.content?? '').toLowerCase().contains(q)
    ).toList();
    setState(() => _filtered = base);
    _applyFilter(searchOnly: true);
  }

  void _applyFilter({bool searchOnly = false}) {
    if (searchOnly && _selectedFilter == 0) return;
    List<ChatConversation> base = _filtered;
    // si pas de recherche, on repart de _all
    if (_searchCtrl.text.isEmpty) base = _all;

    List<ChatConversation> result;
    switch (_selectedFilter) {
      case 1: result = base.where((c) => c.isGroup).toList(); break;
      case 3: result = base.where((c) => c.unreadCount > 0).toList(); break;
      case 2: result = []; break; // Appels
      case 4: result = base; break; // Rdv
      default: result = base;
    }
    setState(() => _filtered = result);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _presenceService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalUnread = _all.fold(0, (s,c) => s + c.unreadCount);

    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          // CONTENU SCROLLABLE
          _isLoading
         ? const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: _C.primary)))
          : RefreshIndicator(
              color: _C.primary,
              onRefresh: _load,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                slivers: [
                  SliverToBoxAdapter(child: _buildCompactHeader(totalUnread)),
                  SliverToBoxAdapter(child: _buildSearchAndChips()),
                  if(_all.isNotEmpty) SliverToBoxAdapter(child: _buildAvatarsRow()),
                  SliverToBoxAdapter(child: const SizedBox(height: 8)),
                  _buildCompactList(),
                  const SliverToBoxAdapter(child: SizedBox(height: 110)),
                ],
              ),
            ),
          // BOTTOM NAV CAPSULE FLOTTANTE
          Positioned(left: 16, right: 16, bottom: 16, child: _buildCapsuleNav(totalUnread)),
        ],
      ),
    );
  }

  // --- HEADER MINI 40px ---
  Widget _buildCompactHeader(int unread) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
        child: Row(
          children: [
            const Text('Messages', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.8, color: _C.dark)),
            Container(margin: const EdgeInsets.only(left: 8), padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(color: _C.dark, borderRadius: BorderRadius.circular(8)),
              child: Text('${_all.length}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
            ),
            const Spacer(),
            _iconBtn(Icons.swap_vert_rounded, hasBadge: _pendingEscalationsCount > 0, count: _pendingEscalationsCount, onTap: () => context.pushNamed('chatEscalationReceived')),
            const SizedBox(width: 8),
            _iconBtn(Icons.more_horiz_rounded, onTap: () {}),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, {bool hasBadge=false, int count=0, VoidCallback? onTap}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(width: 34, height: 34, decoration: BoxDecoration(color: _C.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: _C.line)),
            child: Icon(icon, size: 18, color: _C.dark)),
        ),
        if(hasBadge) Positioned(right: -3, top: -3, child: Container(padding: const EdgeInsets.all(3.5), decoration: const BoxDecoration(color: _C.primary, shape: BoxShape.circle),
          child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)))),
      ],
    );
  }

  // --- SEARCH + FILTERS SUR UNE SEULE LIGNE ---
  Widget _buildSearchAndChips() {
    final tabs = ['Tous', 'Équipes', 'Non lus', 'Appels'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(height: 38, decoration: BoxDecoration(color: _C.surface, borderRadius: BorderRadius.circular(11), border: Border.all(color: _C.line)),
                  child: TextField(controller: _searchCtrl, onChanged: _onSearch,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(hintText: 'Rechercher', hintStyle: TextStyle(fontSize: 13, color: _C.muted, fontWeight: FontWeight.w500),
                      prefixIcon: Icon(Icons.search_rounded, size: 16, color: _C.muted), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Filtres horizontaux
              SizedBox(height: 38, child: ListView.separated(padding: const EdgeInsets.only(right: 16), scrollDirection: Axis.horizontal, itemCount: tabs.length,
                separatorBuilder: (_,__)=> const SizedBox(width: 6),
                itemBuilder: (c,i){
                  final sel = _selectedFilter == i;
                  return GestureDetector(onTap: (){ setState(()=>_selectedFilter=i); _applyFilter(); },
                    child: Container(padding: const EdgeInsets.symmetric(horizontal: 12), alignment: Alignment.center,
                      decoration: BoxDecoration(color: sel? _C.dark : _C.surface, borderRadius: BorderRadius.circular(11), border: Border.all(color: sel? _C.dark : _C.line)),
                      child: Text(tabs[i], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: sel? Colors.white : _C.muted)),
                    ),
                  );
                }
              )),
            ],
          ),
        ],
      ),
    );
  }

  // --- AVATARS 44px COMPACT ---
  Widget _buildAvatarsRow() {
    final contacts = _all.where((c) =>!c.isGroup).take(10).toList();
    return SizedBox(height: 68, child: ListView.builder(padding: const EdgeInsets.fromLTRB(16, 14, 0, 0), scrollDirection: Axis.horizontal, itemCount: contacts.length + 1,
      itemBuilder: (context,i){
        if(i==0){
          return Padding(padding: const EdgeInsets.only(right: 14),
            child: Column(children: [
              InkWell(onTap: _showCreateMenu, child: Container(width: 42, height: 42, decoration: BoxDecoration(color: _C.surface, shape: BoxShape.circle, border: Border.all(color: _C.line, width: 1.2,)), child: const Icon(Icons.add, size: 18, color: _C.dark))),
              const SizedBox(height: 5), const Text('Créer', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _C.muted))
            ]),
          );
        }
        final conv = contacts[i-1];
        return Padding(padding: const EdgeInsets.only(right: 14),
          child: GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(conversationId: conv.id, conversation: conv))),
            child: Column(children: [
              Stack(children: [
                Container(padding: const EdgeInsets.all(1.5), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _C.primary.withOpacity(0.3), width: 1.5)),
                  child: CircleAvatar(radius: 19, backgroundColor: _C.line, backgroundImage: conv.displayAvatar!= null? NetworkImage(conv.displayAvatar!) : null,
                    child: conv.displayAvatar==null? Text(conv.displayName[0].toUpperCase(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _C.dark)) : null)),
                if(conv.unreadCount>0) Positioned(right: 0, top: 0, child: Container(width: 10, height: 10, decoration: BoxDecoration(color: _C.primary, shape: BoxShape.circle, border: Border.all(color: _C.bg, width: 1.5))))
              ]),
              const SizedBox(height: 5), SizedBox(width: 46, child: Text(conv.displayName.split(' ').first, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _C.dark)))
            ]),
          ),
        );
      }
    ));
  }

  // --- LISTE COMPACTE CARTE SUR CARTE ---
  Widget _buildCompactList() {
    if(_filtered.isEmpty) return const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Aucun chat', style: TextStyle(fontSize: 12, color: _C.muted)))));
    return SliverList.builder(itemCount: _filtered.length, itemBuilder: (c,idx){
      final conv = _filtered[idx];
      final last = conv.lastMessage;
      final unread = conv.unreadCount;
      final isUnread = unread>0;
      return InkWell(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(conversationId: conv.id, conversation: conv))),
        child: Container(margin: EdgeInsets.fromLTRB(12, idx==0?8:0, 12, 6), padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: isUnread? _C.unreadBg : _C.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: isUnread? _C.primary.withOpacity(0.12) : _C.line)),
          child: Row(children: [
            CircleAvatar(radius: 20, backgroundColor: _C.bg, backgroundImage: conv.displayAvatar!=null?NetworkImage(conv.displayAvatar!):null,
              child: conv.displayAvatar==null?Text(conv.displayName[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: _C.dark)):null),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(conv.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.5, fontWeight: isUnread?FontWeight.w800:FontWeight.w700, color: _C.dark))),
                Text(_fmt(last?.createdAt?? conv.updatedAt), style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: isUnread? _C.primary : _C.muted)),
              ]),
              const SizedBox(height: 2),
              Row(children: [
                Expanded(child: Text(last?.content?? 'Nouvelle conversation', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: isUnread?FontWeight.w600:FontWeight.w500, color: isUnread? _C.dark.withOpacity(0.8) : _C.muted))),
                const SizedBox(width: 8),
                if(isUnread) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5), decoration: BoxDecoration(color: _C.primary, borderRadius: BorderRadius.circular(20)), child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)))
                else if(conv.isGroup) const Icon(Icons.push_pin_rounded, size: 12, color: _C.muted)
              ])
            ]))
          ]),
        ),
      );
    });
  }

  // --- BOTTOM NAV CAPSULE ---
  Widget _buildCapsuleNav(int badge) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(color: _C.dark, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: _C.dark.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 8))]),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        _capsuleItem(Icons.grid_view_rounded, false, (){}),
        _capsuleItem(Icons.chat_bubble_rounded, true, (){}, badge: badge),
        // Bouton central intégré dans la capsule
        GestureDetector(onTap: _showCreateMenu, child: Container(width: 36, height: 36, decoration: const BoxDecoration(color: _C.primary, shape: BoxShape.circle), child: const Icon(Icons.add_rounded, color: Colors.white, size: 20))),
        _capsuleItem(Icons.layers_rounded, false, (){}),
        _capsuleItem(Icons.person_rounded, false, (){}),
      ]),
    );
  }

  Widget _capsuleItem(IconData icon, bool sel, VoidCallback tap, {int badge=0}){
    return InkWell(onTap: tap, borderRadius: BorderRadius.circular(12), child: Container(width: 44, height: 36, alignment: Alignment.center,
      child: Stack(clipBehavior: Clip.none, children: [
        Icon(icon, size: 20, color: sel? Colors.white : Colors.white.withOpacity(0.45)),
        if(badge>0) Positioned(right: -8, top: -2, child: Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), decoration: BoxDecoration(color: _C.primary, borderRadius: BorderRadius.circular(10)), child: Text('$badge', style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w800))))
      ]),
    ));
  }

  void _showCreateMenu() {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (ctx) => Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), decoration: const BoxDecoration(color: _C.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 28, height: 3, decoration: BoxDecoration(color: _C.line, borderRadius: BorderRadius.circular(2))), margin: const EdgeInsets.only(bottom: 16)),
        _sheetRow(Icons.chat_rounded, 'Nouveau message', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewConversationPage()))),
        const SizedBox(height: 8),
        _sheetRow(Icons.group_add_rounded, 'Créer un groupe', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupCreatePage()))),
      ]),
    ));
  }

  Widget _sheetRow(IconData i, String t, VoidCallback tap){
    return InkWell(onTap: (){ Navigator.pop(context); tap(); }, borderRadius: BorderRadius.circular(12),
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), decoration: BoxDecoration(border: Border.all(color: _C.line), borderRadius: BorderRadius.circular(12)),
        child: Row(children: [Container(width: 32, height: 32, decoration: BoxDecoration(color: _C.bg, borderRadius: BorderRadius.circular(8)), child: Icon(i, size: 16, color: _C.dark)), const SizedBox(width: 10), Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _C.dark))])));
  }

  String _fmt(DateTime t){ final now=DateTime.now(); final d=DateTime(t.year,t.month,t.day); final today=DateTime(now.year,now.month,now.day); if(d==today) return DateFormat('HH:mm').format(t); if(d==today.subtract(const Duration(days:1))) return 'Hier'; return DateFormat('dd/MM').format(t); }
}
