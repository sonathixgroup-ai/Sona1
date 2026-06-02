import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/supabase/supabase_config.dart';

class NotificationService {
  NotificationService({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  final SupabaseClient _client;
<<<<<<< Updated upstream

  NotificationService({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;
=======
>>>>>>> Stashed changes

  static const String _table = 'thix_notifications';
  static const Duration _pollInterval = Duration(seconds: 5);
  static const int _maxNotifications = 50;

<<<<<<< Updated upstream
  /// Normalise les données quel que soit le nom des colonnes (flexible)
  Map<String, dynamic> _normalizeRow(Map<String, dynamic> row) {
    final data = (row['data'] is Map)
        ? (row['data'] as Map).cast<String, dynamic>()
        : (row['payload'] is Map)
            ? (row['payload'] as Map).cast<String, dynamic>()
            : <String, dynamic>{};

    final read = (row['read'] as bool?) ?? (row['seen'] as bool?) ?? false;

    return {
      'id': row['id'],
      'user_id': row['user_id'],
      'type': (row['type'] ?? row['kind'] ?? 'generic').toString(),
      'title': (row['title'] ?? 'Notification').toString(),
      'body': (row['body'] ?? row['message'] ?? row['content'] ?? '').toString(),
      'read': read,
      'data': data,
      'created_at': row['created_at'],
    };
  }

  /// Stream de notifications avec polling (stable et simple)
=======
  // ==========================================================================
  // STREAMS SIMPLES (polling uniquement, pas de Realtime)
  // ==========================================================================

  /// Stream des notifications personnelles (polling toutes les 5 secondes)
>>>>>>> Stashed changes
  Stream<List<Map<String, dynamic>>> streamForUser(String uid) {
    final controller = StreamController<List<Map<String, dynamic>>>.broadcast();
    Timer? pollTimer;
    bool isActive = true;

    Future<void> fetch() async {
      if (!isActive || controller.isClosed) return;

      try {
<<<<<<< Updated upstream
        final rows = await _client
=======
        final response = await _client
>>>>>>> Stashed changes
            .from(_table)
            .select('*')
            .eq('user_id', uid)
            .order('created_at', ascending: false)
<<<<<<< Updated upstream
            .limit(50);

        final list = (rows is List)
            ? rows
                .map((e) => _normalizeRow((e as Map).cast<String, dynamic>()))
                .toList()
            : <Map<String, dynamic>>[];

        if (!controller.isClosed) controller.add(list);
=======
            .limit(_maxNotifications);

        final notifications = response is List
            ? response
                .map((e) => _normalizeRow(e as Map<String, dynamic>))
                .toList(growable: false)
            : <Map<String, dynamic>>[];

        if (!controller.isClosed) controller.add(notifications);
>>>>>>> Stashed changes
      } catch (e) {
        debugPrint('NotificationService: fetch failed for uid=$uid | error=$e');
        if (!controller.isClosed) controller.add([]);
      }
    }

    controller.onListen = () {
      isActive = true;
      unawaited(fetch());
<<<<<<< Updated upstream
      pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => unawaited(fetch()));
=======
      pollTimer = Timer.periodic(_pollInterval, (_) => unawaited(fetch()));
>>>>>>> Stashed changes
    };

    controller.onCancel = () {
      isActive = false;
      pollTimer?.cancel();
      controller.close();
    };

    return controller.stream;
  }

<<<<<<< Updated upstream
  /// Nombre de notifications non lues
=======
  /// Stream des notifications broadcast (user_id = null)
  Stream<List<Map<String, dynamic>>> streamBroadcastOnly() {
    final controller = StreamController<List<Map<String, dynamic>>>.broadcast();
    Timer? pollTimer;
    bool isActive = true;

    Future<void> fetch() async {
      if (!isActive) return;
      try {
        final response = await _client
            .from(_table)
            .select('*')
            .is_('user_id', null)
            .order('created_at', ascending: false)
            .limit(_maxNotifications);

        final notifications = response is List
            ? response
                .map((e) => _normalizeRow(e as Map<String, dynamic>))
                .toList(growable: false)
            : <Map<String, dynamic>>[];

        if (!controller.isClosed) controller.add(notifications);
      } catch (e) {
        debugPrint('NotificationService: broadcast fetch failed err=$e');
        if (!controller.isClosed) controller.add([]);
      }
    }

    controller.onListen = () {
      isActive = true;
      unawaited(fetch());
      pollTimer = Timer.periodic(_pollInterval, (_) => unawaited(fetch()));
    };

    controller.onCancel = () {
      isActive = false;
      pollTimer?.cancel();
      controller.close();
    };

    return controller.stream;
  }

  /// Stream des notifications personnelles + broadcast (mélangées)
  Stream<List<Map<String, dynamic>>> streamForHome({String? uid}) {
    if (uid == null || uid.trim().isEmpty) {
      return streamBroadcastOnly();
    }

    final controller = StreamController<List<Map<String, dynamic>>>.broadcast();
    List<Map<String, dynamic>> personal = [];
    List<Map<String, dynamic>> broadcast = [];
    StreamSubscription? personalSub;
    StreamSubscription? broadcastSub;

    void emitMerged() {
      final merged = <Map<String, dynamic>>[...personal, ...broadcast];
      merged.sort((a, b) {
        final aDate = DateTime.tryParse(a['created_at']?.toString() ?? '');
        final bDate = DateTime.tryParse(b['created_at']?.toString() ?? '');
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });

      final seenIds = <String>{};
      final unique = <Map<String, dynamic>>[];
      for (final item in merged) {
        final id = item['id']?.toString() ?? '';
        if (id.isEmpty || seenIds.add(id)) {
          unique.add(item);
        }
      }

      if (!controller.isClosed) controller.add(unique);
    }

    controller
      ..onListen = () {
        personalSub = streamForUser(uid).listen((data) {
          personal = data;
          emitMerged();
        });
        broadcastSub = streamBroadcastOnly().listen((data) {
          broadcast = data;
          emitMerged();
        });
      }
      ..onCancel = () async {
        await personalSub?.cancel();
        await broadcastSub?.cancel();
      };

    return controller.stream;
  }

  /// Stream du nombre de notifications non lues
>>>>>>> Stashed changes
  Stream<int> streamUnreadCount(String uid) {
    return streamForUser(uid)
        .map((notifications) => notifications.where((n) => n['read'] != true).length)
        .distinct();
  }

<<<<<<< Updated upstream
  /// Ajouter une notification
=======
  // ==========================================================================
  // MÉTHODES D'ACTION
  // ==========================================================================

>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
        'data': data ?? <String, dynamic>{},
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      debugPrint('NotificationService: add failed to=$toUid type=$type | error=$e');
      // Tentative legacy (anciens noms de colonnes)
      try {
        await _client.from(_table).insert({
          'user_id': toUid,
          'title': title,
          'message': body,
          'seen': false,
          'created_at': DateTime.now().toUtc().toIso8601String(),
        });
      } catch (e2) {
        debugPrint('NotificationService: legacy insert also failed | error=$e2');
        rethrow;
      }
=======
        'data': data ?? {},
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      debugPrint('NotificationService: add failed err=$e');
    }
  }

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
      debugPrint('NotificationService: markRead failed err=$e');
>>>>>>> Stashed changes
    }
  }

  /// Marquer une notification comme lue
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
      debugPrint('NotificationService: markRead failed | error=$e');
      // Tentative legacy
      try {
        await _client
            .from(_table)
            .update({'seen': true})
            .eq('id', notificationId)
            .eq('user_id', uid);
      } catch (_) {}
    }
  }

  /// Marquer toutes les notifications comme lues
  Future<void> markAllRead(String uid) async {
    try {
      await _client
          .from(_table)
          .update({'read': true})
          .eq('user_id', uid)
          .eq('read', false);
    } catch (e) {
<<<<<<< Updated upstream
      debugPrint('NotificationService: markAllRead failed | error=$e');
      try {
        await _client
            .from(_table)
            .update({'seen': true})
            .eq('user_id', uid)
            .eq('seen', false);
      } catch (_) {}
    }
  }

  /// Supprimer une notification
  Future<void> delete(String notificationId, String uid) async {
    try {
      await _client
          .from(_table)
          .delete()
          .eq('id', notificationId)
          .eq('user_id', uid);
    } catch (e) {
      debugPrint('NotificationService: delete failed | error=$e');
=======
      debugPrint('NotificationService: markAllRead failed err=$e');
>>>>>>> Stashed changes
    }
  }

  // ==========================================================================
  // MÉTHODES PRIVÉES
  // ==========================================================================

  Map<String, dynamic> _normalizeRow(Map<String, dynamic> row) {
    final data = row['data'] is Map<String, dynamic>
        ? row['data'] as Map<String, dynamic>
        : row['payload'] is Map<String, dynamic>
            ? row['payload'] as Map<String, dynamic>
            : {};

    final read = (row['read'] as bool?) ?? (row['seen'] as bool?) ?? false;

    return {
      'id': row['id'],
      'user_id': row['user_id'],
      'type': (row['type'] ?? row['kind'] ?? 'generic').toString(),
      'title': (row['title'] ?? 'Notification').toString(),
      'body': (row['body'] ?? row['message'] ?? row['content'] ?? '').toString(),
      'read': read,
      'data': data,
      'created_at': row['created_at'],
    };
  }
}
