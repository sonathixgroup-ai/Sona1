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

// 🎨 PALETTE DUO-TONE ULTRA-COMPACTE
class _C {
  static const bg = Colors.white; // Fond pur
  static const ink = Color(0xFF0F172A); // Noir/Gris très profond pour le texte et les icônes
  static const accent = Color(0xFF2563EB); // Bleu Électrique unique pour TOUT ce qui est actif
  static const surface = Color(0xFFF8FAFC); // Gris très léger pour délimiter sans alourdir
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
  int _selectedNav = 1;

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
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearch(String v) {
    final q = v.toLowerCase();
    setState(() {
      _filtered = _all.where((c) => 
        c.displayName.toLowerCase().contains(q) || 
        (c.lastMessage?.content ?? '').toLowerCase().contains(q)
      ).toList();
    });
    _applyFilter();
  }

  void _applyFilter() {
    List<ChatConversation> base = _searchCtrl.text.isEmpty ? _all : _filtered;
    List<ChatConversation> result;
    switch (_selectedFilter) {
      case 1: result = base.where((c) => c.isGroup).toList(); break;
      case 2: result = []; break;
      case 3: result = base.where((c) => c.unreadCount > 0).toList(); break;
      case 4: result = base; break;
      default: result = base;
    }
    setState(() => _filtered = _searchCtrl.text.isEmpty && _selectedFilter == 0 ? _all : result);
    if(_searchCtrl.text.isNotEmpty){
      result = _filtered.where((c) => _selectedFilter == 0 || (_selectedFilter == 1 && c.isGroup) || (_selectedFilter == 3 && c.unreadCount > 0)).toList();
      if(_selectedFilter != 0 && _selectedFilter != 1 && _selectedFilter != 3) result = _filtered;
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _presenceService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enLigne = _all.where((c) => !c.isGroup).length;
    final nouveauxMsg = _all.fold(0, (s,c) => s + c.unreadCount);

    return Scaffold(
      backgroundColor: _C.bg,
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: _C.accent, strokeWidth: 2))
        : Stack(
            children: [
              RefreshIndicator(
                onRefresh: _load,
                color: _C.accent,
                backgroundColor: _C.bg,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  slivers: [
                    _buildCompactHeader(),
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCompactSearchAndStats(enLigne, nouveauxMsg),
                          _buildTinyStories(),
                          _buildMinimalFilters(),
                          const Divider(height: 1, thickness: 1, color: _C.surface),
                        ],
                      ),
                    ),
                    _buildDenseChatList(),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)), // Espace pour la nav flottante
                  ],
                ),
              ),
              _buildFloatingPillNav(),
            ],
          ),
    );
  }

  // =========================================================================
  // 1. HEADER COMPACT (Titre + Escalade)
  // =========================================================================
  Widget _buildCompactHeader() {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      expandedHeight: 60,
      backgroundColor: _C.bg,
      surfaceTintColor: _C.bg,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Discussions', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _C.ink, letterSpacing: -0.5)),
                GestureDetector(
                  onTap: () => context.pushNamed('chatEscalationReceived'),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.swap_vert_rounded, color: _C.ink, size: 28),
                      if (_pendingEscalationsCount > 0)
                        Positioned(
                          right: -4, top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(color: _C.accent, shape: BoxShape.circle),
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            child: Text('$_pendingEscalationsCount', style: const TextStyle(color: _C.bg, fontSize: 9, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 2. RECHERCHE & STATS FUSIONNÉES (Gain de place énorme)
  // =========================================================================
  Widget _buildCompactSearchAndStats(int enLigne, int nouveaux) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Container(
            height: 38, // Très fin
            decoration: BoxDecoration(color: _C.surface, borderRadius: BorderRadius.circular(8)),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearch,
              style: const TextStyle(fontSize: 13, color: _C.ink),
              decoration: const InputDecoration(
                hintText: 'Rechercher...',
                hintStyle: TextStyle(fontSize: 13, color: Colors.black38),
                prefixIcon: Icon(Icons.search, size: 18, color: Colors.black38),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _microStat('$enLigne en ligne', true),
              const SizedBox(width: 12),
              _microStat('$nouveaux non lus', false),
              const SizedBox(width: 12),
              _microStat('12 réunions', false),
            ],
          )
        ],
      ),
    );
  }

  Widget _microStat(String text, bool isActive) {
    return Row(
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: isActive ? _C.accent : Colors.black26)),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black54)),
      ],
    );
  }

  // =========================================================================
  // 3. STORIES MINIATURES (36px max)
  // =========================================================================
  Widget _buildTinyStories() {
    final contacts = _all.where((c) => !c.isGroup).take(10).toList();
    return SizedBox(
      height: 60,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: contacts.length + 1,
        itemBuilder: (context, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(border: Border.all(color: Colors.black12), shape: BoxShape.circle),
                child: const Icon(Icons.add, color: _C.ink, size: 20),
              ),
            );
          }
          final conv = contacts[i - 1];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(conversationId: conv.id, conversation: conv))),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _C.accent, width: 1.5)),
                child: CircleAvatar(
                  radius: 18, // Très petit
                  backgroundColor: _C.surface,
                  backgroundImage: conv.displayAvatar != null ? NetworkImage(conv.displayAvatar!) : null,
                  child: conv.displayAvatar == null ? Text(conv.displayName[0], style: const TextStyle(fontWeight: FontWeight.bold, color: _C.ink, fontSize: 12)) : null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // =========================================================================
  // 4. FILTRES TEXTUELS (Minimalistes)
  // =========================================================================
  Widget _buildMinimalFilters() {
    final tabs = ['Tous', 'Équipes', 'Appels', 'Favoris', 'Rendez-vous'];
    return SizedBox(
      height: 40,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        itemBuilder: (context, i) {
          final sel = _selectedFilter == i;
          return GestureDetector(
            onTap: () { setState(() => _selectedFilter = i); _applyFilter(); },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: sel ? const Border(bottom: BorderSide(color: _C.accent, width: 2)) : null,
              ),
              child: Text(tabs[i], style: TextStyle(fontSize: 13, fontWeight: sel ? FontWeight.bold : FontWeight.w500, color: sel ? _C.accent : Colors.black45)),
            ),
          );
        },
      ),
    );
  }

  // =========================================================================
  // 5. LISTE DENSE (Plus d'infos, moins de vide)
  // =========================================================================
  Widget _buildDenseChatList() {
    final list = _filtered;
    if (list.isEmpty) return const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(40), child: Center(child: Text('Aucun résultat.', style: TextStyle(color: Colors.black38, fontSize: 13)))));
    
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, idx) {
          final conv = list[idx];
          final last = conv.lastMessage;
          final time = last != null ? last.createdAt : conv.updatedAt;
          final unread = conv.unreadCount;
          final isUnread = unread > 0;

          return InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(conversationId: conv.id, conversation: conv))),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), // Padding réduit
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 22, // Plus petit
                        backgroundColor: _C.surface,
                        backgroundImage: conv.displayAvatar != null ? NetworkImage(conv.displayAvatar!) : null,
                        child: conv.displayAvatar == null ? Text(conv.displayName.isNotEmpty ? conv.displayName[0].toUpperCase() : '?', style: const TextStyle(fontWeight: FontWeight.bold, color: _C.ink, fontSize: 14)) : null,
                      ),
                      if(conv.isGroup) Positioned(bottom: 0, right: 0, child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: _C.bg, shape: BoxShape.circle), child: const Icon(Icons.groups, size: 10, color: _C.ink)))
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(conv.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: isUnread ? FontWeight.bold : FontWeight.w600, color: _C.ink)),
                        const SizedBox(height: 2),
                        Text(last?.content ?? 'Nouveau chat...', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: isUnread ? _C.ink : Colors.black54, fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_fmt(time), style: TextStyle(fontSize: 10, fontWeight: isUnread ? FontWeight.bold : FontWeight.w500, color: isUnread ? _C.accent : Colors.black38)),
                      const SizedBox(height: 4),
                      if (isUnread) Container(padding: const EdgeInsets.all(5), decoration: const BoxDecoration(color: _C.accent, shape: BoxShape.circle), child: Text('$unread', style: const TextStyle(color: _C.bg, fontSize: 9, fontWeight: FontWeight.bold)))
                      else const SizedBox(height: 18), // Maintien l'alignement
                    ],
                  ),
                ],
              ),
            ),
          );
        },
        childCount: list.length,
      ),
    );
  }

  // =========================================================================
  // 6. BOTTOM NAV : LA PILULE FLOTTANTE (Design Radical)
  // =========================================================================
  Widget _buildFloatingPillNav() {
    return Positioned(
      bottom: 24, left: 24, right: 24,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: _C.ink, // Fond noir profond
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _pillIcon(Icons.home_filled, 0),
            _pillIcon(Icons.chat_bubble_rounded, 1, badge: _all.fold(0,(s,c)=>s+c.unreadCount)),
            
            // BOUTON ACTION CENTRAL (Bleu Électrique)
            GestureDetector(
              onTap: _showCreateMenu,
              child: Container(
                height: 40, width: 40,
                decoration: const BoxDecoration(color: _C.accent, shape: BoxShape.circle),
                child: const Icon(Icons.add, color: _C.bg, size: 24),
              ),
            ),

            _pillIcon(Icons.workspaces_filled, 2),
            _pillIcon(Icons.person, 3),
          ],
        ),
      ),
    );
  }

  Widget _pillIcon(IconData icon, int idx, {int badge=0}) {
    final sel = _selectedNav == idx;
    return GestureDetector(
      onTap: () => setState(() => _selectedNav = idx),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 22, color: sel ? _C.bg : Colors.white38),
            if(badge > 0) Positioned(
              right: -6, top: -6, 
              child: Container(
                padding: const EdgeInsets.all(4), 
                decoration: const BoxDecoration(color: _C.accent, shape: BoxShape.circle), 
                child: Text('$badge', style: const TextStyle(fontSize: 8, color: _C.bg, fontWeight: FontWeight.bold))
              )
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
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: _C.bg, borderRadius: BorderRadius.circular(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 32, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            _sheetOpt(Icons.person_add_alt_1_rounded, 'Nouvelle discussion', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewConversationPage()))),
            _sheetOpt(Icons.group_add_rounded, 'Nouveau groupe', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupCreatePage()))),
            const SizedBox(height: 8),
          ]
        )
      )
    );
  }

  Widget _sheetOpt(IconData i, String t, VoidCallback tap){ 
    return InkWell(
      onTap: (){ Navigator.pop(context); tap(); }, 
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), 
        child: Row(children: [
          Icon(i, size: 20, color: _C.ink), 
          const SizedBox(width: 16), 
          Text(t, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _C.ink))
        ])
      )
    ); 
  }

  String _fmt(DateTime t){ 
    final now=DateTime.now(); 
    final d=DateTime(t.year,t.month,t.day); 
    final today=DateTime(now.year,now.month,now.day); 
    if(d==today) return DateFormat('HH:mm').format(t); 
    if(d==today.subtract(const Duration(days:1))) return 'Hier'; 
    if(now.difference(t).inDays<7) return DateFormat('E','fr_FR').format(t); 
    return DateFormat('dd/MM').format(t); 
  }
}
