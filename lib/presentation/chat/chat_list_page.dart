import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/chat/chat_service.dart';
import '../../services/chat/presence_service.dart';
import '../../models/chat/chat_conversation.dart';
import '../../models/chat/chat_message.dart';
import '../../models/chat/user_status.dart';
import 'chat_screen.dart';
import 'new_conversation_page.dart';

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
  int _selectedIndex = 0; // 0: Accueil, 1: Chats, 2: Espaces, 3: Paramètres

  // ============================================================
  // CHARTE THIX ID — Design Institutionnel Élite (Navy / Bleu / Or)
  // ============================================================
  static const Color navyDeep = Color(0xFF0A1F44);
  static const Color navy = Color(0xFF123B7A);
  static const Color primaryBlue = Color(0xFF2D6CDF);
  static const Color gold = Color(0xFFE3B23C);
  static const Color goldSoft = Color(0xFFF6E9C9);
  static const Color ivory = Color(0xFFF6F7FB);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color darkText = Color(0xFF10182B);
  static const Color mutedText = Color(0xFF6B7690);
  static const Color success = Color(0xFF1FA971);
  static const Color danger = Color(0xFFD64545);
  static const Color hairline = Color(0xFFE7EAF3);

  @override
  void initState() {
    super.initState();
    _chatService = ChatService(Supabase.instance.client);
    _presenceService = PresenceService(Supabase.instance.client);
    _loadConversations();
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
          SnackBar(content: Text('Erreur: $e'), backgroundColor: danger),
        );
      }
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

  // Récupérer les contacts rapides (les 5 conversations les plus récentes)
  List<ChatConversation> get _quickContacts {
    final list = _conversations.where((c) => !c.isGroup).toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list.take(5).toList();
  }

  // Statistiques calculées dynamiquement à partir des conversations
  int get _onlineCount => _conversations.where((c) => !c.isGroup).length;
  int get _totalUnread => _conversations.fold(0, (sum, c) => sum + c.unreadCount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ivory,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : RefreshIndicator(
              color: primaryBlue,
              onRefresh: _loadConversations,
              child: CustomScrollView(
                slivers: [
                  _buildInstitutionalHeader(),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatsBar(),
                          const SizedBox(height: 22),
                          if (_quickContacts.isNotEmpty) ...[
                            _buildSectionTitle('Contacts rapides', onSeeAll: () {}),
                            const SizedBox(height: 10),
                            _buildQuickContacts(),
                            const SizedBox(height: 22),
                          ],
                          _buildSectionTitle('Conversations récentes', onSeeAll: () {}),
                          const SizedBox(height: 6),
                          _buildRecentConversations(),
                          const SizedBox(height: 110),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: _buildFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // ============================================================
  // HEADER INSTITUTIONNEL ÉLITE — titre soigné + bande recherche
  // compacte avec photo de profil juste à côté (badge notif inclus)
  // ============================================================
  Widget _buildInstitutionalHeader() {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      expandedHeight: 148,
      backgroundColor: navyDeep,
      surfaceTintColor: navyDeep,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [navyDeep, navy, primaryBlue],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
          ),
          child: Stack(
            children: [
              // Halo doré décoratif — touche "élite"
              Positioned(
                top: -36,
                right: -24,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: gold.withOpacity(0.07)),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Titre élite avec liseré or ──
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 26,
                            decoration: BoxDecoration(color: gold, borderRadius: BorderRadius.circular(3)),
                          ),
                          const SizedBox(width: 10),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'THIX CHAT',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              Text(
                                'Connectez-vous. Échangez. Avancez.',
                                style: TextStyle(fontSize: 9.5, color: Colors.white60, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Bande recherche compacte + photo de profil ──
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {},
                              child: Container(
                                height: 38,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(color: navyDeep.withOpacity(0.20), blurRadius: 12, offset: const Offset(0, 5)),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.search_rounded, size: 16, color: primaryBlue),
                                    const SizedBox(width: 7),
                                    Expanded(
                                      child: TextField(
                                        controller: _searchController,
                                        style: const TextStyle(fontSize: 11.5, color: darkText, fontWeight: FontWeight.w500),
                                        decoration: const InputDecoration(
                                          hintText: 'Rechercher un chat, contact…',
                                          hintStyle: TextStyle(color: mutedText, fontSize: 11.5, fontWeight: FontWeight.w500),
                                          border: InputBorder.none,
                                          isDense: true,
                                        ),
                                        onChanged: _onSearchChanged,
                                      ),
                                    ),
                                    if (_searchController.text.isNotEmpty)
                                      InkWell(
                                        onTap: () {
                                          _searchController.clear();
                                          _onSearchChanged('');
                                        },
                                        child: const Icon(Icons.clear_rounded, size: 14, color: mutedText),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Photo de profil — badge notif intégré, pas d'icône séparée
                          InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {},
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: gold, width: 1.6),
                                  ),
                                  child: const CircleAvatar(
                                    backgroundColor: navy,
                                    child: Icon(Icons.person_rounded, size: 17, color: Colors.white),
                                  ),
                                ),
                                Positioned(
                                  bottom: -1,
                                  right: -1,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(color: success, shape: BoxShape.circle, border: Border.all(color: navyDeep, width: 1.6)),
                                  ),
                                ),
                                Positioned(
                                  top: -3,
                                  right: -3,
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(color: gold, shape: BoxShape.circle),
                                    constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                                    child: const Text(
                                      '3',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: navyDeep),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BARRE STATS — "En ligne" renommé en "Statut"
  // ============================================================
  Widget _buildStatsBar() {
    final stats = [
      {'icon': Icons.people_alt_rounded, 'value': '$_onlineCount', 'label': 'Statut', 'color': success},
      {'icon': Icons.mark_chat_unread_rounded, 'value': '$_totalUnread', 'label': 'Messages', 'color': primaryBlue},
      {'icon': Icons.notifications_active_rounded, 'value': '7', 'label': 'Alertes', 'color': gold},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: pureWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: hairline),
        boxShadow: [BoxShadow(color: navyDeep.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          ...stats.map((s) => Expanded(
                child: Column(
                  children: [
                    Icon(s['icon'] as IconData, size: 19, color: s['color'] as Color),
                    const SizedBox(height: 5),
                    Text(s['value'] as String, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: darkText)),
                    const SizedBox(height: 1),
                    Text(s['label'] as String, style: const TextStyle(fontSize: 9, color: mutedText, fontWeight: FontWeight.w600)),
                  ],
                ),
              )),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: ivory, shape: BoxShape.circle),
            child: const Icon(Icons.chevron_right_rounded, size: 15, color: navy),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {VoidCallback? onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: darkText)),
        if (onSeeAll != null)
          InkWell(
            onTap: onSeeAll,
            child: const Text('Voir tout', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: navy)),
          ),
      ],
    );
  }

  // ============================================================
  // CONTACTS RAPIDES — avatars cerclés or, statut vert
  // ============================================================
  Widget _buildQuickContacts() {
    return SizedBox(
      height: 82,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _quickContactSlot(
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: ivory,
                shape: BoxShape.circle,
                border: Border.all(color: navy.withOpacity(0.4), width: 1.2),
              ),
              child: const Icon(Icons.add_rounded, color: navy, size: 20),
            ),
            label: 'Nouveau',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NewConversationPage()));
            },
          ),
          ..._quickContacts.map((conv) {
            final name = conv.displayName;
            final avatar = conv.displayAvatar;
            return _quickContactSlot(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: gold.withOpacity(0.7), width: 1.4),
                    ),
                    child: CircleAvatar(
                      radius: 25,
                      backgroundColor: navy,
                      backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                      child: avatar == null
                          ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 17, color: Colors.white, fontWeight: FontWeight.w700))
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 2,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(color: success, shape: BoxShape.circle, border: Border.all(color: pureWhite, width: 1.8)),
                    ),
                  ),
                ],
              ),
              label: name,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ChatScreen(conversationId: conv.id, conversation: conv)),
                );
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _quickContactSlot({required Widget child, required String label, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: SizedBox(
          width: 58,
          child: Column(
            children: [
              child,
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 9.5, color: darkText, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CONVERSATIONS RÉCENTES — liste compacte, badges or
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
                width: 70,
                height: 70,
                decoration: BoxDecoration(color: ivory, shape: BoxShape.circle),
                child: const Icon(Icons.forum_outlined, size: 30, color: mutedText),
              ),
              const SizedBox(height: 12),
              const Text('Aucune conversation trouvée', style: TextStyle(color: mutedText, fontSize: 12.5, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final conv = list[index];
        final isGroup = conv.isGroup;
        final name = conv.displayName;
        final avatar = conv.displayAvatar;
        final lastMsg = conv.lastMessage;
        final time = lastMsg != null ? lastMsg.createdAt : conv.updatedAt;
        final unread = conv.unreadCount;

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ChatScreen(conversationId: conv.id, conversation: conv)),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: pureWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: hairline),
            ),
            child: Row(
              children: [
                isGroup
                    ? Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(color: navyDeep, borderRadius: BorderRadius.circular(13)),
                        child: const Icon(Icons.groups_rounded, color: gold, size: 20),
                      )
                    : CircleAvatar(
                        radius: 23,
                        backgroundColor: navy,
                        backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                        child: avatar == null
                            ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w700))
                            : null,
                      ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: darkText),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isGroup && lastMsg != null
                            ? '${lastMsg.senderName}: ${lastMsg.content}'
                            : (lastMsg?.content ?? 'Aucun message'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: lastMsg == null ? mutedText : mutedText, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_formatTime(time), style: const TextStyle(fontSize: 9.5, color: mutedText, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 5),
                    if (unread > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: gold, borderRadius: BorderRadius.circular(20)),
                        child: Text(
                          '$unread',
                          style: const TextStyle(color: navyDeep, fontSize: 9.5, fontWeight: FontWeight.w800),
                        ),
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
  // FAB — nouvelle discussion, navy/or
  // ============================================================
  Widget _buildFab() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(colors: [navyDeep, navy]),
        boxShadow: [BoxShadow(color: navyDeep.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const NewConversationPage()));
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add_rounded, color: gold, size: 26),
      ),
    );
  }

  // ============================================================
  // BOTTOM NAV — "Profil" remplacé par "Paramètres"
  // ============================================================
  Widget _buildBottomNavigationBar() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      color: pureWhite,
      elevation: 10,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(Icons.home_rounded, 'Accueil', 0),
            _navItem(Icons.chat_bubble_rounded, 'Chats', 1),
            const SizedBox(width: 40), // espace pour le FAB
            _navItem(Icons.explore_rounded, 'Espaces', 2),
            _navItem(Icons.settings_rounded, 'Paramètres', 3),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        setState(() => _selectedIndex = index);
        if (index == 2) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Page Espace en développement')),
          );
        } else if (index == 3) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Page Paramètres en développement')),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 19, color: isSelected ? navy : mutedText),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 8.5, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500, color: isSelected ? navy : mutedText),
            ),
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
      return DateFormat('dd/MM/yyyy').format(time);
    }
  }
}
