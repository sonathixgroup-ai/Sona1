import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../models/chat/user_status.dart';
import '../../models/chat/chat_participant.dart';

class PresenceService {
  final SupabaseClient _supabase;
  final Map<String, String> _userStatus = {}; // userId -> status
  final Map<String, String> _userCustomStatus = {};
  final Map<String, DateTime> _userLastSeen = {};
  bool _isSubscribed = false;
  RealtimeChannel? _presenceChannel;

  PresenceService(this._supabase);

  String get currentUserId => _supabase.auth.currentUser?.id ?? '';

  // ─── GESTION DU STATUT PERSONNEL ──────────────────────────────

  /// Met à jour le statut de l'utilisateur courant
  Future<void> updateStatus(String status, {String? customStatus}) async {
    final uid = currentUserId;
    if (uid.isEmpty) return;

    try {
      await _supabase.from('user_presence').upsert({
        'user_id': uid,
        'status': status,
        'custom_status': customStatus,
        'last_seen_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      _userStatus[uid] = status;
      _userCustomStatus[uid] = customStatus;

      // Diffuser le changement via Realtime
      if (_presenceChannel != null) {
        await _presenceChannel!.send({
          'type': 'status_update',
          'user_id': uid,
          'status': status,
          'custom_status': customStatus,
        });
      }
    } catch (e) {
      debugPrint('❌ updateStatus: $e');
    }
  }

  /// Récupère le statut d'un utilisateur
  Future<ChatParticipant?> getUserStatus(String userId) async {
    try {
      final response = await _supabase
          .from('user_presence')
          .select('''
            status,
            custom_status,
            last_seen_at,
            profiles!user_id (
              display_name,
              avatar_url
            )
          ''')
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        return ChatParticipant(
          userId: userId,
          displayName: 'Utilisateur',
          status: UserStatus.offline,
        );
      }

      final profile = response['profiles'] as Map<String, dynamic>?;

      return ChatParticipant(
        userId: userId,
        displayName: profile?['display_name'] ?? 'Utilisateur',
        avatarUrl: profile?['avatar_url'],
        status: response['status'] ?? UserStatus.offline,
        customStatus: response['custom_status'],
        lastSeen: response['last_seen_at'] != null
            ? DateTime.parse(response['last_seen_at'])
            : null,
      );
    } catch (e) {
      debugPrint('❌ getUserStatus: $e');
      return ChatParticipant(
        userId: userId,
        displayName: 'Utilisateur',
        status: UserStatus.offline,
      );
    }
  }

  /// Récupère les statuts de plusieurs utilisateurs
  Future<List<ChatParticipant>> getUsersStatus(List<String> userIds) async {
    if (userIds.isEmpty) return [];

    try {
      final response = await _supabase
          .from('user_presence')
          .select('''
            user_id,
            status,
            custom_status,
            last_seen_at,
            profiles!user_id (
              display_name,
              avatar_url
            )
          ''')
          .inFilter('user_id', userIds);

      final participants = <ChatParticipant>[];

      for (var row in response as List) {
        final profile = row['profiles'] as Map<String, dynamic>?;
        participants.add(ChatParticipant(
          userId: row['user_id'],
          displayName: profile?['display_name'] ?? 'Utilisateur',
          avatarUrl: profile?['avatar_url'],
          status: row['status'] ?? UserStatus.offline,
          customStatus: row['custom_status'],
          lastSeen: row['last_seen_at'] != null
              ? DateTime.parse(row['last_seen_at'])
              : null,
        ));
      }

      return participants;
    } catch (e) {
      debugPrint('❌ getUsersStatus: $e');
      return [];
    }
  }

  // ─── REALTIME : ÉCOUTE DES CHANGEMENTS ────────────────────────

  /// S'abonne aux mises à jour de présence pour les utilisateurs d'une conversation
  Stream<List<ChatParticipant>> subscribeToPresence(String conversationId) {
    return _supabase
        .channel('presence:$conversationId')
        .onPostgresChange(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'user_presence',
          callback: (payload) {
            // La mise à jour est reçue, on peut diffuser
          },
        )
        .subscribe()
        .onData((data) {
          // Convertir les données en liste de participants
          // (simplifié, à adapter)
        });
  }

  /// Initialise le canal de présence pour l'utilisateur courant
  Future<void> initPresence() async {
    if (_isSubscribed) return;
    final uid = currentUserId;
    if (uid.isEmpty) return;

    // Créer le canal principal de présence
    _presenceChannel = _supabase.channel('presence:all');

    // S'abonner aux événements de présence
    await _presenceChannel!
        .on('presence', (event, payload) {
          // Gérer les événements de présence (join, leave, update)
          if (payload['type'] == 'join') {
            _userStatus[payload['user_id']] = payload['status'];
          } else if (payload['type'] == 'leave') {
            _userStatus[payload['user_id']] = UserStatus.offline;
          } else if (payload['type'] == 'status_update') {
            _userStatus[payload['user_id']] = payload['status'];
          }
        })
        .subscribe();

    // Envoyer l'état initial
    await _presenceChannel!.send({
      'type': 'join',
      'user_id': uid,
      'status': UserStatus.online,
    });

    // Marquer l'utilisateur comme en ligne dans la base
    await updateStatus(UserStatus.online);

    _isSubscribed = true;
  }

  /// Marquer l'utilisateur comme hors ligne
  Future<void> setOffline() async {
    final uid = currentUserId;
    if (uid.isEmpty) return;

    await updateStatus(UserStatus.offline);

    if (_presenceChannel != null) {
      await _presenceChannel!.send({
        'type': 'leave',
        'user_id': uid,
      });
      await _presenceChannel!.unsubscribe();
      _isSubscribed = false;
    }
  }

  // ─── MÉTHODES D'ACCÈS AUX STATUTS EN MÉMOIRE ──────────────────

  /// Récupère le statut d'un utilisateur depuis la mémoire
  String? getStatus(String userId) => _userStatus[userId];

  /// Récupère le statut personnalisé d'un utilisateur
  String? getCustomStatus(String userId) => _userCustomStatus[userId];

  /// Vérifie si un utilisateur est en ligne
  bool isOnline(String userId) => _userStatus[userId] == UserStatus.online;

  /// Nettoie la connexion
  void dispose() {
    setOffline();
    _presenceChannel = null;
    _isSubscribed = false;
    _userStatus.clear();
    _userCustomStatus.clear();
    _userLastSeen.clear();
  }
}
