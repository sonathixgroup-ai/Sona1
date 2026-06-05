import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/supabase/supabase_config.dart';

class ThixPresence {
  final String userId;
  final bool isOnline;
  final DateTime lastSeenAt;

  const ThixPresence({
    required this.userId,
    required this.isOnline,
    required this.lastSeenAt,
  });

  static DateTime _dt(Object? v) {
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v) ?? DateTime.now().toUtc();
    return DateTime.now().toUtc();
  }

  static ThixPresence fromRow(Map<String, dynamic> row) {
    return ThixPresence(
      userId: (row['user_id'] as String?) ?? '',
      isOnline: (row['is_online'] as bool?) ?? false,
      lastSeenAt: _dt(row['last_seen_at'] ?? row['updated_at']),
    );
  }
}

class PresenceService {
  static const String table = 'thix_presence';
  final SupabaseClient _client;

  PresenceService({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  Timer? _heartbeat;

  bool _isTableMissing(Object e) {
    if (e is PostgrestException) {
      if (e.code == 'PGRST205') return true;
      final m = e.message.toLowerCase();
      if (m.contains('could not find the') && m.contains('in the schema cache')) return true;
      if (m.contains('relation') && m.contains('does not exist')) return true;
    }
    final m = e.toString().toLowerCase();
    return (m.contains('pgrst205') ||
        (m.contains('relation') && m.contains('does not exist')));
  }

  Future<void> _trySchemaReload() async {
    try {
      await _client.rpc('pgrst_schema_reload');
    } catch (e) {
      try {
        await _client.functions.invoke('pgrst_schema_reload', body: const {});
      } catch (_) {}
    }
  }

  Future<void> setOnline(bool online) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    final now = DateTime.now().toUtc().toIso8601String();
    try {
      await _client.from(table).upsert({
        'user_id': uid,
        'is_online': online,
        'last_seen_at': now,
        'updated_at': now,
      });
    } catch (e) {
      if (_isTableMissing(e)) {
        debugPrint('PresenceService: table missing/cache stale. Attempt schema reload. err=$e');
        await _trySchemaReload();
        return;
      }
      debugPrint('PresenceService: setOnline failed online=$online err=$e');
    }
  }

  void startHeartbeat({Duration interval = const Duration(seconds: 30)}) {
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(interval, (_) => unawaited(setOnline(true)));
  }

  void stopHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = null;
  }

  // ✅ Version corrigée : utilise un polling simple au lieu du Realtime problématique
  // Cela garantit l'absence d'erreurs de compilation et reste fonctionnel.
  Stream<ThixPresence?> streamPresence(String userId) {
    final controller = StreamController<ThixPresence?>.broadcast();
    Timer? pollingTimer;

    Future<void> emitLatest() async {
      try {
        final row = await _client
            .from(table)
            .select('*')
            .eq('user_id', userId)
            .maybeSingle();
        if (row == null) {
          controller.add(null);
          return;
        }
        controller.add(ThixPresence.fromRow((row as Map).cast<String, dynamic>()));
      } catch (e) {
        if (_isTableMissing(e)) {
          debugPrint('PresenceService: table missing/cache stale. Disabling presence stream until DB is ready. err=$e');
          controller.add(null);
          return;
        }
        debugPrint('PresenceService: emitLatest failed userId=$userId err=$e');
        controller.add(null);
      }
    }

    // Premier émission à l'écoute + polling toutes les 5 secondes
    controller.onListen = () {
      unawaited(emitLatest());
      pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) => emitLatest());
    };

    controller.onCancel = () {
      pollingTimer?.cancel();
    };

    return controller.stream;
  }
}
