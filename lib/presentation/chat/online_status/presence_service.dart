import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'status_repository.dart';

class PresenceService {
  final StatusRepository _statusRepository;
  final String currentUserId;
  Timer? _heartbeatTimer;
  bool _isActive = false;

  PresenceService({required this.currentUserId}) : _statusRepository = StatusRepository();

  void start() {
    if (_isActive) return;
    _isActive = true;
    _setStatusOnline();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) => _refreshPresence());
  }

  void stop() async {
    _isActive = false;
    _heartbeatTimer?.cancel();
    await _statusRepository.updateStatus(currentUserId, 'offline');
  }

  Future<void> _setStatusOnline() async {
    await _statusRepository.updateStatus(currentUserId, 'online');
  }

  Future<void> _refreshPresence() async {
    if (_isActive) {
      await _statusRepository.updateStatus(currentUserId, 'online');
    }
  }

  // ✅ Typing : utiliser la table thix_typing ou Realtime
  Future<void> sendTyping(String conversationId) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from('thix_typing')
          .upsert({
            'conversation_id': conversationId,
            'user_id': currentUserId,
            'updated_at': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      debugPrint('sendTyping error: $e');
    }
  }

  Future<void> stopTyping(String conversationId) async {
    // Optionnel : supprimer l'entrée
    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from('thix_typing')
          .delete()
          .eq('conversation_id', conversationId)
          .eq('user_id', currentUserId);
    } catch (e) {
      // Ignorer
    }
  }

  void onAppPaused() {
    _statusRepository.updateStatus(currentUserId, 'away');
  }

  void onAppResumed() {
    _statusRepository.updateStatus(currentUserId, 'online');
  }

  void dispose() {
    _heartbeatTimer?.cancel();
    _isActive = false;
  }
}
