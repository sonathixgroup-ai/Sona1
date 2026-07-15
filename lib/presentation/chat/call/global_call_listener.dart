import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/nav.dart';
import 'package:thix_id/models/chat/call_invite.dart';

class GlobalCallListener extends StatefulWidget {
  final Widget child;
  const GlobalCallListener({super.key, required this.child});

  @override
  State<GlobalCallListener> createState() => _GlobalCallListenerState();
}

class _GlobalCallListenerState extends State<GlobalCallListener> {
  RealtimeChannel? _channel;
  StreamSubscription? _authSub;

  @override
  void initState() {
    super.initState();
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((e) {
      if (e.event == AuthChangeEvent.signedIn) _start();
      if (e.event == AuthChangeEvent.signedOut) _stop();
    });
    if (Supabase.instance.client.auth.currentUser != null) _start();
  }

  void _start() {
    final myId = Supabase.instance.client.auth.currentUser?.id;
    if (myId == null) return;
    _stop();
    _channel = Supabase.instance.client
        .channel('calls:$myId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: AppRoutes.tableCallInvites,
          filter: PostgresFilter(
            filter: 'callee_id',
            value: myId,
          ),
          callback: _onIncoming,
        )
        .subscribe();
  }

  void _onIncoming(PostgresChangePayload payload) {
    try {
      final invite = CallInvite.fromMap(payload.newRecord);
      if (invite.status != 'ringing') return;
      if (!mounted) return;
      // évite double push si déjà sur incoming/ongoing
      final loc = GoRouterState.of(context).uri.toString();
      if (loc.contains(AppRoutes.callIncoming) || loc.contains(AppRoutes.callOngoing)) return;

      context.pushNamed(AppRoutes.callIncomingName, extra: invite);
    } catch (_) {}
  }

  void _stop() {
    if (_channel != null) {
      Supabase.instance.client.removeChannel(_channel!);
      _channel = null;
    }
  }

  @override
  void dispose() {
    _stop();
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
