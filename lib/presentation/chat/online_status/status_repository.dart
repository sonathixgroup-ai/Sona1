// lib/presentation/chat/online_status/status_repository.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

// ✅ Utilisation d'un import de package (plus fiable)
import 'package:thix_id/core/auth/token_service.dart';

class StatusRepository {
  final String _baseUrl = 'https://kfzkxaatdbapqwxcely.supabase.co/functions/v1';

  Future<http.Response> _authenticatedRequest(
    String endpoint, {
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    // ✅ Récupération du token avec gestion d'erreur
    String token;
    try {
      token = await TokenService.getToken();
    } catch (e) {
      // Fallback : utiliser le token de Supabase si TokenService échoue
      final session = Supabase.instance.client.auth.currentSession;
      token = session?.accessToken ?? '';
      if (token.isEmpty) {
        throw Exception('Impossible d\'obtenir un token d\'authentification');
      }
    }

    final uri = Uri.parse('$_baseUrl/$endpoint');
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      switch (method) {
        case 'GET':
          return await http.get(uri, headers: headers);
        case 'POST':
          return await http.post(uri, headers: headers, body: jsonEncode(body));
        case 'PUT':
          return await http.put(uri, headers: headers, body: jsonEncode(body));
        case 'DELETE':
          return await http.delete(uri, headers: headers);
        default:
          throw Exception('Méthode non supportée: $method');
      }
    } catch (e) {
      throw Exception('Erreur de requête vers $endpoint: $e');
    }
  }

  // ============================================================
  // MÉTHODES DE STATUT
  // ============================================================

  Future<void> updateStatus(String userId, String status, {String? customStatus}) async {
    final response = await _authenticatedRequest(
      'update_presence',
      method: 'POST',
      body: {
        'user_id': userId,
        'status': status,
        'custom_status': customStatus,
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur updateStatus: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getStatus(String userId) async {
    final response = await _authenticatedRequest('presence?user_id=$userId');
    if (response.statusCode != 200) {
      throw Exception('Erreur getStatus: ${response.body}');
    }
    return jsonDecode(response.body);
  }

  Future<List<Map<String, dynamic>>> getOnlineUsers() async {
    final response = await _authenticatedRequest('online_users');
    if (response.statusCode != 200) {
      throw Exception('Erreur getOnlineUsers: ${response.body}');
    }
    final List<dynamic> jsonList = jsonDecode(response.body);
    return jsonList.cast<Map<String, dynamic>>();
  }
}
