import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class NotificationService {
  final SupabaseClient _client;
  static const String _table = 'notifications';

  NotificationService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Map<String, dynamic> _normalizeRow(Map<String, dynamic> r) {
    final data = (r['data'] is Map)
        ? (r['data'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};

    return {
      'id': r['id'],
      'user_id': r['user_id'],
      'type': (r['type'] ?? 'generic').toString(),
      'title': (r['title'] ?? 'Notification').toString(),
      'body': (r['body'] ?? r['message'] ?? '').toString(),
      'read': r['read'] ?? r['seen'] ?? false,
      'data': data,
      'created_at': r['created_at'],
    };
  }

  /// Real-time notifications stream with polling fallback
  Stream<List<Map<String, dynamic>>> streamForUser(String uid) {
    late final StreamController<List<Map<String, dynamic>>> controller;
    Timer? pollTimer;
    RealtimeChannel? channel;
    bool isCancelled = false;

    Future<void> emitLatest() async {
      try {
        final response = await _client
            .from(_table)
            .select()
            .eq('user_id', uid)
            .order('created_at', ascending: false)
            .limit(50);

        final list = (response as List)
            .map((e) => _normalizeRow(e as Map<String, dynamic>))
            .toList();

        controller.add(list);
      } catch (e) {
        debugPrint('NotificationService: emitLatest error: $e');
        controller.add(const []);
      }
    }

    void startPolling() {
      pollTimer?.cancel();
      pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => emitLatest());
    }

    controller = StreamController.broadcast(
      onListen: () => emitLatest(),
      onCancel: () {
        isCancelled = true;
        pollTimer?.cancel();
        if (channel != null) _client.removeChannel(channel!);
      },
    );

    // Setup realtime
    try {
      channel = _client.channel('notifications:$uid');

      channel
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: _table,
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: uid,
            ),
            callback: (payload) => emitLatest(),
          )
          .subscribe(
            (status, error) {
              debugPrint('NotificationService subscribe: $status, error: $error');
              if (status == RealtimeSubscribeStatus.channelError ||
                  (error?.toString().toLowerCase().contains('permission') ?? false)) {
                startPolling();
              }
            },
          );
    } catch (e) {
      debugPrint('Realtime setup failed, using polling: $e');
      startPolling();
    }

    return controller.stream;
  }

  // Unread count
  Stream<int> streamUnreadCount(String uid) {
    return streamForUser(uid)
        .map((rows) => rows.where((r) => !(r['read'] as bool? ?? false)).length)
        .distinct();
  }

  // Create notification
  Future<void> add({
    required String toUid,
    required String type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _client.from(_table).insert({
        'user_id': toUid,
        'type': type,
        'title': title,
        'body': body,
        'read': false,
        'data': data ?? {},
      });
    } catch (e) {
      debugPrint('NotificationService.add error: $e');
    }
  }

  // Mark as read
  Future<void> markRead({
    required String uid,
    required String notificationId,
  }) async {
    try {
      await _client
          .from(_table)
          .update({'read': true})
          .eq('id', notificationId)
          .eq('user_id', uid);
    } catch (e) {
      debugPrint('NotificationService.markRead error: $e');
    }
  }

  // Mark all read
  Future<void> markAllRead(String uid) async {
    try {
      await _client
          .from(_table)
          .update({'read': true})
          .eq('user_id', uid)
          .eq('read', false);
    } catch (e) {
      debugPrint('NotificationService.markAllRead error: $e');
    }
  }
}
