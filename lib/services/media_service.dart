import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/models/media_content.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;

typedef ProgressCallback = void Function(double progress);

// ---------------- MODÈLES ----------------

class CommentItem {
  final String id;
  final String userId;
  final String userName;
  final String? avatarUrl;
  final String content;
  final DateTime createdAt;
  final String? parentId;
  final int likeCount;
  final int replyCount;

  CommentItem({
    required this.id,
    required this.userId,
    required this.userName,
    required this.content,
    required this.createdAt,
    this.avatarUrl,
    this.parentId,
    this.likeCount = 0,
    this.replyCount = 0,
  });

  factory CommentItem.fromMap(Map<String, dynamic> map) {
    return CommentItem(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      userName: (map['user_name'] as String?)?.trim().isNotEmpty == true ? map['user_name'] as String : 'Utilisateur',
      avatarUrl: map['avatar_url'] as String?,
      content: map['content'] as String,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      parentId: map['parent_id'] as String?,
      likeCount: (map['like_count'] as num?)?.toInt() ?? 0,
      replyCount: (map['reply_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class CommentPage {
  final List<CommentItem> items;
  final bool hasMore;
  final String? nextCursorCreatedAt;
  final String? nextCursorId;

  CommentPage({required this.items, required this.hasMore, this.nextCursorCreatedAt, this.nextCursorId});
}

class FeedPage {
  final List<MediaContent> items;
  final double nextCursor;

  FeedPage({required this.items, required this.nextCursor});
}

class MediaCounts {
  final int likeCount;
  final int viewCount;
  final int commentCount;
  const MediaCounts({required this.likeCount, required this.viewCount, required this.commentCount});
}

// ---------------- SERVICE SCALABLE, PROFIL & ADMIN ----------------

class MediaService {
  // 1. SCALABILITY: Pattern SINGLETON strict
  static final MediaService _instance = MediaService._internal();

  factory MediaService({SupabaseClient? client, String bucket = 'media'}) {
    _instance.supabase = client ?? Supabase.instance.client;
    _instance.bucket = bucket;
    return _instance;
  }

  MediaService._internal();

  late SupabaseClient supabase;
  late String bucket;
  final Uuid _uuid = const Uuid();

  // ====== FIL MÉLANGÉ SCALABLE (ALGORITHME TIKTOK) ======
  Future<FeedPage> fetchShuffledFeed({required List<String> seenIds, int limit = 10}) async {
    final data = await supabase.rpc('get_shuffled_feed', params: {
      'p_seen_ids': seenIds,
      'p_limit': limit,
    }) as List;

    final items = data.map((e) => MediaContent.fromJson(e as Map<String, dynamic>)).toList();
    
    return FeedPage(items: items, nextCursor: 0.0);
  }

  // ====== COMPTEURS LIVE (Polling Scalable pour millions d'users) ======
  Stream<MediaCounts> watchMediaCounts(String mediaId) async* {
    while (true) {
      try {
        final r = await supabase.from('media_stats').select('like_count,view_count,comment_count').eq('media_id', mediaId).maybeSingle();
        yield MediaCounts(
          likeCount: (r?['like_count'] as num?)?.toInt() ?? 0,
          viewCount: (r?['view_count'] as num?)?.toInt() ?? 0,
          commentCount: (r?['comment_count'] as num?)?.toInt() ?? 0,
        );
      } catch (_) {}
      await Future.delayed(const Duration(seconds: 12)); // Évite de saturer la base de données
    }
  }

  // ====== BATCHING DES VUES (Protection de la BDD) ======
  static final Set<String> _pendingViews = {};
  static Timer? _viewTimer;

  void registerView(String mediaId) {
    _pendingViews.add(mediaId);
    _viewTimer ??= Timer(const Duration(seconds: 10), _flushViews);
  }

  Future<void> _flushViews() async {
    if (_pendingViews.isEmpty) {
      _viewTimer = null;
      return;
    }
    final batch = _pendingViews.toList();
    _pendingViews.clear();
    _viewTimer = null;

    try {
      await supabase.rpc('batch_register_views', params: {'p_media_ids': batch});
    } catch (e) {
      _pendingViews.addAll(batch);
      debugPrint('View batching failed, retrying later: $e');
    }
  }

  // ====== GESTION DU PROFIL ET FOLLOW (THIX CENTRAL) ======
  
  Future<Map<String, dynamic>?> fetchProfile(String userId) async {
    final res = await supabase.from('profiles').select('*').eq('id', userId).maybeSingle();
    return res as Map<String, dynamic>?;
  }

  Future<bool> isFollowing(String targetUserId) async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null || uid == targetUserId) return false;
    
    final res = await supabase
        .from('follows')
        .select()
        .eq('follower_id', uid)
        .eq('following_id', targetUserId)
        .maybeSingle();
        
    return res != null;
  }

  Future<bool> toggleFollow(String targetUserId) async {
    final res = await supabase.rpc('toggle_follow', params: {'p_target_id': targetUserId});
    return res as bool;
  }

  Future<Map<String, int>> fetchUserStats(String userId) async {
    final followersCount = await supabase
        .from('follows')
        .count(CountOption.exact)
        .eq('following_id', userId);

    final followingCount = await supabase
        .from('follows')
        .count(CountOption.exact)
        .eq('follower_id', userId);

    final postsCount = await supabase
        .from('media_content')
        .count(CountOption.exact)
        .eq('user_id', userId);

    return {
      'followers': followersCount.count,
      'following': followingCount.count,
      'posts': postsCount.count,
    };
  }

  // ====== LIKES (RPC atomique) ======
  Future<bool> toggleLike(String mediaId) async {
    final res = await _retry(() => supabase.rpc('toggle_media_like', params: {'p_media_id': mediaId}));
    return res as bool;
  }

  Future<Set<String>> getLikedMediaIds(List<String> mediaIds) async {
    if (mediaIds.isEmpty) return {};
    final res = await supabase.rpc('get_liked_media_ids', params: {'p_media_ids': mediaIds});
    return (res as List).map((e) => e as String).toSet();
  }

  // ====== COMMENTAIRES ======
  Future<CommentPage> fetchRootComments(String mediaId, {int limit = 20}) async {
    final data = await supabase
        .from('media_comments')
        .select('id, user_id, user_name, avatar_url, content, created_at, parent_id, like_count, reply_count')
        .eq('media_id', mediaId)
        .filter('parent_id', 'is', null)
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .limit(limit + 1);
    return _buildPage(data as List, limit);
  }

  Future<CommentPage> fetchRootCommentsNext(String mediaId, {required String cursorCreatedAt, int limit = 20}) async {
    final data = await supabase
        .from('media_comments')
        .select('id, user_id, user_name, avatar_url, content, created_at, parent_id, like_count, reply_count')
        .eq('media_id', mediaId)
        .filter('parent_id', 'is', null)
        .lt('created_at', cursorCreatedAt)
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .limit(limit + 1);
    return _buildPage(data as List, limit);
  }

  Future<CommentPage> fetchReplies(String parentId, {int limit = 10, String? afterCreatedAt}) async {
    var query = supabase
        .from('media_comments')
        .select('id, user_id, user_name, avatar_url, content, created_at, parent_id, like_count, reply_count')
        .eq('parent_id', parentId);
    if (afterCreatedAt != null) {
      query = query.gt('created_at', afterCreatedAt);
    }
    final data = await query.order('created_at', ascending: true).order('id', ascending: true).limit(limit + 1);
    return _buildPage(data as List, limit, ascending: true);
  }

  CommentPage _buildPage(List data, int limit, {bool ascending = false}) {
    final hasMore = data.length > limit;
    final slice = hasMore ? data.sublist(0, limit) : data;
    final items = slice.map((e) => CommentItem.fromMap(e as Map<String, dynamic>)).toList();
    return CommentPage(
      items: items,
      hasMore: hasMore,
      nextCursorCreatedAt: items.isNotEmpty ? slice.last['created_at'] as String : null,
      nextCursorId: items.isNotEmpty ? slice.last['id'] as String : null,
    );
  }

  Future<CommentItem> postComment(String mediaId, String content, {String? parentId}) async {
    final res = await _retry(() => supabase.rpc('post_media_comment', params: {
          'p_media_id': mediaId,
          'p_content': content,
        }));
    var map = res as Map<String, dynamic>;
    if (parentId != null) {
      await supabase.from('media_comments').update({'parent_id': parentId}).eq('id', map['id']);
      map = {...map, 'parent_id': parentId};
    }
    return CommentItem.fromMap(map);
  }

  Future<void> updateComment(String commentId, String content) async {
    await supabase.from('media_comments').update({'content': content}).eq('id', commentId);
  }

  Future<void> deleteComment(String commentId) async {
    await supabase.from('media_comments').delete().eq('id', commentId);
  }

  Future<bool> toggleCommentLike(String commentId) async {
    final res = await supabase.rpc('toggle_comment_like', params: {'p_comment_id': commentId});
    return res as bool;
  }

  Future<void> reportComment(String commentId, {String? reason}) async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;
    await supabase.from('comment_reports').upsert({
      'comment_id': commentId,
      'reporter_id': uid,
      'reason': reason,
    }, onConflict: 'comment_id,reporter_id', ignoreDuplicates: true);
  }

  // ====== PAGINATION EXPLORER & ADMIN ======
  Future<List<MediaContent>> fetchAllMedia({int page = 0, int limit = 50}) async {
    final start = page * limit;
    final end = start + limit - 1;
    final data = await supabase.from('media_content').select().order('created_at', ascending: false).range(start, end) as List<dynamic>;
    return data.map((e) => MediaContent.fromJson(e as Map<String, dynamic>)).toList(growable: false);
  }

  Future<List<MediaContent>> fetchAllMediaPaginated({int limit = 30, int offset = 0}) async {
    final data = await supabase.from('media_content').select().order('created_at', ascending: false).range(offset, offset + limit - 1) as List<dynamic>;
    return data.map((e) => MediaContent.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ====== UPLOAD DE FICHIERS ET POST DIRECT DANS LE FIL ======
  Future<MediaContent> insertWithFiles(MediaContent item, {PlatformFile? coverFile, PlatformFile? videoFile, ProgressCallback? onProgress}) async {
    final newId = _uuid.v4();
    final uid = supabase.auth.currentUser?.id;

    String? finalCoverUrl;
    String? finalVideoUrl;
    int totalTasks = (coverFile != null ? 1 : 0) + (videoFile != null ? 1 : 0);
    int doneTasks = 0;
    
    void tick() {
      doneTasks++;
      if (onProgress != null && totalTasks > 0) onProgress(doneTasks / totalTasks);
    }
    
    final tasks = <Future<void>>[];
    if (coverFile != null) tasks.add(_uploadPhysicalFile(coverFile, 'thix_media/$newId/covers').then((url) { finalCoverUrl = url; tick(); }));
    if (videoFile != null) tasks.add(_uploadPhysicalFile(videoFile, 'thix_media/$newId/videos').then((url) { finalVideoUrl = url; tick(); }));
    if (tasks.isNotEmpty) await Future.wait(tasks);

    // CORRECTION MAJEURE ICI : Construction explicite avec les noms snake_case attendus par Supabase
    final map = {
      'id': newId,
      'title': item.title,
      'type': 'Fil', // Force le post dans le fil
      'user_id': uid,
      'cover_url': finalCoverUrl ?? item.coverUrl,
      'video_url': finalVideoUrl ?? item.videoUrl,
      'is_published': true,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (item.subtitle != null && item.subtitle!.isNotEmpty) {
      map['subtitle'] = item.subtitle!;
    }

    final inserted = await _retry(() => supabase.from('media_content').insert(map).select().single());
    return MediaContent.fromJson(inserted as Map<String, dynamic>);
  }

  Future<MediaContent> updateWithFiles(MediaContent existing, {PlatformFile? newCoverFile, PlatformFile? newVideoFile, ProgressCallback? onProgress}) async {
    String? finalCoverUrl;
    String? finalVideoUrl;
    int totalTasks = (newCoverFile != null ? 1 : 0) + (newVideoFile != null ? 1 : 0);
    int doneTasks = 0;
    void tick() {
      doneTasks++;
      if (onProgress != null && totalTasks > 0) onProgress(doneTasks / totalTasks);
    }
    final tasks = <Future<void>>[];
    if (newCoverFile != null) tasks.add(_uploadPhysicalFile(newCoverFile, 'thix_media/${existing.id}/covers').then((url) { finalCoverUrl = url; tick(); }));
    if (newVideoFile != null) tasks.add(_uploadPhysicalFile(newVideoFile, 'thix_media/${existing.id}/videos').then((url) { finalVideoUrl = url; tick(); }));
    if (tasks.isNotEmpty) await Future.wait(tasks);

    // CORRECTION ICI AUSSI POUR L'UPDATE
    final updateMap = {
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (finalCoverUrl != null) updateMap['cover_url'] = finalCoverUrl;
    if (finalVideoUrl != null) updateMap['video_url'] = finalVideoUrl;

    await _retry(() => supabase.from('media_content').update(updateMap).eq('id', existing.id));
    
    return existing.copyWith(
      coverUrl: finalCoverUrl ?? existing.coverUrl, 
      videoUrl: finalVideoUrl ?? existing.videoUrl, 
      updatedAt: DateTime.now()
    );
  }

  Future<void> deleteMedia(MediaContent item) async {
    final paths = <String>[];
    String? extractPath(String url) {
      if (url.isEmpty) return null;
      final marker = '/public/$bucket/';
      if (url.contains(marker)) return url.split(marker).last.split('?').first;
      final marker2 = '/object/public/$bucket/';
      if (url.contains(marker2)) return url.split(marker2).last.split('?').first;
      if (!url.startsWith('http')) return url;
      return null;
    }
    final cp = extractPath(item.coverUrl);
    final vp = extractPath(item.videoUrl);
    if (cp != null) paths.add(cp);
    if (vp != null) paths.add(vp);
    if (paths.isNotEmpty) {
      try { await supabase.storage.from(bucket).remove(paths); } catch (_) {}
    }
    await _retry(() => supabase.from('media_content').delete().eq('id', item.id));
  }

  Future<String> _uploadPhysicalFile(PlatformFile file, String basePath) async {
    final extension = p.extension(file.name);
    final secureFileName = '${_uuid.v4()}$extension';
    final fullPath = '$basePath/$secureFileName';

    if (kIsWeb) {
      if (file.bytes == null) throw Exception('Web: bytes null, active withData:true');
      await _retry(() => supabase.storage.from(bucket).uploadBinary(fullPath, file.bytes!, fileOptions: const FileOptions(cacheControl: '31536000', upsert: true)));
    } else {
      if (file.path != null) {
        final physicalFile = File(file.path!);
        await _retry(() => supabase.storage.from(bucket).upload(fullPath, physicalFile, fileOptions: const FileOptions(cacheControl: '31536000', upsert: true)));
      } else if (file.bytes != null) {
        await _retry(() => supabase.storage.from(bucket).uploadBinary(fullPath, file.bytes!, fileOptions: const FileOptions(cacheControl: '31536000', upsert: true)));
      } else {
        throw Exception('Mobile: path & bytes null');
      }
    }
    return supabase.storage.from(bucket).getPublicUrl(fullPath);
  }

  Future<T> _retry<T>(Future<T> Function() fn, {int max = 3}) async {
    int attempt = 0;
    while (true) {
      try { return await fn(); } catch (e) { attempt++; if (attempt >= max) rethrow; await Future.delayed(Duration(milliseconds: 300 * attempt)); }
    }
  }
}
