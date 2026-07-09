// lib/services/network_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import '../models/network_post.dart';
import '../models/network_connection.dart';
import '../models/network_community.dart';
import '../models/network_message.dart';
import '../models/network_notification.dart';
import '../models/network_story.dart';
import '../models/comment.dart'; // Ajout

class PostScore {
  final NetworkPost post;
  double score;
  PostScore(this.post, this.score);
}

class NetworkService {
  final SupabaseClient _supabase;
  NetworkService(this._supabase);
  String get currentUserId => _supabase.auth.currentUser?.id ?? '';

  static List<String> _imageUrlsFromRow(Map<String, dynamic> row) {
    if (row['image_urls'] != null) return List<String>.from(row['image_urls'] as List);
    final mediaUrl = row['media_url'] as String?;
    return mediaUrl != null && mediaUrl.isNotEmpty ? [mediaUrl] : [];
  }

  // ─── COMMENTAIRES AVEC RÉPONSES ───
  Future<List<Comment>> getCommentsWithReplies(String postId) async {
    try {
      final response = await _supabase
          .from('comments')
          .select('*, profiles!user_id(display_name, avatar_url)')
          .eq('post_id', postId)
          .order('created_at', ascending: false);
      final Map<String, Comment> commentMap = {};
      for (var json in response as List) {
        final c = Comment.fromJson(json);
        commentMap[c.id] = c;
      }
      final List<Comment> root = [];
      for (var c in commentMap.values) {
        if (c.parentId == null || c.parentId!.isEmpty) root.add(c);
        else {
          final parent = commentMap[c.parentId];
          if (parent != null) parent.replies.add(c);
          else root.add(c);
        }
      }
      return root;
    } catch (e) {
      debugPrint('❌ getCommentsWithReplies: $e');
      return [];
    }
  }

  Future<Comment> addComment(String postId, String content, {String? parentId}) async {
    final uid = currentUserId;
    if (uid.isEmpty) throw Exception('Not logged in');
    final response = await _supabase.from('comments').insert({
      'post_id': postId,
      'user_id': uid,
      'content': content,
      'parent_id': parentId,
      'created_at': DateTime.now().toIso8601String(),
    }).select('*, profiles!user_id(display_name, avatar_url)').single();
    if (parentId == null) {
      await _createNotification(userId: await _getPostOwnerId(postId), type: 'comment', postId: postId);
    }
    return Comment.fromJson(response);
  }

