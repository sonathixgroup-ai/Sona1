import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class MediaService {
  // Singleton Pattern pour une instance unique
  static final MediaService _instance = MediaService._internal();
  factory MediaService() => _instance;
  MediaService._internal();

  // --- BATCHING DES VUES ---
  static final Set<String> _pendingViews = {};
  static Timer? _timer;

  /// Enregistre une vue localement. L'envoi au serveur est différé pour
  /// éviter de saturer la base de données (Write Amplification).
  Future<void> registerView(String mediaId) async {
    _pendingViews.add(mediaId);
    _timer ??= Timer(const Duration(seconds: 10), _flushViews);
  }

  static Future<void> _flushViews() async {
    if (_pendingViews.isEmpty) {
      _timer = null;
      return;
    }
    final batch = _pendingViews.toList();
    _pendingViews.clear();
    _timer = null;

    try {
      await Supabase.instance.client.rpc('batch_register_views', params: {'p_media_ids': batch});
    } catch (_) {
      // En cas d'échec réseau, on remet les IDs dans la file d'attente
      _pendingViews.addAll(batch);
    }
  }

  // --- ACTIONS UTILISATEUR ---

  /// Bascule l'état "J'aime" via une fonction RPC pour éviter les conflits
  Future<void> toggleLike(String mediaId) async {
    await Supabase.instance.client.rpc('toggle_like', params: {'p_media_id': mediaId});
  }

  /// Récupère en une seule requête les IDs likés par l'utilisateur parmi une liste donnée
  Future<Set<String>> getLikedMediaIds(List<String> mediaIds) async {
    if (mediaIds.isEmpty) return {};
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return {};

    try {
      final res = await Supabase.instance.client
          .from('media_likes')
          .select('media_id')
          .eq('user_id', uid)
          .inFilter('media_id', mediaIds);
      
      return (res as List).map((e) => e['media_id'] as String).toSet();
    } catch (_) {
      return {};
    }
  }
}
