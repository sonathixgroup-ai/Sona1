import 'dart:io';
import 'package:flutter/material.dart';
import 'package:thix_id/services/chat_service.dart' as chat_service;
import 'package:thix_id/presentation/chat/core/chat_models.dart';

class ChatProvider extends ChangeNotifier {
  final chat_service.ChatService _chatService;

  // États
  List<Conversation> _conversations = [];
  List<Conversation> _archivedConversations = [];
  List<chat_service.ChatMessage> _messages = [];
  List<chat_service.Story> _stories = [];
  List<chat_service.Space> _spaces = [];
  chat_service.ChatStats _stats = const chat_service.ChatStats();

  bool _isLoading = false;
  String? _error;

  // 🔥 Nouveaux états pour la pagination des conversations
  bool _isLoadingMore = false;
  bool _hasMoreConversations = true;
  final int _pageSize = 20;

  // 🔥 Nouveaux états pour la pagination des messages
  bool _isLoadingMoreMessages = false;
  bool _hasMoreMessages = true;

  // Getters
  List<Conversation> get conversations => _conversations;
  List<Conversation> get archivedConversations => _archivedConversations;
  List<chat_service.ChatMessage> get messages => _messages;
  List<chat_service.Story> get stories => _stories;
  List<chat_service.Space> get spaces => _spaces;
  chat_service.ChatStats get stats => _stats;
  
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreConversations => _hasMoreConversations;
  String? get error => _error;

  ChatProvider(this._chatService);

  // ============================================================
  // CONVERTER (CORRIGÉ : on ne perd plus les données)
  // ============================================================
  Conversation _toUIConversation(chat_service.ChatConversation s) {
    return Conversation(
      id: s.id,
      name: s.displayName ?? 'Inconnu', // S'adapte au groupe ou au contact
      avatarUrl: s.displayAvatar,
      isGroup: s.isGroup,
      participantIds: s.participantIds,
      lastMessage: s.lastMessage?.content ?? '', // ✅ Récupère le dernier message
      lastMessageTime: s.lastMessage?.createdAt ?? s.updatedAt,
      unreadCount: s.unreadCount, // ✅ Ne plus coder en dur à 0 !
      isArchived: false, // À mapper si géré dans ton service
      isOnline: false, // Géré par le PresenceService
    );
  }

  // ============================================================
  // CONVERSATIONS (PAGINÉES)
  // ============================================================

  /// Charge la première page (Refresh)
  Future<void> loadConversations() async {
    _setLoading(true);
    _hasMoreConversations = true;
    
    try {
      final serviceConvs = await _chatService.getConversations(limit: _pageSize, offset: 0);
      _conversations = serviceConvs.map(_toUIConversation).toList();
      
      if (serviceConvs.length < _pageSize) {
        _hasMoreConversations = false;
      }
      
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// Charge la page suivante (Infinite Scroll)
  Future<void> loadMoreConversations() async {
    if (_isLoadingMore || !_hasMoreConversations) return;
    
    _isLoadingMore = true;
    notifyListeners();

    try {
      final offset = _conversations.length;
      final serviceConvs = await _chatService.getConversations(limit: _pageSize, offset: offset);
      
      if (serviceConvs.isEmpty) {
        _hasMoreConversations = false;
      } else {
        _conversations.addAll(serviceConvs.map(_toUIConversation));
        if (serviceConvs.length < _pageSize) {
          _hasMoreConversations = false;
        }
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // ============================================================
  // MESSAGES (PAGINÉS)
  // ============================================================

  /// Charge la première page de messages en ouvrant le chat
  Future<void> loadMessages(String conversationId) async {
    _setLoading(true);
    _hasMoreMessages = true;
    try {
      _messages = await _chatService.getMessages(conversationId, limit: 50, offset: 0);
      if (_messages.length < 50) _hasMoreMessages = false;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// Charge les messages plus anciens quand on scroll vers le haut
  Future<void> loadMoreMessages(String conversationId) async {
    if (_isLoadingMoreMessages || !_hasMoreMessages) return;

    _isLoadingMoreMessages = true;
    notifyListeners();

    try {
      final offset = _messages.length;
      final olderMessages = await _chatService.getMessages(conversationId, limit: 50, offset: offset);
      
      if (olderMessages.isEmpty) {
        _hasMoreMessages = false;
      } else {
        _messages.addAll(olderMessages); // Attention: vérifie l'ordre d'affichage (reversed ou non) dans ton UI
        if (olderMessages.length < 50) _hasMoreMessages = false;
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingMoreMessages = false;
      notifyListeners();
    }
  }

  Future<chat_service.ChatMessage> sendMessage(String conversationId, String content) async {
    try {
      final msg = await _chatService.sendMessage(
        conversationId: conversationId, 
        content: content
      );
      _messages.insert(0, msg); // Insère en haut de la liste locale
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
      await _chatService.markAsRead(conversationId);
      
      // ✅ Mise à jour locale (optimiste) pour l'UI sans recharger toute la DB
      final index = _conversations.indexWhere((c) => c.id == conversationId);
      if (index != -1) {
        final conv = _conversations[index];
        _conversations[index] = Conversation(
          id: conv.id,
          name: conv.name,
          avatarUrl: conv.avatarUrl,
          isGroup: conv.isGroup,
          participantIds: conv.participantIds,
          lastMessage: conv.lastMessage,
          lastMessageTime: conv.lastMessageTime,
          unreadCount: 0, // Remise à zéro locale
          isArchived: conv.isArchived,
          isOnline: conv.isOnline,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // --- Le reste de tes méthodes (Stories, Spaces, etc.) reste inchangé ---
  // ...

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
    _stats = const chat_service.ChatStats();
    _isLoading = false;
    _isLoadingMore = false;
    _hasMoreConversations = true;
    _hasMoreMessages = true;
    _error = null;
    notifyListeners();
  }
}
