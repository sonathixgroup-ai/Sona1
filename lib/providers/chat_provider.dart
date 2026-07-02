// lib/providers/chat_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'dart:io';

import '../services/chat_service.dart';
import '../models/chat_models.dart';

class ChatProvider extends ChangeNotifier {
  late ChatService _service;
  
  // Données
  List<Conversation> _conversations = [];
  List<ChatMessage> _messages = [];
  List<Story> _stories = [];
  List<Space> _spaces = [];
  List<Conversation> _filteredConversations = [];
  List<Conversation> _archivedConversations = [];
  ChatStats _stats = ChatStats(
    onlineCount: 0,
    newMessagesCount: 0,
    activeCallsCount: 0,
    securityAlertsCount: 0,
  );
  
  // États
  bool _isLoading = false;
  bool _isTyping = false;
  String? _error;
  ChatMessage? _pinnedMessage;
  bool _isTypingInConversation = false;
  
  // Realtime
  RealtimeChannel? _messagesChannel;
  Timer? _typingTimer;
  String? _currentConversationId;
  
  ChatProvider() {
    _service = ChatService(Supabase.instance.client);
  }
  
  // ============================================================
  // GETTERS
  // ============================================================
  
  List<Conversation> get conversations => _conversations;
  List<Conversation> get filteredConversations => _filteredConversations;
  List<Conversation> get archivedConversations => _archivedConversations;
  List<ChatMessage> get messages => _messages;
  List<Story> get stories => _stories;
  List<Space> get spaces => _spaces;
  ChatStats get stats => _stats;
  bool get isLoading => _isLoading;
  bool get isTyping => _isTyping;
  bool get isTypingInConversation => _isTypingInConversation;
  String? get error => _error;
  ChatMessage? get pinnedMessage => _pinnedMessage;
  
  // ============================================================
  // INITIALISATION
  // ============================================================
  
  void initRealtime() {
    _setupRealtimeListener();
  }
  
  void initConversationRealtime(String conversationId) {
    _currentConversationId = conversationId;
    _setupConversationListener(conversationId);
  }
  
