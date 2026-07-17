import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/network_post.dart';
import '../models/network_connection.dart';
import '../models/network_community.dart';
import '../models/network_story.dart';

class NetworkService extends ChangeNotifier {
  final SupabaseClient _supabase;
  NetworkService(this._supabase);

  String get currentUserId => _supabase.auth.currentUser?.id?? '';
  String? get _uid => _supabase.auth.currentUser?.id;

  static List<String> _imageUrlsFromRow(Map<String, dynamic> row) {
    if (row['image_urls'] is List) return List<String>.from(row['image_urls']);
    final url = row['media_url'] as String?;
    return url!= null && url.isNotEmpty? [url] : [];
  }

  // ─── FEED ───
  Future<List<NetworkPost>> getFeedPosts({int limit = 20, int offset = 0, String feedType = 'smart'}) async {
    final uid = currentUserId;
    if (uid.isEmpty) return [];

    if (feedType == 'smart') {
      final res = await _supabase.rpc('get_smart_feed', params: {'p_user_id': uid, 'p_limit': limit, 'p_offset': offset});
      return (res as List).map((e) => NetworkPost.fromJson({...e, 'image_urls': _imageUrlsFromRow(e)})).toList();
    }

    final hiddenIds = await _supabase.from('hidden_posts').select('post_id').eq('user_id', uid);
    final hiddenSet = (hiddenIds as List).map((e) => e['post_id'] as String).toSet();

    var builder = _supabase.from('posts_view').select().eq('is_public', true).order('created_at', ascending: false).range(offset, offset + limit - 1);

    if (feedType == 'network') {
      final connIds = await _getConnectionIds();
      if (connIds.isEmpty) return [];
      builder = _supabase.from('posts_view').select().eq('is_public', true).inFilter('user_id', connIds.toList()).order('created_at', ascending: false).range(offset, offset + limit - 1);
    } else if (feedType == 'popular') {
      builder = _supabase.from('posts_view').select().eq('is_public', true).gte('created_at', DateTime.now().subtract(const Duration(days: 7)).toIso8601String()).order('likes_count', ascending: false).range(offset, offset + limit - 1);
    }

    final res = await builder;
    final list = (res as List).map((e) => NetworkPost.fromJson({...e, 'image_urls': _imageUrlsFromRow(e)})).where((p) =>!hiddenSet.contains(p.id)).toList();
    return list;
  }

  Future<Set<String>> _getConnectionIds() async {
    final res = await _supabase.from('connections').select('connection_id').eq('user_id', currentUserId).eq('status', 'accepted');
    return (res as List).map((e) => e['connection_id'] as String).toSet();
  }

  // ─── POSTS ───
  Future<String> createPost(String content, List<String> images) async {
    final res = await _supabase.from('posts').insert({
      'user_id': currentUserId, 'content': content.trim(),
      'image_urls': images, 'media_url': images.isNotEmpty? images.first : null,
    }).select('id').single();
    notifyListeners();
    return res['id'] as String;
  }
  Future<void> deletePost(String id) async { await _supabase.from('posts').delete().eq('id', id); notifyListeners(); }
  Future<void> updatePost(String id, String c) async { await _supabase.from('posts').update({'content': c.trim()}).eq('id', id); notifyListeners(); }
  Future<void> hidePost(String id) async { await _supabase.from('hidden_posts').upsert({'post_id': id, 'user_id': currentUserId}, onConflict: 'post_id,user_id'); notifyListeners(); }
  Future<void> likePost(String id) async { await _supabase.from('post_likes').upsert({'post_id': id, 'user_id': currentUserId}, onConflict: 'post_id,user_id'); notifyListeners(); }
  Future<void> unlikePost(String id) async { await _supabase.from('post_likes').delete().eq('post_id', id).eq('user_id', currentUserId); notifyListeners(); }
  Future<void> sharePost(String id) async { await _supabase.rpc('increment_share', params: {'p_post_id': id}); }

  // ─── STORIES ───
  Future<List<NetworkStory>> getActiveStories() async {
    final res = await _supabase.from('stories').select('*, profiles!user_id(display_name, avatar_url)').eq('is_active', true).gte('expires_at', DateTime.now().toIso8601String()).order('created_at', ascending: false).limit(30);
    return (res as List).map((e) => NetworkStory.fromJson({...e, 'image_url': e['media_url']?? '', 'userName': e['profiles']?['display_name'], 'userAvatar': e['profiles']?['avatar_url']})).toList();
  }
  Future<void> createStory(String mediaUrl, {String mediaType = 'image', int duration = 24}) async {
    await _supabase.from('stories').insert({
      'user_id': currentUserId, 'media_url': mediaUrl, 'media_type': mediaType, 'is_active': true,
      'created_at': DateTime.now().toIso8601String(),
      'expires_at': DateTime.now().add(Duration(hours: duration.clamp(6, 48))).toIso8601String(),
    }); notifyListeners();
  }

