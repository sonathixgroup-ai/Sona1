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

// ── PALETTE ENTERPRISE ──
class _C {
  static const bg = Colors.white;
  static const surfaceAlt = Color(0xFFF8FAFC); // Gris ultra léger
  static const searchBg = Color(0xFFF1F5F9); // Fond de recherche doux
  static const border = Color(0xFFE2E8F0);
  static const primary = Color(0xFF2D6CDF); // Bleu Corporate (Unifié avec le chat)
  static const textMain = Color(0xFF0F172A); // Presque noir
  static const textMuted = Color(0xFF64748B); // Gris ardoise
  static const red = Color(0xFFEF4444);
  static const orange = Color(0xFFF59E0B);
}

class ChatListPage extends ConsumerStatefulWidget {
  const ChatListPage({super.key});
  @override 
  ConsumerState<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends ConsumerState<ChatListPage> {
  final _searchCtrl = TextEditingController();
  final _scroll = ScrollController();
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
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 16), 
            child: Row(children: [
              Icon(Icons.notifications_rounded, color: _C.textMain, size: 24), 
              SizedBox(width: 12), 
              Text('Notifications', style: TextStyle(color: _C.textMain, fontSize: 18, fontWeight: FontWeight.w800))
            ])
          ),
          const Divider(height: 1, color: _C.border),
          Flexible(
            child: pending > 0 
              ? ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: _C.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.swap_vert_rounded, color: _C.red)),
                  title: Text('$pending escalade(s) en attente', style: const TextStyle(color: _C.textMain, fontWeight: FontWeight.w700, fontSize: 15)),
                  subtitle: const Text('Nécessite une action de votre part', style: TextStyle(color: _C.textMuted, fontSize: 13)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: _C.textMuted),
                  onTap: () { Navigator.pop(ctx); context.pushNamed('chatEscalationReceived'); },
                ) 
              : const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: Text('Aucune notification récente', style: TextStyle(color: _C.textMuted, fontSize: 14))))
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
          _sheetOpt(Icons.chat_bubble_outline_rounded, 'Nouvelle discussion', 'Démarrer une conversation privée', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewConversationPage()))), 
          const SizedBox(height: 12), 
          _sheetOpt(Icons.group_add_outlined, 'Créer un groupe', 'Collaborer en équipe', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupCreatePage())))
        ])
      )
    );
  }

  Widget _sheetOpt(IconData icon, String title, String subtitle, VoidCallback tap) => InkWell(
    onTap: () { Navigator.pop(context); tap(); }, 
    borderRadius: BorderRadius.circular(16), 
    child: Container(
      padding: const EdgeInsets.all(16), 
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: _C.border), borderRadius: BorderRadius.circular(16)), 
      child: Row(children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(color: _C.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, size: 24, color: _C.primary)), 
        const SizedBox(width: 16), 
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: _C.textMain, fontSize: 16, fontWeight: FontWeight.w700)),
              Text(subtitle, style: const TextStyle(color: _C.textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          )
        )
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateMenu,
        backgroundColor: _C.primary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.edit_square, color: Colors.white, size: 22),
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
                if (state.pendingEscalations > 0) SliverToBoxAdapter(child: _escalationBanner(state.pendingEscalations)),
                SliverToBoxAdapter(child: _filters(state.filterIndex)),
                const SliverToBoxAdapter(child: Divider(height: 1, color: _C.border)),
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
      backgroundColor: _C.bg,
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 24,
      title: const Text('THIX CHAT', style: TextStyle(color: _C.textMain, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
      actions: [
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
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: _C.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                )
              ),
          ],
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: _C.textMain, size: 26),
              onPressed: () => _openNotifications(pending),
              splashRadius: 24,
            ),
            if (pending > 0)
              Positioned(
                right: 10, top: 10,
                child: Container(width: 8, height: 8, decoration: BoxDecoration(color: _C.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5))),
              )
          ],
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _searchBar() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
    child: Container(
      height: 44, 
      decoration: BoxDecoration(color: _C.searchBg, borderRadius: BorderRadius.circular(12)), 
      child: TextField(
        controller: _searchCtrl, 
        onChanged: (v) => ref.read(chatListProvider.notifier).search(v), 
        style: const TextStyle(fontSize: 15, color: _C.textMain, fontWeight: FontWeight.w500), 
        decoration: InputDecoration(
          hintText: 'Rechercher une conversation...', 
          hintStyle: const TextStyle(fontSize: 15, color: _C.textMuted), 
          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: _C.textMuted), 
          suffixIcon: _searchCtrl.text.isNotEmpty 
            ? IconButton(icon: const Icon(Icons.close_rounded, size: 18, color: _C.textMuted), onPressed: () { _searchCtrl.clear(); ref.read(chatListProvider.notifier).search(''); }) 
            : null,
          border: InputBorder.none, 
          contentPadding: const EdgeInsets.symmetric(vertical: 12)
        )
      )
    ),
  );

  Widget _escalationBanner(int pending) {
    return GestureDetector(
      onTap: () => context.pushNamed('chatEscalationReceived'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _C.red.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _C.red.withOpacity(0.2))
        ),
        child: Row(children: [
          const Icon(Icons.warning_rounded, color: _C.red, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text('$pending escalade(s) en attente', style: const TextStyle(color: _C.red, fontWeight: FontWeight.w700, fontSize: 14))),
          const Icon(Icons.arrow_forward_ios_rounded, color: _C.red, size: 14)
        ]),
      ),
    );
  }

  Widget _filters(int selected) {
    final tabs = ['Toutes', 'Non lues', 'Équipes', 'Personnelles'];
    return SizedBox(
      height: 48, 
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), 
        scrollDirection: Axis.horizontal, 
        itemCount: tabs.length, 
        itemBuilder: (ctx, i) { 
          final sel = selected == i; 
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4), 
            child: InkWell(
              onTap: () => ref.read(chatListProvider.notifier).setFilter(i), 
              borderRadius: BorderRadius.circular(20), 
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200), 
                padding: const EdgeInsets.symmetric(horizontal: 16), 
                alignment: Alignment.center, 
                decoration: BoxDecoration(
                  color: sel ? _C.primary.withOpacity(0.1) : Colors.transparent, 
                  borderRadius: BorderRadius.circular(20), 
                ), 
                child: Text(tabs[i], style: TextStyle(fontSize: 14, fontWeight: sel ? FontWeight.w700 : FontWeight.w600, color: sel ? _C.primary : _C.textMuted))
              )
            )
          ); 
        }
      )
    );
  }

  Widget _chatList(List<ChatConversation> list) {
    if (list.isEmpty) return const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(40), child: Center(child: Text('Aucune conversation trouvée', style: TextStyle(color: _C.textMuted, fontSize: 15)))));
    
    return SliverList(delegate: SliverChildBuilderDelegate((ctx, idx) {
      final conv = list[idx];
      final last = conv.lastMessage;
      final t = last != null ? last.createdAt : conv.updatedAt;
      final unread = conv.unreadCount > 0;
      
      return InkWell(
        // ✅ CORRECTION MAINTENUE : L'attente et le rafraîchissement silencieux
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(conversationId: conv.id, conversation: conv)));
          ref.read(chatListProvider.notifier).refresh();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(children: [
            // Avatar Modernisé
            Stack(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: _C.searchBg,
                    borderRadius: BorderRadius.circular(18), // Squircle plus doux
                    image: conv.displayAvatar != null ? DecorationImage(image: NetworkImage(conv.displayAvatar!), fit: BoxFit.cover) : null,
                  ),
                  child: conv.displayAvatar == null 
                    ? Center(child: Text(conv.displayName.isNotEmpty ? conv.displayName[0].toUpperCase() : '?', style: const TextStyle(fontWeight: FontWeight.bold, color: _C.textMuted, fontSize: 20)))
                    : null,
                ),
                if (unread)
                  Positioned(
                    right: -2, top: -2,
                    child: Container(width: 14, height: 14, decoration: BoxDecoration(color: _C.primary, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))
                  )
              ],
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
                        Flexible(child: Text(conv.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _C.textMain))), 
                        if (conv.isGroup) const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.groups_rounded, size: 18, color: _C.textMuted))
                      ]
                    )
                  ),
                  Text(_fmt(t), style: TextStyle(fontSize: 12, fontWeight: unread ? FontWeight.w700 : FontWeight.w500, color: unread ? _C.primary : _C.textMuted)),
                ]
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      last?.content ?? 'Nouvelle conversation', 
                      maxLines: 1, 
                      overflow: TextOverflow.ellipsis, 
                      style: TextStyle(fontSize: 14, fontWeight: unread ? FontWeight.w600 : FontWeight.w400, color: unread ? _C.textMain : _C.textMuted)
                    )
                  ),
                  if (unread) 
                    Container(
                      margin: const EdgeInsets.only(left: 12),
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: _C.primary, shape: BoxShape.circle), 
                      child: Text('${conv.unreadCount}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))
                    )
                ]
              ),
            ])),
          ]),
        ),
      );
    }, childCount: list.length));
  }

  Widget _corporateBottomNav(int unread) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: _selectedNav,
          onTap: (idx) {
            if (idx == 0) context.pushNamed('connections'); 
            else if (idx == 2) context.pushNamed('workspaces'); 
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
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, height: 1.5),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, height: 1.5),
          items: [
            const BottomNavigationBarItem(icon: Icon(Icons.people_alt_outlined), activeIcon: Icon(Icons.people_alt), label: 'Réseau'),
            BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none, 
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded), 
                  if (unread > 0) Positioned(right: -2, top: -2, child: Container(width: 8, height: 8, decoration: BoxDecoration(color: _C.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5))))
                ]
              ), 
              activeIcon: Stack(
                clipBehavior: Clip.none, 
                children: [
                  const Icon(Icons.chat_bubble_rounded), 
                  if (unread > 0) Positioned(right: -2, top: -2, child: Container(width: 8, height: 8, decoration: BoxDecoration(color: _C.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5))))
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
    if (now.difference(d).inDays < 7) return DateFormat('EEEE', 'fr_FR').format(d); 
    return DateFormat('dd/MM/yy').format(d);
  }
}
