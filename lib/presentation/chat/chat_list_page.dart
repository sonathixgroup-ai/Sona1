// lib/presentation/chat/chat_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../services/chat/chat_service.dart';
import '../../services/chat/presence_service.dart';
import '../../models/chat/chat_conversation.dart';
import 'chat_screen.dart';
import 'new_conversation_page.dart';
import 'package:thix_id/presentation/chat/screens/group_create_page.dart';
// ✅ Importer la page des escalades reçues
import 'package:thix_id/presentation/chat/escalation/screens/received_escalations_page.dart';
import 'package:thix_id/presentation/chat/escalation/providers/escalation_provider.dart';
import 'package:provider/provider.dart';

// ============================================================
// CHARTE GRAPHIQUE ULTRA-PREMIUM (Clair & Élégant)
// ============================================================
class _ChatColors {
  static const Color background = Color(0xFFF4F7FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color navyDeep = Color(0xFF0A1F44);
  static const Color primaryBlue = Color(0xFF2D6CDF);
  static const Color softBlue = Color(0xFFE8F0FE);
  static const Color gold = Color(0xFFE3B23C);
  static const Color mutedText = Color(0xFF7B8BA4);
  static const Color success = Color(0xFF10B981);
  static const Color danger = Color(0xFFEF4444);
  static const Color border = Color(0xFFE2E8F0);
}

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  late ChatService _chatService;
  late PresenceService _presenceService;
  List<ChatConversation> _conversations = [];
  List<ChatConversation> _filteredConversations = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  int _selectedIndex = 0;
  int _pendingEscalationsCount = 0;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService(Supabase.instance.client);
    _presenceService = PresenceService(Supabase.instance.client);
    _loadConversations();
    _loadPendingEscalationsCount();
    _presenceService.initPresence();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _presenceService.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);
    try {
      final convs = await _chatService.getConversations();
      setState(() {
        _conversations = convs;
        _filteredConversations = convs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: _ChatColors.danger),
        );
      }
    }
  }

  // ✅ Charger le nombre d'escalades en attente reçues par l'utilisateur
  Future<void> _loadPendingEscalationsCount() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      // ✅ Utilisation de .count() après select
      final count = await Supabase.instance.client
          .from('escalation_steps')
          .select('id')
          .eq('to_agent_id', user.id)
          .eq('status', 0) // 0 = pending
          .count();
      setState(() {
        _pendingEscalationsCount = count ?? 0;
      });
    } catch (e) {
      debugPrint('Erreur chargement escalades: $e');
    }
  }

  void _onSearchChanged(String value) {
    final query = value.toLowerCase();
    setState(() {
      _filteredConversations = _conversations.where((conv) {
        return conv.displayName.toLowerCase().contains(query) ||
            (conv.lastMessage?.content ?? '').toLowerCase().contains(query);
      }).toList();
    });
  }

  List<ChatConversation> get _quickContacts {
    final list = _conversations.where((c) => !c.isGroup).toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list.take(5).toList();
  }

  int get _onlineCount => _conversations.where((c) => !c.isGroup).length;
  int get _groupCount => _conversations.where((c) => c.isGroup).length;
  int get _totalUnread => _conversations.fold(0, (sum, c) => sum + c.unreadCount);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: _ChatColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _ChatColors.primaryBlue))
          : RefreshIndicator(
              color: _ChatColors.primaryBlue,
              backgroundColor: _ChatColors.surface,
              onRefresh: () async {
                await _loadConversations();
                await _loadPendingEscalationsCount();
              },
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                slivers: [
                  _buildPremiumHeader(),
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildSearchBar(),
                        const SizedBox(height: 24),
                        _buildStatsBar(),
                        const SizedBox(height: 28),
                        if (_quickContacts.isNotEmpty) ...[
                          _buildSectionTitle('Contacts Récents', onSeeAll: () {}),
                          const SizedBox(height: 16),
                          _buildQuickContacts(),
                          const SizedBox(height: 28),
                        ],
                        _buildSectionTitle('Conversations', unreadCount: _totalUnread),
                        const SizedBox(height: 12),
                        _buildRecentConversations(),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: _buildPremiumFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildFloatingBottomNav(),
    );
  }

  // ============================================================
  // HEADER avec BOUTON ESCALADES (à côté du profil)
  // ============================================================
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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _ChatColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: _ChatColors.navyDeep.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: const Icon(Icons.forum_rounded, color: _ChatColors.gold, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'THIX CHAT',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _ChatColors.navyDeep, letterSpacing: 0.5),
                        ),
                        Text(
                          'Connectez-vous. Avancez.',
                          style: TextStyle(fontSize: 11, color: _ChatColors.mutedText, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    // ✅ BOUTON ESCALADES REÇUES (avec badge)
                    Stack(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            context.pushNamed('chatEscalationReceived');
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _ChatColors.surface,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: _ChatColors.navyDeep.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
                            ),
                            child: Icon(
                              Icons.swap_vertical_circle_rounded,
                              color: _pendingEscalationsCount > 0 ? _ChatColors.gold : _ChatColors.mutedText,
                              size: 24,
                            ),
                          ),
                        ),
                        if (_pendingEscalationsCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: _ChatColors.danger,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                              child: Text(
                                '$_pendingEscalationsCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    // Avatar profil
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {}, // Action Profil
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _ChatColors.primaryBlue.withOpacity(0.3), width: 2),
                        ),
                        child: const CircleAvatar(
                          radius: 20,
                          backgroundImage: NetworkImage('https://i.pravatar.cc/150'),
                        ),
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

  // ============================================================
  // BARRE DE STATISTIQUES (avec Alerte cliquable)
  // ============================================================
  Widget _buildStatsBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _ChatColors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: _ChatColors.navyDeep.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _statItem(Icons.people_alt_rounded, '$_onlineCount', 'Contacts', _ChatColors.primaryBlue, onTap: null),
            _verticalDivider(),
            _statItem(Icons.groups_rounded, '$_groupCount', 'Groupes', _ChatColors.navyDeep, onTap: null),
            _verticalDivider(),
            // ✅ ALERTES cliquables -> redirige vers les escalades reçues
            _statItem(
              Icons.notifications_active_rounded,
              '$_pendingEscalationsCount',
              'Alertes',
              _ChatColors.gold,
              onTap: () => context.pushNamed('chatEscalationReceived'),
              isClickable: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(IconData icon, String value, String label, Color color, {VoidCallback? onTap, bool isClickable = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _ChatColors.navyDeep)),
            Text(label, style: TextStyle(fontSize: 10, color: isClickable ? _ChatColors.primaryBlue : _ChatColors.mutedText, fontWeight: isClickable ? FontWeight.w700 : FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(width: 1, height: 30, color: _ChatColors.border);
  }

  // ============================================================
  // BARRE DE RECHERCHE FLOTTANTE
  // ============================================================
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: _ChatColors.surface,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [BoxShadow(color: _ChatColors.navyDeep.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 20, right: 12),
              child: Icon(Icons.search_rounded, color: _ChatColors.mutedText, size: 20),
            ),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: const TextStyle(fontSize: 14, color: _ChatColors.navyDeep, fontWeight: FontWeight.w600),
                decoration: const InputDecoration(
                  hintText: 'Rechercher un message, un contact...',
                  hintStyle: TextStyle(color: _ChatColors.mutedText, fontSize: 13.5, fontWeight: FontWeight.w400),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            if (_searchController.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.close_rounded, color: _ChatColors.mutedText, size: 18),
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
              ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TITRE DE SECTION
  // ============================================================
  Widget _buildSectionTitle(String title, {VoidCallback? onSeeAll, int? unreadCount}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _ChatColors.navyDeep)),
          if (unreadCount != null && unreadCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: _ChatColors.gold.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              child: Text('$unreadCount', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _ChatColors.gold)),
            ),
          ],
          const Spacer(),
          if (onSeeAll != null)
            InkWell(
              onTap: onSeeAll,
              child: const Text('Tout voir', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _ChatColors.primaryBlue)),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // CONTACTS RAPIDES
  // ============================================================
  Widget _buildQuickContacts() {
    return SizedBox(
      height: 90,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _quickContactSlot(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _ChatColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: _ChatColors.border, width: 2),
                boxShadow: [BoxShadow(color: _ChatColors.navyDeep.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: const Icon(Icons.add_rounded, color: _ChatColors.primaryBlue, size: 24),
            ),
            label: 'Nouveau',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewConversationPage())),
          ),
          ..._quickContacts.map((conv) {
            final name = conv.displayName;
            final avatar = conv.displayAvatar;
            return _quickContactSlot(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(colors: [_ChatColors.primaryBlue, _ChatColors.gold]),
                      boxShadow: [BoxShadow(color: _ChatColors.primaryBlue.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
                    ),
                    child: Container(
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: _ChatColors.surface),
                      padding: const EdgeInsets.all(2),
                      child: CircleAvatar(
                        backgroundColor: _ChatColors.softBlue,
                        backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                        child: avatar == null
                            ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 18, color: _ChatColors.primaryBlue, fontWeight: FontWeight.w800))
                            : null,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(color: _ChatColors.success, shape: BoxShape.circle, border: Border.all(color: _ChatColors.surface, width: 2)),
                    ),
                  ),
                ],
              ),
              label: name,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(conversationId: conv.id, conversation: conv))),
            );
          }),
        ],
      ),
    );
  }

  Widget _quickContactSlot({required Widget child, required String label, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: SizedBox(
          width: 60,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              child,
              const SizedBox(height: 6),
              Text(
                label.split(' ').first,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, color: _ChatColors.navyDeep, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CONVERSATIONS RÉCENTES
  // ============================================================
  Widget _buildRecentConversations() {
    final list = _searchController.text.isEmpty ? _conversations : _filteredConversations;

    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(color: _ChatColors.surface, shape: BoxShape.circle),
                child: const Icon(Icons.chat_bubble_outline_rounded, size: 30, color: _ChatColors.mutedText),
              ),
              const SizedBox(height: 16),
              const Text('Aucune conversation trouvée', style: TextStyle(color: _ChatColors.mutedText, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final conv = list[index];
        final isGroup = conv.isGroup;
        final name = conv.displayName;
        final avatar = conv.displayAvatar;
        final lastMsg = conv.lastMessage;
        final time = lastMsg != null ? lastMsg.createdAt : conv.updatedAt;
        final unread = conv.unreadCount;
        final hasUnread = unread > 0;

        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(conversationId: conv.id, conversation: conv))),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _ChatColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: hasUnread ? _ChatColors.primaryBlue.withOpacity(0.2) : _ChatColors.border),
              boxShadow: [BoxShadow(color: _ChatColors.navyDeep.withOpacity(hasUnread ? 0.08 : 0.02), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                isGroup
                    ? Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(color: _ChatColors.softBlue, borderRadius: BorderRadius.circular(16)),
                        child: const Icon(Icons.groups_rounded, color: _ChatColors.primaryBlue, size: 24),
                      )
                    : CircleAvatar(
                        radius: 26,
                        backgroundColor: _ChatColors.softBlue,
                        backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                        child: avatar == null
                            ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 18, color: _ChatColors.primaryBlue, fontWeight: FontWeight.w800))
                            : null,
                      ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: hasUnread ? FontWeight.w900 : FontWeight.w700, fontSize: 15, color: _ChatColors.navyDeep),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isGroup && lastMsg != null ? '${lastMsg.senderName}: ${lastMsg.content}' : (lastMsg?.content ?? 'Nouvelle conversation'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.5, color: hasUnread ? _ChatColors.navyDeep.withOpacity(0.8) : _ChatColors.mutedText, fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_formatTime(time), style: TextStyle(fontSize: 10.5, color: hasUnread ? _ChatColors.primaryBlue : _ChatColors.mutedText, fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w600)),
                    const SizedBox(height: 6),
                    if (hasUnread)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(gradient: const LinearGradient(colors: [_ChatColors.primaryBlue, _ChatColors.navyDeep]), borderRadius: BorderRadius.circular(12)),
                        child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // FAB
  // ============================================================
  Widget _buildPremiumFab() {
    return Container(
      margin: const EdgeInsets.only(bottom: 80),
      height: 60,
      width: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_ChatColors.primaryBlue, _ChatColors.navyDeep]),
        boxShadow: [BoxShadow(color: _ChatColors.primaryBlue.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (ctx) => Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(color: _ChatColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: _ChatColors.border, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 24),
                  _modalOption(Icons.chat_bubble_rounded, 'Nouvelle discussion', () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const NewConversationPage()));
                  }),
                  const SizedBox(height: 12),
                  _modalOption(Icons.group_add_rounded, 'Nouveau groupe', () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupCreatePage()));
                  }),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.edit_rounded, color: Colors.white, size: 26),
      ),
    );
  }

  Widget _modalOption(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(border: Border.all(color: _ChatColors.border), borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _ChatColors.softBlue, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: _ChatColors.primaryBlue)),
            const SizedBox(width: 16),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _ChatColors.navyDeep)),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM NAV
  // ============================================================
  Widget _buildFloatingBottomNav() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      decoration: BoxDecoration(
        color: _ChatColors.navyDeep,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: _ChatColors.navyDeep.withOpacity(0.3), blurRadius: 25, offset: const Offset(0, 10))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _navItem(Icons.home_rounded, 'Accueil', 0),
              _navItem(Icons.forum_rounded, 'Chats', 1),
              _navItem(Icons.explore_rounded, 'Espaces', 2),
              _navItem(Icons.settings_rounded, 'Paramètres', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () {
        setState(() => _selectedIndex = index);
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _ChatColors.primaryBlue.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: isSelected ? _ChatColors.gold : Colors.white70),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _ChatColors.gold)),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(time.year, time.month, time.day);

    if (date == today) {
      return DateFormat('HH:mm').format(time);
    } else if (date == today.subtract(const Duration(days: 1))) {
      return 'Hier';
    } else if (now.difference(time).inDays < 7) {
      return DateFormat('E').format(time);
    } else {
      return DateFormat('dd/MM').format(time);
    }
  }
}