  // ─── SAVE / REPOST / PIN / REPORT ───
  Future<void> savePost(String postId) async { await _supabase.from('saved_posts').upsert({'post_id': postId, 'user_id': currentUserId, 'saved_at': DateTime.now().toIso8601String()}, onConflict: 'post_id,user_id'); notifyListeners(); }
  Future<void> unsavePost(String postId) async { await _supabase.from('saved_posts').delete().eq('post_id', postId).eq('user_id', currentUserId); notifyListeners(); }
  Future<void> repost(String originalPostId, String? quote) async { await _supabase.from('reposts').insert({'original_post_id': originalPostId, 'user_id': currentUserId, 'quote': quote, 'created_at': DateTime.now().toIso8601String()}); notifyListeners(); }
  Future<void> pinPost(String postId) async { await _supabase.from('posts').update({'is_pinned': false}).eq('user_id', currentUserId).eq('is_pinned', true); await _supabase.from('posts').update({'is_pinned': true}).eq('id', postId); notifyListeners(); }
  Future<void> reportPost(String postId, String reason) async { await _supabase.from('reported_posts').insert({'post_id': postId, 'user_id': currentUserId, 'reason': reason, 'reported_at': DateTime.now().toIso8601String()}); }

  Future<String?> uploadImageBytes(Uint8List bytes, {required String fileExtension, String bucket = 'post_images'}) async {
    try { final name='${DateTime.now().millisecondsSinceEpoch}.$fileExtension'; final path='$currentUserId/$name'; await _supabase.storage.from(bucket).uploadBinary(path, bytes, fileOptions: FileOptions(contentType: 'image/$fileExtension', upsert: true)); return _supabase.storage.from(bucket).getPublicUrl(path); } catch (e){ debugPrint('upload $e'); return null; }
  }

  // ─── USERS ───
  Future<List<Map<String,dynamic>>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];
    final res = await _supabase.from('profiles').select('id, display_name, avatar_url, email').ilike('display_name', '%$query%').limit(10);
    return List<Map<String,dynamic>>.from(res as List);
  }

  // ─── COMMENTS - MANQUAIENT = BUILD FAIL ───
  Future<Map<String,dynamic>?> addComment(String postId, String content, {String? parentId}) async {
    if (_uid == null) return null;
    final res = await _supabase.from('comments').insert({
      'post_id': postId, 'user_id': _uid, 'content': content.trim(), 'parent_id': parentId,
      'created_at': DateTime.now().toIso8601String(),
    }).select('*, profiles!inner(display_name,avatar_url)').single();
    notifyListeners(); return res;
  }
  Future<bool> updateComment(String commentId, String newContent) async {
    try { await _supabase.from('comments').update({'content': newContent.trim(),'is_edited': true,'updated_at': DateTime.now().toIso8601String()}).eq('id', commentId).eq('user_id', _uid!); notifyListeners(); return true; } catch(e){ return false; }
  }
  Future<bool> deleteComment(String commentId) async { try{ await _supabase.from('comments').delete().eq('id', commentId); notifyListeners(); return true; }catch(_){ return false; } }
  Future<bool> likeComment(String commentId) async {
    if (_uid==null) return false;
    try{ await _supabase.from('comment_likes').upsert({'comment_id': commentId,'user_id': _uid,'created_at': DateTime.now().toIso8601String()}, onConflict: 'comment_id,user_id'); notifyListeners(); return true; }catch(e){ return false; }
  }
  Future<bool> unlikeComment(String commentId) async { try{ await _supabase.from('comment_likes').delete().eq('comment_id', commentId).eq('user_id', _uid!); notifyListeners(); return true; }catch(_){ return false; } }

  // ─── RESTE ───
  Future<List<NetworkConnection>> getSuggestedConnections({int limit = 5}) async {
    final res = await _supabase.rpc('get_suggested_connections', params: {'p_user_id': currentUserId, 'p_limit': limit});
    return (res as List).map((e) => NetworkConnection(id: e['id'], name: e['display_name'], avatar: e['avatar_url'], title: e['profession'], mutualConnections: e['mutual_count']??0)).toList();
  }
  Future<List<NetworkCommunity>> getAllCommunities({int limit = 20}) async {
    final res = await _supabase.from('communities_with_membership').select().eq('current_user_id', currentUserId).order('members_count', ascending: false).limit(limit);
    return (res as List).map((e) => NetworkCommunity.fromJson(e)).toList();
  }
  Future<void> sendConnectionRequest
