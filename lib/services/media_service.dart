import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/models/media_content.dart';

class CommentItem { 
  final String id, userId, userName, content; 
  final String? avatarUrl, parentId; 
  final DateTime createdAt; 
  final int likeCount, replyCount;
  
  CommentItem({
    required this.id, 
    required this.userId, 
    required this.userName, 
    required this.content, 
    required this.createdAt, 
    this.avatarUrl, 
    this.parentId, 
    this.likeCount = 0, 
    this.replyCount = 0
  });
  
  factory CommentItem.fromMap(Map<String, dynamic> m) => CommentItem(
    id: m['id'], 
    userId: m['user_id'], 
    userName: (m['user_name'] as String?)?.isNotEmpty == true ? m['user_name'] : 'Utilisateur', 
    avatarUrl: m['avatar_url'], 
    content: m['content'], 
    createdAt: DateTime.parse(m['created_at']).toLocal(), 
    parentId: m['parent_id'], 
    likeCount: (m['like_count'] as num?)?.toInt() ?? 0, 
    replyCount: (m['reply_count'] as num?)?.toInt() ?? 0
  );
}

class CommentPage { 
  final List<CommentItem> items; 
  final bool hasMore; 
  final String? nextCursor; 
  CommentPage({required this.items, required this.hasMore, this.nextCursor}); 
}

class FeedPage { 
  final List<MediaContent> items; 
  final double nextCursor; 
  FeedPage({required this.items, required this.nextCursor}); 
}

class MediaCounts { 
  final int likeCount, viewCount, commentCount; 
  const MediaCounts({required this.likeCount, required this.viewCount, required this.commentCount}); 
}

class MediaService {
  static final MediaService _instance = MediaService._internal();
  
  String bucket = 'media';

  // Factory pour accepter les paramètres des classes Admin sans casser le code principal
  factory MediaService({SupabaseClient? client, String? bucket}) {
    if (bucket != null) _instance.bucket = bucket;
    return _instance;
  }
  
  MediaService._internal();
  
  SupabaseClient get supabase => Supabase.instance.client;

  // FIL: seenIds au lieu de double cursor
  Future<FeedPage> fetchShuffledFeed({required List<String> seenIds, int limit = 12, String? category}) async {
    final data = await supabase.rpc('get_shuffled_feed', params: {'p_seen_ids': seenIds, 'p_limit': limit, 'p_category': category}) as List;
    final items = data.map((e) => MediaContent.fromJson(e as Map<String, dynamic>)).toList();
    return FeedPage(items: items, nextCursor: 0);
  }

  // Comptes: polling 15s, pas Realtime pour préserver le serveur
  Stream<MediaCounts> watchMediaCounts(String mediaId) async* {
    while (true) {
      try {
        final r = await supabase.from('media_stats').select('like_count,view_count,comment_count').eq('media_id', mediaId).maybeSingle();
        yield MediaCounts(
          likeCount: r?['like_count'] ?? 0, 
          viewCount: r?['view_count'] ?? 0, 
          commentCount: r?['comment_count'] ?? 0
        );
      } catch (_) {}
      await Future.delayed(const Duration(seconds: 15));
    }
  }

  // Batch vues (Ultra performant)
  static final Set<String> _pendingViews = {}; 
  static Timer? _viewTimer;
  
  void registerView(String id) { 
    _pendingViews.add(id); 
    _viewTimer ??= Timer(const Duration(seconds: 8), _flushViews); 
  }
  
  static Future<void> _flushViews() async {
    if (_pendingViews.isEmpty) { 
      _viewTimer = null; 
      return; 
    }
    final batch = _pendingViews.toList(); 
    _pendingViews.clear(); 
    _viewTimer = null;
    try { 
      await Supabase.instance.client.rpc('batch_register_views', params: {'p_media_ids': batch}); 
    } catch (e) { 
      _pendingViews.addAll(batch); 
    }
  }

  Future<bool> toggleLike(String id) async { 
    final r = await supabase.rpc('toggle_media_like', params: {'p_media_id': id}); 
    return r as bool; 
  }
  
