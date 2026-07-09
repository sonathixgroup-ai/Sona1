import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:thix_id/models/chat/user_status.dart';
import 'package:thix_id/models/chat/chat_participant.dart';

class PresenceService {
  final SupabaseClient _supabase;
  final Map<String, String> _userStatus = {};
  final Map<String, String?> _userCustomStatus = {};

  PresenceService(this._supabase);

  String get currentUserId => _supabase.auth.currentUser?.id ?? '';

  /// Met à jour le statut dans la base et en mémoire
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
            profiles!user_id (display_name, avatar_url)
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
            profiles!user_id (display_name, avatar_url)
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

  /// Initialisation (pas de Realtime pour l'instant)
  Future<void> initPresence() async {
    // On marque l'utilisateur comme en ligne au démarrage
    await updateStatus(UserStatus.online);
  }

  /// Passe le statut à "hors ligne"
  Future<void> setOffline() async {
    await updateStatus(UserStatus.offline);
  }

  // Récupération mémoire
  String? getStatus(String userId) => _userStatus[userId];
  String? getCustomStatus(String userId) => _userCustomStatus[userId];
  bool isOnline(String userId) => _userStatus[userId] == UserStatus.online;

  /// Nettoyage
  void dispose() {
    setOffline();
    _userStatus.clear();
    _userCustomStatus.clear();
  }
}
