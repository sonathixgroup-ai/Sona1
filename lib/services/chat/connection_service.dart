import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================
// MODÈLES
// ============================================================

class ConnectionRequest {
  final String id;
  final String senderId;
  final String receiverId;
  final String status; // pending, accepted, rejected, blocked
  final String? message;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final Map<String, dynamic>? sender;
  final Map<String, dynamic>? receiver;

  ConnectionRequest({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.status,
    this.message,
    required this.createdAt,
    this.respondedAt,
    this.sender,
    this.receiver,
  });

  factory ConnectionRequest.fromJson(Map<String, dynamic> json) {
    return ConnectionRequest(
      id: json['id'] ?? '',
      senderId: json['sender_id'] ?? '',
      receiverId: json['receiver_id'] ?? '',
      status: json['status'] ?? 'pending',
      message: json['message'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      respondedAt: json['responded_at'] != null
          ? DateTime.parse(json['responded_at'])
          : null,
      sender: json['sender'],
      receiver: json['receiver'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'status': status,
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'responded_at': respondedAt?.toIso8601String(),
    };
  }
}

class Connection {
  final String id;
  final String user1Id;
  final String user2Id;
  final DateTime createdAt;

  Connection({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.createdAt,
  });

  factory Connection.fromJson(Map<String, dynamic> json) {
    return Connection(
      id: json['id'] ?? '',
      user1Id: json['user1_id'] ?? '',
      user2Id: json['user2_id'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

// ============================================================
// SERVICE
// ============================================================

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
        .or('user1_id.eq.$userId1,user2_id.eq.$userId1')
        .or('user1_id.eq.$userId2,user2_id.eq.$userId2')
        .maybeSingle();
    return response != null;
  }

  // ✅ Obtenir le statut de connexion entre deux utilisateurs
  // Retourne : 'connected', 'pending', 'rejected', 'none'
  Future<String> getStatusBetween(String userId1, String userId2) async {
    // Vérifier si une connexion existe
    final isConnected = await checkConnection(userId1, userId2);
    if (isConnected) return 'connected';

    // Vérifier s'il y a une demande en attente
    final pending = await _supabase
        .from('connection_requests')
        .select('status')
        .or('sender_id.eq.$userId1,receiver_id.eq.$userId1')
        .or('sender_id.eq.$userId2,receiver_id.eq.$userId2')
        .eq('status', 'pending')
        .maybeSingle();
    if (pending != null) return 'pending';

    // Vérifier s'il y a une demande rejetée
    final rejected = await _supabase
        .from('connection_requests')
        .select('status')
        .or('sender_id.eq.$userId1,receiver_id.eq.$userId1')
        .or('sender_id.eq.$userId2,receiver_id.eq.$userId2')
        .eq('status', 'rejected')
        .maybeSingle();
    if (rejected != null) return 'rejected';

    return 'none';
  }

  // Bloquer un utilisateur
  Future<void> blockUser(String userId, String blockedId) async {
    // À implémenter selon votre modèle
  }
}
