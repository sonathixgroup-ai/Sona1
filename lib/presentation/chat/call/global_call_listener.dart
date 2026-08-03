// Route: lib/presentation/chat/call/global_call_listener.dart
// PRODUCTION - GlobalCallListener avec Riverpod (ConsumerStatefulWidget)
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/nav.dart';
import 'package:thix_id/models/chat/call_invite.dart';

class GlobalCallListener extends ConsumerStatefulWidget {
  final Widget child;
  const GlobalCallListener({super.key, required this.child});

  @override
  ConsumerState<GlobalCallListener> createState() => _GlobalCallListenerState();
}

class _GlobalCallListenerState extends ConsumerState<GlobalCallListener> {
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
          // Correction syntaxe Supabase Realtime
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'callee_id',
            value: myId,
          ),
          callback: _onIncoming,
        )
        .subscribe();
  }

  void _onIncoming(PostgresChangePayload payload) {
    try {
      // Utilisation correcte de fromJson
      final invite = CallInvite.fromJson(payload.newRecord);
      
      if (invite.status != 'ringing') return;
      if (!mounted) return;
      
      // Évite le double push si l'utilisateur est déjà sur l'écran d'appel
      final loc = GoRouterState.of(context).uri.toString();
      if (loc.contains(AppRoutes.callIncoming) || loc.contains(AppRoutes.callOngoing)) return;

      context.pushNamed(AppRoutes.callIncomingName, extra: invite);
    } catch (e) {
      debugPrint('❌ Erreur réception appel global: $e');
    }
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
