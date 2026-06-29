// lib/providers/feed_provider.dart
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
    debugPrint('🎙️ FeedProvider: Initialisation realtime...');
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
            callback: (payload) {
              debugPrint('📬 [REALTIME] Nouvelle publication détectée!');
              _onPostInserted(payload.newRecord);
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'posts',
            callback: (payload) {
              debugPrint('📝 [REALTIME] Publication mise à jour');
              _onPostUpdated(payload.newRecord);
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
  
  void _onPostInserted(dynamic newRecord) {
    try {
      if (newRecord == null) return;
      final Map<String, dynamic> jsonData;
      if (newRecord is Map<String, dynamic>) {
        jsonData = newRecord;
      } else {
        jsonData = (newRecord as Map).cast<String, dynamic>();
      }
      final post = NetworkPost.fromJson(jsonData);
      _posts.insert(0, post);
      notifyListeners();
      debugPrint('✅ FeedProvider: Post inséré en début de liste');
    } catch (e) {
      debugPrint('❌ FeedProvider _onPostInserted error: $e');
    }
  }
  
  void _onPostUpdated(dynamic updatedRecord) {
    try {
      if (updatedRecord == null) return;
      final Map<String, dynamic> jsonData;
      if (updatedRecord is Map<String, dynamic>) {
        jsonData = updatedRecord;
      } else {
        jsonData = (updatedRecord as Map).cast<String, dynamic>();
      }
      final updated = NetworkPost.fromJson(jsonData);
      final index = _posts.indexWhere((p) => p.id == updated.id);
      if (index != -1) {
        _posts[index] = updated;
        notifyListeners();
        debugPrint('✅ FeedProvider: Post ${updated.id} mis à jour');
      }
    } catch (e) {
      debugPrint('❌ FeedProvider _onPostUpdated error: $e');
    }
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
      final deleted = NetworkPost.fromJson(jsonData);
      _posts.removeWhere((p) => p.id == deleted.id);
      notifyListeners();
      debugPrint('✅ FeedProvider: Post ${deleted.id} supprimé');
    } catch (e) {
      debugPrint('❌ FeedProvider _onPostDeleted error: $e');
    }
  }

  // ============================================================
  // CHARGEMENT DU FEED
  // ============================================================

  Future<void> loadFeed({String? feedType, int limit = 20}) async {
    if (_isLoading) return;
    
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
      await loadFeed(feedType: _currentFeedType);
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
  
  /// ✅ CORRIGÉ: utilise 'isLiked' au lieu de 'isLikedByCurrentUser'
  Future<void> toggleLike(String postId) async {
    try {
      final index = _posts.indexWhere((p) => p.id == postId);
      if (index == -1) return;
      
      final post = _posts[index];
      final currentLikeStatus = post.isLiked;  // ← Utilise isLiked
      
      if (currentLikeStatus) {
        await _networkService.unlikePost(postId);
        _posts[index] = post.copyWith(
          likesCount: (post.likesCount - 1).clamp(0, double.infinity).toInt(),
          isLiked: false,  // ← Utilise isLiked
        );
      } else {
        await _networkService.likePost(postId);
        _posts[index] = post.copyWith(
          likesCount: post.likesCount + 1,
          isLiked: true,  // ← Utilise isLiked
        );
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('❌ FeedProvider toggleLike error: $e');
    }
  }
  
  /// ✅ CORRIGÉ: utilise 'addComment' au lieu de 'addCommentToPost'
  Future<void> addComment(String postId, String comment) async {
    try {
      await _networkService.addComment(postId, comment);  // ← Utilise addComment
      
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
