import 'dart:io';
import 'package:flutter/material.dart';
import 'package:thix_id/services/chat_service.dart' as chat_service;
import 'package:thix_id/presentation/chat/core/chat_models.dart';

class ChatProvider extends ChangeNotifier {
  final chat_service.ChatService _chatService;

  // États – utilisent le modèle UI (chat_models.dart) pour les conversations
  List<Conversation> _conversations = [];
  List<Conversation> _archivedConversations = [];
  List<chat_service.ChatMessage> _messages = [];
  List<chat_service.Story> _stories = [];
  List<chat_service.Space> _spaces = [];
  chat_service.ChatStats _stats = const chat_service.ChatStats(); // ✅ corrigé

  bool _isLoading = false;
  String? _error;

  // Getters
  List<Conversation> get conversations => _conversations;
  List<Conversation> get archivedConversations => _archivedConversations;
  List<chat_service.ChatMessage> get messages => _messages;
  List<chat_service.Story> get stories => _stories;
  List<chat_service.Space> get spaces => _spaces;
  chat_service.ChatStats get stats => _stats; // ✅ corrigé
  bool get isLoading => _isLoading;
  String? get error => _error;

  ChatProvider(this._chatService);

  // ============================================================
  // CONVERTER
  // ============================================================
  Conversation _toUIConversation(chat_service.Conversation s) {
    return Conversation(
      id: s.id,
      name: s.name ?? '',
      avatarUrl: s.avatarURL,
      isGroup: s.type == chat_service.ConversationType.group,
      participantIds: s.participantIds,
      lastMessage: '',
      lastMessageTime: s.lastMessageAt ?? s.updatedAt,
      unreadCount: 0,
      isArchived: s.status == chat_service.ConversationStatus.archived,
      isOnline: false,
    );
  }

  // ============================================================
  // CONVERSATIONS
  // ============================================================

  Future<void> loadConversations() async {
    _setLoading(true);
    try {
      final serviceConvs = await _chatService.getConversations();
      _conversations = serviceConvs.map(_toUIConversation).toList();
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
      final serviceConvs = await _chatService.getArchivedConversations();
      _archivedConversations = serviceConvs.map(_toUIConversation).toList();
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
      await loadConversations();
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
      final serviceConvs = await _chatService.searchArchivedConversations(filters);
      _archivedConversations = serviceConvs.map(_toUIConversation).toList();
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

  Future<chat_service.ChatMessage> sendMessage(String conversationId, String content) async {
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

  Future<chat_service.ChatMessage> sendMedia(String conversationId, String filePath, String type) async {
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

  List<chat_service.ChatUser> _contactsStatus = [];
  List<chat_service.ChatUser> get contactsStatus => _contactsStatus;

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
  // PRESENCE
  // ============================================================

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
    _stats = const chat_service.ChatStats(); // ✅ corrigé
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
