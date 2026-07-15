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

// 🎨 PALETTE COULEURS PREMIUM
class _ChatColors {
  static const background = Color(0xFFF4F7FC);
  static const surface = Colors.white;
  static const primaryBlue = Color(0xFF2563EB);
  static const navyDeep = Color(0xFF0F172A);
  static const mutedText = Color(0xFF64748B);
  static const border = Color(0xFFE2E8F0);
  static const success = Color(0xFF10B981);
  static const danger = Color(0xFFEF4444);
  static const gold = Color(0xFFEAB308); // Jaune doré pour l'icône de chat
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
      case 2: result = []; break; // Appels
      case 3: result = base.where((c) => c.unreadCount > 0).toList(); break; // Favoris
      case 4: result = base; break; // Rendez-vous
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
      backgroundColor: _ChatColors.background,
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: _ChatColors.primaryBlue))
        : RefreshIndicator(
            onRefresh: _load,
            color: _ChatColors.primaryBlue,
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
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                _buildChatList(),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
      bottomNavigationBar: _buildModernBottomNav(),
      floatingActionButton: _buildSleekFAB(),
    );
  }

  // =========================================================================
  // HEADER EXACTEMENT COMME LA CAPTURE D'ÉCRAN
  // =========================================================================
  Widget _buildPremiumHeader() {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      expandedHeight: 80,
      backgroundColor: _ChatColors.background,
      surfaceTintColor: _ChatColors.background,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    // Icône Dorée THIX CHAT
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _ChatColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: _ChatColors.navyDeep.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: const Icon(Icons.forum_rounded, color: _ChatColors.gold, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('THIX CHAT', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _ChatColors.navyDeep, letterSpacing: 0.2)),
                        Text('Connectez-vous. Avancez.', style: TextStyle(fontSize: 12, color: _ChatColors.mutedText, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Bouton Escalades gris clair
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => context.pushNamed('chatEscalationReceived'),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF1F5F9), // Gris très clair comme sur l'image
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.swap_vert_rounded, color: Color(0xFF64748B), size: 22),
                          ),
                        ),
                        if (_pendingEscalationsCount > 0)
                          Positioned(
                            right: -2, top: -2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: _ChatColors.danger, shape: BoxShape.circle),
                              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                              child: Text('$_pendingEscalationsCount', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    // Avatar Profil avec bordure violette claire
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFD8B4FE), width: 2.5)), // Violet clair comme sur la photo
                      child: const CircleAvatar(radius: 16, backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=12')),
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Container(
        height: 44,
        decoration: BoxDecoration(color: _ChatColors.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: _ChatColors.border)),
        child: TextField(
          controller: _searchCtrl,
          onChanged: _onSearch,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _ChatColors.navyDeep),
          decoration: InputDecoration(
            hintText: 'Rechercher un chat, groupe...',
            hintStyle: const TextStyle(fontSize: 13, color: _ChatColors.mutedText),
            prefixIcon: const Icon(Icons.search_rounded, size: 20, color: _ChatColors.mutedText),
            suffixIcon: IconButton(icon: const Icon(Icons.tune_rounded, size: 18, color: _ChatColors.primaryBlue), onPressed: (){}),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // BANDE DE STATS TRÈS FINE ET DISCRÈTE
  // =========================================================================
  Widget _buildCompactStats(int enLigne, int nouveaux) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _microStat(Icons.groups_rounded, '$enLigne en ligne', _ChatColors.success),
          _microStat(Icons.chat_bubble_rounded, '$nouveaux msg', _ChatColors.primaryBlue),
          _microStat(Icons.videocam_rounded, '12 réunions', _ChatColors.gold),
        ],
      ),
    );
  }

  Widget _microStat(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _ChatColors.navyDeep.withOpacity(0.8))),
      ],
    );
  }

  Widget _buildOnlineStories() {
    final contacts = _all.where((c) => !c.isGroup).take(8).toList();
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: SizedBox(
        height: 80,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: contacts.length + 1,
          itemBuilder: (context, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Column(
                  children: [
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(color: _ChatColors.surface, shape: BoxShape.circle, border: Border.all(color: _ChatColors.border, width: 2)),
                      child: const Icon(Icons.add_rounded, color: _ChatColors.mutedText, size: 24),
                    ),
                    const SizedBox(height: 6),
                    const Text('Nouveau', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _ChatColors.mutedText)),
                  ],
                ),
              );
            }
            final conv = contacts[i - 1];
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(conversationId: conv.id, conversation: conv))),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [_ChatColors.primaryBlue, Color(0xFF60A5FA)])),
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: _ChatColors.surface,
                            backgroundImage: conv.displayAvatar != null ? NetworkImage(conv.displayAvatar!) : null,
                            child: conv.displayAvatar == null ? Text(conv.displayName[0], style: const TextStyle(fontWeight: FontWeight.w800, color: _ChatColors.primaryBlue, fontSize: 16)) : null,
                          ),
                        ),
                        Positioned(bottom: 2, right: 2, child: Container(width: 12, height: 12, decoration: BoxDecoration(color: _ChatColors.success, shape: BoxShape.circle, border: Border.all(color: _ChatColors.surface, width: 2)))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SizedBox(width: 56, child: Text(conv.displayName.split(' ').first, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _ChatColors.navyDeep))),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // FAVORIS EST DE RETOUR
  Widget _buildFilterTabs() {
    final tabs = ['Tous', 'Équipes', 'Appels', 'Favoris', 'Rendez-vous'];
    return SizedBox(
      height: 36,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        itemBuilder: (context, i) {
          final sel = _selectedFilter == i;
          return GestureDetector(
            onTap: () { setState(() => _selectedFilter = i); _applyFilter(); },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: sel ? _ChatColors.navyDeep : _ChatColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sel ? _ChatColors.navyDeep : _ChatColors.border),
              ),
              child: Center(child: Text(tabs[i], style: TextStyle(fontSize: 12, fontWeight: sel ? FontWeight.w700 : FontWeight.w600, color: sel ? Colors.white : _ChatColors.mutedText))),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChatList() {
    final list = _filtered;
    if (list.isEmpty) return const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(40), child: Center(child: Text('Aucune conversation trouvée.', style: TextStyle(color: _ChatColors.mutedText, fontSize: 13)))));
    
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: _ChatColors.border.withOpacity(0.5),
                        backgroundImage: conv.displayAvatar != null ? NetworkImage(conv.displayAvatar!) : null,
                        child: conv.displayAvatar == null ? Text(conv.displayName.isNotEmpty ? conv.displayName[0].toUpperCase() : '?', style: const TextStyle(fontWeight: FontWeight.w800, color: _ChatColors.primaryBlue, fontSize: 18)) : null,
                      ),
                      if(conv.isGroup) Positioned(bottom: 0, right: 0, child: Container(padding: const EdgeInsets.all(3), decoration: const BoxDecoration(color: _ChatColors.surface, shape: BoxShape.circle), child: const Icon(Icons.groups, size: 12, color: _ChatColors.primaryBlue)))
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(conv.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: isUnread ? FontWeight.w800 : FontWeight.w600, color: _ChatColors.navyDeep)),
                        const SizedBox(height: 4),
                        Text(last?.content ?? 'Commencez à discuter...', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: isUnread ? _ChatColors.navyDeep : _ChatColors.mutedText, fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(_fmt(time), style: TextStyle(fontSize: 11, fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500, color: isUnread ? _ChatColors.primaryBlue : _ChatColors.mutedText)),
                      const SizedBox(height: 6),
                      if (isUnread) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), decoration: const BoxDecoration(color: _ChatColors.primaryBlue, shape: BoxShape.circle), child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)))
                      else const SizedBox(height: 18),
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

  Widget _buildSleekFAB() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      height: 56, width: 56,
      decoration: BoxDecoration(color: _ChatColors.primaryBlue, shape: BoxShape.circle, boxShadow: [BoxShadow(color: _ChatColors.primaryBlue.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))]),
      child: IconButton(
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        onPressed: () => showModalBottomSheet(
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
        )
      ),
    );
  }

  Widget _sheetOpt(IconData i, String t, VoidCallback tap){ return InkWell(onTap: (){ Navigator.pop(context); tap(); }, child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(border: Border.all(color: _ChatColors.border), borderRadius: BorderRadius.circular(16)), child: Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _ChatColors.background, borderRadius: BorderRadius.circular(10)), child: Icon(i, size: 20, color: _ChatColors.primaryBlue)), const SizedBox(width: 16), Text(t, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _ChatColors.navyDeep))]))); }

  Widget _buildModernBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: _ChatColors.surface, border: const Border(top: BorderSide(color: _ChatColors.border)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, -4))]),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _nav(Icons.home_rounded, 'Accueil', 0),
            _nav(Icons.chat_bubble_rounded, 'Chats', 1, badge: _all.fold(0,(s,c)=>s+c.unreadCount)),
            const SizedBox(width: 48), 
            _nav(Icons.workspaces_rounded, 'Spaces', 2),
            _nav(Icons.person_rounded, 'Profil', 3),
          ],
        ),
      ),
    );
  }

  Widget _nav(IconData icon, String label, int idx, {int badge=0}) {
    final sel = _selectedNav == idx;
    return InkWell(
      onTap: () => setState(() => _selectedNav = idx),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, size: 24, color: sel ? _ChatColors.primaryBlue : _ChatColors.mutedText),
              if(badge > 0) Positioned(right: -8, top: -6, child: Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical:2), decoration: const BoxDecoration(color: _ChatColors.danger, shape: BoxShape.circle), child: Text('$badge', style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w800)))),
            ],
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: sel ? FontWeight.w800 : FontWeight.w600, color: sel ? _ChatColors.primaryBlue : _ChatColors.mutedText)),
        ],
      ),
    );
  }

  String _fmt(DateTime t){ final now=DateTime.now(); final d=DateTime(t.year,t.month,t.day); final today=DateTime(now.year,now.month,now.day); if(d==today) return DateFormat('HH:mm').format(t); if(d==today.subtract(const Duration(days:1))) return 'Hier'; if(now.difference(t).inDays<7) return DateFormat('E','fr_FR').format(t); return DateFormat('dd/MM').format(t); }
}
