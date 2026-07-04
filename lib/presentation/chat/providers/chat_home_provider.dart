import 'dart:async' show StreamSubscription, unawaited;

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
  List<Conversation> _allConversations = [];
  int _totalOnlineCount = 0;
  int _totalNewMessages = 0;
  int _totalActiveMeetings = 0;
  int _totalSecurityAlerts = 0;
  bool _isLoading = false;
  String _selectedTab = 'all'; // all, teams, calls, favorites, appointments
  String _searchQuery = '';
  String? _currentUserId;
  StreamSubscription<AuthState>? _authSubscription;
  RealtimeChannel? _conversationsChannel;
  RealtimeChannel? _messagesChannel;
  RealtimeChannel? _presenceChannel;

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
    _authSubscription = _supabase.auth.onAuthStateChange.listen((event) {
      final nextUserId = event.session?.user.id;
      if (nextUserId == _currentUserId) return;
      _currentUserId = nextUserId;
      if (_currentUserId == null) {
        _clearData();
        return;
      }
      _subscribeToRealtime();
      unawaited(_refreshAllDataSafely());
    });

    if (_currentUserId != null) {
      _subscribeToRealtime();
      unawaited(_refreshAllDataSafely());
    }
  }

  Future<void> loadAllData() async {
    _setLoading(true);
    try {
      await Future.wait([
        loadConversations(),
        loadOnlineUsers(),
      ]);
      await loadChatStats();
    } catch (e) {
      debugPrint('Error loading chat home data: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _refreshAllDataSafely() async {
    try {
      await loadAllData();
    } catch (e) {
      debugPrint('Error refreshing chat home data: $e');
    }
  }

  Future<void> _refreshConversationsSafely() async {
    try {
      await loadConversations();
    } catch (e) {
      debugPrint('Error refreshing conversations: $e');
    }
  }

  Future<void> _refreshOnlineUsersSafely() async {
    try {
      await loadOnlineUsers();
    } catch (e) {
      debugPrint('Error refreshing online users: $e');
    }
  }

  Future<void> loadConversations() async {
    if (_currentUserId == null) return;

    try {
      final response = await _supabase
          .from('thix_chat_chats')
          .select('id, type, title, avatar_url, participants, participant_name, last_message, last_message_at, created_at, updated_at')
          .contains('participants', [_currentUserId!])
          .order('last_message_at', ascending: false)
          .limit(50);

      final chatRows = (response as List).map((row) => Map<String, dynamic>.from(row as Map)).toList();
      final chatIds = chatRows.map((row) => row['id'] as String?).whereType<String>().where((id) => id.isNotEmpty).toList(growable: false);
      final readAtByChat = await _loadReadAtByChat(chatIds);
      final profileByUserId = await _loadProfileByUserId(_conversationParticipantIds(chatRows));
      final List<Conversation> convs = [];

      for (final conv in chatRows) {
        final lastTime = _parseDateTime(
              conv['last_message_at'] ?? conv['updated_at'] ?? conv['created_at'],
            ) ??
            DateTime.now();
        final chatId = conv['id'] as String? ?? '';
        final isGroup = _isGroupConversation(conv);
        final lastMessage = _normalizedText(conv['last_message'], fallback: 'Pas de message');
        final hasUnread = _hasUnreadConversation(
          lastMessageAt: conv['last_message_at'],
          readAt: readAtByChat[chatId],
        );

        convs.add(Conversation(
          id: chatId,
          name: _conversationName(conv, profileByUserId),
          lastMessage: lastMessage,
          avatar: _conversationAvatar(conv, profileByUserId),
          lastMessageTime: lastTime,
          unreadCount: hasUnread ? 1 : 0,
          isGroup: isGroup,
        ));
      }

      _allConversations = convs;
      _conversations = _applySearchQuery(convs);
      _totalNewMessages = convs.fold(0, (sum, c) => sum + c.unreadCount);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading conversations: $e');
    }
  }

  Future<void> loadOnlineUsers() async {
    if (_currentUserId == null) return;

    try {
      final response = await _supabase
          .from('thix_presence')
          .select('user_id, is_online, last_seen_at')
          .eq('is_online', true)
          .neq('user_id', _currentUserId!)
          .order('last_seen_at', ascending: false)
          .limit(10);

      final presenceRows = (response as List).map((row) => Map<String, dynamic>.from(row as Map)).toList();
      final profiles = await _loadProfileByUserId(
        presenceRows.map((row) => row['user_id'] as String? ?? '').where((id) => id.isNotEmpty).toSet(),
      );
      final List<ChatUser> users = [];

      for (final user in presenceRows) {
        final userId = user['user_id'] as String? ?? '';
        final profile = profiles[userId] ?? const <String, dynamic>{};
        users.add(ChatUser(
          id: userId,
          name: _profileDisplayName(profile),
          avatar: _profileAvatar(profile, userId),
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
      _totalOnlineCount = _onlineUsers.length;
      _totalNewMessages = _allConversations.fold(0, (sum, c) => sum + c.unreadCount);
      _totalActiveMeetings = 0;
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
    _searchQuery = query.trim().toLowerCase();
    _conversations = _applySearchQuery(_allConversations);
    notifyListeners();
  }

  Future<void> markConversationAsRead(String conversationId) async {
    if (_currentUserId == null) return;

    try {
      final index = _conversations.indexWhere((c) => c.id == conversationId);
      if (index != -1) {
        final updatedConversation = Conversation(
          id: _conversations[index].id,
          name: _conversations[index].name,
          lastMessage: _conversations[index].lastMessage,
          avatar: _conversations[index].avatar,
          lastMessageTime: _conversations[index].lastMessageTime,
          unreadCount: 0,
          isGroup: _conversations[index].isGroup,
        );
        await _supabase.from('thix_chat_reads').upsert({
          'chat_id': conversationId,
          'user_id': _currentUserId!,
          'read_at': DateTime.now().toUtc().toIso8601String(),
        });

        _conversations[index] = updatedConversation;
        final allIndex = _allConversations.indexWhere((c) => c.id == conversationId);
        if (allIndex != -1) {
          _allConversations[allIndex] = updatedConversation;
        }
        _totalNewMessages = _allConversations.fold(0, (sum, c) => sum + c.unreadCount);
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
  void _subscribeToRealtime() {
    if (_currentUserId == null) return;

    _disposeRealtimeChannels();

    _conversationsChannel = _supabase
        .channel('thix_chat_home_conversations')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'thix_chat_chats',
          callback: (payload) {
            unawaited(_refreshConversationsSafely());
          },
        )
        .subscribe();

    _messagesChannel = _supabase
        .channel('thix_chat_home_messages')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'thix_chat_messages',
          callback: (payload) {
            unawaited(_refreshConversationsSafely());
          },
        )
        .subscribe();

    _presenceChannel = _supabase
        .channel('thix_chat_home_presence')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'thix_presence',
          callback: (payload) {
            unawaited(_refreshOnlineUsersSafely());
          },
        )
        .subscribe();
  }

  void _clearData() {
    _disposeRealtimeChannels();
    _onlineUsers = [];
    _conversations = [];
    _allConversations = [];
    _totalOnlineCount = 0;
    _totalNewMessages = 0;
    _totalActiveMeetings = 0;
    _totalSecurityAlerts = 0;
    _isLoading = false;
    _searchQuery = '';
    notifyListeners();
  }

  List<Conversation> _applySearchQuery(List<Conversation> source) {
    if (_searchQuery.isEmpty) {
      return List<Conversation>.from(source);
    }
    return source.where((c) => c.name.toLowerCase().contains(_searchQuery)).toList(growable: false);
  }

  Set<String> _conversationParticipantIds(List<Map<String, dynamic>> chats) {
    final ids = <String>{};
    for (final chat in chats) {
      ids.addAll(_participantsFrom(chat).where((id) => id != _currentUserId));
    }
    return ids;
  }

  List<String> _participantsFrom(Map<String, dynamic> row) {
    final raw = row['participants'];
    if (raw is List) {
      return raw.whereType<String>().toList(growable: false);
    }
    return const <String>[];
  }

  Map<String, String> _participantNamesFrom(Map<String, dynamic> row) {
    final raw = row['participant_name'];
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value?.toString() ?? ''));
    }
    return const <String, String>{};
  }

  bool _isGroupConversation(Map<String, dynamic> row) {
    return (row['type'] as String?) == 'group';
  }

  bool _hasUnreadConversation({required Object? lastMessageAt, required DateTime? readAt}) {
    final parsedLastMessageAt = _parseDateTime(lastMessageAt);
    if (parsedLastMessageAt == null) return false;
    if (readAt == null) return true;
    return parsedLastMessageAt.isAfter(readAt);
  }

  String _conversationName(Map<String, dynamic> row, Map<String, Map<String, dynamic>> profileByUserId) {
    final title = _normalizedText(row['title']);
    final participantNames = _participantNamesFrom(row);
    final participants = _participantsFrom(row);
    final otherParticipantIds = participants.where((id) => id != _currentUserId).toList(growable: false);

    if (_isGroupConversation(row)) {
      if (title.isNotEmpty) return title;
      final derivedNames = otherParticipantIds
          .map((id) => participantNames[id] ?? _profileDisplayName(profileByUserId[id] ?? <String, dynamic>{}))
          .where((name) => name.trim().isNotEmpty)
          .take(3)
          .toList(growable: false);
      return derivedNames.isEmpty ? 'Groupe' : derivedNames.join(', ');
    }

    if (otherParticipantIds.isEmpty) return title.isNotEmpty ? title : 'Conversation';
    final otherUserId = otherParticipantIds.first;
    final participantName = participantNames[otherUserId];
    if (participantName != null && participantName.trim().isNotEmpty) {
      return participantName.trim();
    }

    return _profileDisplayName(profileByUserId[otherUserId] ?? <String, dynamic>{});
  }

  String _conversationAvatar(Map<String, dynamic> row, Map<String, Map<String, dynamic>> profileByUserId) {
    final explicitAvatar = _normalizedText(row['avatar_url']);
    if (explicitAvatar.isNotEmpty) return explicitAvatar;

    final participants = _participantsFrom(row);
    final otherParticipantIds = participants.where((id) => id != _currentUserId).toList(growable: false);
    if (!_isGroupConversation(row) && otherParticipantIds.isNotEmpty) {
      return _profileAvatar(profileByUserId[otherParticipantIds.first] ?? <String, dynamic>{}, otherParticipantIds.first);
    }

    final seed = (row['id'] as String?) ?? 'group';
    return _fallbackAvatar(seed);
  }

  Future<Map<String, DateTime>> _loadReadAtByChat(List<String> chatIds) async {
    if (_currentUserId == null || chatIds.isEmpty) return const <String, DateTime>{};

    try {
      final response = await _supabase
          .from('thix_chat_reads')
          .select('chat_id, read_at')
          .eq('user_id', _currentUserId!)
          .inFilter('chat_id', chatIds);

      final Map<String, DateTime> readAtByChat = {};
      for (final row in response as List) {
        final item = Map<String, dynamic>.from(row as Map);
        final chatId = item['chat_id'] as String?;
        final readAt = _parseDateTime(item['read_at']);
        if (chatId != null && chatId.isNotEmpty && readAt != null) {
          readAtByChat[chatId] = readAt;
        }
      }
      return readAtByChat;
    } catch (e) {
      debugPrint('Error loading chat read state: $e');
      return const <String, DateTime>{};
    }
  }

  Future<Map<String, Map<String, dynamic>>> _loadProfileByUserId(Set<String> userIds) async {
    if (userIds.isEmpty) return const <String, Map<String, dynamic>>{};

    try {
      final response = await _supabase
          .from('profiles')
          .select('id, display_name, full_name, avatar_url, photo_url')
          .inFilter('id', userIds.toList(growable: false));

      final profiles = <String, Map<String, dynamic>>{};
      for (final row in response as List) {
        final item = Map<String, dynamic>.from(row as Map);
        final id = item['id'] as String?;
        if (id != null && id.isNotEmpty) {
          profiles[id] = item;
        }
      }
      return profiles;
    } catch (e) {
      debugPrint('Error loading chat profiles: $e');
      return const <String, Map<String, dynamic>>{};
    }
  }

  String _profileDisplayName(Map<String, dynamic> profile) {
    final fullName = _normalizedText(profile['full_name']);
    if (fullName.isNotEmpty) return fullName;
    final displayName = _normalizedText(profile['display_name']);
    if (displayName.isNotEmpty) return displayName;
    return 'Utilisateur';
  }

  String _profileAvatar(Map<String, dynamic> profile, String seed) {
    final avatarUrl = _normalizedText(profile['avatar_url']);
    if (avatarUrl.isNotEmpty) return avatarUrl;
    final photoUrl = _normalizedText(profile['photo_url']);
    if (photoUrl.isNotEmpty) return photoUrl;
    return _fallbackAvatar(seed);
  }

  String _fallbackAvatar(String seed) => 'https://i.pravatar.cc/150?img=${seed.hashCode.abs() % 70}';

  String _normalizedText(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  DateTime? _parseDateTime(Object? value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  void _disposeRealtimeChannels() {
    _conversationsChannel?.unsubscribe();
    _messagesChannel?.unsubscribe();
    _presenceChannel?.unsubscribe();
    _conversationsChannel = null;
    _messagesChannel = null;
    _presenceChannel = null;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _disposeRealtimeChannels();
    super.dispose();
  }
}
