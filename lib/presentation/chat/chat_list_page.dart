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

// Nouvelle palette "Grandeur Entreprise" (Thème Clair & Lumineux)
class _C {
  static const bg = Colors.white;
  static const surface = Color(0xFFF8FAFC); // Gris perle très léger
  static const border = Color(0xFFE2E8F0);
  static const primary = Color(0xFF0A66C2); // Bleu "Trust" Entreprise
  static const primaryLight = Color(0xFFEFF6FF);
  static const textMain = Color(0xFF0F172A); // Noir/Ardoise profond
  static const textMuted = Color(0xFF64748B);
  static const unreadBadge = Color(0xFF22C55E); // Vert WhatsApp-like
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
                  leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: _C.red.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.warning_amber_rounded, color: _C.red)),
                  title: Text('$pending escalade(s) en attente', style: const TextStyle(color: _C.textMain, fontWeight: FontWeight.w600, fontSize: 15)),
                  subtitle: const Text('Nécessite votre attention immédiate', style: TextStyle(color: _C.textMuted, fontSize: 13)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: _C.textMuted),
                  onTap: () { Navigator.pop(ctx); context.pushNamed('chatEscalationReceived'); },
                ) 
              : const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: Text('Aucune nouvelle notification', style: TextStyle(color: _C.textMuted, fontSize: 15))))
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
          _sheetOpt(Icons.group_add_outlined, 'Nouveau groupe', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupCreatePage())))
        ])
      )
    );
  }

  Widget _sheetOpt(IconData icon, String text, VoidCallback tap) => InkWell(
    onTap: () { Navigator.pop(context); tap(); }, 
    borderRadius: BorderRadius.circular(16), 
    child: Container(
      padding: const EdgeInsets.all(16), 
      decoration: BoxDecoration(color: _C.surface, border: Border.all(color: _C.border), borderRadius: BorderRadius.circular(16)), 
      child: Row(children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: _C.primaryLight, shape: BoxShape.circle), child: Icon(icon, size: 20, color: _C.primary)), 
        const SizedBox(width: 16), 
        Text(text, style: const TextStyle(color: _C.textMain, fontSize: 16, fontWeight: FontWeight.w600))
      ])
    )
  );

  @override 
  Widget build(BuildContext context) {
    final state = ref.watch(chatListProvider);
    final notifier = ref.read(chatListProvider.notifier);

    return Scaffold(
      backgroundColor: _C.bg,
      bottomNavigationBar: _standardBottomNav(state.totalUnread),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateMenu,
        backgroundColor: _C.primary,
        elevation: 4,
        child: const Icon(Icons.add_comment_rounded, color: Colors.white),
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
                _buildSliverAppBar(state.pendingEscalations),
                SliverToBoxAdapter(child: _searchBar()),
                SliverToBoxAdapter(child: _filters(state.filterIndex)),
                if (state.pendingEscalations > 0) SliverToBoxAdapter(child: _escalationBanner(state.pendingEscalations)),
                _chatList(state.filtered),
                if (state.isLoadingMore) const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Center(child: CircularProgressIndicator(color: _C.primary, strokeWidth: 3)))),
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          ),
    );
  }

  Widget _buildSliverAppBar(int pending) {
    return SliverAppBar(
      backgroundColor: _C.bg,
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      titleSpacing: 20,
      title: const Text('Discussions', style: TextStyle(color: _C.textMain, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
      actions: [
        IconButton(
          icon: Icon(_showSearch ? Icons.close_rounded : Icons.search_rounded, color: _C.textMain, size: 26),
          onPressed: _toggleSearch,
          splashRadius: 24,
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded, color: _C.textMain, size: 26),
              onPressed: () => _openNotifications(pending),
              splashRadius: 24,
            ),
            if (pending > 0) 
              Positioned(
                right: 8, 
                top: 8, 
                child: Container(
                  padding: const EdgeInsets.all(4), 
                  decoration: BoxDecoration(color: _C.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                )
              ),
          ],
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _C.red.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _C.red.withOpacity(0.2))
        ),
        child: Row(children: [
          const Icon(Icons.error_outline_rounded, color: _C.red, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text('$pending escalade(s) requiert votre attention', style: const TextStyle(color: _C.red, fontWeight: FontWeight.w600, fontSize: 14))),
          const Icon(Icons.arrow_forward_ios_rounded, color: _C.red, size: 14)
        ]),
      ),
    );
  }

  Widget _searchBar() => AnimatedCrossFade(
    duration: const Duration(milliseconds: 200), 
    crossFadeState: _showSearch ? CrossFadeState.showFirst : CrossFadeState.showSecond, 
    firstChild: Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), 
      child: Container(
        height: 46, 
        decoration: BoxDecoration(color: _C.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.border)), 
        child: TextField(
          controller: _searchCtrl, 
          autofocus: true, 
          onChanged: (v) => ref.read(chatListProvider.notifier).search(v), 
          style: const TextStyle(fontSize: 16, color: _C.textMain), 
          decoration: const InputDecoration(
            hintText: 'Rechercher une discussion...', 
            hintStyle: TextStyle(fontSize: 15, color: _C.textMuted), 
            prefixIcon: Icon(Icons.search_rounded, size: 20, color: _C.textMuted), 
            border: InputBorder.none, 
            contentPadding: EdgeInsets.symmetric(vertical: 12)
          )
        )
      )
    ), 
    secondChild: const SizedBox(height: 0)
  );

  Widget _filters(int selected) {
    final tabs = ['Toutes', 'Non lues', 'Groupes', 'Personnelles'];
    return Container(
      height: 48, 
      padding: const EdgeInsets.only(bottom: 12),
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
              borderRadius: BorderRadius.circular(20), 
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200), 
                padding: const EdgeInsets.symmetric(horizontal: 16), 
                alignment: Alignment.center, 
                decoration: BoxDecoration(
                  color: sel ? _C.primaryLight : Colors.white, 
                  borderRadius: BorderRadius.circular(20), 
                  border: Border.all(color: sel ? _C.primary : _C.border)
                ), 
                child: Text(tabs[i], style: TextStyle(fontSize: 14, fontWeight: sel ? FontWeight.bold : FontWeight.w600, color: sel ? _C.primary : _C.textMuted))
              )
            )
          ); 
        }
      )
    );
  }

  Widget _chatList(List<ChatConversation> list) {
    if (list.isEmpty) return const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(40), child: Center(child: Text('Aucune conversation trouvée', style: TextStyle(color: _C.textMuted, fontSize: 16)))));
    
    return SliverList(delegate: SliverChildBuilderDelegate((ctx, idx) {
      final conv = list[idx];
      final last = conv.lastMessage;
      final t = last != null ? last.createdAt : conv.updatedAt;
      final unread = conv.unreadCount > 0;
      
      return InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(conversationId: conv.id, conversation: conv))),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            // Avatar imposant
            CircleAvatar(
              radius: 26, 
              backgroundColor: _C.surface, 
              backgroundImage: conv.displayAvatar != null ? NetworkImage(conv.displayAvatar!) : null, 
              child: conv.displayAvatar == null 
                ? Text(conv.displayName.isNotEmpty ? conv.displayName[0].toUpperCase() : '?', style: const TextStyle(fontWeight: FontWeight.bold, color: _C.textMuted, fontSize: 20)) 
                : null
            ),
            const SizedBox(width: 14),
            // Contenu central
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(child: Text(conv.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _C.textMain))), 
                        if (conv.isGroup) const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.groups_rounded, size: 16, color: _C.textMuted))
                      ]
                    )
                  ),
                  Text(_fmt(t), style: TextStyle(fontSize: 12, fontWeight: unread ? FontWeight.w600 : FontWeight.w500, color: unread ? _C.unreadBadge : _C.textMuted)),
                ]
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(last?.content ?? 'Commencer à discuter', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: unread ? FontWeight.w600 : FontWeight.normal, color: unread ? _C.textMain : _C.textMuted))),
                  if (unread) 
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      constraints: const BoxConstraints(minWidth: 22, minHeight: 22), 
                      padding: const EdgeInsets.symmetric(horizontal: 6), 
                      alignment: Alignment.center, 
                      decoration: const BoxDecoration(color: _C.unreadBadge, shape: BoxShape.rectangle, borderRadius: BorderRadius.all(Radius.circular(12))), 
                      child: Text('${conv.unreadCount}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))
                    )
                ]
              ),
            ])),
          ]),
        ),
      );
    }, childCount: list.length));
  }

  // Barre de navigation standard d'entreprise
  Widget _standardBottomNav(int unread) {
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
                  if (unread > 0) Positioned(right: -4, top: -2, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: _C.red, shape: BoxShape.circle)))
                ]
              ), 
              activeIcon: Stack(
                clipBehavior: Clip.none, 
                children: [
                  const Icon(Icons.chat_bubble_rounded), 
                  if (unread > 0) Positioned(right: -4, top: -2, child: Container(width: 8, height: 8, decoration: BoxDecoration(color: _C.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5))))
                ]
              ), 
              label: 'Chats'
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
    if (now.difference(d).inDays < 7) return DateFormat('EEEE', 'fr_FR').format(d); // Affiche 'lundi', 'mardi'
    return DateFormat('dd/MM/yy').format(d);
  }
}
