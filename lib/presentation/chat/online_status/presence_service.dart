// lib/presentation/chat/online_status/presence_service.dart
// Service de présence avec heartbeat et Edge Functions

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

// ✅ Import corrigé avec package (plus fiable)
import 'package:thix_id/core/auth/token_service.dart';

import 'status_repository.dart';

class PresenceService {
  final StatusRepository _statusRepository;
  final String currentUserId;
  Timer? _heartbeatTimer;
  bool _isActive = false;
  final String _baseUrl = 'https://kfzkxaatdbapqwxcely.supabase.co/functions/v1';

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

  // ✅ Correction avec fallback si TokenService n'est pas disponible
  Future<void> sendTyping(String conversationId) async {
    try {
      String token;
      try {
        token = await TokenService.getToken();
      } catch (e) {
        // Fallback: utiliser le token de la session Supabase
        final session = Supabase.instance.client.auth.currentSession;
        token = session?.accessToken ?? '';
        if (token.isEmpty) {
          throw Exception('Impossible d\'obtenir un token d\'authentification');
        }
      }

      await http.post(
        Uri.parse('$_baseUrl/typing'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'conversation_id': conversationId,
          'user_id': currentUserId,
        }),
      );
    } catch (e) {
      debugPrint('sendTyping error: $e');
    }
  }

  Future<void> stopTyping(String conversationId) async {
    // Optionnel : envoyer un signal d'arrêt
    // On peut envoyer un message de stop ou simplement ignorer
    // car le timeout du serveur gérera l'arrêt
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
