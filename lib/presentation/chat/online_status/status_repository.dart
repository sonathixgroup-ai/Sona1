// lib/presentation/chat/online_status/status_repository.dart
// Appels aux Edge Functions pour les statuts

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/auth/token_service.dart';
import '../core/chat_models.dart';

class StatusRepository {
  final String _baseUrl = 'https://ton-projet.supabase.co/functions/v1';

  Future<ChatUser> getUserStatus(String userId) async {
    final token = await TokenService.getToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/user_status?user_id=$userId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur getUserStatus: ${response.body}');
    }
    return ChatUser.fromJson(jsonDecode(response.body));
  }

  Future<List<ChatUser>> getOnlineContacts(String currentUserId) async {
    final token = await TokenService.getToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/online_contacts?user_id=$currentUserId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur getOnlineContacts: ${response.body}');
    }
    final List<dynamic> list = jsonDecode(response.body);
    return list.map((json) => ChatUser.fromJson(json)).toList();
  }

  Future<void> updateStatus(String userId, String status) async {
    final token = await TokenService.getToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/update_status'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'user_id': userId, 'status': status}),
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur updateStatus: ${response.body}');
    }
  }

  // Streaming Realtime (conserve SupabaseClient)
  Stream<ChatUser> listenToStatusChanges(String userId) {
    final supabase = Supabase.instance.client;
    return supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((event) => ChatUser.fromJson(event.first));
  }
}
