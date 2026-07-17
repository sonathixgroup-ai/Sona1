import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================
// MODÈLES
// ============================================================

class ConnectionRequest {
  final String id;
  final String senderId;
  final String receiverId;
  final String status;
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
// SERVICE (ChangeNotifier)
// ============================================================

class ConnectionService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  // État
  List<ConnectionRequest> _sentRequests = [];
  List<ConnectionRequest> _receivedRequests = [];
  List<Map<String, dynamic>> _connections = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<ConnectionRequest> get sentRequests => _sentRequests;
  List<ConnectionRequest> get receivedRequests => _receivedRequests;
  List<Map<String, dynamic>> get connections => _connections;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Charger toutes les données
  Future<void> loadData(String userId) async {
    _setLoading(true);
    _error = null;

    try {
      final sent = await _getSentRequests(userId);
      final received = await _getPendingRequests(userId);
      final active = await _getActiveConnections(userId);

      _sentRequests = sent;
      _receivedRequests = received;
      _connections = active;
      _setLoading(false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
    }
  }

  Future<List<ConnectionRequest>> _getPendingRequests(String userId) async {
    final response = await _supabase
        .from('connection_requests')
        .select('*, sender:profiles!sender_id(id, display_name, username, avatar_url)')
        .eq('receiver_id', userId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return response.map((json) => ConnectionRequest.fromJson(json)).toList();
  }

  Future<List<ConnectionRequest>> _getSentRequests(String userId) async {
    final response = await _supabase
        .from('connection_requests')
        .select('*, receiver:profiles!receiver_id(id, display_name, username, avatar_url)')
        .eq('sender_id', userId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return response.map((json) => ConnectionRequest.fromJson(json)).toList();
  }

  Future<List<Map<String, dynamic>>> _getActiveConnections(String userId) async {
    final response = await _supabase
        .from('connections')
        .select('''
          id,
          user1_id,
          user2_id,
          user1:profiles!connections_user1_id_fkey(id, display_name, username, avatar_url),
          user2:profiles!connections_user2_id_fkey(id, display_name, username, avatar_url)
        ''')
        .or('user1_id.eq.$userId,user2_id.eq.$userId');

    final List<Map<String, dynamic>> connections = [];
    for (var row in response) {
      final isUser1 = row['user1_id'] == userId;
      final other = isUser1 ? row['user2'] : row['user1'];
      if (other != null) {
        connections.add({
          'id': row['id'],
          'user_id': other['id'],
          'display_name': other['display_name'] ?? 'Inconnu',
          'username': other['username'],
          'avatar_url': other['avatar_url'],
        });
      }
    }
    return connections;
  }

  // Envoyer une demande
  Future<bool> sendRequest({
    required String senderId,
    required String receiverId,
    String? message,
  }) async {
    try {
      final data = {
        'sender_id': senderId,
        'receiver_id': receiverId,
        'message': message,
        'status': 'pending',
      };
      await _supabase
          .from('connection_requests')
          .insert(data)
          .select()
          .single();
      await loadData(senderId); // Recharger
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Accepter une demande
  Future<bool> acceptRequest(String requestId, String userId) async {
    try {
      await _supabase
          .from('connection_requests')
          .update({
            'status': 'accepted',
            'responded_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId);
      await loadData(userId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Refuser une demande
  Future<bool> rejectRequest(String requestId, String userId) async {
    try {
      await _supabase
          .from('connection_requests')
          .update({
            'status': 'rejected',
            'responded_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId);
      await loadData(userId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Annuler une demande envoyée
  Future<bool> cancelRequest(String requestId, String userId) async {
    try {
      await _supabase
          .from('connection_requests')
          .delete()
          .eq('id', requestId);
      await loadData(userId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Vérifier le statut entre deux utilisateurs
  Future<String> getStatusBetween(String userId1, String userId2) async {
    // Vérifier si une connexion existe
    final connected = await _supabase
        .from('connections')
        .select('id')
        .or('user1_id.eq.$userId1,user2_id.eq.$userId1')
        .or('user1_id.eq.$userId2,user2_id.eq.$userId2')
        .maybeSingle();
    if (connected != null) return 'connected';

    final pending = await _supabase
        .from('connection_requests')
        .select('status')
        .or('sender_id.eq.$userId1,receiver_id.eq.$userId1')
        .or('sender_id.eq.$userId2,receiver_id.eq.$userId2')
        .eq('status', 'pending')
        .maybeSingle();
    if (pending != null) return 'pending';

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

  // Vérifier si une connexion existe
  Future<bool> checkConnection(String userId1, String userId2) async {
    final response = await _supabase
        .from('connections')
        .select('id')
        .or('user1_id.eq.$userId1,user2_id.eq.$userId1')
        .or('user1_id.eq.$userId2,user2_id.eq.$userId2')
        .maybeSingle();
    return response != null;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
