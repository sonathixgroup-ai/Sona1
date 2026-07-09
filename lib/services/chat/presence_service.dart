import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:thix_id/models/chat/user_status.dart';
import 'package:thix_id/models/chat/chat_participant.dart';

class PresenceService {
  final SupabaseClient _supabase;
  final Map<String, String> _userStatus = {};
  final Map<String, String?> _userCustomStatus = {}; // ✅ autorise null
  bool _isSubscribed = false;
  RealtimeChannel? _presenceChannel;

  PresenceService(this._supabase);

  String get currentUserId => _supabase.auth.currentUser?.id ?? '';

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
      _userCustomStatus[uid] = customStatus; // ✅ assignation compatible
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

  // ─── REALTIME ────────────────────────────────────────────────

  Future<void> initPresence() async {
    if (_isSubscribed) return;
    final uid = currentUserId;
    if (uid.isEmpty) return;

    _presenceChannel = _supabase.channel('presence:all');

    // Écouter les mises à jour de la table user_presence
    _presenceChannel!
        .on('postgres_changes', (payload) {
          if (payload != null && payload['type'] == 'UPDATE') {
            final record = payload['new'];
            final userId = record?['user_id'];
            final status = record?['status'];
            if (userId != null) {
              _userStatus[userId] = status ?? UserStatus.offline;
            }
          }
        })
        .subscribe((status, error) async {
          if (status == RealtimeSubscribeStatus.subscribed) {
            await updateStatus(UserStatus.online);
            _isSubscribed = true;
          }
        });
  }

  Future<void> setOffline() async {
    final uid = currentUserId;
    if (uid.isEmpty) return;

    await updateStatus(UserStatus.offline);

    if (_presenceChannel != null) {
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
