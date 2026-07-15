// Route: lib/services/chat/call_signaling_service.dart
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/chat/call_invite.dart';

class CallSignalingService {
  final _db = Supabase.instance.client;
  RealtimeChannel? _ch;
  StreamSubscription? _sub;

  void listenMyInvites(
    String myId,
    Function(CallInvite invite) onRinging,
  ) {
    _ch = _db.channel('calls:$myId');

    _ch!.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'call_invites',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'callee_id',
        value: myId,
      ),
      callback: (payload) {
        final row = payload.newRecord;
        final invite = CallInvite.fromJson(row);
        if (invite.status.name == 'ringing') {
          onRinging(invite);
        }
      },
    ).subscribe();
  }

  Future<String> create({
    required String channel,
    required String calleeId,
    required String type,
  }) async {
    final uid = _db.auth.currentUser!.id;
    final res = await _db.from('call_invites').insert({
      'channel_name': channel,
      'caller_id': uid,
      'callee_id': calleeId,
      'call_type': type,
      'status': 'ringing',
    }).select().single();
    return res['id'] as String;
  }

  Future<void> update(
    String id,
    String status,
  ) async {
    await _db.from('call_invites')
        .update({'status': status})
        .eq('id', id);
  }

  void dispose() {
    if (_ch != null) _db.removeChannel(_ch!);
    _sub?.cancel();
  }
}
