// lib/services/notification_service.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

// Utilisation d'un préfixe pour accéder aux énumérations realtime si nécessaire
// (facultatif, on peut aussi utiliser des strings)
import 'package:realtime_client/realtime_client.dart' as realtime;

class NotificationService {
  final SupabaseClient _client;
  static const String _table = 'notifications';

  NotificationService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Map<String, dynamic> _normalizeRow(Map<String, dynamic> row) {
    return {
      'id': row['id'],
      'user_id': row['user_id'],
      'type': (row['type'] ?? 'generic').toString(),
      'title': (row['title'] ?? 'Notification').toString(),
      'body': (row['body'] ?? row['message'] ?? '').toString(),
      'read': row['read'] ?? row['seen'] ?? false,
      'data': row['data'] ?? {},
      'created_at': row['created_at'],
    };
  }

  Stream<List<Map<String, dynamic>>> streamForUser(String uid) {
    final controller = StreamController<List<Map<String, dynamic>>>.broadcast();
    RealtimeChannel? channel;
    Timer? pollTimer;
    bool cancelled = false;

    Future<void> fetchAndEmit() async {
      if (cancelled) return;
      try {
        final data = await _client
            .from(_table)
            .select()
            .eq('user_id', uid)
            .order('created_at', ascending: false)
            .limit(50);

        final list = (data as List)
            .map((e) => _normalizeRow(e as Map<String, dynamic>))
            .toList();
        controller.add(list);
      } catch (e) {
        debugPrint('NotificationService fetch error: $e');
        controller.add([]);
      }
    }

    void startPolling() {
      pollTimer?.cancel();
      pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => fetchAndEmit());
    }

    // Tentative de mise en place du Realtime
    try {
      channel = _client.channel('notifications:$uid');

      // Nouvelle API : on('postgres_changes', filter, callback)
      // On utilise des strings pour éviter les dépendances d'import,
      // mais on peut aussi utiliser realtime.RealtimeEvent.postgresChanges
      channel!.on(
        'postgres_changes',
        {
          'event': '*', // '*' pour tous les événements (INSERT, UPDATE, DELETE)
          'schema': 'public',
          'table': _table,
          'filter': 'user_id=eq.$uid', // format Supabase: colonne=op.valeur
        },
        (_) => fetchAndEmit(),
      );

      // Souscription avec gestion du statut
      channel.subscribe((status, [error]) {
        debugPrint('Notification subscribe: $status, error=$error');
        // Le statut est une chaîne, par exemple 'SUBSCRIBED', 'CHANNEL_ERROR'
        if (status == 'CHANNEL_ERROR' || error != null) {
          startPolling();
        }
      });
    } catch (e) {
      debugPrint('Realtime failed → polling: $e');
      startPolling();
    }

    // Chargement initial
    fetchAndEmit();

    // Nettoyage
    controller.onCancel = () {
      cancelled = true;
      pollTimer?.cancel();
      if (channel != null) _client.removeChannel(channel!);
    };

    return controller.stream;
  }

  Stream<int> streamUnreadCount(String uid) {
    return streamForUser(uid)
        .map((list) => list.where((n) => n['read'] != true).length)
        .distinct();
  }

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
      debugPrint('Notification add error: $e');
    }
  }

  Future<void> markRead({required String uid, required String notificationId}) async {
    await _client
        .from(_table)
        .update({'read': true})
        .eq('id', notificationId)
        .eq('user_id', uid);
  }

  Future<void> markAllRead(String uid) async {
    await _client
        .from(_table)
        .update({'read': true})
        .eq('user_id', uid)
        .eq('read', false);
  }
}
