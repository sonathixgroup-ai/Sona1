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

// 🎨 PALETTE ULTRA-PREMIUM (K.O Design 2.0)
class _ChatColors {
  static const bg = Color(0xFFF8FAFC); // Gris très très clair, presque blanc
  static const surface = Colors.white;
  static const textDark = Color(0xFF0F172A); // Noir profond
  static const textMuted = Color(0xFF64748B); // Gris pro
  
  // Le nouveau dégradé "Signature" pour les éléments importants
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const primarySolid = Color(0xFF4F46E5); // Indigo premium
  
  static const border = Color(0xFFF1F5F9);
  static const online = Color(0xFF10B981);
  static const alert = Color(0xFFEF4444);
  static const gold = Color(0xFFF59E0B);
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
      setState(() => _isLoading = false);
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
      backgroundColor: _ChatColors.bg,
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: _ChatColors.primarySolid))
        : RefreshIndicator(
            onRefresh: _load,
            color: _ChatColors.primarySolid,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                _buildPremiumHeader(),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildSearchBar(),
                      _buildCompactStats(enLigne, nouveauxMsg),
                      _buildOnlineStories(),
                      _buildFilterTabs(),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                _buildChatList(),
                const SliverToBoxAdapter(child: SizedBox(height: 120)), // Espace pour la bottom nav
              ],
            ),
          ),
      // 🚀 LE BOUTON FLOTTANT DISPARAÎT, LA BOTTOM NAV GÈRE TOUT
      bottomNavigationBar: _buildUltimateBottomNav(), 
    );
  }

  // =========================================================================
  // 1. HEADER (Épuré : Sans l'avatar, juste le bouton Escalade)
  // =========================================================================
  Widget _buildPremiumHeader() {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      expandedHeight: 80,
      backgroundColor: _ChatColors.bg,
      surfaceTintColor: _ChatColors.bg,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _ChatColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: _ChatColors.textDark.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: const Icon(Icons.forum_rounded, color: _ChatColors.gold, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('THIX CHAT', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: _ChatColors.textDark, letterSpacing: -0.3)),
                        Text('Connectez-vous. Avancez.', style: TextStyle(fontSize: 11.5, color: _ChatColors.textMuted, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
                // JUSTE LE BOUTON ESCALADE, ADIEU LE CERCLE PROFIL !
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => context.pushNamed('chatEscalationReceived'),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF1F5F9), 
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.swap_vert_rounded, color: Color(0xFF475569), size: 22),
                      ),
                    ),
                    if (_pendingEscalationsCount > 0)
                      Positioned(
                        right: -2, top: -2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: _ChatColors.alert, shape: BoxShape.circle),
                          constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                          child: Text('$_pendingEscalationsCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900), textAlign: TextAlign.center),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 2. RECHERCHE ULTRA SLEEK
  // =========================================================================
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: _ChatColors.surface, 
          borderRadius: BorderRadius.circular(16), 
          border: Border.all(color: _ChatColors.border, width: 1.5)
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged: _onSearch,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _ChatColors.textDark),
          decoration: InputDecoration(
            hintText: 'Rechercher un chat, groupe...',
            hintStyle: const TextStyle(fontSize: 13.5, color: _ChatColors.textMuted, fontWeight: FontWeight.w500),
            prefixIcon: const Icon(Icons.search_rounded, size: 20, color: _ChatColors.textMuted),
            suffixIcon: IconButton(icon: const Icon(Icons.tune_rounded, size: 18, color: _ChatColors.primarySolid), onPressed: (){}),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 3. STATS INVISIBLES MAIS PRÉSENTES
  // =========================================================================
  Widget _buildCompactStats(int enLigne, int nouveaux) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _microStat(Icons.fiber_manual_record, '$enLigne en ligne', _ChatColors.online),
          _microStat(Icons.mark_chat_unread_rounded, '$nouveaux msg', _ChatColors.primarySolid),
          _microStat(Icons.videocam_rounded, '12 réunions', _ChatColors.gold),
        ],
      ),
    );
  }

  Widget _microStat(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: _ChatColors.textMuted)),
      ],
    );
  }

  // =========================================================================
  // 4. STORIES (Inspiration Insta - Dégradé)
  // =========================================================================
  Widget _buildOnlineStories() {
    final contacts = _all.where((c) => !c.isGroup).take(8).toList();
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 12),
      child: SizedBox(
        height: 90,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          scrollDirection: Axis.horizontal,
          itemCount: contacts.length + 1,
          itemBuilder: (context, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.only(right: 18),
                child: Column(
                  children: [
                    Container(
                      width: 58, height: 58,
                      decoration: BoxDecoration(color: _ChatColors.surface, shape: BoxShape.circle, border: Border.all(color: _ChatColors.border, width: 2)),
                      child: const Icon(Icons.add_rounded, color: _ChatColors.textMuted, size: 26),
                    ),
                    const SizedBox(height: 8),
                    const Text('Nouveau', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _ChatColors.textMuted)),
                  ],
                ),
              );
            }
            final conv = contacts[i - 1];
            return Padding(
              padding: const EdgeInsets.only(right: 18),
              child: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(conversationId: conv.id, conversation: conv))),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: const BoxDecoration(shape: BoxShape.circle, gradient: _ChatColors.primaryGradient),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: _ChatColors.bg),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: _ChatColors.surface,
                          backgroundImage: conv.displayAvatar != null ? NetworkImage(conv.displayAvatar!) : null,
                          child: conv.displayAvatar == null ? Text(conv.displayName[0], style: const TextStyle(fontWeight: FontWeight.w900, color: _ChatColors.primarySolid, fontSize: 18)) : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(width: 60, child: Text(conv.displayName.split(' ').first, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _ChatColors.textDark))),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // =========================================================================
  // 5. FILTRES PILLULES
  // =========================================================================
  Widget _buildFilterTabs() {
    final tabs = ['Tous', 'Équipes', 'Appels', 'Favoris', 'Rendez-vous'];
    return SizedBox(
      height: 38,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        itemBuilder: (context, i) {
          final sel = _selectedFilter == i;
          return GestureDetector(
            onTap: () { setState(() => _selectedFilter = i); _applyFilter(); },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              decoration: BoxDecoration(
                color: sel ? _ChatColors.textDark : _ChatColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sel ? _ChatColors.textDark : _ChatColors.border),
                boxShadow: sel ? [BoxShadow(color: _ChatColors.textDark.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 3))] : [],
              ),
              child: Center(child: Text(tabs[i], style: TextStyle(fontSize: 13, fontWeight: sel ? FontWeight.w800 : FontWeight.w600, color: sel ? Colors.white : _ChatColors.textMuted))),
            ),
          );
        },
      ),
    );
  }

  // =========================================================================
  // 6. LA LISTE DE CHATS (Belles typographies, contraste parfait)
  // =========================================================================
  Widget _buildChatList() {
    final list = _filtered;
    if (list.isEmpty) return const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(40), child: Center(child: Text('Aucune conversation trouvée.', style: TextStyle(color: _ChatColors.textMuted, fontSize: 13)))));
    
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
            child: Container(
              color: isUnread ? _ChatColors.primarySolid.withOpacity(0.02) : Colors.transparent, // Léger fond si non lu
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: _ChatColors.border,
                        backgroundImage: conv.displayAvatar != null ? NetworkImage(conv.displayAvatar!) : null,
                        child: conv.displayAvatar == null ? Text(conv.displayName.isNotEmpty ? conv.displayName[0].toUpperCase() : '?', style: const TextStyle(fontWeight: FontWeight.w900, color: _ChatColors.primarySolid, fontSize: 18)) : null,
                      ),
                      if(conv.isGroup) Positioned(bottom: 0, right: 0, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: _ChatColors.surface, shape: BoxShape.circle), child: const Icon(Icons.groups, size: 12, color: _ChatColors.textDark)))
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(conv.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16, fontWeight: isUnread ? FontWeight.w900 : FontWeight.w700, color: _ChatColors.textDark, letterSpacing: -0.2)),
                        const SizedBox(height: 4),
                        Text(last?.content ?? 'Commencez à discuter...', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.5, color: isUnread ? _ChatColors.textDark : _ChatColors.textMuted, fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(_fmt(time), style: TextStyle(fontSize: 11.5, fontWeight: isUnread ? FontWeight.w800 : FontWeight.w600, color: isUnread ? _ChatColors.primarySolid : _ChatColors.textMuted)),
                      const SizedBox(height: 8),
                      if (isUnread) Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4), decoration: const BoxDecoration(gradient: _ChatColors.primaryGradient, shape: BoxShape.circle), child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)))
                      else const SizedBox(height: 20),
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
  // 7. THE "KNOCKOUT" BOTTOM NAV BAR (Bouton central intégré)
  // =========================================================================
  Widget _buildUltimateBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: _ChatColors.surface,
        boxShadow: [BoxShadow(color: _ChatColors.textDark.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navIcon(Icons.home_rounded, 'Accueil', 0),
              _navIcon(Icons.chat_bubble_rounded, 'Chats', 1, badge: _all.fold(0,(s,c)=>s+c.unreadCount)),
              
              // 🌟 LE BOUTON CRÉER CENTRAL
              GestureDetector(
                onTap: _showCreateMenu,
                child: Container(
                  height: 52, width: 52,
                  decoration: BoxDecoration(
                    gradient: _ChatColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: _ChatColors.primarySolid.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
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

  Widget _navIcon(IconData icon, String label, int idx, {int badge=0}) {
    final sel = _selectedNav == idx;
    return InkWell(
      onTap: () => setState(() => _selectedNav = idx),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 26, color: sel ? _ChatColors.textDark : _ChatColors.textMuted.withOpacity(0.6)),
                if(badge > 0) Positioned(right: -6, top: -4, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: _ChatColors.alert, shape: BoxShape.circle), child: Text('$badge', style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w900)))),
              ],
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: sel ? FontWeight.w800 : FontWeight.w600, color: sel ? _ChatColors.textDark : _ChatColors.textMuted.withOpacity(0.8))),
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
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: _ChatColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: _ChatColors.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            _sheetOpt(Icons.chat_bubble_rounded, 'Nouvelle discussion', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewConversationPage()))),
            const SizedBox(height: 12),
            _sheetOpt(Icons.group_add_rounded, 'Nouveau groupe', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupCreatePage()))),
            const SizedBox(height: 24),
          ]
        )
      )
    );
  }

  Widget _sheetOpt(IconData i, String t, VoidCallback tap){ 
    return InkWell(
      onTap: (){ Navigator.pop(context); tap(); }, 
      child: Container(
        padding: const EdgeInsets.all(16), 
        decoration: BoxDecoration(border: Border.all(color: _ChatColors.border, width: 1.5), borderRadius: BorderRadius.circular(16)), 
        child: Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: _ChatColors.bg, shape: BoxShape.circle), child: Icon(i, size: 22, color: _ChatColors.primarySolid)), 
          const SizedBox(width: 16), 
          Text(t, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _ChatColors.textDark))
        ])
      )
    ); 
  }

  String _fmt(DateTime t){ final now=DateTime.now(); final d=DateTime(t.year,t.month,t.day); final today=DateTime(now.year,now.month,now.day); if(d==today) return DateFormat('HH:mm').format(t); if(d==today.subtract(const Duration(days:1))) return 'Hier'; if(now.difference(t).inDays<7) return DateFormat('E','fr_FR').format(t); return DateFormat('dd/MM').format(t); }
}
