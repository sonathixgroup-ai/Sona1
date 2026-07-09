import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../models/chat/user_status.dart';
import '../../models/chat/chat_participant.dart';

class PresenceService {
  final SupabaseClient _supabase;
  final Map<String, String> _userStatus = {};
  final Map<String, String> _userCustomStatus = {};
  bool _isSubscribed = false;
  RealtimeChannel? _presenceChannel;

  PresenceService(this._supabase);

  String get currentUserId => _supabase.auth.currentUser?.id ?? '';

  // ─── GESTION DU STATUT PERSONNEL ──────────────────────────────

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

  // ─── REALTIME ──────────────────────────────────────────────────

  Stream<List<ChatParticipant>> subscribeToPresence(String conversationId) {
    return _supabase
        .channel('presence:$conversationId')
        .onPostgresChange(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'user_presence',
          callback: (payload) {},
        )
        .subscribe()
        .map((data) => <ChatParticipant>[]); // À adapter selon votre logique
  }

  Future<void> initPresence() async {
    if (_isSubscribed) return;
    final uid = currentUserId;
    if (uid.isEmpty) return;

    _presenceChannel = _supabase.channel('presence:all');

    await _presenceChannel!
        .on('presence', (event, payload) {
          if (payload['type'] == 'join') {
            _userStatus[payload['user_id']] = payload['status'];
          } else if (payload['type'] == 'leave') {
            _userStatus[payload['user_id']] = UserStatus.offline;
          } else if (payload['type'] == 'status_update') {
            _userStatus[payload['user_id']] = payload['status'];
          }
        })
        .subscribe();

    await _presenceChannel!.send({
      'type': 'join',
      'user_id': uid,
      'status': UserStatus.online,
    });

    await updateStatus(UserStatus.online);
    _isSubscribed = true;
  }

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

  String? getStatus(String userId) => _userStatus[userId];
  String? getCustomStatus(String userId) => _userCustomStatus[userId];
  bool isOnline(String userId) => _userStatus[userId] == UserStatus.online;

  void dispose() {
    setOffline();
    _presenceChannel = null;
    _isSubscribed = false;
    _userStatus.clear();
    _userCustomStatus.clear();
  }
}
