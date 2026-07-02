// lib/presentation/chat/security_advanced/session_manager.dart
// Gestion des sessions (multi-appareils, révocation)

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Session {
  final String id;
  final String deviceName;
  final DateTime lastActive;
  final bool isCurrent;

  Session({required this.id, required this.deviceName, required this.lastActive, this.isCurrent = false});

  Map<String, dynamic> toJson() => {
    'id': id,
    'device_name': deviceName,
    'last_active': lastActive.toIso8601String(),
    'is_current': isCurrent,
  };

  factory Session.fromJson(Map<String, dynamic> json) => Session(
    id: json['id'],
    deviceName: json['device_name'],
    lastActive: DateTime.parse(json['last_active']),
    isCurrent: json['is_current'] ?? false,
  );
}

class SessionManager {
  static const String _sessionsKey = 'active_sessions';

  static Future<List<Session>> getActiveSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_sessionsKey);
    if (data == null) return [];
    final List<dynamic> list = jsonDecode(data);
    return list.map((e) => Session.fromJson(e)).toList();
  }

  static Future<void> addSession(Session session) async {
    final sessions = await getActiveSessions();
    sessions.add(session);
    await _saveSessions(sessions);
  }

  static Future<void> removeSession(String sessionId) async {
    var sessions = await getActiveSessions();
    sessions.removeWhere((s) => s.id == sessionId);
    await _saveSessions(sessions);
  }

  static Future<void> revokeAllExceptCurrent() async {
    final sessions = await getActiveSessions();
    final current = sessions.where((s) => s.isCurrent).toList();
    await _saveSessions(current);
  }

  static Future<void> _saveSessions(List<Session> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(sessions.map((s) => s.toJson()).toList());
    await prefs.setString(_sessionsKey, data);
  }
}
