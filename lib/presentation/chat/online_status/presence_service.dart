// lib/presentation/chat/online_status/presence_service.dart
// Service de présence avec heartbeat et Edge Functions

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'status_repository.dart';
import '../../../core/auth/token_service.dart';

class PresenceService {
  final StatusRepository _statusRepository;
  final String currentUserId;
  Timer? _heartbeatTimer;
  bool _isActive = false;
  final String _baseUrl = 'https://ton-projet.supabase.co/functions/v1';

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

  Future<void> sendTyping(String conversationId) async {
    final token = await TokenService.getToken();
    await http.post(
      Uri.parse('$_baseUrl/typing'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'conversation_id': conversationId, 'user_id': currentUserId}),
    );
  }

  Future<void> stopTyping(String conversationId) async {
    // Optionnel : envoyer un signal d'arrêt
  }

  void onAppPaused() {
    _statusRepository.updateStatus(currentUserId, 'away');
  }

  void onAppResumed() {
    _statusRepository.updateStatus(currentUserId, 'online');
  }
}
