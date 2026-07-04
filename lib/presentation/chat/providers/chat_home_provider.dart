import 'package:flutter/material.dart';

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
  List<ChatUser> _onlineUsers = [];
  List<Conversation> _conversations = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String _selectedTab = 'all'; // all, teams, calls, favorites, appointments

  // Getters
  List<ChatUser> get onlineUsers => _onlineUsers;
  List<Conversation> get conversations => _conversations;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String get selectedTab => _selectedTab;

  // Données mockées pour démo
  static const int mockOnlineCount = 142;
  static const int mockNewMessages = 38;
  static const int mockActiveMeetings = 12;
  static const int mockSecurityAlerts = 7;

  ChatHomeProvider() {
    _loadMockData();
  }

  void _loadMockData() {
    _isLoading = true;
    notifyListeners();

    // Mock utilisateurs en ligne
    _onlineUsers = [
      ChatUser(
        id: '1',
        name: 'Aminata',
        avatar: 'https://i.pravatar.cc/150?img=1',
        isOnline: true,
      ),
      ChatUser(
        id: '2',
        name: 'Nathan',
        avatar: 'https://i.pravatar.cc/150?img=2',
        isOnline: true,
      ),
      ChatUser(
        id: '3',
        name: 'Sarah',
        avatar: 'https://i.pravatar.cc/150?img=3',
        isOnline: true,
      ),
      ChatUser(
        id: '4',
        name: 'Koffi',
        avatar: 'https://i.pravatar.cc/150?img=4',
        isOnline: true,
      ),
      ChatUser(
        id: '5',
        name: 'David',
        avatar: 'https://i.pravatar.cc/150?img=5',
        isOnline: true,
      ),
    ];

    // Mock conversations
    _conversations = [
      Conversation(
        id: '1',
        name: 'Aminata Diallo',
        lastMessage: 'Peux-tu me partager le document du projet s\'il te plaît ?',
        avatar: 'https://i.pravatar.cc/150?img=1',
        lastMessageTime: DateTime.now().subtract(const Duration(minutes: 31)),
        unreadCount: 2,
        isGroup: false,
      ),
      Conversation(
        id: '2',
        name: 'Équipe Marketing',
        lastMessage: 'David : Voici les visuels pour la campagne de la semaine.',
        avatar: 'https://i.pravatar.cc/150?img=10',
        lastMessageTime: DateTime.now().subtract(const Duration(minutes: 48)),
        unreadCount: 5,
        isGroup: true,
      ),
      Conversation(
        id: '3',
        name: 'Koffi Mensah',
        lastMessage: 'Merci pour ton retour !\nOn avance bien 💪',
        avatar: 'https://i.pravatar.cc/150?img=4',
        lastMessageTime: DateTime.now().subtract(const Duration(hours: 1)),
        unreadCount: 1,
        isGroup: false,
      ),
      Conversation(
        id: '4',
        name: 'Projets Innovants',
        lastMessage: 'Mariama : N\'oubliez pas la réunion de ce soir à 18h.',
        avatar: 'https://i.pravatar.cc/150?img=11',
        lastMessageTime: DateTime.now().subtract(const Duration(hours: 3)),
        unreadCount: 3,
        isGroup: true,
      ),
      Conversation(
        id: '5',
        name: 'THIX Support',
        lastMessage: 'Bonjour Michel, comment pouvons-nous vous aider ?',
        avatar: 'https://i.pravatar.cc/150?img=12',
        lastMessageTime: DateTime.now().subtract(const Duration(days: 1)),
        unreadCount: 1,
        isGroup: false,
      ),
    ];

    _unreadCount = _conversations.fold(0, (sum, conv) => sum + conv.unreadCount);
    _isLoading = false;
    notifyListeners();
  }

  void selectTab(String tab) {
    _selectedTab = tab;
    notifyListeners();
  }

  List<Conversation> getFilteredConversations() {
    // TODO: Implémenter le filtrage selon _selectedTab
    // Pour l'instant, retourner toutes les conversations
    return _conversations;
  }

  void searchConversations(String query) {
    // TODO: Implémenter la recherche
    notifyListeners();
  }

  void markConversationAsRead(String conversationId) {
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index != -1) {
      _unreadCount -= _conversations[index].unreadCount;
      _conversations[index] = Conversation(
        id: _conversations[index].id,
        name: _conversations[index].name,
        lastMessage: _conversations[index].lastMessage,
        avatar: _conversations[index].avatar,
        lastMessageTime: _conversations[index].lastMessageTime,
        unreadCount: 0,
        isGroup: _conversations[index].isGroup,
      );
      notifyListeners();
    }
  }
}
