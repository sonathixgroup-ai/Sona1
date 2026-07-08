import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../services/network_service.dart';
import '../models/network_post.dart';

class FeedProvider extends ChangeNotifier {
  final NetworkService _networkService;
  final SupabaseClient? _supabase;

  List<NetworkPost> _posts = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String _currentFeedType = 'smart';
  String? _error;
  bool _realtimeInitialized = false;

  // Real-time
  RealtimeChannel? _realtimeChannel;
  Timer? _autoRefreshTimer;
  DateTime? _lastRefresh;

  FeedProvider(this._networkService, {SupabaseClient? supabase})
      : _supabase = supabase;

  // Getters
  List<NetworkPost> get posts => _posts;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String get currentFeedType => _currentFeedType;
  String? get error => _error;

  // ============================================================
  // INITIALISATION REALTIME
  // ============================================================

  void initRealtime() {
    if (_realtimeInitialized) return;
    _realtimeInitialized = true;
    _setupRealtimeListener();
    _setupAutoRefresh();
  }

  void disposeRealtime() {
    _realtimeChannel?.unsubscribe();
    _autoRefreshTimer?.cancel();
  }

  void _setupRealtimeListener() {
    if (_supabase == null) return;

    _realtimeChannel = _supabase!
        .channel('public:posts_feed')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'posts',
          callback: (payload) => _onPostInserted(payload),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'posts',
          callback: (payload) => _onPostUpdated(payload),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'posts',
          callback: (payload) => _onPostDeleted(payload),
        );

    _realtimeChannel!.subscribe((status, err) {
      if (err != null) debugPrint('❌ Realtime error: $err');
    });
  }

  void _setupAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (!_isLoading) await _autoRefresh();
    });
  }

  // ============================================================
  // TRAITEMENT DES ÉVÉNEMENTS REALTIME (OPTIMISÉ)
  // ============================================================

  Future<void> _onPostInserted(PostgresChangePayload payload) async {
    try {
      final newPost = NetworkPost.fromJson(payload.newRecord);
      // On ne l'ajoute que s'il n'est pas archivé
      if (newPost.archivedAt == null) {
        _posts.insert(0, newPost);
        notifyListeners();
        debugPrint('📥 Post ajouté en temps réel : ${newPost.id}');
      }
    } catch (e) {
      debugPrint('❌ _onPostInserted error: $e');
    }
  }

  Future<void> _onPostUpdated(PostgresChangePayload payload) async {
    try {
      final updatedPost = NetworkPost.fromJson(payload.newRecord);
      final index = _posts.indexWhere((p) => p.id == updatedPost.id);

      if (updatedPost.archivedAt != null) {
        // Le post a été archivé → on le retire s'il est dans la liste
        if (index != -1) {
          _posts.removeAt(index);
          notifyListeners();
          debugPrint('🗑️ Post archivé retiré : ${updatedPost.id}');
        }
      } else {
        // Le post est actif (archivedAt null)
        if (index != -1) {
          // Mise à jour des infos (likes, comments, etc.)
          _posts[index] = updatedPost;
        } else {
          // Nouveau post actif (peut arriver si désarchivé ou ajouté hors realtime)
          _posts.insert(0, updatedPost);
        }
        notifyListeners();
        debugPrint('🔄 Post mis à jour : ${updatedPost.id}');
      }
    } catch (e) {
      debugPrint('❌ _onPostUpdated error: $e');
    }
  }

  void _onPostDeleted(PostgresChangePayload payload) {
    try {
      final deletedId = payload.oldRecord['id'] as String?;
      if (deletedId != null) {
        _posts.removeWhere((p) => p.id == deletedId);
        notifyListeners();
        debugPrint('🗑️ Post supprimé : $deletedId');
      }
    } catch (e) {
      debugPrint('❌ _onPostDeleted error: $e');
    }
  }

  // ============================================================
  // CHARGEMENT DU FEED (AVEC FILTRE)
  // ============================================================

  Future<void> loadFeed({String? feedType, int limit = 20, bool force = false}) async {
    if (_isLoading && !force) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (feedType != null) _currentFeedType = feedType;

      // 👉 La méthode getFeedPosts doit déjà filtrer archived_at IS NULL
      final newPosts = await _networkService.getFeedPosts(limit: limit);
      _posts = newPosts;
      _hasMore = newPosts.length >= limit;
      _lastRefresh = DateTime.now();
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ loadFeed error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Rafraîchissement forcé (pull-to-refresh)
  Future<void> refreshFeed() async {
    await loadFeed(feedType: _currentFeedType, force: true);
  }

  // ============================================================
  // AUTO-REFRESH (si nécessaire, mais on peut le désactiver)
  // ============================================================

  Future<void> _autoRefresh() async {
    try {
      final now = DateTime.now();
      if (_lastRefresh != null && now.difference(_lastRefresh!).inSeconds < 3) return;
      _lastRefresh = now;
      // Rechargement discret (sans afficher le spinner)
      final newPosts = await _networkService.getFeedPosts(limit: 20);
      // Comparer et mettre à jour uniquement si différent
      if (_posts.length != newPosts.length ||
          !_posts.every((p) => newPosts.any((np) => np.id == p.id))) {
        _posts = newPosts;
        notifyListeners();
        debugPrint('🔄 Auto-refresh effectué');
      }
    } catch (e) {
      debugPrint('❌ _autoRefresh error: $e');
    }
  }

  // ============================================================
  // CRÉATION DE POST
  // ============================================================

  Future<bool> createPost(String content, List<String> images) async {
    try {
      final postId = await _networkService.createPost(content, images);
      if (postId.isEmpty) return false;
      // Le realtime insérera le post s'il est actif, donc pas besoin de recharger.
      // Mais on peut forcer un refresh au cas où.
      await refreshFeed();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ============================================================
  // INTERACTIONS (LIKE, COMMENTAIRE)
  // ============================================================

  Future<void> toggleLike(String postId) async {
    try {
      final index = _posts.indexWhere((p) => p.id == postId);
      if (index == -1) return;

      final post = _posts[index];
      final currentLike = post.isLiked;

      // Optimistic update
      _posts[index] = post.copyWith(
        likesCount: currentLike ? post.likesCount - 1 : post.likesCount + 1,
        isLiked: !currentLike,
      );
      notifyListeners();

      // Appel API
      if (currentLike) {
        await _networkService.unlikePost(postId);
      } else {
        await _networkService.likePost(postId);
      }
    } catch (e) {
      // Revert en cas d'erreur
      await loadFeed(feedType: _currentFeedType, force: true);
      debugPrint('❌ toggleLike error: $e');
    }
  }

  Future<void> addComment(String postId, String comment) async {
    try {
      await _networkService.addComment(postId, comment);
      final index = _posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        _posts[index] = _posts[index].copyWith(
          commentsCount: _posts[index].commentsCount + 1,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ addComment error: $e');
    }
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }
}
