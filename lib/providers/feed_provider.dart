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
  
  // Real-time listening
  RealtimeChannel? _realtimeChannel;
  Timer? _autoRefreshTimer;
  DateTime? _lastRefresh;
  
  FeedProvider(this._networkService, {SupabaseClient? supabase}) : _supabase = supabase;
  
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
    if (_realtimeInitialized) {
      debugPrint('⚠️ FeedProvider: Realtime déjà initialisé, skip');
      return;
    }
    debugPrint('🎙️ FeedProvider: Initialisation realtime...');
    _realtimeInitialized = true;
    _setupRealtimeListener();
    _setupAutoRefresh();
  }
  
  void disposeRealtime() {
    _realtimeChannel?.unsubscribe();
    _autoRefreshTimer?.cancel();
  }
  
  void _setupRealtimeListener() {
    try {
      if (_supabase == null) {
        debugPrint('❌ FeedProvider: Supabase client manquant');
        return;
      }
      
      _realtimeChannel = _supabase!
          .channel('public:posts_feed')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'posts',
            callback: (payload) async {
              debugPrint('📬 [REALTIME] Nouvelle publication détectée!');
              await _onPostInserted();
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'posts',
            callback: (payload) async {
              debugPrint('📝 [REALTIME] Publication mise à jour');
              await _onPostUpdated();
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.delete,
            schema: 'public',
            table: 'posts',
            callback: (payload) {
              debugPrint('🗑️ [REALTIME] Publication supprimée');
              _onPostDeleted(payload.oldRecord);
            },
          );
      
      _realtimeChannel!.subscribe((status, err) {
        if (err != null) {
          debugPrint('❌ FeedProvider Realtime error: $err');
        } else {
          debugPrint('✅ FeedProvider: Realtime connecté - status: $status');
        }
      });
    } catch (e) {
      debugPrint('❌ FeedProvider _setupRealtimeListener error: $e');
    }
  }
  
  void _setupAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (!_isLoading) {
        await _autoRefresh();
      }
    });
    debugPrint('✅ FeedProvider: Auto-refresh activé (10s)');
  }
  
  Future<void> _autoRefresh() async {
    try {
      final now = DateTime.now();
      if (_lastRefresh != null && now.difference(_lastRefresh!).inSeconds < 3) {
        return;
      }
      _lastRefresh = now;
      await loadFeed(feedType: _currentFeedType);
    } catch (e) {
      debugPrint('❌ FeedProvider _autoRefresh error: $e');
    }
  }
  
  Future<void> _onPostInserted() async {
    debugPrint('📬 FeedProvider: Nouveau post inséré - rechargement du feed...');
    await loadFeed(feedType: _currentFeedType);
  }
  
  Future<void> _onPostUpdated() async {
    debugPrint('📝 FeedProvider: Post mis à jour - rechargement du feed...');
    await loadFeed(feedType: _currentFeedType);
  }
  
  void _onPostDeleted(dynamic deletedRecord) {
    try {
      if (deletedRecord == null) return;
      final Map<String, dynamic> jsonData;
      if (deletedRecord is Map<String, dynamic>) {
        jsonData = deletedRecord;
      } else {
        jsonData = (deletedRecord as Map).cast<String, dynamic>();
      }
      final deletedId = jsonData['id'] as String?;
      if (deletedId != null && deletedId.isNotEmpty) {
        _posts.removeWhere((p) => p.id == deletedId);
        notifyListeners();
        debugPrint('✅ FeedProvider: Post $deletedId supprimé');
      }
    } catch (e) {
      debugPrint('❌ FeedProvider _onPostDeleted error: $e');
    }
  }

  // ============================================================
  // CHARGEMENT DU FEED
  // ============================================================

  /// Charge le feed avec possibilité de forcer le rechargement
  /// même si _isLoading est true.
  Future<void> loadFeed({String? feedType, int limit = 20, bool force = false}) async {
    if (_isLoading && !force) return;  // ✅ Ajout de force
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      if (feedType != null) _currentFeedType = feedType;
      
      late List<NetworkPost> newPosts;
      
      switch (_currentFeedType) {
        case 'smart':
          newPosts = await _networkService.getSmartFeed(limit: limit);
          break;
        case 'popular':
          final allPosts = await _networkService.getFeedPosts(limit: 50);
          allPosts.sort((a, b) => b.likesCount.compareTo(a.likesCount));
          newPosts = allPosts.take(limit).toList();
          break;
        default:
          newPosts = await _networkService.getFeedPosts(limit: limit);
      }
      
      _posts = newPosts;
      _hasMore = newPosts.length >= limit;
      _lastRefresh = DateTime.now();
      
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ FeedProvider loadFeed error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // ============================================================
  // CRÉATION DE POST
  // ============================================================
  
  Future<bool> createPost(String content, List<String> images) async {
    try {
      debugPrint('📝 FeedProvider: création du post...');
      final postId = await _networkService.createPost(content, images);
      if (postId.isEmpty) {
        debugPrint('❌ FeedProvider: pas d\'ID retourné');
        return false;
      }
      debugPrint('✅ FeedProvider: post créé avec ID: $postId');
      await loadFeed(feedType: _currentFeedType, force: true); // ✅ Force refresh
      return true;
    } catch (e) {
      debugPrint('❌ FeedProvider createPost error: $e');
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
      final currentLikeStatus = post.isLiked;
      
      if (currentLikeStatus) {
        await _networkService.unlikePost(postId);
        _posts[index] = post.copyWith(
          likesCount: (post.likesCount - 1).clamp(0, double.infinity).toInt(),
          isLiked: false,
        );
      } else {
        await _networkService.likePost(postId);
        _posts[index] = post.copyWith(
          likesCount: post.likesCount + 1,
          isLiked: true,
        );
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('❌ FeedProvider toggleLike error: $e');
    }
  }
  
  Future<void> addComment(String postId, String comment) async {
    try {
      await _networkService.addComment(postId, comment);
      
      final index = _posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        final post = _posts[index];
        _posts[index] = post.copyWith(
          commentsCount: post.commentsCount + 1,
        );
        notifyListeners();
      }
      debugPrint('✅ FeedProvider: Commentaire ajouté');
    } catch (e) {
      debugPrint('❌ FeedProvider addComment error: $e');
    }
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }
}