  void _setupRealtimeListener() {
    try {
      final supabase = Supabase.instance.client;
      _messagesChannel = supabase
          .channel('public:messages')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'messages',
            callback: (payload) {
              debugPrint('📬 Nouveau message détecté');
              _onNewMessage(payload.newRecord);
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('Error setting up realtime: $e');
    }
  }
  
  void _setupConversationListener(String conversationId) {
    // Logique pour écouter les messages d'une conversation spécifique
  }
  
  void _onNewMessage(dynamic payload) {
    // Mettre à jour la liste des messages
    notifyListeners();
  }
  
  // ============================================================
  // CONVERSATIONS
  // ============================================================
  
  Future<void> loadConversations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _conversations = await _service.getConversations();
      _filteredConversations = List.from(_conversations);
      await loadStats();
      await loadStories();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading conversations: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> loadStats() async {
    try {
      _stats = await _service.getStats();
    } catch (e) {
      debugPrint('Error loading stats: $e');
    }
    notifyListeners();
  }
  
  Future<void> loadStories() async {
    try {
      _stories = await _service.getStories();
    } catch (e) {
      debugPrint('Error loading stories: $e');
    }
    notifyListeners();
  }
  
  Future<void> loadSpaces() async {
    try {
      _spaces = await _service.getSpaces();
    } catch (e) {
      debugPrint('Error loading spaces: $e');
    }
    notifyListeners();
  }
  
  Conversation? getConversation(String id) {
    try {
      return _conversations.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }
  
  void filterConversations(String? filter) {
    if (filter == null) {
      _filteredConversations = List.from(_conversations);
    } else if (filter == 'group') {
      _filteredConversations = _conversations.where((c) => c.type == 'group').toList();
    } else {
      _filteredConversations = _conversations;
    }
    notifyListeners();
  }
  
  Future<void> searchConversations(String query) async {
    if (query.isEmpty) {
      _filteredConversations = List.from(_conversations);
    } else {
      _filteredConversations = _conversations
          .where((c) => c.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }
  
  // ============================================================
  // MESSAGES
  // ============================================================
  
  Future<void> loadMessages(String conversationId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _messages = await _service.getMessages(conversationId);
      _pinnedMessage = _messages.firstWhere(
        (m) => m.isPinned,
        orElse: () => null as ChatMessage,
      );
      await markMessagesAsRead(conversationId);
    } catch (e) {
      debugPrint('Error loading messages: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // ✅ Envoi de message avec paramètres nommés
  Future<void> sendMessage({
    required String conversationId,
    required String content,
    String? type,
    String? mediaUrl,
  }) async {
    if (content.trim().isEmpty && (mediaUrl == null || mediaUrl.isEmpty)) return;

    try {
      // Création optimiste
      final tempId = DateTime.now().millisecondsSinceEpoch.toString();
      final tempMessage = ChatMessage(
        id: tempId,
        conversationId: conversationId,
        senderId: _service.currentUserId,
        type: _stringToMessageType(type ?? 'text'),
        content: content.trim(),
        mediaURL: mediaUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        reactions: {},
        isPinned: false,
        isPriority: false,
      );

      _messages.insert(0, tempMessage);
      notifyListeners();

      // Appel au service
      ChatMessage sentMessage;
      if (mediaUrl != null && mediaUrl.isNotEmpty) {
        sentMessage = await _service.sendMedia(conversationId, mediaUrl, type ?? 'file');
      } else {
        sentMessage = await _service.sendMessage(conversationId, content.trim());
      }

      // Remplacer le message temporaire
      final index = _messages.indexWhere((m) => m.id == tempId);
      if (index != -1) {
        _messages[index] = sentMessage;
        notifyListeners();
      }
      await loadConversations();
    } catch (e) {
      _error = e.toString();
      _messages.removeWhere((m) => m.id.startsWith(tempId));
      notifyListeners();
    }
  }
  
  // Ancienne méthode sendMessage (pour compatibilité)
  Future<void> sendTextMessage(String conversationId, String content) async {
    await sendMessage(conversationId: conversationId, content: content, type: 'text');
  }
  
  Future<void> sendMedia(String conversationId, String filePath, String type) async {
    try {
      final message = await _service.sendMedia(conversationId, filePath, type);
      _messages.add(message);
      notifyListeners();
    } catch (e) {
      debugPrint('Error sending media: $e');
    }
  }
  
  Future<void> toggleLike(String messageId) async {
    try {
      await _service.toggleLike(messageId);
      final index = _messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        final message = _messages[index];
        _messages[index] = message.copyWith(
          isLiked: !message.isLiked,
          likesCount: message.isLiked ? message.likesCount - 1 : message.likesCount + 1,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error toggling like: $e');
    }
  }
  
  Future<void> addReaction(String messageId, String emoji) async {
    try {
      await _service.addReaction(messageId, emoji);
      final index = _messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        final message = _messages[index];
        final reactions = Map<String, List<String>>.from(message.reactions);
        if (reactions.containsKey(emoji)) {
          reactions[emoji]!.add(_service.currentUserId);
        } else {
          reactions[emoji] = [_service.currentUserId];
        }
        _messages[index] = message.copyWith(reactions: reactions);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error adding reaction: $e');
    }
  }
  
  Future<void> pinMessage(String conversationId, String messageId) async {
    try {
      await _service.pinMessage(messageId);
      await loadMessages(conversationId);
    } catch (e) {
      debugPrint('Error pinning message: $e');
    }
  }
  
  Future<void> markMessagesAsRead(String conversationId) async {
    try {
      await _service.markMessagesAsRead(conversationId);
      await loadConversations();
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }
  
  // ✅ Suppression d'un message
  Future<void> deleteMessage(String messageId) async {
    try {
      await _service.deleteMessage(messageId);
      _messages.removeWhere((m) => m.id == messageId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  void sendTypingStatus(String conversationId, bool isTyping) {
    _isTypingInConversation = isTyping;
    notifyListeners();
  }
  
  // ============================================================
  // STORIES
  // ============================================================
  
  Future<void> loadMyStories() async {
    try {
      _stories = await _service.getMyStories();
    } catch (e) {
      debugPrint('Error loading my stories: $e');
    }
    notifyListeners();
  }
  
  Future<void> loadContactsStatus() async {
    try {
      // Implémenter le chargement des statuts des contacts
    } catch (e) {
      debugPrint('Error loading contacts status: $e');
    }
    notifyListeners();
  }
  
  Future<bool> postStoryImage(File imageFile) async {
    try {
      await _service.createStory(imageFile, 'image');
      await loadMyStories();
      return true;
    } catch (e) {
      debugPrint('Error posting story: $e');
      return false;
    }
  }
  
  Future<bool> postStoryText(String text) async {
    try {
      await _service.createStoryText(text);
      await loadMyStories();
      return true;
    } catch (e) {
      debugPrint('Error posting story: $e');
      return false;
    }
  }
  
  // ============================================================
  // ARCHIVES
  // ============================================================
  
  Future<void> loadArchivedConversations() async {
    _isLoading = true;
    notifyListeners();
    try {
      _archivedConversations = await _service.getArchivedConversations();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> unarchiveConversation(String conversationId) async {
    try {
      await _service.unarchiveConversation(conversationId);
      await loadArchivedConversations();
      await loadConversations();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  Future<void> deleteArchivedConversation(String conversationId) async {
    try {
      await _service.deleteArchivedConversation(conversationId);
      await loadArchivedConversations();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  Future<void> searchArchivedConversations(Map<String, dynamic> filters) async {
    _isLoading = true;
    notifyListeners();
    try {
      _archivedConversations = await _service.searchArchivedConversations(filters);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // ============================================================
  // UTILITAIRES
  // ============================================================
  
  MessageType _stringToMessageType(String type) {
    switch (type) {
      case 'image': return MessageType.image;
      case 'audio': return MessageType.audio;
      case 'video': return MessageType.video;
      case 'file': return MessageType.file;
      case 'reaction': return MessageType.reaction;
      default: return MessageType.text;
    }
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _messagesChannel?.unsubscribe();
    _typingTimer?.cancel();
    super.dispose();
  }
}
