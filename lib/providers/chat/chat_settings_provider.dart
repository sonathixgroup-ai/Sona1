// ============================================================
// 📁 lib/providers/chat/chat_settings_provider.dart
// ============================================================

import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/chat/chat_user.dart';
import '../../models/chat/chat_settings.dart';
import '../../services/chat/chat_settings_service.dart';

class ChatSettingsProvider extends ChangeNotifier {
  final ChatSettingsService _service = ChatSettingsService();

  ChatUser? _chatUser;
  ChatSettings? _settings;
  bool _isLoading = false;
  String? _error;
  
  String? _currentUserId; 

  ChatUser? get chatUser => _chatUser;
  ChatSettings? get settings => _settings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Charger toutes les données (VERSION ANTI-CRASH)
  Future<void> load(String userId) async {
    _currentUserId = userId; 
    _setLoading(true);
    _error = null;

    // 1. Tenter de charger le profil
    try {
      _chatUser = await _service.getChatUser(userId);
    } catch (e) {
      print('⚠️ Erreur Supabase (getChatUser) : $e');
      _error = 'Erreur Profil: $e';
    }

    // 2. Tenter de charger les paramètres (Même si le profil a échoué)
    try {
      _settings = await _service.getSettings(userId);
    } catch (e) {
      print('⚠️ Erreur Supabase (getSettings) : $e');
      _error = 'Erreur Settings: $e';
      // Fallback : On crée des paramètres par défaut vides pour débloquer l'interface
      _settings = ChatSettings.fromJson({});
    }

    _setLoading(false);
  }

  Future<bool> updateChatUser(ChatUser user) async {
    if (_currentUserId == null) return false;
    _setLoading(true);
    try {
      await _service.updateChatUser(_currentUserId!, user);
      _chatUser = user;
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<String?> uploadAvatar(File image) async {
    if (_currentUserId == null || _chatUser == null) return null;
    _setLoading(true);
    try {
      final url = await _service.uploadAvatar(_currentUserId!, image);
      _chatUser = _chatUser!.copyWith(avatarUrl: url);
      _setLoading(false);
      return url;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return null;
    }
  }

  Future<bool> updateSettings(ChatSettings settings) async {
    if (_currentUserId == null) return false;
    _setLoading(true);
    try {
      await _service.updateSettings(_currentUserId!, settings);
      _settings = settings;
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
