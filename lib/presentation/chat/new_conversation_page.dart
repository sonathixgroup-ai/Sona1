// lib/presentation/chat/new_conversation_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/chat/chat_service.dart';
import '../../models/chat/chat_conversation.dart';
import 'chat_screen.dart';
import 'package:thix_id/models/chat/chat_message.dart';

class NewConversationPage extends StatefulWidget {
  const NewConversationPage({super.key});

  @override
  State<NewConversationPage> createState() => _NewConversationPageState();
}

class _NewConversationPageState extends State<NewConversationPage> {
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _results = [];
  final List<Map<String, dynamic>> _selected = [];

  bool _isLoading = false;
  bool _isCreatingChat = false;
  String _groupName = '';

  Timer? _debounce;

  final supabase = Supabase.instance.client;
  late ChatService _chatService;

  // ============================================================
  // CHARTE THIX ID — Design Institutionnel Premium (Navy / Bleu / Or)
  // ============================================================
  static const Color navyDeep = Color(0xFF0A1F44);
  static const Color navy = Color(0xFF123B7A);
  static const Color primaryBlue = Color(0xFF2D6CDF);
  static const Color gold = Color(0xFFE3B23C);
  static const Color ivory = Color(0xFFF6F7FB);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color darkText = Color(0xFF10182B);
  static const Color mutedText = Color(0xFF6B7690);
  static const Color danger = Color(0xFFD64545);
  static const Color hairline = Color(0xFFE7EAF3);

