import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/network_post.dart';
import '../models/network_connection.dart';
import '../models/network_community.dart';
import '../models/network_story.dart';
import '../models/comment.dart';

class NetworkService {
  final SupabaseClient _supabase;
  NetworkService(this._supabase);
  String get currentUserId => _supabase.auth.currentUser?.id?? '';

  static List<String> _imageUrlsFromRow(Map<String, dynamic> row) {
    if (row['image_urls'] is List) return List<String>.from(row['image_urls']);
    final url = row['media_url'] as String?;
    return url!= null && url.isNotEmpty? [url] : [];
  }

  // ─── FEED : 1 REQUÊTE = SCALABLE ───
  Future<List<NetworkPost>> getFeedPosts({int limit = 20, int offset = 0, String feedType = 'smart'}) async {
    final uid = currentUserId;
    if (uid.isEmpty) return [];

    if (feedType == 'smart') {
      final res = await _supabase.rpc('get_smart_feed', params: {'p_user_id': uid, 'p_limit': limit, 'p_offset': offset});
      return (res as List).map((e) => NetworkPost.fromJson({...e, 'image_urls': _imageUrlsFromRow(e)})).toList();
    }

    // Pour 'network', 'popular', 'shorts' on utilise la view
    var query = _supabase.from('posts_view').select().eq('is_public', true);

    // Filtre hidden
    query = query.not('id', 'in', ' (select post_id from hidden_posts where user_id = $uid) ');

    if (feedType == 'network') {
      query = query.inFilter('user_id', await _getConnectionIds());
    } else if (feedType == 'popular') {
      query = query.gte('created_at', DateTime.now().subtract(const Duration(days: 7)).toIso8601String()).order('likes_count', ascending: false);
    } else {
      query = query.order('created_at', ascending: false);
    }

    final res = await query.range(offset, offset + limit - 1);
    return (res as List).map((e) => NetworkPost.fromJson({...e, 'image_urls': _imageUrlsFromRow(e)})).toList();
  }

  Future<Set<String>> _getConnectionIds() async {
    final res = await _supabase.from('connections').select('connection_id').eq('user_id', currentUserId).eq('status', 'accepted');
    return (res as List).map((e) => e['connection_id'] as String).toSet();
  }

  // ─── POSTS ───
  Future<String> createPost(String content, List<String> images) async {
    final res = await _supabase.from('posts').insert({
      'user_id': currentUserId,
      'content': content.trim(),
      'image_urls': images,
      'media_url': images.isNotEmpty? images.first : null,
    }).select('id').single();
    return res['id'];
  }
  Future<void> deletePost(String id) => _supabase.from('posts').delete().eq('id', id);
  Future<void> updatePost(String id, String c) => _supabase.from('posts').update({'content': c.trim()}).eq('id', id);
  Future<void> hidePost(String id) => _supabase.from('hidden_posts').upsert({'post_id': id, 'user_id': currentUserId}, onConflict: 'post_id,user_id');
  Future<void> likePost(String id) => _supabase.from('post_likes').upsert({'post_id': id, 'user_id': currentUserId}, onConflict: 'post_id,user_id');
  Future<void> unlikePost(String id) => _supabase.from('post_likes').delete().eq('post_id', id).eq('user_id', currentUserId);
  Future<void> sharePost(String id) => _supabase.rpc('increment_share', params: {'p_post_id': id});

  // ─── STORIES & SUGGESTIONS : BATCHED ───
  Future<List<NetworkStory>> getActiveStories() async {
    final res = await _supabase.from('stories').select('*, profiles!user_id(display_name, avatar_url)').eq('is_active', true).gte('expires_at', DateTime.now().toIso8601String()).order('created_at', ascending: false).limit(30);
    return (res as List).map((e) => NetworkStory.fromJson({...e, 'image_url': e['media_url']?? '', 'userName': e['profiles']['display_name'], 'userAvatar': e['profiles']['avatar_url']})).toList();
  }

  // ─── MÉTHODES UTILITAIRES RÉINTÉGRÉES ───

  Future<void> createStory(String mediaUrl, {String mediaType = 'image', int duration = 24}) async {
    await _supabase.from('stories').insert({
      'user_id': currentUserId,
      'media_url': mediaUrl,
      'media_type': mediaType,
      'is_active': true,
      'created_at': DateTime.now().toIso8601String(),
      'expires_at': DateTime.now().add(Duration(hours: duration)).toIso8601String(),
    });
  }

  Future<void> savePost(String postId) async {
    await _supabase.from('saved_posts').upsert({
      'post_id': postId,
      'user_id': currentUserId,
      'saved_at': DateTime.now().toIso8601String(),
    }, onConflict: 'post_id,user_id');
  }

  Future<void> unsavePost(String postId) async {
    await _supabase.from('saved_posts').delete().eq('post_id', postId).eq('user_id', currentUserId);
  }

  Future<void> repost(String originalPostId, String? quote) async {
    await _supabase.from('reposts').insert({
      'original_post_id': originalPostId,
      'user_id': currentUserId,
      'quote': quote,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> pinPost(String postId) async {
    await _supabase.from('posts').update({'is_pinned': false}).eq('user_id', currentUserId).eq('is_pinned', true);
    await _supabase.from('posts').update({'is_pinned': true}).eq('id', postId);
  }

  Future<void> reportPost(String postId, String reason) async {
    await _supabase.from('reported_posts').insert({
      'post_id': postId,
      'user_id': currentUserId,
      'reason': reason,
      'reported_at': DateTime.now().toIso8601String(),
    });
  }

  Future<String?> uploadImageBytes(Uint8List bytes, {required String fileExtension, String bucket = 'post_images'}) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final path = '$currentUserId/$fileName';
      await _supabase.storage.from(bucket).uploadBinary(path, bytes);
      return _supabase.storage.from(bucket).getPublicUrl(path);
    } catch (e) {
      debugPrint('Error uploading: $e');
      return null;
    }
  }

  
  Future<List<NetworkConnection>> getSuggestedConnections({int limit = 5}) async {
    // 1 seule RPC qui calcule tout côté SQL
    final res = await _supabase.rpc('get_suggested_connections', params: {'p_user_id': currentUserId, 'p_limit': limit});
    return (res as List).map((e) => NetworkConnection(id: e['id'], name: e['display_name'], avatar: e['avatar_url'], title: e['profession'], mutualConnections: e['mutual_count']?? 0)).toList();
  }

  // ─── COMMUNITIES & RESTE ───
  Future<List<NetworkCommunity>> getAllCommunities({int limit = 20}) async {
    final res = await _supabase.from('communities_with_membership').select().eq('current_user_id', currentUserId).order('members_count', ascending: false).limit(limit);
    return (res as List).map((e) => NetworkCommunity.fromJson(e)).toList();
  }

  Future<void> sendConnectionRequest(String targetId) async {
    await _supabase.from('connection_requests').upsert({'sender_id': currentUserId, 'receiver_id': targetId}, onConflict: 'sender_id,receiver_id');
  }

  String _getPostOwnerIdCache(String postId) => ''; // plus besoin, géré par trigger DB
  Future<String> _getPostOwnerId(String postId) async => (await _supabase.from('posts').select('user_id').eq('id', postId).maybeSingle())?['user_id']?? '';
  Future<void> _createNotification({required String userId, required String type, String? postId}) async {
    if(userId == currentUserId || userId.isEmpty) return;
    unawaited(_supabase.from('notifications').insert({'user_id': userId, 'type': type, 'sender_id': currentUserId, 'post_id': postId}));
  }
}
