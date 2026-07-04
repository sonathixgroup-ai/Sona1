import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatUser {
  final String id;
  final String name;
  final String avatar;
  final bool isOnline;

  ChatUser({
    required this.id,
    required this.name,
    required this.avatar,
    required this.isOnline,
  });
}

class Conversation {
  final String id;
  final String name;
  final String lastMessage;
  final String avatar;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool isGroup;

  Conversation({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.avatar,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.isGroup,
  });
}

class ChatHomeProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<ChatUser> _onlineUsers = [];
  List<Conversation> _conversations = [];
  int _totalOnlineCount = 0;
  int _totalNewMessages = 0;
  int _totalActiveMeetings = 0;
  int _totalSecurityAlerts = 0;
  bool _isLoading = false;
  String _selectedTab = 'all'; // all, teams, calls, favorites, appointments
  String? _currentUserId;

  // Getters
  List<ChatUser> get onlineUsers => _onlineUsers;
  List<Conversation> get conversations => _conversations;
  int get totalOnlineCount => _totalOnlineCount;
  int get totalNewMessages => _totalNewMessages;
  int get totalActiveMeetings => _totalActiveMeetings;
  int get totalSecurityAlerts => _totalSecurityAlerts;
  bool get isLoading => _isLoading;
  String get selectedTab => _selectedTab;

  ChatHomeProvider() {
    _initUser();
  }

  void _initUser() {
    _currentUserId = _supabase.auth.currentUser?.id;
    if (_currentUserId != null) {
      loadAllData();
    }
  }

  Future<void> loadAllData() async {
    _setLoading(true);
    try {
      await Future.wait([
        loadConversations(),
        loadOnlineUsers(),
        loadChatStats(),
      ]);
    } catch (e) {
      debugPrint('Error loading chat home data: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadConversations() async {
    if (_currentUserId == null) return;

    try {
      final response = await _supabase
          .from('social_conversations')
          .select(
              '''id, title, is_group, created_at, 
              social_messages!social_messages_conversation_id (
                id, body, sender_id, created_at
              )''')
          .order('created_at', ascending: false)
          .limit(50);

      final List<Conversation> convs = [];

      for (var conv in response as List) {
        final messages = List<Map<String, dynamic>>.from(
            conv['social_messages'] ?? []);

        String lastMessage = 'Pas de message';
        DateTime lastTime = DateTime.parse(conv['created_at'] ?? DateTime.now().toIso8601String());

        if (messages.isNotEmpty) {
          final lastMsg = messages.first;
          lastMessage = lastMsg['body'] ?? 'Message non disponible';
          lastTime = DateTime.parse(lastMsg['created_at']);
        }

        // Récupérer l'avatar du groupe ou utilisateur
        String avatar = 'https://i.pravatar.cc/150?img=${conv['id'].hashCode % 70}';

        convs.add(Conversation(
          id: conv['id'],
          name: conv['title'] ?? 'Conversation',
          lastMessage: lastMessage,
          avatar: avatar,
          lastMessageTime: lastTime,
          unreadCount: 0, // À implémenter selon votre logique de read receipts
          isGroup: conv['is_group'] ?? false,
        ));
      }

      _conversations = convs;
      _totalNewMessages = _conversations.fold(0, (sum, c) => sum + c.unreadCount);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading conversations: $e');
    }
  }

  Future<void> loadOnlineUsers() async {
    if (_currentUserId == null) return;

    try {
      // Charger les utilisateurs avec statut online
      final response = await _supabase
          .from('users')
          .select('id, display_name, photo_url, is_online, last_seen')
          .eq('is_online', true)
          .limit(10);

      final List<ChatUser> users = [];

      for (var user in response as List) {
        users.add(ChatUser(
          id: user['id'],
          name: user['display_name'] ?? 'Utilisateur',
          avatar: user['photo_url'] ?? 'https://i.pravatar.cc/150?img=${user['id'].hashCode % 70}',
          isOnline: user['is_online'] ?? false,
        ));
      }

      _onlineUsers = users;
      _totalOnlineCount = _onlineUsers.length;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading online users: $e');
    }
  }

  Future<void> loadChatStats() async {
    if (_currentUserId == null) return;

    try {
      // Charger les stats
      // Nombre de conversations non lues
      final unreadConvs = await _supabase
          .from('social_message_reads')
          .select('id')
          .eq('reader_id', _currentUserId!);

      _totalNewMessages = unreadConvs.length;

      // Réunions actives - à adapter selon votre modèle
      _totalActiveMeetings = 0;

      // Alertes sécurité - à adapter selon votre modèle
      _totalSecurityAlerts = 0;

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading chat stats: $e');
    }
  }

  void selectTab(String tab) {
    _selectedTab = tab;
    notifyListeners();
  }

  List<Conversation> getFilteredConversations() {
    switch (_selectedTab) {
      case 'teams':
        return _conversations.where((c) => c.isGroup).toList();
      case 'calls':
        // Filtrer les appels si applicable
        return [];
      case 'favorites':
        // Filtrer les favoris
        return [];
      case 'appointments':
        // Filtrer les rendez-vous
        return [];
      default: // 'all'
        return _conversations;
    }
  }

  void searchConversations(String query) {
    if (query.isEmpty) {
      loadConversations();
      return;
    }

    _conversations = _conversations
        .where((c) => c.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    notifyListeners();
  }

  Future<void> markConversationAsRead(String conversationId) async {
    if (_currentUserId == null) return;

    try {
      final index = _conversations.indexWhere((c) => c.id == conversationId);
      if (index != -1) {
        _conversations[index] = Conversation(
          id: _conversations[index].id,
          name: _conversations[index].name,
          lastMessage: _conversations[index].lastMessage,
          avatar: _conversations[index].avatar,
          lastMessageTime: _conversations[index].lastMessageTime,
          unreadCount: 0,
          isGroup: _conversations[index].isGroup,
        );

        _totalNewMessages = _conversations.fold(0, (sum, c) => sum + c.unreadCount);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking conversation as read: $e');
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Subscribe to real-time updates
  void subscribeToConversationUpdates() {
    if (_currentUserId == null) return;

    _supabase
        .channel('conversations_updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'social_conversations',
          callback: (payload) {
            loadConversations();
          },
        )
        .subscribe();
  }

  void subscribeToMessageUpdates() {
    _supabase
        .channel('messages_updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'social_messages',
          callback: (payload) {
            loadConversations();
          },
        )
        .subscribe();
  }

  void subscribeToPresenceUpdates() {
    _supabase
        .channel('presence_updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'users',
          callback: (payload) {
            loadOnlineUsers();
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _supabase.channel('conversations_updates').unsubscribe();
    _supabase.channel('messages_updates').unsubscribe();
    _supabase.channel('presence_updates').unsubscribe();
    super.dispose();
  }
}
