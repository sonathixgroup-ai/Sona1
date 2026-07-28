// lib/presentation/chat/chat_list_page.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/chat/chat_conversation.dart';
import 'providers/chat_list_provider.dart';
import 'chat_screen.dart';
import 'new_conversation_page.dart';
import 'package:thix_id/presentation/chat/screens/group_create_page.dart';
import 'settings/chat_settings_page.dart';

// Palette "Enterprise SaaS" (Totalement différent de WhatsApp)
class _C {
  static const bg = Color(0xFFF1F5F9); // Gris perle (fond d'application pro)
  static const surface = Colors.white; // Cartes
  static const border = Color(0xFFE2E8F0);
  static const primary = Color(0xFF1D4ED8); // Bleu Corporate (type Teams/LinkedIn)
  static const primaryLight = Color(0xFFEFF6FF);
  static const textMain = Color(0xFF0F172A);
  static const textMuted = Color(0xFF64748B);
  static const unreadAccent = Color(0xFF3B82F6); 
  static const red = Color(0xFFEF4444);
}

class ChatListPage extends ConsumerStatefulWidget {
  const ChatListPage({super.key});
  @override 
  ConsumerState<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends ConsumerState<ChatListPage> {
  final _searchCtrl = TextEditingController();
  final _scroll = ScrollController();
  bool _showSearch = false;
  int _selectedNav = 1;

  @override 
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300) {
        ref.read(chatListProvider.notifier).loadMore();
      }
    });
  }

  @override 
  void dispose() { 
    _searchCtrl.dispose(); 
    _scroll.dispose(); 
    super.dispose(); 
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchCtrl.clear();
        ref.read(chatListProvider.notifier).search('');
      }
    });
  }

  void _openNotifications(int pending) {
    showModalBottomSheet(
      context: context, 
      backgroundColor: Colors.transparent, 
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.6),
        decoration: const BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 20, offset: Offset(0, -5))]
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 5, decoration: BoxDecoration(color: _C.border, borderRadius: BorderRadius.circular(3))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10), 
            child: Row(children: const [
              Icon(Icons.notifications_outlined, color: _C.textMain, size: 24), 
              SizedBox(width: 10), 
              Text('Notifications', style: TextStyle(color: _C.textMain, fontSize: 18, fontWeight: FontWeight.bold))
            ])
          ),
          const Divider(height: 1, color: _C.border),
          Flexible(
            child: pending > 0 
              ? ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: _C.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.swap_vert_rounded, color: _C.red)),
                  title: Text('$pending escalade(s) en attente', style: const TextStyle(color: _C.textMain, fontWeight: FontWeight.w700, fontSize: 14)),
                  subtitle: const Text('Requiert votre attention', style: TextStyle(color: _C.textMuted, fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: _C.textMuted),
                  onTap: () { Navigator.pop(ctx); context.pushNamed('chatEscalationReceived'); },
                ) 
              : const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: Text('Aucune notification', style: TextStyle(color: _C.textMuted, fontSize: 14))))
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  void _showCreateMenu() {
    showModalBottomSheet(
      context: context, 
      backgroundColor: Colors.transparent, 
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32), 
        decoration: const BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 20, offset: Offset(0, -5))]
        ), 
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 5, decoration: BoxDecoration(color: _C.border, borderRadius: BorderRadius.circular(3))), 
          const SizedBox(height: 24), 
          _sheetOpt(Icons.chat_bubble_outline_rounded, 'Nouvelle discussion', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewConversationPage()))), 
          const SizedBox(height: 12), 
          _sheetOpt(Icons.group_add_outlined, 'Créer une équipe (Groupe)', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupCreatePage())))
        ])
      )
    );
  }

  Widget _sheetOpt(IconData icon, String text, VoidCallback tap) => InkWell(
    onTap: () { Navigator.pop(context); tap(); }, 
    borderRadius: BorderRadius.circular(16), 
    child: Container(
      padding: const EdgeInsets.all(16), 
      decoration: BoxDecoration(color: _C.bg, border: Border.all(color: _C.border), borderRadius: BorderRadius.circular(16)), 
      child: Row(children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: _C.primary, borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 20, color: Colors.white)), 
        const SizedBox(width: 16), 
        Text(text, style: const TextStyle(color: _C.textMain, fontSize: 15, fontWeight: FontWeight.w700))
      ])
    )
  );

  @override 
  Widget build(BuildContext context) {
    final state = ref.watch(chatListProvider);
    final notifier = ref.read(chatListProvider.notifier);

    return Scaffold(
      backgroundColor: _C.bg,
      bottomNavigationBar: _corporateBottomNav(state.totalUnread),
      // Bouton d'action flottant Étendu (Style Gmail / Enterprise)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateMenu,
        backgroundColor: _C.primary,
        elevation: 4,
        icon: const Icon(Icons.edit_square, color: Colors.white, size: 20),
        label: const Text('Nouveau', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
      ),
      body: state.isLoading 
        ? const Center(child: CircularProgressIndicator(color: _C.primary, strokeWidth: 3)) 
        : RefreshIndicator(
            color: _C.primary, 
            backgroundColor: Colors.white,
            onRefresh: () async => notifier.refresh(),
            child: CustomScrollView(
              controller: _scroll,
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                _buildCorporateAppBar(state.pendingEscalations),
                SliverToBoxAdapter(child: _searchBar()),
                SliverToBoxAdapter(child: _filters(state.filterIndex)),
                if (state.pendingEscalations > 0) SliverToBoxAdapter(child: _escalationBanner(state.pendingEscalations)),
                _chatList(state.filtered),
                if (state.isLoadingMore) const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Center(child: CircularProgressIndicator(color: _C.primary, strokeWidth: 3)))),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
    );
  }

  Widget _buildCorporateAppBar(int pending) {
    return SliverAppBar(
      backgroundColor: Colors.white,
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 2,
      shadowColor: Colors.black.withOpacity(0.05),
      titleSpacing: 20,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: _C.primary, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.chat_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          const Text('THIX CHAT', style: TextStyle(color: _C.textMain, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        ],
      ),
      actions: [
        // 1. Bouton Escalade (Les deux traits verticaux) remis avant la recherche
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.swap_vert_rounded, color: _C.textMain, size: 26),
              onPressed: () => context.pushNamed('chatEscalationReceived'),
              splashRadius: 24,
            ),
            if (pending > 0) 
              Positioned(
                right: 8, top: 8, 
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(color: _C.red, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white, width: 1.5)),
                  child: Text('$pending', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                )
              ),
          ],
        ),
        // 2. Bouton Recherche
        IconButton(
          icon: Icon(_showSearch ? Icons.close_rounded : Icons.search_rounded, color: _C.textMain, size: 24),
          onPressed: _toggleSearch,
          splashRadius: 24,
        ),
        // 3. Bouton Notifications
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded, color: _C.textMain, size: 24),
          onPressed: () => _openNotifications(pending),
          splashRadius: 24,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _escalationBanner(int pending) {
    return GestureDetector(
      onTap: () => context.pushNamed('chatEscalationReceived'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.red.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: _C.red.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: _C.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.warning_amber_rounded, color: _C.red, size: 20)
          ),
          const SizedBox(width: 16),
          Expanded(child: Text('$pending escalade(s) requiert votre attention', style: const TextStyle(color: _C.textMain, fontWeight: FontWeight.w700, fontSize: 13))),
          const Icon(Icons.arrow_forward_ios_rounded, color: _C.textMuted, size: 14)
        ]),
      ),
    );
  }

  Widget _searchBar() => AnimatedCrossFade(
    duration: const Duration(milliseconds: 200), 
    crossFadeState: _showSearch ? CrossFadeState.showFirst : CrossFadeState.showSecond, 
    firstChild: Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16), 
      child: Container(
        height: 44, 
        decoration: BoxDecoration(color: _C.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.border)), 
        child: TextField(
          controller: _searchCtrl, 
          autofocus: true, 
          onChanged: (v) => ref.read(chatListProvider.notifier).search(v), 
          style: const TextStyle(fontSize: 14, color: _C.textMain, fontWeight: FontWeight.w500), 
          decoration: const InputDecoration(
            hintText: 'Rechercher un collègue, un ID...', 
            hintStyle: TextStyle(fontSize: 14, color: _C.textMuted), 
            prefixIcon: Icon(Icons.search_rounded, size: 18, color: _C.textMuted), 
            border: InputBorder.none, 
            contentPadding: EdgeInsets.symmetric(vertical: 13)
          )
        )
      )
    ), 
    secondChild: const SizedBox(height: 0)
  );

  Widget _filters(int selected) {
    final tabs = ['Toutes', 'Non lues', 'Équipes', 'Personnelles'];
    return Container(
      color: Colors.white,
      height: 54, 
      padding: const EdgeInsets.only(bottom: 16),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16), 
        scrollDirection: Axis.horizontal, 
        itemCount: tabs.length, 
        itemBuilder: (ctx, i) { 
          final sel = selected == i; 
          return Padding(
            padding: const EdgeInsets.only(right: 8), 
            child: InkWell(
              onTap: () => ref.read(chatListProvider.notifier).setFilter(i), 
              borderRadius: BorderRadius.circular(10), 
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200), 
                padding: const EdgeInsets.symmetric(horizontal: 16), 
                alignment: Alignment.center, 
                decoration: BoxDecoration(
                  color: sel ? _C.textMain : _C.bg, 
                  borderRadius: BorderRadius.circular(10), 
                  border: Border.all(color: sel ? _C.textMain : _C.border)
                ), 
                child: Text(tabs[i], style: TextStyle(fontSize: 13, fontWeight: sel ? FontWeight.bold : FontWeight.w600, color: sel ? Colors.white : _C.textMuted))
              )
            )
          ); 
        }
      )
    );
  }

  Widget _chatList(List<ChatConversation> list) {
    if (list.isEmpty) return const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(40), child: Center(child: Text('Aucune conversation', style: TextStyle(color: _C.textMuted, fontSize: 14)))));
    
    return SliverList(delegate: SliverChildBuilderDelegate((ctx, idx) {
      final conv = list[idx];
      final last = conv.lastMessage;
      final t = last != null ? last.createdAt : conv.updatedAt;
      final unread = conv.unreadCount > 0;
      
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(conversationId: conv.id, conversation: conv))),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: unread ? _C.primary.withOpacity(0.3) : _C.border),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]
            ),
            child: Row(children: [
              // Avatar "Squircle" (Carré arrondi) - Design typique SaaS / Enterprise
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  color: _C.bg,
                  borderRadius: BorderRadius.circular(16),
                  image: conv.displayAvatar != null ? DecorationImage(image: NetworkImage(conv.displayAvatar!), fit: BoxFit.cover) : null,
                ),
                child: conv.displayAvatar == null 
                  ? Center(child: Text(conv.displayName.isNotEmpty ? conv.displayName[0].toUpperCase() : '?', style: const TextStyle(fontWeight: FontWeight.bold, color: _C.textMuted, fontSize: 18)))
                  : null,
              ),
              const SizedBox(width: 16),
              
              // Contenu central
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(child: Text(conv.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _C.textMain))), 
                          if (conv.isGroup) const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.groups_rounded, size: 16, color: _C.textMuted))
                        ]
                      )
                    ),
                    Text(_fmt(t), style: TextStyle(fontSize: 11, fontWeight: unread ? FontWeight.bold : FontWeight.w600, color: unread ? _C.primary : _C.textMuted)),
                  ]
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(child: Text(last?.content ?? 'Nouvelle conversation', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: unread ? FontWeight.w600 : FontWeight.w500, color: unread ? _C.textMain : _C.textMuted))),
                    if (unread) 
                      Container(
                        margin: const EdgeInsets.only(left: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), 
                        decoration: BoxDecoration(color: _C.primary, borderRadius: BorderRadius.circular(8)), 
                        child: Text('${conv.unreadCount} NOUVEAU', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5))
                      )
                  ]
                ),
              ])),
            ]),
          ),
        ),
      );
    }, childCount: list.length));
  }

  // Barre de navigation style Dashboard Professionnel
  Widget _corporateBottomNav(int unread) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _C.border, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: _selectedNav,
          onTap: (idx) {
            if (idx == 0) context.pushNamed('connections'); 
            else if (idx == 2) context.pushNamed('workspaces'); // Route fictive si applicable
            else if (idx == 3) Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatSettingsPage())); 
            else setState(() => _selectedNav = idx);
          },
          backgroundColor: Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: _C.primary,
          unselectedItemColor: _C.textMuted,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, height: 1.5),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, height: 1.5),
          items: [
            const BottomNavigationBarItem(icon: Icon(Icons.people_alt_outlined), activeIcon: Icon(Icons.people_alt), label: 'Réseau'),
            BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none, 
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded), 
                  if (unread > 0) Positioned(right: -4, top: -4, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: _C.primary, shape: BoxShape.circle)))
                ]
              ), 
              activeIcon: Stack(
                clipBehavior: Clip.none, 
                children: [
                  const Icon(Icons.chat_bubble_rounded), 
                  if (unread > 0) Positioned(right: -4, top: -4, child: Container(width: 8, height: 8, decoration: BoxDecoration(color: _C.primary, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5))))
                ]
              ), 
              label: 'Discussions'
            ),
            const BottomNavigationBarItem(icon: Icon(Icons.workspaces_outline), activeIcon: Icon(Icons.workspaces_filled), label: 'Espaces'),
            const BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: 'Réglages'),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime d) {
    final now = DateTime.now();
    final day = DateTime(d.year, d.month, d.day);
    final today = DateTime(now.year, now.month, now.day);
    if (day == today) return DateFormat('HH:mm').format(d);
    if (day == today.subtract(const Duration(days: 1))) return 'Hier';
    if (now.difference(d).inDays < 7) return DateFormat('EEEE', 'fr_FR').format(d); // Affiche 'lundi', 'mardi' comme demandé
    return DateFormat('dd/MM/yy').format(d);
  }
}
