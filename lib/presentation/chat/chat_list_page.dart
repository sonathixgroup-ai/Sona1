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
import 'package:thix_id/presentation/chat/screens/group_create_page.dart';

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

  // Couleurs THIX ID
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

  List<ChatConversation> get _quickContacts {
    final list = _conversations.where((c) => !c.isGroup).toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list.take(5).toList();
  }

  // Statistiques : Statut = contacts individuels, Groupes = groupes, Alertes = notifications
  int get _onlineCount => _conversations.where((c) => !c.isGroup).length;
  int get _groupCount => _conversations.where((c) => c.isGroup).length;
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
                  _buildInstitutionalHeader(), // Header réduit
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatsBar(), // Stats avec "Groupes"
                          const SizedBox(height: 16),
                          if (_quickContacts.isNotEmpty) ...[
                            _buildSectionTitle('Contacts rapides', onSeeAll: () {}),
                            const SizedBox(height: 8),
                            _buildQuickContacts(),
                            const SizedBox(height: 16),
                          ],
                          _buildSectionTitle('Conversations récentes', onSeeAll: () {}),
                          const SizedBox(height: 6),
                          _buildRecentConversations(),
                          const SizedBox(height: 100),
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
  // HEADER RÉDUIT (hauteur réduite, texte plus petit)
  // ============================================================
  Widget _buildInstitutionalHeader() {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      expandedHeight: 120, // Réduit de 148 à 120
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
              bottomLeft: Radius.circular(22),
              bottomRight: Radius.circular(22),
            ),
          ),
          child: Stack(
            children: [
              // Halo doré plus petit
              Positioned(
                top: -28,
                right: -16,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: gold.withOpacity(0.06)),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Titre élite avec liseré or ──
                      Row(
                        children: [
                          Container(
                            width: 3,
                            height: 20,
                            decoration: BoxDecoration(color: gold, borderRadius: BorderRadius.circular(3)),
                          ),
                          const SizedBox(width: 8),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'THIX CHAT',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              Text(
                                'Connectez-vous. Échangez. Avancez.',
                                style: TextStyle(fontSize: 8.5, color: Colors.white60, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // ── Bande recherche compacte ──
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {},
                              child: Container(
                                height: 32, // Réduit de 38 à 32
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20), // Cylindrique
                                  boxShadow: [
                                    BoxShadow(color: navyDeep.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 3)),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.search_rounded, size: 14, color: primaryBlue),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: TextField(
                                        controller: _searchController,
                                        style: const TextStyle(fontSize: 10.5, color: darkText, fontWeight: FontWeight.w500),
                                        decoration: const InputDecoration(
                                          hintText: 'Rechercher un chat, contact…',
                                          hintStyle: TextStyle(color: mutedText, fontSize: 10.5, fontWeight: FontWeight.w500),
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
                                        child: const Icon(Icons.clear_rounded, size: 12, color: mutedText),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Photo de profil réduite
                          InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {},
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: gold, width: 1.2),
                                  ),
                                  child: const CircleAvatar(
                                    backgroundColor: navy,
                                    child: Icon(Icons.person_rounded, size: 14, color: Colors.white),
                                  ),
                                ),
                                Positioned(
                                  bottom: -2,
                                  right: -2,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(color: success, shape: BoxShape.circle, border: Border.all(color: navyDeep, width: 1.2)),
                                  ),
                                ),
                                Positioned(
                                  top: -4,
                                  right: -4,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(color: gold, shape: BoxShape.circle),
                                    constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                                    child: const Text(
                                      '3',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 7, fontWeight: FontWeight.w800, color: navyDeep),
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
  // BARRE STATS — "Messages" devient "Groupes"
  // ============================================================
  Widget _buildStatsBar() {
    final stats = [
      {'icon': Icons.people_alt_rounded, 'value': '$_onlineCount', 'label': 'Statut', 'color': success},
      {'icon': Icons.group_rounded, 'value': '$_groupCount', 'label': 'Groupes', 'color': primaryBlue}, 
      {'icon': Icons.notifications_active_rounded, 'value': '$_totalUnread', 'label': 'Alertes', 'color': gold},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: pureWhite,
        borderRadius: BorderRadius.circular(30), // Cylindrique
        border: Border.all(color: hairline),
        boxShadow: [BoxShadow(color: navyDeep.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          ...stats.map((s) => Expanded(
                child: Column(
                  children: [
                    Icon(s['icon'] as IconData, size: 16, color: s['color'] as Color),
                    const SizedBox(height: 3),
                    Text(s['value'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: darkText)),
                    const SizedBox(height: 1),
                    Text(s['label'] as String, style: const TextStyle(fontSize: 8, color: mutedText, fontWeight: FontWeight.w600)),
                  ],
                ),
              )),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(color: ivory, shape: BoxShape.circle),
            child: const Icon(Icons.chevron_right_rounded, size: 12, color: navy),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {VoidCallback? onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: darkText)),
        if (onSeeAll != null)
          InkWell(
            onTap: onSeeAll,
            child: const Text('Voir tout', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: navy)),
          ),
      ],
    );
  }

  // ============================================================
  // CONTACTS RAPIDES (réduits)
  // ============================================================
  Widget _buildQuickContacts() {
    return SizedBox(
      height: 70,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _quickContactSlot(
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: ivory,
                shape: BoxShape.circle,
                border: Border.all(color: navy.withOpacity(0.4), width: 1),
              ),
              child: const Icon(Icons.add_rounded, color: navy, size: 18),
            ),
            label: 'Nouveau',
            onTap: () {
              // CORRECTION: const retiré ici
              Navigator.push(context, MaterialPageRoute(builder: (_) => NewConversationPage()));
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
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: gold.withOpacity(0.7), width: 1.2),
                    ),
                    child: CircleAvatar(
                      radius: 21,
                      backgroundColor: navy,
                      backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                      child: avatar == null
                          ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w700))
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: -1,
                    right: -1,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(color: success, shape: BoxShape.circle, border: Border.all(color: pureWhite, width: 1.4)),
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
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: SizedBox(
          width: 50,
          child: Column(
            children: [
              child,
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 8.5, color: darkText, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CONVERSATIONS RÉCENTES — conteneurs cylindriques
  // ============================================================
  Widget _buildRecentConversations() {
    final list = _searchController.text.isEmpty ? _conversations : _filteredConversations;

    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(color: ivory, shape: BoxShape.circle),
                child: const Icon(Icons.forum_outlined, size: 24, color: mutedText),
              ),
              const SizedBox(height: 8),
              const Text('Aucune conversation trouvée', style: TextStyle(color: mutedText, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final conv = list[index];
        final isGroup = conv.isGroup;
        final name = conv.displayName;
        final avatar = conv.displayAvatar;
        final lastMsg = conv.lastMessage;
        final time = lastMsg != null ? lastMsg.createdAt : conv.updatedAt;
        final unread = conv.unreadCount;

        return InkWell(
          borderRadius: BorderRadius.circular(40), // Cylindrique
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ChatScreen(conversationId: conv.id, conversation: conv)),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: pureWhite,
              borderRadius: BorderRadius.circular(40), // Cylindrique
              border: Border.all(color: hairline),
              boxShadow: [BoxShadow(color: navyDeep.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                isGroup
                    ? Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(color: navyDeep, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.groups_rounded, color: gold, size: 16),
                      )
                    : CircleAvatar(
                        radius: 19,
                        backgroundColor: navy,
                        backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                        child: avatar == null
                            ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w700))
                            : null,
                      ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5, color: darkText),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        isGroup && lastMsg != null
                            ? '${lastMsg.senderName}: ${lastMsg.content}'
                            : (lastMsg?.content ?? 'Aucun message'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 10, color: lastMsg == null ? mutedText : mutedText, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_formatTime(time), style: const TextStyle(fontSize: 9, color: mutedText, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    if (unread > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(color: gold, borderRadius: BorderRadius.circular(20)),
                        child: Text(
                          '$unread',
                          style: const TextStyle(color: navyDeep, fontSize: 8.5, fontWeight: FontWeight.w800),
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
  // FAB — nouvelle discussion/groupe
  // ============================================================
  Widget _buildFab() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(colors: [navyDeep, navy]),
        boxShadow: [BoxShadow(color: navyDeep.withOpacity(0.30), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (ctx) => SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.chat_rounded, color: navy),
                      title: const Text('Nouvelle discussion'),
                      onTap: () {
                        Navigator.pop(ctx);
                        // CORRECTION: const retiré ici
                        Navigator.push(context, MaterialPageRoute(builder: (_) => NewConversationPage()));
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.group_add_rounded, color: navy),
                      title: const Text('Nouveau groupe'),
                      onTap: () {
                        Navigator.pop(ctx);
                        // CORRECTION: const retiré ici
                        Navigator.push(context, MaterialPageRoute(builder: (_) => GroupCreatePage()));
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add_rounded, color: gold, size: 26),
      ),
    );
  }

  // ============================================================
  // BOTTOM NAV
  // ============================================================
  Widget _buildBottomNavigationBar() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      color: pureWhite,
      elevation: 8,
      child: SizedBox(
        height: 54,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(Icons.home_rounded, 'Accueil', 0),
            _navItem(Icons.chat_bubble_rounded, 'Chats', 1),
            const SizedBox(width: 40),
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
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: isSelected ? navy : mutedText),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 8, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500, color: isSelected ? navy : mutedText),
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