  @override
  void initState() {
    super.initState();
    _chatService = ChatService(supabase);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      final query = _searchController.text.trim();
      if (query.isNotEmpty) {
        _searchUsers(query);
      } else {
        setState(() => _results.clear());
      }
    });
  }

  /// Recherche par identifiant THIX CHAT ou par nom
  Future<void> _searchUsers(String query) async {
    setState(() => _isLoading = true);
    try {
      final exactResponse = await supabase
          .from('profiles')
          .select('id, display_name, avatar_url, profession, thix_chat')
          .ilike('thix_chat', '%$query%')
          .limit(5);

      final nameResponse = await supabase
          .from('profiles')
          .select('id, display_name, avatar_url, profession, thix_chat')
          .ilike('display_name', '%$query%')
          .limit(20);

      final allResults = <Map<String, dynamic>>[];
      final seenIds = <String>{};

      for (var r in exactResponse as List) {
        if (!seenIds.contains(r['id'])) {
          seenIds.add(r['id']);
          allResults.add(r);
        }
      }
      for (var r in nameResponse as List) {
        if (!seenIds.contains(r['id'])) {
          seenIds.add(r['id']);
          allResults.add(r);
        }
      }

      setState(() => _results.clear());
      for (var r in allResults) {
        final alreadySelected = _selected.any((s) => s['id'] == r['id']);
        if (!alreadySelected) {
          setState(() => _results.add(r));
        }
      }
    } catch (e) {
      debugPrint('❌ Erreur recherche: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _toggleSelection(Map<String, dynamic> user) {
    setState(() {
      if (_selected.any((s) => s['id'] == user['id'])) {
        _selected.removeWhere((s) => s['id'] == user['id']);
        _searchUsers(_searchController.text.trim());
      } else {
        _selected.add(user);
        _results.removeWhere((r) => r['id'] == user['id']);
      }
    });
  }

  Future<void> _startChat() async {
    if (_isCreatingChat) return;

    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez au moins une personne')),
      );
      return;
    }

    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur : Utilisateur non authentifié.')),
      );
      return;
    }

    setState(() => _isCreatingChat = true);

    final participantIds = _selected.map((u) => u['id'] as String).toList();
    if (!participantIds.contains(currentUser.id)) {
      participantIds.add(currentUser.id);
    }

    try {
      final conversation = await _chatService.createConversation(
        participantIds: participantIds,
        isGroup: _selected.length > 1,
        groupName: _selected.length > 1 ? _groupName.trim() : null,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              conversationId: conversation.id,
              conversation: conversation,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: danger),
      );
    } finally {
      if (mounted) {
        setState(() => _isCreatingChat = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ivory,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // ============================================================
          // BARRE DE RECHERCHE — pilule blanche sur fond ivoire
          // ============================================================
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Container(
              decoration: BoxDecoration(
                color: pureWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: hairline),
                boxShadow: [BoxShadow(color: navyDeep.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(fontSize: 13, color: darkText, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: 'Rechercher par THIX CHAT (@…) ou nom',
                  hintStyle: const TextStyle(color: mutedText, fontSize: 12.5, fontWeight: FontWeight.w500),
                  prefixIcon: const Icon(Icons.search_rounded, color: navy, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: mutedText, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _results.clear());
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          // ============================================================
          // NOM DU GROUPE (si plusieurs sélectionnés)
          // ============================================================
          if (_selected.length > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: pureWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: hairline),
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _groupName = v),
                  style: const TextStyle(fontSize: 13, color: darkText, fontWeight: FontWeight.w500),
                  decoration: const InputDecoration(
                    hintText: 'Nom du groupe (optionnel)',
                    hintStyle: TextStyle(color: mutedText, fontSize: 12.5, fontWeight: FontWeight.w500),
                    prefixIcon: Icon(Icons.groups_rounded, color: navy, size: 20),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),

          // ============================================================
          // UTILISATEURS SÉLECTIONNÉS — chips navy/or
          // ============================================================
          if (_selected.isNotEmpty)
            Container(
              height: 66,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selected.length,
                itemBuilder: (context, index) {
                  final user = _selected[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Container(
                      padding: const EdgeInsets.only(left: 4, right: 8),
                      decoration: BoxDecoration(
                        color: navyDeep,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: gold, width: 1.3),
                            ),
                            child: CircleAvatar(
                              radius: 13,
                              backgroundColor: navy,
                              backgroundImage: user['avatar_url'] != null ? NetworkImage(user['avatar_url']) : null,
                              child: user['avatar_url'] == null
                                  ? const Icon(Icons.person_rounded, size: 13, color: Colors.white)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            user['display_name'] ?? '',
                            style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(width: 5),
                          InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => _toggleSelection(user),
                            child: const Icon(Icons.close_rounded, size: 15, color: gold),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          // ============================================================
          // RÉSULTATS DE RECHERCHE
          // ============================================================
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: primaryBlue))
                : _results.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(color: ivory, shape: BoxShape.circle),
                              child: const Icon(Icons.people_outline_rounded, size: 36, color: mutedText),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              _searchController.text.isEmpty ? 'Recherchez un utilisateur' : 'Aucun résultat',
                              style: const TextStyle(color: darkText, fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                            if (_searchController.text.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              const Text(
                                "Vérifiez l'orthographe de l'identifiant THIX CHAT",
                                style: TextStyle(color: mutedText, fontSize: 11.5, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final user = _results[index];
                          final isSelected = _selected.any((s) => s['id'] == user['id']);
                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              if (_selected.isEmpty) {
                                _selected.add(user);
                                _startChat();
                              } else {
                                _toggleSelection(user);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: pureWhite,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: isSelected ? gold : hairline, width: isSelected ? 1.4 : 1),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: gold.withOpacity(0.6), width: 1.3),
                                    ),
                                    child: CircleAvatar(
                                      radius: 22,
                                      backgroundColor: navy,
                                      backgroundImage: user['avatar_url'] != null ? NetworkImage(user['avatar_url']) : null,
                                      child: user['avatar_url'] == null
                                          ? const Icon(Icons.person_rounded, color: Colors.white, size: 20)
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user['display_name'] ?? 'Utilisateur',
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: darkText),
                                        ),
                                        const SizedBox(height: 2),
                                        if ((user['profession'] ?? '').toString().isNotEmpty)
                                          Text(
                                            user['profession'],
                                            style: const TextStyle(fontSize: 11, color: mutedText, fontWeight: FontWeight.w500),
                                          ),
                                        if (user['thix_chat'] != null)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 2),
                                            child: Text(
                                              user['thix_chat'],
                                              style: const TextStyle(fontSize: 11, color: navy, fontWeight: FontWeight.w700),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  isSelected
                                      ? const Icon(Icons.check_circle_rounded, color: gold, size: 22)
                                      : (_selected.length > 1 || _selected.isEmpty
                                          ? InkWell(
                                              borderRadius: BorderRadius.circular(20),
                                              onTap: () => _toggleSelection(user),
                                              child: Container(
                                                padding: const EdgeInsets.all(5),
                                                decoration: BoxDecoration(color: ivory, shape: BoxShape.circle),
                                                child: const Icon(Icons.add_rounded, color: navy, size: 18),
                                              ),
                                            )
                                          : const SizedBox.shrink()),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // APP BAR — navy institutionnel, action "Démarrer" en or
  // ============================================================
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: navyDeep,
      elevation: 0,
      title: const Text(
        'Nouvelle conversation',
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5, color: Colors.white),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (_selected.isNotEmpty)
          _isCreatingChat
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.0),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: gold),
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: _startChat,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: gold,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.send_rounded, size: 15, color: navyDeep),
                          const SizedBox(width: 6),
                          Text(
                            'Démarrer (${_selected.length})',
                            style: const TextStyle(color: navyDeep, fontWeight: FontWeight.w800, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
      ],
    );
  }
}
