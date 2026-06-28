// lib/services/post_service.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/models/post.dart';
import 'package:thix_id/models/post_media.dart';
import 'package:thix_id/models/comment.dart';

class PostService {
  final SupabaseClient supabase;
  final String storageBucket;

  PostService({SupabaseClient? client, this.storageBucket = 'posts'}) : supabase = client ?? Supabase.instance.client;

  /// Create a post with optional media files. Returns the created Post model.
  Future<Post> createPost({
    required String profileId,
    required String content,
    String privacy = 'public',
    List<PlatformFile>? mediaFiles,
  }) async {
    try {
      final insert = await supabase
          .from('posts')
          .insert({
            'author': profileId,
            'content': content.trim(),
            'privacy': privacy,
          })
          .select()
          .single();

      final post = Post.fromMap(insert as Map<String, dynamic>);

      if (mediaFiles != null && mediaFiles.isNotEmpty) {
        for (var i = 0; i < mediaFiles.length; i++) {
          final f = mediaFiles[i];
          final filename = '${DateTime.now().millisecondsSinceEpoch}_${f.name}';
          final key = 'posts/${post.id}/$filename';

          // Upload: handle web (bytes) and io (path)
          if (kIsWeb) {
            final bytes = f.bytes;
            if (bytes == null) continue;
            await supabase.storage.from(storageBucket).uploadBinary(key, bytes, fileOptions: FileOptions(cacheControl: '3600'));
          } else {
            final path = f.path;
            if (path == null) continue;
            final file = File(path);
            await supabase.storage.from(storageBucket).upload(key, file);
          }

          final publicUrl = supabase.storage.from(storageBucket).getPublicUrl(key).data;

          await supabase.from('post_media').insert({
            'post_id': post.id,
            'storage_path': key,
            'mime': f.mimeType ?? 'application/octet-stream',
            'size': f.size,
            'ordering': i,
          });

          // update in-memory media list (optional)
          post.media.add(PostMedia(
            id: '',
            postId: post.id,
            storagePath: key,
            url: publicUrl ?? '',
            mime: f.mimeType ?? 'application/octet-stream',
            size: f.size,
            ordering: i,
          ));
        }
      }

      return post;
    } catch (e, st) {
      debugPrint('PostService.createPost error: $e\n$st');
      rethrow;
    }
  }

  /// Fetch feed with simple pagination. For production, consider server-side RPC for ranking.
  Future<List<Post>> fetchFeed({int limit = 20, int offset = 0}) async {
    try {
      final res = await supabase
          .from('posts')
          .select('*, profiles:author(*) , post_media(*)')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1)
          .execute();

      final data = res.data as List<dynamic>? ?? [];
      return data.map((e) => Post.fromMap(e as Map<String, dynamic>)).toList();
    } catch (e, st) {
      debugPrint('PostService.fetchFeed error: $e\n$st');
      rethrow;
    }
  }

  /// Stream posts realtime (inserts/updates/deletes).
  RealtimeSubscription streamPosts({required void Function(List<Post>) onData}) {
    final channel = supabase.channel('public:posts');

    channel
        .on(RealtimeListenTypes.postgresChanges, ChannelFilter(event: '*', schema: 'public', table: 'posts'), (payload, {ref}) async {
      try {
        // payload contains record data; fetch latest feed slice for simplicity
        final posts = await fetchFeed(limit: 50, offset: 0);
        onData(posts);
      } catch (e) {
        debugPrint('streamPosts handler error: $e');
      }
    }).subscribe();

    return channel;
  }

  /// Like a post. Note: for robust counters use an RPC or DB trigger to avoid race conditions.
  Future<void> likePost({required String profileId, required String postId}) async {
    try {
      await supabase.from('likes').insert({'user_id': profileId, 'post_id': postId}).execute();
      // Attempt a best-effort increment (may race). Prefer an RPC/trigger in production.
      await supabase.rpc('increment_post_like_count', params: {'post_id': postId});
    } catch (e, st) {
      debugPrint('PostService.likePost error: $e\n$st');
      rethrow;
    }
  }

  Future<void> unlikePost({required String profileId, required String postId}) async {
    try {
      await supabase.from('likes').delete().match({'user_id': profileId, 'post_id': postId}).execute();
      await supabase.rpc('decrement_post_like_count', params: {'post_id': postId});
    } catch (e, st) {
      debugPrint('PostService.unlikePost error: $e\n$st');
      rethrow;
    }
  }

  Future<void> addComment({required String profileId, required String postId, required String content, String? parentId}) async {
    try {
      final res = await supabase
          .from('comments')
          .insert({'post_id': postId, 'author': profileId, 'content': content, 'parent_id': parentId})
          .select()
          .single();

      // optionally increment comment counter safely via RPC
      await supabase.rpc('increment_post_comment_count', params: {'post_id': postId});

      // return created comment if needed
      // final comment = Comment.fromMap(res as Map<String, dynamic>);
      // return comment;
    } catch (e, st) {
      debugPrint('PostService.addComment error: $e\n$st');
      rethrow;
    }
  }

  /// Fetch comments for a post with pagination. Returns a list of Comment models.
  Future<List<Comment>> fetchComments({required String postId, int limit = 50, int offset = 0}) async {
    try {
      final res = await supabase
          .from('comments')
          .select('*, profiles:author(*)')
          .eq('post_id', postId)
          .order('created_at', ascending: true)
          .range(offset, offset + limit - 1)
          .execute();

      final data = res.data as List<dynamic>? ?? [];
      return data.map((e) => Comment.fromMap(e as Map<String, dynamic>)).toList();
    } catch (e, st) {
      debugPrint('PostService.fetchComments error: $e\n$st');
      rethrow;
    }
  }

  /// Stream comments for a post using realtime.
  RealtimeSubscription streamComments({required String postId, required void Function(List<Comment>) onData}) {
    final channel = supabase.channel('public:comments:$postId');

    channel
        .on(RealtimeListenTypes.postgresChanges, ChannelFilter(event: '*', schema: 'public', table: 'comments', filter: 'post_id=eq.$postId'), (payload, {ref}) async {
      try {
        final comments = await fetchComments(postId: postId, limit: 100, offset: 0);
        onData(comments);
      } catch (e) {
        debugPrint('streamComments handler error: $e');
      }
    }).subscribe();

    return channel;
  }
}