  Future<Set<String>> getLikedMediaIds(List<String> ids) async { 
    if (ids.isEmpty) return {}; 
    final r = await supabase.rpc('get_liked_media_ids', params: {'p_media_ids': ids}); 
    return (r as List).map((e) => e as String).toSet(); 
  }

  // Root Comments
  Future<CommentPage> fetchRootComments(String mediaId, {int limit = 20}) async {
    final data = await supabase.from('media_comments').select().eq('media_id', mediaId).filter('parent_id', 'is', null).order('created_at', ascending: false).limit(limit + 1) as List;
    final hasMore = data.length > limit; 
    final slice = hasMore ? data.sublist(0, limit) : data;
    return CommentPage(
      items: slice.map((e) => CommentItem.fromMap(e as Map<String, dynamic>)).toList(), 
      hasMore: hasMore, 
      nextCursor: slice.isNotEmpty ? slice.last['created_at'] as String : null
    );
  }
  
  Future<CommentPage> fetchRootCommentsNext(String mediaId, {required String cursorCreatedAt, int limit = 20}) async {
    final data = await supabase.from('media_comments').select().eq('media_id', mediaId).filter('parent_id', 'is', null).lt('created_at', cursorCreatedAt).order('created_at', ascending: false).limit(limit + 1) as List;
    final hasMore = data.length > limit; 
    final slice = hasMore ? data.sublist(0, limit) : data;
    return CommentPage(
      items: slice.map((e) => CommentItem.fromMap(e as Map<String, dynamic>)).toList(), 
      hasMore: hasMore, 
      nextCursor: slice.isNotEmpty ? slice.last['created_at'] as String : null
    );
  }

  // Replies / Comments actions
  Future<CommentPage> fetchReplies(String parentId, {int limit = 15}) async {
    final data = await supabase.from('media_comments').select().eq('parent_id', parentId).order('created_at', ascending: true).limit(limit) as List;
    return CommentPage(
      items: data.map((e) => CommentItem.fromMap(e as Map<String, dynamic>)).toList(), 
      hasMore: false
    );
  }

  Future<CommentItem> postComment(String mediaId, String content, {String? parentId}) async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) throw Exception("Non connecté");
    
    final profile = await supabase.from('profiles').select('username, avatar_url').eq('id', uid).maybeSingle();
    final name = (profile?['username'] as String?)?.isNotEmpty == true ? profile!['username'] : 'Utilisateur';

    final res = await supabase.from('media_comments').insert({
      'media_id': mediaId,
      'user_id': uid,
      'user_name': name,
      'avatar_url': profile?['avatar_url'],
      'content': content,
      'parent_id': parentId,
    }).select().single();

    return CommentItem.fromMap(res);
  }

  Future<void> updateComment(String commentId, String newContent) async {
    await supabase.from('media_comments').update({'content': newContent}).eq('id', commentId);
  }

  Future<void> deleteComment(String commentId) async {
    await supabase.from('media_comments').delete().eq('id', commentId);
  }

  Future<void> toggleCommentLike(String commentId) async {
    try {
      await supabase.rpc('toggle_comment_like', params: {'p_comment_id': commentId});
    } catch (_) {}
  }

  Future<void> reportComment(String commentId) async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;
    try {
      await supabase.from('comment_reports').insert({
        'comment_id': commentId, 
        'reporter_id': uid
      });
    } catch (_) {}
  }

  // =========================================================================
  // --- FONCTION D'ADMINISTRATION (RESTAURÉE) ---
  // =========================================================================

  Future<void> deleteMedia(MediaContent item) async {
    // 1. Suppression de la base de données
    await supabase.from('media_content').delete().eq('id', item.id);
    
    // 2. Suppression des fichiers du Storage (Optionnel mais recommandé)
    try {
      if (item.videoUrl.contains(bucket)) {
        final videoPath = item.videoUrl.split('$bucket/').last;
        await supabase.storage.from(bucket).remove([videoPath]);
      }
      if (item.coverUrl.contains(bucket)) {
        final coverPath = item.coverUrl.split('$bucket/').last;
        await supabase.storage.from(bucket).remove([coverPath]);
      }
    } catch (e) {
      debugPrint('Erreur lors de la suppression des fichiers: $e');
    }
  }
}
