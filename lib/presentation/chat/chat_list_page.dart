// lib/presentation/chat/chat_list_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/chat/chat_service.dart';
import '../../services/chat/presence_service.dart';
import '../../models/chat/chat_conversation.dart';
import 'chat_screen.dart';
import 'new_conversation_page.dart';
import 'package:thix_id/presentation/chat/screens/group_create_page.dart';

class _C {
  static const bg = Color(0xFFF7F8FD);
  static const white = Colors.white;
  static const navy = Color(0xFF1A1C6B);
  static const blue = Color(0xFF2F5BFF);
  static const softBlue = Color(0xFFEEF2FF);
  static const textMuted = Color(0xFF8A8FA8);
  static const border = Color(0xFFECEEF6);
  static const green = Color(0xFF10B981);
  static const orange = Color(0xFFFF8A1A);
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
  int _pendingEscalations = 0;
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
          final res = await Supabase.instance.client.from('escalation_steps').select('id').eq('to_agent_id', user.id).eq('status', 0).count();
          pending = (res.count as int?) ?? 0;
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _all = convs;
        _filtered = convs;
        _pendingEscalations = pending;
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
      _filtered = _all.where((c) => c.displayName.toLowerCase().contains(q) || (c.lastMessage?.content ?? '').toLowerCase().contains(q)).toList();
    });
    _applyFilter();
  }

  void _applyFilter() {
    List<ChatConversation> base = _searchCtrl.text.isEmpty ? _all : _filtered;
    List<ChatConversation> result;
    switch (_selectedFilter) {
      case 1: result = base.where((c) => c.isGroup).toList(); break;
      case 2: result = []; break; // Appels -> tu brancheras call_history
      case 3: result = base.where((c) => c.unreadCount > 0).toList(); break; // Favoris = non lus pour l'instant
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
      backgroundColor: _C.bg,
      body: SafeArea(
        child: _isLoading ? const Center(child: CircularProgressIndicator(color: _C.blue))
        : RefreshIndicator(
          onRefresh: _load,
          color: _C.blue,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              SliverToBoxAdapter(child: _header()),
              SliverToBoxAdapter(child: _searchBar()),
              SliverToBoxAdapter(child: _statsCard(enLigne, nouveauxMsg)),
              SliverToBoxAdapter(child: _enLigneSection()),
              SliverToBoxAdapter(child: _filterTabs()),
              SliverToBoxAdapter(child: _sectionTitle()),
              _conversationSliver(),
              const SliverToBoxAdapter(child: SizedBox(height: 110)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _bottomNav(),
      floatingActionButton: _fab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          const Icon(Icons.menu, size: 22, color: _C.navy),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              RichText(text: TextSpan(children: [
                TextSpan(text: 'THIX ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _C.navy, letterSpacing:.5)),
                TextSpan(text: 'CHAT', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _C.blue)),
              ])),
              Text('Connectez-vous. Échangez. Avancez.', style: TextStyle(fontSize: 10.5, color: _C.textMuted, fontWeight: FontWeight.w500)),
            ]),
          ),
          IconButton(onPressed: (){}, icon: const Icon(Icons.search_rounded, color: _C.navy, size: 22)),
          Stack(children: [
            IconButton(onPressed: _load, icon: const Icon(Icons.notifications_none_rounded, color: _C.navy, size: 22)),
            if(_pendingEscalations>0) Positioned(right: 6, top: 6, child: Container(padding: const EdgeInsets.all(3), decoration: const BoxDecoration(color: _C.blue, shape: BoxShape.circle), child: Text('$_pendingEscalations', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800)))),
          ]),
          const SizedBox(width: 4),
          Container(padding: const EdgeInsets.all(1.5), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _C.border)), child: const CircleAvatar(radius: 16, backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=12'))),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        height: 42,
        decoration: BoxDecoration(color: _C.softBlue, borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          const SizedBox(width: 12),
          const Icon(Icons.search, size: 18, color: _C.textMuted),
          const SizedBox(width: 8),
          Expanded(child: TextField(controller: _searchCtrl, onChanged: _onSearch, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), decoration: const InputDecoration(hintText: 'Rechercher un chat, contact, groupe...', hintStyle: TextStyle(fontSize: 12.5, color: _C.textMuted), border: InputBorder.none, isDense: true))),
          IconButton(icon: const Icon(Icons.tune_rounded, size: 18, color: _C.navy), onPressed: (){}),
        ]),
      ),
    );
  }

  Widget _statsCard(int enLigne, int nouveaux) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(color: _C.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0,4))]),
      child: Row(children: [
        _stat(icon: Icons.groups_rounded, color: _C.green, value: '$enLigne', label: 'En ligne'),
        _divider(),
        _stat(icon: Icons.chat_bubble_rounded, color: _C.blue, value: '$nouveaux', label: 'Nouveaux\nmessages'),
        _divider(),
        _stat(icon: Icons.videocam_rounded, color: _C.blue, value: '12', label: 'Réunions\nactives'),
        _divider(),
        _stat(icon: Icons.verified_user_rounded, color: _C.orange, value: '$_pendingEscalations', label: 'Alertes\nsécurité', isLast: true),
      ]),
    );
  }
  Widget _stat({required IconData icon, required Color color, required String value, required String label, bool isLast=false}) {
    return Expanded(child: Column(children: [
      Icon(icon, size: 18, color: color),
      const SizedBox(height: 6),
      Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _C.navy)),
      const SizedBox(height: 2),
      Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, height: 1.1, color: _C.textMuted, fontWeight: FontWeight.w600)),
    ]));
  }
  Widget _divider() => Container(width: 1, height: 34, color: _C.border);

  Widget _enLigneSection() {
    final contacts = _all.where((c) => !c.isGroup).take(6).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text('En ligne', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: _C.navy)),
              const Spacer(),
              InkWell(
                onTap: () {},
                child: const Row(
                  children: [
                    Text('Voir tout', style: TextStyle(fontSize: 11, color: _C.blue, fontWeight: FontWeight.w700)),
                    Icon(Icons.chevron_right, size: 14, color: _C.blue)
                  ]
                )
              )
            ]
          )
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 72,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: contacts.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (c, i) {
              if (i == 0) {
                return Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(color: _C.softBlue, shape: BoxShape.circle, border: Border.all(color: _C.border)),
                      child: const Icon(Icons.add, color: _C.navy, size: 20)
                    ),
                    const SizedBox(height: 5),
                    const Text('Nouvelle\nhistoire', textAlign: TextAlign.center, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: _C.textMuted, height: 1.1))
                  ]
                );
              }
              final conv = contacts[i - 1];
              return InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(conversationId: conv.id, conversation: conv))),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(1.8),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(colors: [_C.blue, Color(0xFF8AA8FF)])
                          ), // CORRECTION DE LA PARENTHÈSE ICI
                          child: CircleAvatar(
                            radius: 22,
                            backgroundColor: _C.softBlue,
                            backgroundImage: conv.displayAvatar != null ? NetworkImage(conv.displayAvatar!) : null,
                            child: conv.displayAvatar == null ? Text(conv.displayName[0], style: const TextStyle(fontWeight: FontWeight.w800, color: _C.blue, fontSize: 14)) : null
                          )
                        ),
                        Positioned(
                          bottom: 0,
                          right: 1,
                          child: Container(width: 10, height: 10, decoration: BoxDecoration(color: _C.green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)))
                        )
                      ]
                    ),
                    const SizedBox(height: 5),
                    SizedBox(
                      width: 52,
                      child: Text(conv.displayName.split(' ').first, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _C.navy))
                    )
                  ]
                )
              );
            }
          )
        ),
        const SizedBox(height: 14),
      ]
    );
  }

  Widget _filterTabs() {
    final tabs = [
      {'icon': Icons.chat_bubble_rounded, 'label': 'Tous'},
      {'icon': Icons.groups_rounded, 'label': 'Équipes'},
      {'icon': Icons.call_rounded, 'label': 'Appels'},
      {'icon': Icons.star_rounded, 'label': 'Favoris'},
      {'icon': Icons.calendar_month_rounded, 'label': 'Rendez-vous'},
    ];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: _C.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _C.border)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: List.generate(tabs.length, (i){
        final sel = _selectedFilter==i;
        return InkWell(onTap: (){ setState(()=>_selectedFilter=i); _applyFilter(); }, borderRadius: BorderRadius.circular(12), child: Column(children: [
          Icon(tabs[i]['icon'] as IconData, size: 18, color: sel? _C.blue : _C.textMuted),
          const SizedBox(height: 4),
          Text(tabs[i]['label'] as String, style: TextStyle(fontSize: 10.5, fontWeight: sel? FontWeight.w800:FontWeight.w600, color: sel? _C.blue:_C.textMuted)),
          const SizedBox(height: 4),
          AnimatedContainer(duration: const Duration(milliseconds: 200), height: 2.5, width: sel? 18:0, decoration: BoxDecoration(color: _C.blue, borderRadius: BorderRadius.circular(2))),
        ]));
      })),
    );
  }

  Widget _sectionTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          const Text('Conversations récentes', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: _C.navy)),
          const Spacer(),
          InkWell(
            onTap: () {},
            child: const Row(
              children: [
                Text('Filtres', style: TextStyle(fontSize: 11, color: _C.blue, fontWeight: FontWeight.w700)),
                SizedBox(width: 4),
                Icon(Icons.tune, size: 14, color: _C.blue)
              ]
            )
          )
        ]
      )
    );
  }

  Widget _conversationSliver() {
    final list = _filtered;
    if(list.isEmpty) return const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(30), child: Center(child: Text('Aucune conversation', style: TextStyle(color: _C.textMuted, fontSize: 12)))) );
    return SliverList.separated(
      itemCount: list.length,
      separatorBuilder: (_,__) => const SizedBox(height: 8),
      itemBuilder: (context, idx) {
        final conv = list[idx];
        final last = conv.lastMessage;
        final time = last != null ? last.createdAt : conv.updatedAt;
        final unread = conv.unreadCount;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(conversationId: conv.id, conversation: conv))),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _C.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: unread > 0 ? _C.blue.withOpacity(0.18) : _C.border)
              ),
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: _C.softBlue,
                        backgroundImage: conv.displayAvatar != null ? NetworkImage(conv.displayAvatar!) : null,
                        child: conv.displayAvatar == null ? Text(conv.displayName.isNotEmpty ? conv.displayName[0].toUpperCase() : '?', style: const TextStyle(fontWeight: FontWeight.w800, color: _C.blue, fontSize: 14)) : null
                      ),
                      if(conv.isGroup)
                        Positioned(bottom: -2, right: -2, child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: _C.white, shape: BoxShape.circle), child: const Icon(Icons.groups, size: 10, color: _C.blue)))
                      else if(unread == 0)
                        Positioned(bottom: 0, right: 0, child: Container(width: 9, height: 9, decoration: BoxDecoration(color: _C.green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)))),
                    ]
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(child: Text(conv.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: unread > 0 ? FontWeight.w800 : FontWeight.w700, color: _C.navy))),
                            if(!conv.isGroup && conv.displayName.contains('Aminata'))
                              const Padding(padding: EdgeInsets.only(left:4), child: Icon(Icons.verified, size: 12, color: _C.blue))
                          ]
                        ),
                        const SizedBox(height: 3),
                        Text(last?.content ?? 'Nouvelle conversation', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, color: unread > 0 ? _C.navy.withOpacity(0.8) : _C.textMuted, fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.w400)),
                      ]
                    )
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(_fmt(time), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: unread > 0 ? _C.navy : _C.textMuted)),
                      const SizedBox(height: 5),
                      if(unread > 0)
                        Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5), decoration: const BoxDecoration(color: _C.blue, shape: BoxShape.circle), child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)))
                      else
                        const Icon(Icons.push_pin, size: 12, color: Colors.transparent),
                    ]
                  )
                ]
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _fab() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: _C.blue,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: _C.blue.withOpacity(0.35), blurRadius: 14, offset: const Offset(0,6))]
      ),
      child: IconButton(
        icon: const Icon(Icons.add, color: Colors.white, size: 26),
        onPressed: () => showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (ctx) => Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(color: _C.white, borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 36, height: 4, decoration: BoxDecoration(color: _C.border, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                _sheetOpt(Icons.chat_bubble_rounded, 'Nouvelle discussion', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewConversationPage()))),
                const SizedBox(height: 10),
                _sheetOpt(Icons.group_add_rounded, 'Nouveau groupe', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupCreatePage()))),
                const SizedBox(height: 10),
              ]
            )
          )
        )
      )
    );
  }

  Widget _sheetOpt(IconData i, String t, VoidCallback tap){ return InkWell(onTap: (){ Navigator.pop(context); tap(); }, child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(border: Border.all(color: _C.border), borderRadius: BorderRadius.circular(12)), child: Row(children: [Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: _C.softBlue, borderRadius: BorderRadius.circular(8)), child: Icon(i, size: 18, color: _C.blue)), const SizedBox(width: 12), Text(t, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: _C.navy))]))); }

  Widget _bottomNav(){
    return Container(
      margin: const EdgeInsets.fromLTRB(12,0,12,12),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(color: _C.white, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 18, offset: const Offset(0,6))], border: Border.all(color: _C.border)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _nav(Icons.home_rounded, 'Accueil', 0),
        _nav(Icons.chat_bubble_rounded, 'Chats', 1, badge: _all.fold(0,(s,c)=>s+c.unreadCount)),
        const SizedBox(width: 36),
        _nav(Icons.workspaces_rounded, 'Spaces', 2),
        _nav(Icons.person_rounded, 'Profil', 3),
      ]),
    );
  }
  
  Widget _nav(IconData icon, String label, int idx, {int badge=0}){
    final sel = _selectedNav==idx;
    return InkWell(onTap: ()=> setState(()=>_selectedNav=idx), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Stack(clipBehavior: Clip.none, children: [Icon(icon, size: 20, color: sel? _C.blue:_C.textMuted), if(badge>0) Positioned(right: -6, top: -4, child: Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical:1), decoration: const BoxDecoration(color: _C.blue, shape: BoxShape.circle), child: Text('$badge', style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.w800))))]),
      const SizedBox(height: 3),
      Text(label, style: TextStyle(fontSize: 10, fontWeight: sel? FontWeight.w800:FontWeight.w600, color: sel? _C.blue:_C.textMuted)),
      if(sel) Container(margin: const EdgeInsets.only(top:3), width: 4, height: 4, decoration: const BoxDecoration(color: _C.blue, shape: BoxShape.circle)),
    ]));
  }

  String _fmt(DateTime t){ final now=DateTime.now(); final d=DateTime(t.year,t.month,t.day); final today=DateTime(now.year,now.month,now.day); if(d==today) return DateFormat('HH:mm').format(t); if(d==today.subtract(const Duration(days:1))) return 'Hier'; if(now.difference(t).inDays<7) return DateFormat('E','fr_FR').format(t); return DateFormat('dd/MM').format(t); }
}
