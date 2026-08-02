import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Fournit un Set<String> contenant les IDs (UUIDs) de tous les utilisateurs actuellement en ligne
final presenceProvider = StateNotifierProvider<PresenceNotifier, Set<String>>((ref) {
  return PresenceNotifier();
});

class PresenceNotifier extends StateNotifier<Set<String>> {
  late final RealtimeChannel _channel;
  final _supabase = Supabase.instance.client;

  PresenceNotifier() : super({}) {
    _initPresence();
  }

  void _initPresence() {
    final myUserId = _supabase.auth.currentUser?.id;
    if (myUserId == null) return;

    // 1. On rejoint un salon virtuel (canal) global pour le chat
    _channel = _supabase.channel('thix-global-presence');

    // 2. On écoute les entrées/sorties en temps réel
    _channel.onPresenceSync((payload) {
      final newState = <String>{};
      final presences = _channel.presenceState();
      
      for (final key in presences.keys) {
        for (final presence in presences[key]!) {
          if (presence['user_id'] != null) {
            newState.add(presence['user_id'] as String);
          }
        }
      }
      // Met à jour l'interface Flutter automatiquement
      state = newState;
    }).subscribe((status, [error]) async {
      // 3. Dès qu'on est connecté au websocket, on s'annonce aux autres
      if (status == RealtimeSubscribeStatus.subscribed) {
        await _channel.track({'user_id': myUserId});
      }
    });
  }

  @override
  void dispose() {
    // On se déconnecte proprement quand l'utilisateur quitte l'app
    _channel.unsubscribe();
    super.dispose();
  }
}
