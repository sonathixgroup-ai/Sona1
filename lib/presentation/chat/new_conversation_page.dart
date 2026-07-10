// lib/presentation/chat/new_conversation_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/chat/chat_service.dart';
import '../../models/chat/chat_conversation.dart';
import 'chat_screen.dart';

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
  String _groupName = '';
  bool _isGroup = false;

  final supabase = Supabase.instance.client;
  late ChatService _chatService;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService(supabase);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      _searchUsers(query);
    } else {
      setState(() => _results.clear());
    }
  }

  /// Recherche par identifiant THIX CHAT ou par nom
  Future<void> _searchUsers(String query) async {
    setState(() => _isLoading = true);
    try {
      // 1. Recherche exacte sur thix_chat (privilégiée)
      final exactResponse = await supabase
          .from('profiles')
          .select('id, display_name, avatar_url, profession, thix_chat')
          .ilike('thix_chat', '%$query%')
          .limit(5);

      // 2. Recherche sur display_name
      final nameResponse = await supabase
          .from('profiles')
          .select('id, display_name, avatar_url, profession, thix_chat')
          .ilike('display_name', '%$query%')
          .limit(20);

      // Fusionner sans doublons
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
        // Vérifier que l'utilisateur n'est pas déjà sélectionné
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
        // Remettre l'utilisateur dans les résultats si il correspond à la recherche
        _searchUsers(_searchController.text.trim());
      } else {
        _selected.add(user);
        // Retirer des résultats
        _results.removeWhere((r) => r['id'] == user['id']);
      }
    });
  }

  Future<void> _startChat() async {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez au moins une personne')),
      );
      return;
    }

    final participantIds = _selected.map((u) => u['id'] as String).toList();
    final currentUserId = supabase.auth.currentUser!.id;
    if (!participantIds.contains(currentUserId)) {
      participantIds.add(currentUserId);
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
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle conversation'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_selected.isNotEmpty)
            TextButton.icon(
              onPressed: _startChat,
              icon: const Icon(Icons.send),
              label: Text('Démarrer (${_selected.length})'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFD4AF37),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Rechercher par THIX CHAT (@...) ou nom',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _results.clear());
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),

          // Sélection de groupe (si plusieurs)
          if (_selected.length > 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: (v) => setState(() => _groupName = v),
                decoration: const InputDecoration(
                  hintText: 'Nom du groupe (optionnel)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),

          // Sélectionnés
          if (_selected.isNotEmpty)
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selected.length,
                itemBuilder: (context, index) {
                  final user = _selected[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Chip(
                      avatar: CircleAvatar(
                        radius: 14,
                        backgroundImage: user['avatar_url'] != null
                            ? NetworkImage(user['avatar_url'])
                            : null,
                        child: user['avatar_url'] == null
                            ? const Icon(Icons.person, size: 14)
                            : null,
                      ),
                      label: Text(user['display_name'] ?? ''),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => _toggleSelection(user),
                    ),
                  );
                },
              ),
            ),

          // Résultats
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 60, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            Text(
                              _searchController.text.isEmpty
                                  ? 'Recherchez un utilisateur'
                                  : 'Aucun résultat',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            if (_searchController.text.isNotEmpty)
                              Text(
                                'Vérifiez l\'orthographe de l\'identifiant THIX CHAT',
                                style: TextStyle(color: Colors.grey[400]),
                              ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final user = _results[index];
                          final isSelected = _selected.any((s) => s['id'] == user['id']);
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: user['avatar_url'] != null
                                  ? NetworkImage(user['avatar_url'])
                                  : null,
                              child: user['avatar_url'] == null
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                            title: Text(user['display_name'] ?? 'Utilisateur'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user['profession'] ?? '',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                if (user['thix_chat'] != null)
                                  Text(
                                    user['thix_chat'],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFFD4AF37),
                                    ),
                                  ),
                              ],
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle, color: Color(0xFFD4AF37))
                                : (_selected.length > 1 || _selected.isEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.add_circle_outline),
                                        onPressed: () => _toggleSelection(user),
                                      )
                                    : null),
                            onTap: () {
                              if (_selected.isEmpty) {
                                // Démarrer directement la conversation
                                _selected.add(user);
                                _startChat();
                              } else {
                                _toggleSelection(user);
                              }
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