  Future<void> likeComment(String commentId) async {
    final uid = currentUserId;
    if (uid.isEmpty) return;
    await _supabase.from('comment_likes').insert({
      'comment_id': commentId,
      'user_id': uid,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> unlikeComment(String commentId) async {
    final uid = currentUserId;
    if (uid.isEmpty) return;
    await _supabase.from('comment_likes').delete().eq('comment_id', commentId).eq('user_id', uid);
  }

  Future<void> updateComment(String commentId, String newContent) async {
    final uid = currentUserId;
    if (uid.isEmpty) throw Exception('Not logged in');
    final comment = await _supabase.from('comments').select('user_id').eq('id', commentId).single();
    if (comment['user_id'] != uid) throw Exception('Not your comment');
    await _supabase.from('comments').update({
      'content': newContent,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', commentId);
  }

  // ─── POSTS FEED ───
  Future<List<NetworkPost>> getFeedPosts({int limit = 20, int start = 0}) async {
    try {
      final uid = currentUserId;
      if (uid.isEmpty) return [];
      final response = await _supabase
          .from('posts')
          .select('*, profiles:user_id(display_name, avatar_url, profession)')
          .eq('is_public', true)
          .order('created_at', ascending: false)
          .range(start, start + limit - 1);
      final posts = <NetworkPost>[];
      for (var e in response as List) {
        final likes = await _supabase.from('post_likes').select('id').eq('post_id', e['id']);
        final comments = await _supabase.from('comments').select('id').eq('post_id', e['id']);
        final liked = await _supabase.from('post_likes').select('id').eq('post_id', e['id']).eq('user_id', uid);
        posts.add(NetworkPost.fromJson({
          ...e,
          'author_name': e['profiles']?['display_name'] ?? 'Utilisateur',
          'author_avatar': e['profiles']?['avatar_url'],
          'author_title': e['profiles']?['profession'],
          'likes_count': (likes as List).length,
          'comments_count': (comments as List).length,
          'is_liked': (liked as List).isNotEmpty,
          'image_urls': _imageUrlsFromRow(e),
        }));
      }
      return posts;
    } catch (e, s) {
      debugPrint('❌ getFeedPosts: $e\n$s');
      return [];
    }
  }

  Future<List<NetworkPost>> getSmartFeed({int limit = 20}) async {
    try {
      final uid = currentUserId;
      if (uid.isEmpty) return [];
      final response = await _supabase
          .from('posts')
          .select('*, profiles:user_id(display_name, avatar_url, profession)')
          .eq('is_public', true)
          .limit(100);
      final connections = await _supabase.from('connections').select('connection_id').eq('user_id', uid).eq('status', 'accepted');
      final connected = (connections as List).map((c) => c['connection_id'] as String).toSet();
      final scored = <PostScore>[];
      for (var e in response as List) {
        final likes = await _supabase.from('post_likes').select('id').eq('post_id', e['id']);
        final comments = await _supabase.from('comments').select('id').eq('post_id', e['id']);
        final liked = await _supabase.from('post_likes').select('id').eq('post_id', e['id']).eq('user_id', uid);
        final post = NetworkPost.fromJson({
          ...e,
          'author_name': e['profiles']?['display_name'] ?? 'Utilisateur',
          'author_avatar': e['profiles']?['avatar_url'],
          'author_title': e['profiles']?['profession'],
          'likes_count': (likes as List).length,
          'comments_count': (comments as List).length,
          'is_liked': (liked as List).isNotEmpty,
          'image_urls': _imageUrlsFromRow(e),
        });
        double score = 0;
        score += post.likesCount * 1.0 + post.commentsCount * 3.0;
        final age = DateTime.now().difference(post.createdAt).inMinutes;
        score += 100.0 / (age + 10);
        if (connected.contains(post.userId)) score += 50;
        final hours = age / 60;
        if (hours > 0) {
          final engagement = (post.likesCount + post.commentsCount) / hours;
          if (engagement > 10) score += 40;
          else if (engagement > 5) score += 20;
          else if (engagement > 1) score += 10;
        }
        if (post.userId == uid) score += 1000;
        score += (DateTime.now().millisecondsSinceEpoch % 100) / 100 * 30;
        scored.add(PostScore(post, score));
      }
      scored.sort((a, b) => b.score.compareTo(a.score));
      return scored.take(limit).map((e) => e.post).toList();
    } catch (e) {
      debugPrint('❌ getSmartFeed: $e');
      return [];
    }
  }

  Future<NetworkPost?> getPostById(String postId) async {
    try {
      final uid = currentUserId;
      if (uid.isEmpty) return null;
      final response = await _supabase
          .from('posts')
          .select('*, profiles:user_id(display_name, avatar_url, profession)')
          .eq('id', postId)
          .maybeSingle();
      if (response == null) return null;
      final likes = await _supabase.from('post_likes').select('id').eq('post_id', postId);
      final comments = await _supabase.from('comments').select('id').eq('post_id', postId);
      final liked = await _supabase.from('post_likes').select('id').eq('post_id', postId).eq('user_id', uid);
      return NetworkPost.fromJson({
        ...response,
        'author_name': response['profiles']?['display_name'] ?? 'Utilisateur',
        'author_avatar': response['profiles']?['avatar_url'],
        'author_title': response['profiles']?['profession'],
        'likes_count': (likes as List).length,
        'comments_count': (comments as List).length,
        'is_liked': (liked as List).isNotEmpty,
        'image_urls': _imageUrlsFromRow(response),
      });
    } catch (e) {
      debugPrint('❌ getPostById: $e');
      return null;
    }
  }

  Future<String> createPost(String content, List<String> images) async {
    final uid = currentUserId;
    if (uid.isEmpty) throw Exception('Not logged in');
    final response = await _supabase.from('posts').insert({
      'user_id': uid,
      'content': content,
      'media_url': images.isNotEmpty ? images[0] : null,
      'media_type': images.isNotEmpty ? 'image' : 'none',
      'is_public': true,
      'created_at': DateTime.now().toIso8601String(),
    }).select('id').single();
    return response['id'] as String;
  }

  Future<String> createCommunityPost({required String communityId, required String content, List<String> images = const []}) async {
    final uid = currentUserId;
    if (uid.isEmpty) throw Exception('Not logged in');
    final response = await _supabase.from('posts').insert({
      'user_id': uid,
      'community_id': communityId,
      'content': content,
      'media_url': images.isNotEmpty ? images[0] : null,
      'media_type': images.isNotEmpty ? 'image' : 'none',
      'created_at': DateTime.now().toIso8601String(),
    }).select('id').single();
    return response['id'] as String;
  }

  Future<void> updatePost(String postId, String newContent) async {
    final uid = currentUserId;
    if (uid.isEmpty) throw Exception('Not logged in');
    final post = await _supabase.from('posts').select('user_id').eq('id', postId).single();
    if (post['user_id'] != uid) throw Exception('Not your post');
    await _supabase.from('posts').update({
      'content': newContent,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', postId);
  }

  Future<void> deletePost(String postId) async {
    final uid = currentUserId;
    if (uid.isEmpty) throw Exception('Not logged in');
    final post = await _supabase.from('posts').select('user_id').eq('id', postId).single();
    if (post['user_id'] != uid) throw Exception('Not your post');
    await _supabase.from('posts').delete().eq('id', postId);
  }

  Future<void> hidePost(String postId) async {
    final uid = currentUserId;
    if (uid.isEmpty) return;
    await _supabase.from('hidden_posts').insert({
      'post_id': postId,
      'user_id': uid,
      'hidden_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> reportPost(String postId, String reason) async {
    final uid = currentUserId;
    if (uid.isEmpty) return;
    await _supabase.from('reported_posts').insert({
      'post_id': postId,
      'user_id': uid,
      'reason': reason,
      'reported_at': DateTime.now().toIso8601String(),
    });
  }

  // ─── INTERACTIONS ───
  Future<void> likePost(String postId) async {
    final uid = currentUserId;
    if (uid.isEmpty) return;
    await _supabase.from('post_likes').insert({
      'post_id': postId,
      'user_id': uid,
      'created_at': DateTime.now().toIso8601String(),
    });
    await _createNotification(userId: await _getPostOwnerId(postId), type: 'like', postId: postId);
  }

  Future<void> unlikePost(String postId) async {
    final uid = currentUserId;
    if (uid.isEmpty) return;
    await _supabase.from('post_likes').delete().eq('post_id', postId).eq('user_id', uid);
  }

  // addComment avec parentId (remplace l'ancienne)
  Future<bool> addCommentToPost(String postId, String comment) async {
    try {
      await addComment(postId, comment);
      return true;
    } catch (e) {
      debugPrint('❌ addCommentToPost: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getComments(String postId) async {
    try {
      final response = await _supabase
          .from('comments')
          .select('*, profiles!user_id(id, display_name, avatar_url)')
          .eq('post_id', postId)
          .order('created_at', ascending: true);
      return (response as List).map((e) => {
        'id': e['id'],
        'user_id': e['user_id'],
        'user_name': e['profiles']['display_name'],
        'user_avatar': e['profiles']['avatar_url'],
        'content': e['content'],
        'created_at': e['created_at'],
      }).toList();
    } catch (e) {
      debugPrint('Error getComments: $e');
      return [];
    }
  }

  Future<void> deleteComment(String commentId) async {
    final uid = currentUserId;
    if (uid.isEmpty) return;
    final comment = await _supabase.from('comments').select('user_id').eq('id', commentId).single();
    if (comment['user_id'] != uid) throw Exception('Not your comment');
    await _supabase.from('comments').delete().eq('id', commentId);
  }

  Future<void> sharePost(String postId) async {
    try {
      final uid = currentUserId;
      if (uid.isEmpty) return;
      final post = await _supabase.from('posts').select('shares_count').eq('id', postId).maybeSingle();
      if (post != null) {
        final current = post['shares_count'] ?? 0;
        await _supabase.from('posts').update({'shares_count': current + 1}).eq('id', postId);
      }
    } catch (e) { debugPrint('Error sharePost: $e'); }
  }

  Future<String> _getPostOwnerId(String postId) async {
    final response = await _supabase.from('posts').select('user_id').eq('id', postId).single();
    return response['user_id'];
  }

  // ─── PIN ───
  Future<void> pinPost(String postId) async {
    final uid = currentUserId;
    if (uid.isEmpty) return;
    await _supabase.from('posts').update({'is_pinned': false}).eq('user_id', uid).eq('is_pinned', true);
    await _supabase.from('posts').update({'is_pinned': true}).eq('id', postId);
  }

  Future<NetworkPost?> getPinnedPost(String userId) async {
    final response = await _supabase
        .from('posts')
        .select('*, profiles:user_id(display_name, avatar_url, profession)')
        .eq('user_id', userId)
        .eq('is_pinned', true)
        .maybeSingle();
    if (response == null) return null;
    return NetworkPost.fromJson({
      ...response,
      'author_name': response['profiles']?['display_name'],
      'author_avatar': response['profiles']?['avatar_url'],
      'author_title': response['profiles']?['profession'],
    });
  }

  Future<List<NetworkPost>> getPinnedPosts(String userId) async {
    final response = await _supabase
        .from('posts')
        .select('*, profiles:user_id(display_name, avatar_url, profession)')
        .eq('user_id', userId)
        .eq('is_pinned', true)
        .order('created_at', ascending: false);
    return (response as List).map((e) => NetworkPost.fromJson({
      ...e,
      'author_name': e['profiles']?['display_name'],
      'author_avatar': e['profiles']?['avatar_url'],
      'author_title': e['profiles']?['profession'],
    })).toList();
  }

  Future<void> unpinPost(String postId) async {
    await _supabase.from('posts').update({'is_pinned': false}).eq('id', postId);
  }

  // ─── SAVE ───
  Future<void> savePost(String postId) async {
    final uid = currentUserId;
    if (uid.isEmpty) return;
    final existing = await _supabase.from('saved_posts').select('id').eq('post_id', postId).eq('user_id', uid).maybeSingle();
    if (existing == null) {
      await _supabase.from('saved_posts').insert({
        'post_id': postId,
        'user_id': uid,
        'saved_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> unsavePost(String postId) async {
    final uid = currentUserId;
    if (uid.isEmpty) return;
    await _supabase.from('saved_posts').delete().eq('post_id', postId).eq('user_id', uid);
  }

  Future<List<NetworkPost>> getSavedPosts() async {
    final uid = currentUserId;
    final response = await _supabase
        .from('saved_posts')
        .select('post:post_id(*)')
        .eq('user_id', uid)
        .order('saved_at', ascending: false);
    return (response as List).map((e) => NetworkPost.fromJson(e['post'])).toList();
  }

  // ─── REPOST ───
  Future<void> repost(String originalPostId, String? quote) async {
    final uid = currentUserId;
    await _supabase.from('reposts').insert({
      'original_post_id': originalPostId,
      'user_id': uid,
      'quote': quote,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<NetworkPost>> getUserReposts(String userId) async {
    final response = await _supabase
        .from('reposts')
        .select('post:original_post_id(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (response as List).map((e) => NetworkPost.fromJson(e['post'])).toList();
  }

  // ─── STORIES ───
  Future<List<NetworkStory>> getActiveStories() async {
    try {
      final uid = currentUserId;
      if (uid.isEmpty) return [];
      NetworkStory.setCurrentUserId(uid);
      final response = await _supabase
          .from('stories')
          .select('*, profiles!user_id(display_name, avatar_url, profession)')
          .eq('is_active', true)
          .gte('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false);
      return (response as List).map((e) {
        final user = e['profiles'] as Map<String, dynamic>?;
        return NetworkStory.fromJson({
          ...e,
          'image_url': e['image_url'] ?? e['media_url'] ?? '',
          'profiles': user != null ? {
            'display_name': user['display_name'],
            'avatar_url': user['avatar_url'],
            'title': user['profession'],
          } : null,
        });
      }).toList();
    } catch (e) {
      debugPrint('Error getActiveStories: $e');
      return [];
    }
  }

  Future<void> createStory(String mediaUrl, {String mediaType = 'image', int duration = 24}) async {
    final uid = currentUserId;
    if (uid.isEmpty) return;
    await _supabase.from('stories').insert({
      'user_id': uid,
      'media_url': mediaUrl,
      'media_type': mediaType,
      'is_active': true,
      'created_at': DateTime.now().toIso8601String(),
      'expires_at': DateTime.now().add(Duration(hours: duration)).toIso8601String(),
    });
  }

  Future<void> deleteStory(String storyId) async {
    final uid = currentUserId;
    if (uid.isEmpty) return;
    await _supabase.from('stories').delete().eq('id', storyId).eq('user_id', uid);
  }

  Future<void> markStoryAsViewed(String storyId) async {
    final uid = currentUserId;
    if (uid.isEmpty) return;
    final existing = await _supabase.from('story_views').select('id').eq('story_id', storyId).eq('user_id', uid);
    if ((existing as List).isEmpty) {
      await _supabase.from('story_views').insert({
        'story_id': storyId,
        'user_id': uid,
        'viewed_at': DateTime.now().toIso8601String(),
      });
    }
  }

  // ─── HIGHLIGHTS ───
  Future<List<Highlight>> getUserHighlights(String userId) async {
    final response = await _supabase
        .from('story_highlights')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (response as List).map((e) => Highlight(
      id: e['id'],
      name: e['name'],
      coverImage: e['cover_image'],
      storyIds: List<String>.from(e['story_ids']),
      createdAt: DateTime.parse(e['created_at']),
    )).toList();
  }

  Future<void> createHighlight(String name, List<String> storyIds, String? coverImage) async {
    final uid = currentUserId;
    await _supabase.from('story_highlights').insert({
      'user_id': uid,
      'name': name,
      'cover_image': coverImage,
      'story_ids': storyIds,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // ─── UPLOAD ───
  Future<String?> uploadImageBytes(Uint8List bytes, {required String fileExtension, String bucket = 'post_images'}) async {
    try {
      final uid = currentUserId;
      if (uid.isEmpty) return null;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final path = '$uid/$fileName';
      await _supabase.storage.from(bucket).uploadBinary(path, bytes);
      return _supabase.storage.from(bucket).getPublicUrl(path);
    } catch (e) {
      debugPrint('Error uploading: $e');
      return null;
    }
  }

  Future<void> deleteImage(String imageUrl, {String bucket = 'post_images'}) async {
    try {
      final uri = Uri.parse(imageUrl);
      final segments = uri.pathSegments;
      final idx = segments.indexOf(bucket);
      if (idx != -1 && idx + 1 < segments.length) {
        final path = segments.sublist(idx + 1).join('/');
        await _supabase.storage.from(bucket).remove([path]);
      }
    } catch (e) { debugPrint('Error deleting image: $e'); }
  }

  // ─── COMMUNAUTÉS ───
  Future<NetworkCommunity> createCommunity({required String name, String? description, String? bannerUrl}) async {
    final uid = currentUserId;
    if (uid.isEmpty) throw Exception('Not logged in');
    final response = await _supabase.from('communities').insert({
      'name': name,
      'description': description,
      'logo_url': bannerUrl,
      'created_by': uid,
      'created_at': DateTime.now().toIso8601String(),
      'members_count': 1,
      'posts_count': 0,
    }).select().single();
    await _supabase.from('community_members').insert({
      'community_id': response['id'],
      'user_id': uid,
      'role': 'admin',
      'joined_at': DateTime.now().toIso8601String(),
    });
    return NetworkCommunity.fromJson(response);
  }

  Future<List<NetworkCommunity>> getAllCommunities({int limit = 50}) async {
    try {
      final uid = currentUserId;
      final response = await _supabase.from('communities').select('*').order('members_count', ascending: false).limit(limit);
      final communities = <NetworkCommunity>[];
      for (var e in response as List) {
        final member = await _supabase.from('community_members').select('id').eq('community_id', e['id']).eq('user_id', uid);
        communities.add(NetworkCommunity.fromJson({...e, 'is_member': (member as List).isNotEmpty}));
      }
      return communities;
    } catch (e) { debugPrint('Error getAllCommunities: $e'); return []; }
  }

  Future<List<NetworkCommunity>> getSuggestedCommunities({int limit = 10}) async {
    try {
      final uid = currentUserId;
      final response = await _supabase.from('communities').select('*').order('members_count', ascending: false).limit(limit);
      final list = <NetworkCommunity>[];
      for (var e in response as List) {
        final member = await _supabase.from('community_members').select('id').eq('community_id', e['id']).eq('user_id', uid);
        if ((member as List).isEmpty) {
          list.add(NetworkCommunity.fromJson({...e, 'is_member': false}));
        }
      }
      return list;
    } catch (e) { debugPrint('Error getSuggestedCommunities: $e'); return []; }
  }

  Future<List<NetworkCommunity>> getMyCommunities() async {
    try {
      final uid = currentUserId;
      if (uid.isEmpty) return [];
      final response = await _supabase.from('community_members').select('community_id').eq('user_id', uid);
      final communities = <NetworkCommunity>[];
      for (var m in response as List) {
        final data = await _supabase.from('communities').select('*').eq('id', m['community_id']).single();
        communities.add(NetworkCommunity.fromJson({...data, 'is_member': true}));
      }
      return communities;
    } catch (e) { debugPrint('Error getMyCommunities: $e'); return []; }
  }

  Future<NetworkCommunity?> getCommunityById(String communityId) async {
    try {
      final uid = currentUserId;
      final response = await _supabase.from('communities').select('*').eq('id', communityId).single();
      final member = await _supabase.from('community_members').select('id').eq('community_id', communityId).eq('user_id', uid);
      return NetworkCommunity.fromJson({...response, 'is_member': (member as List).isNotEmpty});
    } catch (e) { debugPrint('Error getCommunityById: $e'); return null; }
  }

  Future<void> joinCommunity(String communityId) async {
    final uid = currentUserId;
    if (uid.isEmpty) return;
    final existing = await _supabase.from('community_members').select('id').eq('community_id', communityId).eq('user_id', uid);
    if ((existing as List).isEmpty) {
      await _supabase.from('community_members').insert({
        'community_id': communityId,
        'user_id': uid,
        'role': 'member',
        'joined_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> leaveCommunity(String communityId) async {
    final uid = currentUserId;
    if (uid.isEmpty) return;
    final admin = await _isCommunityAdmin(communityId, uid);
    if (admin) throw Exception('Admins cannot leave');
    await _supabase.from('community_members').delete().eq('community_id', communityId).eq('user_id', uid);
  }

  Future<bool> _isCommunityAdmin(String communityId, String userId) async {
    try {
      final response = await _supabase.from('community_members').select('role').eq('community_id', communityId).eq('user_id', userId);
      final list = response as List;
      return list.isNotEmpty && list[0]['role'] == 'admin';
    } catch (e) { return false; }
  }

  // ─── CONNEXIONS ───
  Future<List<NetworkConnection>> getSuggestedConnections({int limit = 10}) async {
    try {
      final uid = currentUserId;
      if (uid.isEmpty) return [];
      final response = await _supabase.from('profiles').select('id, display_name, avatar_url, profession').neq('id', uid).limit(limit);
      final suggestions = <NetworkConnection>[];
      for (var user in response as List) {
        final mutual = await _supabase.from('connections').select('id').eq('user_id', uid).eq('connection_id', user['id']);
        suggestions.add(NetworkConnection(
          id: user['id'],
          name: user['display_name'] ?? 'Utilisateur',
          avatar: user['avatar_url'],
          title: user['profession'] ?? 'Membre',
          mutualConnections: (mutual as List).length,
        ));
      }
      return suggestions;
    } catch (e) { debugPrint('Error getSuggestedConnections: $e'); return []; }
  }

  Future<void> sendConnectionRequest(String targetUserId) async {
    final uid = currentUserId;
    if (uid.isEmpty) return;
    await _supabase.from('connection_requests').insert({
      'sender_id': uid,
      'receiver_id': targetUserId,
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });
    await _createNotification(userId: targetUserId, type: 'connection');
  }

  Future<void> acceptConnectionRequest(String requestId) async {
    await _supabase.from('connection_requests').update({'status': 'accepted'}).eq('id', requestId);
    final request = await _supabase.from('connection_requests').select('sender_id, receiver_id').eq('id', requestId).single();
    await _supabase.from('connections').insert({
      'user_id': request['sender_id'],
      'connection_id': request['receiver_id'],
      'status': 'accepted',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // ─── MESSAGES ───
  Future<List<Conversation>> getConversations() async {
    try {
      final uid = currentUserId;
      if (uid.isEmpty) return [];
      final response = await _supabase
          .from('messages')
          .select('''
            sender_id, receiver_id, content, created_at, is_read,
            sender:profiles!messages_sender_id(id, display_name, avatar_url),
            receiver:profiles!messages_receiver_id(id, display_name, avatar_url)
          ''')
          .or('sender_id.eq.$uid,receiver_id.eq.$uid')
          .order('created_at', ascending: false);
      final Map<String, Conversation> convs = {};
      for (var msg in response as List) {
        final otherId = msg['sender_id'] == uid ? msg['receiver_id'] : msg['sender_id'];
        final otherUser = msg['sender_id'] == uid ? msg['receiver'] : msg['sender'];
        if (!convs.containsKey(otherId)) {
          convs[otherId] = Conversation(
            id: otherId,
            otherUserId: otherId,
            otherUserName: otherUser?['display_name'] ?? 'Utilisateur',
            otherUserAvatar: otherUser?['avatar_url'],
            lastMessage: msg['content'],
            lastMessageAt: DateTime.parse(msg['created_at']),
            lastMessageIsFromMe: msg['sender_id'] == uid,
            unreadCount: (msg['is_read'] == false && msg['receiver_id'] == uid) ? 1 : 0,
          );
        }
      }
      return convs.values.toList();
    } catch (e) { debugPrint('Error getConversations: $e'); return []; }
  }

  Future<Map<String, dynamic>> sendMessage(String receiverId, String content) async {
    final uid = currentUserId;
    if (uid.isEmpty) throw Exception('Not logged in');
    final response = await _supabase.from('messages').insert({
      'sender_id': uid,
      'receiver_id': receiverId,
      'content': content,
      'is_read': false,
      'created_at': DateTime.now().toIso8601String(),
    }).select().single();
    return {
      'id': response['id'],
      'content': response['content'],
      'is_sent_by_me': true,
      'created_at': DateTime.parse(response['created_at']),
    };
  }

  Future<List<Map<String, dynamic>>> getMessages(String otherUserId) async {
    try {
      final uid = currentUserId;
      if (uid.isEmpty) return [];
      final response = await _supabase
          .from('messages')
          .select('*')
          .or('sender_id.eq.$uid,receiver_id.eq.$uid')
          .or('sender_id.eq.$otherUserId,receiver_id.eq.$otherUserId')
          .order('created_at', ascending: true);
      return (response as List).map((e) => ({
        'id': e['id'],
        'content': e['content'],
        'is_sent_by_me': e['sender_id'] == uid,
        'created_at': DateTime.parse(e['created_at']),
      })).toList();
    } catch (e) { debugPrint('Error getMessages: $e'); return []; }
  }

  Future<void> markMessagesAsRead(String otherUserId) async {
    try {
      final uid = currentUserId;
      if (uid.isEmpty) return;
      await _supabase.from('messages').update({'is_read': true}).eq('receiver_id', uid).eq('sender_id', otherUserId);
    } catch (e) { debugPrint('Error markMessagesAsRead: $e'); }
  }

  // ─── NOTIFICATIONS ───
  Future<List<NetworkNotification>> getNotifications() async {
    try {
      final uid = currentUserId;
      if (uid.isEmpty) return [];
      final response = await _supabase
          .from('notifications')
          .select('*, profiles!sender_id(display_name, avatar_url), posts!post_id(id, content)')
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(50);
      return (response as List).map((e) => NetworkNotification.fromJson(e)).toList();
    } catch (e) { debugPrint('Error getNotifications: $e'); return []; }
  }

  Future<int> getUnreadNotificationsCount() async {
    try {
      final uid = currentUserId;
      if (uid.isEmpty) return 0;
      final response = await _supabase.from('notifications').select('id').eq('user_id', uid).eq('is_read', false);
      return (response as List).length;
    } catch (e) { return 0; }
  }

  Future<int> getUnreadMessagesCount() async {
    try {
      final uid = currentUserId;
      if (uid.isEmpty) return 0;
      final response = await _supabase.from('messages').select('id').eq('receiver_id', uid).eq('is_read', false);
      return (response as List).length;
    } catch (e) { return 0; }
  }

  Future<void> markAllNotificationsAsRead() async {
    try {
      final uid = currentUserId;
      if (uid.isEmpty) return;
      await _supabase.from('notifications').update({'is_read': true}).eq('user_id', uid).eq('is_read', false);
    } catch (e) { debugPrint('Error markAllNotificationsAsRead: $e'); }
  }

  Future<void> _createNotification({required String userId, required String type, String? postId}) async {
    final uid = currentUserId;
    if (userId == uid) return;
    await _supabase.from('notifications').insert({
      'user_id': userId,
      'type': type,
      'sender_id': uid,
      'post_id': postId,
      'is_read': false,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // ─── PROFIL ───
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('id, display_name, avatar_url, profession, bio, skills')
          .eq('id', userId)
          .maybeSingle();
      if (response == null) return null;
      final posts = await _supabase.from('posts').select('id').eq('user_id', userId);
      final followers = await _supabase.from('connections').select('id').eq('connection_id', userId).eq('status', 'accepted');
      final following = await _supabase.from('connections').select('id').eq('user_id', userId).eq('status', 'accepted');
      return {
        ...response,
        'posts_count': (posts as List).length,
        'followers_count': (followers as List).length,
        'following_count': (following as List).length,
      };
    } catch (e) { debugPrint('Error getUserProfile: $e'); return null; }
  }

  Future<List<NetworkPost>> getUserPosts(String userId) async {
    try {
      final response = await _supabase
          .from('posts')
          .select('*, profiles!user_id(display_name, avatar_url, profession)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return (response as List).map((e) => NetworkPost.fromJson({
        ...e,
        'author_name': e['profiles']?['display_name'],
        'author_avatar': e['profiles']?['avatar_url'],
        'author_title': e['profiles']?['profession'],
        'likes_count': 0,
        'comments_count': 0,
        'is_liked': false,
      })).toList();
    } catch (e) { debugPrint('Error getUserPosts: $e'); return []; }
  }

  // ─── RECHERCHE ───
  Future<List<NetworkCommunity>> searchCommunities(String query) async {
    try {
      final uid = currentUserId;
      final response = await _supabase.from('communities').select('*').ilike('name', '%$query%').order('members_count', ascending: false).limit(20);
      final list = <NetworkCommunity>[];
      for (var e in response as List) {
        final member = await _supabase.from('community_members').select('id').eq('community_id', e['id']).eq('user_id', uid);
        list.add(NetworkCommunity.fromJson({...e, 'is_member': (member as List).isNotEmpty}));
      }
      return list;
    } catch (e) { debugPrint('Error searchCommunities: $e'); return []; }
  }

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      final response = await _supabase.from('profiles').select('id, display_name, avatar_url, profession').ilike('display_name', '%$query%').limit(20);
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) { debugPrint('Error searchUsers: $e'); return []; }
  }

  Future<List<Map<String, dynamic>>> searchPosts(String query) async {
    try {
      final response = await _supabase
          .from('posts')
          .select('id, content, created_at, profiles!user_id(display_name, avatar_url)')
          .ilike('content', '%$query%')
          .order('created_at', ascending: false)
          .limit(20);
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) { debugPrint('Error searchPosts: $e'); return []; }
  }

  // ─── ÉVÉNEMENTS ───
  Future<void> markEventInterest(String eventId) async {
    final uid = currentUserId;
    if (uid.isEmpty) return;
    final existing = await _supabase.from('event_interests').select('id').eq('event_id', eventId).eq('user_id', uid);
    if ((existing as List).isEmpty) {
      await _supabase.from('event_interests').insert({
        'event_id': eventId,
        'user_id': uid,
        'interested_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<bool> hasEventInterest(String eventId) async {
    try {
      final uid = currentUserId;
      if (uid.isEmpty) return false;
      final response = await _supabase.from('event_interests').select('id').eq('event_id', eventId).eq('user_id', uid);
      return (response as List).isNotEmpty;
    } catch (e) { return false; }
  }

  // ─── RECOMMANDATIONS ───
  Future<Map<String, int>> getRecommendationsCount() async {
    final uid = currentUserId;
    if (uid.isEmpty) return {'people': 0, 'opportunities': 0, 'communities': 0};
    try {
      final people = await _supabase.from('profiles').select('id').neq('id', uid).limit(10);
      final communities = await _supabase.from('communities').select('id').limit(10);
      return {
        'people': (people as List).length,
        'opportunities': 0,
        'communities': (communities as List).length,
      };
    } catch (e) { return {'people': 0, 'opportunities': 0, 'communities': 0}; }
  }
}

// ─── CLASSES AUXILIAIRES ───
class Highlight {
  final String id, name;
  final String? coverImage;
  final List<String> storyIds;
  final DateTime createdAt;
  Highlight({required this.id, required this.name, this.coverImage, required this.storyIds, required this.createdAt});
}

class Conversation {
  final String id, otherUserId, otherUserName, lastMessage;
  final String? otherUserAvatar;
  final DateTime lastMessageAt;
  final bool lastMessageIsFromMe;
  final int unreadCount;
  Conversation({
    required this.id,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.lastMessageIsFromMe,
    required this.unreadCount,
  });
}

class Repost {
  final String id, originalPostId, userId;
  final String? quote;
  final DateTime createdAt;
  Repost({required this.id, required this.originalPostId, required this.userId, this.quote, required this.createdAt});
  factory Repost.fromJson(Map<String, dynamic> json) => Repost(
    id: json['id'],
    originalPostId: json['original_post_id'],
    userId: json['user_id'],
    quote: json['quote'],
    createdAt: DateTime.parse(json['created_at']),
  );
}
