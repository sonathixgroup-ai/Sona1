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

  // Getters
  ChatUser? get chatUser => _chatUser;
  ChatSettings? get settings => _settings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Charger toutes les données
  Future<void> load(String userId) async {
    _setLoading(true);
    _error = null;

    try {
      final user = await _service.getChatUser(userId);
      final settings = await _service.getSettings(userId);
      _chatUser = user;
      _settings = settings;
      _setLoading(false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
    }
  }

  // Mettre à jour le profil chat
  Future<bool> updateChatUser(ChatUser user) async {
    if (_chatUser == null) return false;
    _setLoading(true);

    try {
      await _service.updateChatUser(_chatUser!.id, user);
      _chatUser = user;
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Uploader un avatar
  Future<String?> uploadAvatar(File image) async {
    if (_chatUser == null) return null;
    _setLoading(true);

    try {
      final url = await _service.uploadAvatar(_chatUser!.id, image);
      _chatUser = _chatUser!.copyWith(avatarUrl: url);
      _setLoading(false);
      return url;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return null;
    }
  }

  // Mettre à jour les réglages
  Future<bool> updateSettings(ChatSettings settings) async {
    if (_chatUser == null) return false;
    _setLoading(true);

    try {
      await _service.updateSettings(_chatUser!.id, settings);
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
