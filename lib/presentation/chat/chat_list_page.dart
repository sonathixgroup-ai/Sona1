// lib/presentation/chat/chat_list_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/chat/chat_service.dart';
import '../../services/chat/presence_service.dart';
import '../../models/chat/chat_conversation.dart';
import '../../models/chat/chat_message.dart';
import '../../models/chat/user_status.dart';
import '../../auth/auth_controller.dart';
import 'chat_screen.dart';

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
  String _searchQuery = '';
  bool _showOnlyUnread = false;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService(Provider.of<SupabaseClient>(context, listen: false));
    _presenceService = PresenceService(Provider.of<SupabaseClient>(context, listen: false));
    _loadConversations();
    _initPresence();
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);
    try {
      final convs = await _chatService.getConversations();
      setState(() {
        _conversations = convs;
        _applyFilter();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de chargement: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _initPresence() async {
    await _presenceService.initPresence();
    // Écouter les changements de statut en temps réel
    // (à implémenter avec un Stream si nécessaire)
  }

  void _applyFilter() {
    setState(() {
      _filteredConversations = _conversations.where((conv) {
        // Filtre par recherche
        final matchSearch = _searchQuery.isEmpty ||
            conv.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (conv.lastMessage?.content ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
        // Filtre par non-lus
        final matchUnread = !_showOnlyUnread || conv.unreadCount > 0;
        return matchSearch && matchUnread;
      }).toList();
    });
  }

  void _onSearchChanged(String value) {
    _searchQuery = value;
    _applyFilter();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _presenceService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('THIX CHAT', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.grey),
            onPressed: () => _showSearchBar(),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.grey),
            onPressed: () => _toggleFilter(),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFFD4AF37)),
            onPressed: () => _startNewConversation(),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_searchController.text.isNotEmpty || _showOnlyUnread)
            _buildFilterChips(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredConversations.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadConversations,
                        color: const Color(0xFFD4AF37),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _filteredConversations.length,
                          itemBuilder: (context, index) {
                            final conv = _filteredConversations[index];
                            return _buildConversationTile(conv);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (_searchController.text.isNotEmpty)
            Chip(
              label: Text('🔍 "${_searchController.text}"'),
              onDeleted: () {
                _searchController.clear();
                _onSearchChanged('');
              },
              backgroundColor: Colors.white,
              deleteIconColor: Colors.grey,
            ),
          if (_showOnlyUnread)
            Chip(
              label: const Text('Non lus'),
              onDeleted: () {
                setState(() => _showOnlyUnread = false);
                _applyFilter();
              },
              backgroundColor: const Color(0xFFD4AF37).withOpacity(0.1),
              deleteIconColor: Colors.grey,
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('Aucune conversation', style: TextStyle(color: Colors.grey[600], fontSize: 18)),
          const SizedBox(height: 8),
          Text('Commencez à discuter avec vos contacts', style: TextStyle(color: Colors.grey[400])),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _startNewConversation,
            icon: const Icon(Icons.add),
            label: const Text('Nouvelle discussion'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationTile(ChatConversation conv) {
    final isGroup = conv.isGroup;
    final isPinned = conv.isPinned;
    final hasUnread = conv.unreadCount > 0;
    final lastMsg = conv.lastMessage;
    final otherParticipantId = conv.participantIds.firstWhere(
      (id) => id != _chatService.currentUserId,
      orElse: () => '',
    );
    final status = _presenceService.getStatus(otherParticipantId) ?? UserStatus.offline;

    return Dismissible(
      key: Key(conv.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) async {
        // Option de suppression de conversation (masquage)
        // à implémenter selon les besoins
      },
      child: InkWell(
        onTap: () => _openChat(conv),
        onLongPress: () => _showConversationOptions(conv),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: hasUnread
                ? Border.all(color: const Color(0xFFD4AF37), width: 1.5)
                : null,
          ),
          child: Row(
            children: [
              // Avatar
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: isGroup
                        ? (conv.groupAvatar != null ? NetworkImage(conv.groupAvatar!) : null)
                        : (otherParticipantId.isNotEmpty
                            ? NetworkImage('https://via.placeholder.com/56') // À remplacer par l'avatar réel
                            : null),
                    child: (isGroup && conv.groupAvatar == null)
                        ? const Icon(Icons.group, color: Colors.grey)
                        : (!isGroup && otherParticipantId.isEmpty)
                            ? const Icon(Icons.person, color: Colors.grey)
                            : null,
                  ),
                  if (!isGroup)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: UserStatus.presenceIndicator(status, size: 14),
                    ),
                  if (isGroup)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          color: Color(0xFFD4AF37),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.group, size: 8, color: Colors.white),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              // Contenu
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conv.displayName,
                            style: TextStyle(
                              fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _formatDate(conv.updatedAt),
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _getPreviewText(lastMsg),
                            style: TextStyle(
                              fontSize: 13,
                              color: hasUnread ? Colors.black87 : Colors.grey[600],
                              fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasUnread)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4AF37),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${conv.unreadCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (isPinned) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.push_pin, size: 14, color: Color(0xFFD4AF37)),
                        ],
                        if (lastMsg?.isEphemeral == true) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.timer, size: 14, color: Colors.orange),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPreviewText(ChatMessage? lastMsg) {
    if (lastMsg == null) return 'Aucun message';
    if (lastMsg.isCodeSnippet) return '💻 Code snippet';
    if (lastMsg.mediaUrl != null) return '📎 Pièce jointe';
    return lastMsg.content;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 7) {
      return DateFormat('d MMM').format(date);
    } else if (diff.inDays > 0) {
      return DateFormat('EEE').format(date);
    } else {
      return DateFormat('HH:mm').format(date);
    }
  }

  void _openChat(ChatConversation conv) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          conversationId: conv.id,
          conversation: conv,
        ),
      ),
    );
  }

  void _showConversationOptions(ChatConversation conv) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(conv.isPinned ? Icons.push_pin : Icons.push_pin_outlined),
              title: Text(conv.isPinned ? 'Désépingler' : 'Épingler'),
              onTap: () async {
                await _chatService.togglePinned(conv.id);
                Navigator.pop(context);
                _loadConversations();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Masquer la conversation'),
              onTap: () {
                // Implémenter la suppression/archivage
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Ajouter un participant (groupe)'),
              onTap: () {
                Navigator.pop(context);
                // Ouvrir un dialogue pour ajouter
              },
            ),
          ],
        ),
      ),
    );
  }

  void _toggleFilter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Filtres'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Afficher uniquement les non lus'),
              value: _showOnlyUnread,
              onChanged: (value) {
                setState(() => _showOnlyUnread = value);
                _applyFilter();
                Navigator.pop(context);
              },
              activeColor: const Color(0xFFD4AF37),
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchBar() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 20,
          left: 16,
          right: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Rechercher une conversation...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                          Navigator.pop(context);
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
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _startNewConversation() {
    // Implémenter la sélection d'un contact
    // Pour l'instant, un placeholder
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvelle conversation'),
        content: const Text('Recherchez un utilisateur pour commencer à discuter.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
