// lib/services/chat/connection_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/connection_request.dart';
import '../models/connection.dart';

class ConnectionService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Envoyer une demande de connexion
  Future<ConnectionRequest> sendRequest({
    required String senderId,
    required String receiverId,
    String? message,
  }) async {
    final data = {
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message': message,
      'status': 'pending',
    };
    final response = await _supabase
        .from('connection_requests')
        .insert(data)
        .select()
        .single();
    return ConnectionRequest.fromJson(response);
  }

  // Accepter une demande
  Future<Connection> acceptRequest(String requestId) async {
    // 1. Mettre à jour le statut de la demande
    final requestResponse = await _supabase
        .from('connection_requests')
        .update({
          'status': 'accepted',
          'responded_at': DateTime.now().toIso8601String(),
        })
        .eq('id', requestId)
        .select()
        .single();

    final request = ConnectionRequest.fromJson(requestResponse);

    // 2. Créer la connexion
    final connectionData = {
      'user1_id': request.senderId,
      'user2_id': request.receiverId,
    };
    final connectionResponse = await _supabase
        .from('connections')
        .insert(connectionData)
        .select()
        .single();

    // 3. Créer une conversation (optionnel)
    // Ou laisser ChatService gérer la création de conversation

    return Connection.fromJson(connectionResponse);
  }

  // Refuser une demande
  Future<void> rejectRequest(String requestId) async {
    await _supabase
        .from('connection_requests')
        .update({
          'status': 'rejected',
          'responded_at': DateTime.now().toIso8601String(),
        })
        .eq('id', requestId);
  }

  // Obtenir les demandes en attente (reçues)
  Future<List<ConnectionRequest>> getPendingRequests(String userId) async {
    final response = await _supabase
        .from('connection_requests')
        .select('*, sender:profiles!sender_id(id, display_name, username, avatar_url)')
        .eq('receiver_id', userId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return response.map((json) => ConnectionRequest.fromJson(json)).toList();
  }

  // Obtenir les demandes envoyées
  Future<List<ConnectionRequest>> getSentRequests(String userId) async {
    final response = await _supabase
        .from('connection_requests')
        .select('*, receiver:profiles!receiver_id(id, display_name, username, avatar_url)')
        .eq('sender_id', userId)
        .order('created_at', ascending: false);
    return response.map((json) => ConnectionRequest.fromJson(json)).toList();
  }

  // Vérifier si une connexion existe entre deux utilisateurs
  Future<bool> checkConnection(String userId1, String userId2) async {
    final response = await _supabase
        .from('connections')
        .select('id')
        .or('user1_id.eq.$userId1,user2_id.eq.$userId2')
        .or('user1_id.eq.$userId2,user2_id.eq.$userId1')
        .maybeSingle();
    return response != null;
  }

  // Vérifier si une demande est en attente
  Future<String?> checkPendingRequest(String senderId, String receiverId) async {
    final response = await _supabase
        .from('connection_requests')
        .select('status')
        .eq('sender_id', senderId)
        .eq('receiver_id', receiverId)
        .maybeSingle();
    return response?['status'] as String?;
  }

  // Bloquer un utilisateur
  Future<void> blockUser(String userId, String blockedId) async {
    // Créer ou mettre à jour une entrée de blocage
    // (à implémenter selon votre modèle)
  }
}
