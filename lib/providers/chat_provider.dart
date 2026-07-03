import 'dart:io';
import 'package:flutter/material.dart';
import 'package:thix_id/services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService;

  // États
  List<Conversation> _conversations = [];
  List<Conversation> _archivedConversations = [];
  List<ChatMessage> _messages = [];
  List<Story> _stories = [];
  List<Space> _spaces = [];
  ChatStats _stats = const ChatStats();

  bool _isLoading = false;
  String? _error;

  // Getters
  List<Conversation> get conversations => _conversations;
  List<Conversation> get archivedConversations => _archivedConversations;
  List<ChatMessage> get messages => _messages;
  List<Story> get stories => _stories;
  List<Space> get spaces => _spaces;
  ChatStats get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ChatProvider(this._chatService);

  // ============================================================
  // CONVERSATIONS
  // ============================================================

  Future<void> loadConversations() async {
    _setLoading(true);
    try {
      _conversations = await _chatService.getConversations();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadArchivedConversations() async {
    _setLoading(true);
    try {
      _archivedConversations = await _chatService.getArchivedConversations();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> archiveConversation(String conversationId) async {
    try {
      await _chatService.archiveConversation(conversationId);
      _conversations.removeWhere((c) => c.id == conversationId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> unarchiveConversation(String conversationId) async {
    try {
      await _chatService.unarchiveConversation(conversationId);
      _archivedConversations.removeWhere((c) => c.id == conversationId);
      await loadConversations(); // Recharge la liste active
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteArchivedConversation(String conversationId) async {
    try {
      await _chatService.deleteArchivedConversation(conversationId);
      _archivedConversations.removeWhere((c) => c.id == conversationId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> searchArchivedConversations(Map<String, dynamic> filters) async {
    _setLoading(true);
    try {
      _archivedConversations = await _chatService.searchArchivedConversations(filters);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // MESSAGES
  // ============================================================

  Future<void> loadMessages(String conversationId) async {
    _setLoading(true);
    try {
      _messages = await _chatService.fetchMessages(conversationId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<ChatMessage> sendMessage(String conversationId, String content) async {
    try {
      final msg = await _chatService.sendMessage(conversationId, content);
      _messages.insert(0, msg);
      _error = null;
      notifyListeners();
      return msg;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<ChatMessage> sendMedia(String conversationId, String filePath, String type) async {
    try {
      final msg = await _chatService.sendMedia(conversationId, filePath, type);
      _messages.insert(0, msg);
      _error = null;
      notifyListeners();
      return msg;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> markAsRead(String conversationId) async {
    try {
      await _chatService.markMessagesAsRead(conversationId);
      // Optionnel : mettre à jour les compteurs de messages non lus
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggleLike(String messageId) async {
    try {
      await _chatService.toggleLike(messageId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> addReaction(String messageId, String emoji) async {
    try {
      await _chatService.addReaction(messageId, emoji);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> pinMessage(String messageId) async {
    try {
      await _chatService.pinMessage(messageId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await _chatService.deleteMessage(messageId);
      _messages.removeWhere((m) => m.id == messageId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ============================================================
  // STORIES, SPACES & STATS
  // ============================================================

  Future<void> loadStories() async {
    try {
      _stories = await _chatService.getStories();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<void> loadSpaces() async {
    try {
      _spaces = await _chatService.getSpaces();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<void> loadStats() async {
    try {
      _stats = await _chatService.getStats();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }

  // ============================================================
  // CONTACTS STATUS
  // ============================================================

  List<ChatUser> _contactsStatus = [];
  List<ChatUser> get contactsStatus => _contactsStatus;

  Future<void> loadContactsStatus() async {
    try {
      _contactsStatus = await _chatService.getContactsStatus();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }

  // ============================================================
  // PRESENCE (AJOUTÉ)
  // ============================================================

  /// Met à jour le statut de présence de l'utilisateur connecté
  /// via le backend, puis notifie les listeners.
  Future<void> updatePresence(String status) async {
    try {
      await _chatService.updatePresence(status);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }

  // ============================================================
  // STORIES (CREATE)
  // ============================================================

  Future<void> createStoryText(String text) async {
    try {
      await _chatService.createStoryText(text);
      await loadStories();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> createStory(File imageFile, String type) async {
    try {
      await _chatService.createStory(imageFile, type);
      await loadStories();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ============================================================
  // UTILITAIRES
  // ============================================================

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void reset() {
    _conversations = [];
    _archivedConversations = [];
    _messages = [];
    _stories = [];
    _spaces = [];
    _stats = const ChatStats();
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
