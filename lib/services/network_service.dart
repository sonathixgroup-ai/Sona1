// lib/services/network_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import '../models/network_post.dart';
import '../models/network_connection.dart';
import '../models/network_community.dart';
import '../models/network_message.dart';
import '../models/network_notification.dart';
import '../models/network_story.dart';
import 'dart:io';

// ============================================================
// CLASSE POSTSCORE
// ============================================================
class PostScore {
  final NetworkPost post;
  double score;
  PostScore(this.post, this.score);
}

class NetworkService {
  final SupabaseClient _supabase;

  NetworkService(this._supabase);

  String get currentUserId => _supabase.auth.currentUser?.id ?? '';

  // ============================================================
  // SECTION 1: POSTS - GET FEED
  // ============================================================

  Future<List<NetworkPost>> getFeedPosts({int limit = 20}) async {
    try {
      final currentUserId = this.currentUserId;
      if (currentUserId.isEmpty) return [];
      
      final response = await _supabase
          .from('posts')
          .select('''
            *,
            users:user_id (
              display_name,
              photo_url,
              profession
            )
          ''')
          .eq('is_public', true)
          .order('created_at', ascending: false)
          .limit(limit);
      
      final posts = <NetworkPost>[];
      for (var e in response as List) {
        final likesData = await _supabase
            .from('post_likes')
            .select('id')
            .eq('post_id', e['id']);
        
        final commentsData = await _supabase
            .from('comments')
            .select('id')
            .eq('post_id', e['id']);
        
        final likedData = await _supabase
            .from('post_likes')
            .select('id')
            .eq('post_id', e['id'])
            .eq('user_id', currentUserId);
        
        posts.add(NetworkPost.fromJson({
          ...e,
          'author_name': e['users']?['display_name'] ?? 'Utilisateur',
          'author_avatar': e['users']?['photo_url'],
          'author_title': e['users']?['profession'],
          'likes_count': (likesData as List).length,
          'comments_count': (commentsData as List).length,
          'is_liked': (likedData as List).isNotEmpty,
        }));
      }
      
      return posts;
    } catch (e) {
      debugPrint('❌ Error getFeedPosts: $e');
      return [];
    }
  }

  // ============================================================
  // SECTION 2: FEED INTELLIGENT (IA & ALGORITHME)
  // ============================================================

  Future<List<NetworkPost>> getSmartFeed({int limit = 20}) async {
    try {
      final currentUserId = this.currentUserId;
      if (currentUserId.isEmpty) return [];
      
      final response = await _supabase
          .from('posts')
          .select('''
            *,
            users:user_id (
              display_name,
              photo_url,
              profession
            )
          ''')
          .eq('is_public', true)
          .limit(100);
      
      final connections = await _supabase
          .from('connections')
          .select('connection_id')
          .eq('user_id', currentUserId)
          .eq('status', 'accepted');
      
      final connectedUserIds = (connections as List)
          .map((c) => c['connection_id'] as String)
          .toSet();
      
      final postsWithScores = <PostScore>[];
      
      for (var e in response as List) {
        final likesData = await _supabase
            .from('post_likes')
            .select('id')
            .eq('post_id', e['id']);
        
        final commentsData = await _supabase
            .from('comments')
            .select('id')
            .eq('post_id', e['id']);
        
        final userLikedData = await _supabase
            .from('post_likes')
            .select('id')
            .eq('post_id', e['id'])
            .eq('user_id', currentUserId);
        
        final userData = e['users'] as Map<String, dynamic>?;
        
        final post = NetworkPost.fromJson({
          ...e,
          'author_name': userData?['display_name'] ?? 'Utilisateur',
          'author_avatar': userData?['photo_url'],
          'author_title': userData?['profession'],
          'likes_count': (likesData as List).length,
          'comments_count': (commentsData as List).length,
          'is_liked': (userLikedData as List).isNotEmpty,
        });
        
        double score = 0;
        score += post.likesCount * 1.0;
        score += post.commentsCount * 3.0;
        
        final ageInMinutes = DateTime.now().difference(post.createdAt).inMinutes;
        final recencyScore = 100.0 / (ageInMinutes + 10);
        score += recencyScore;
        
        if (connectedUserIds.contains(post.userId)) score += 50;
        
        final hoursSincePost = ageInMinutes / 60;
        if (hoursSincePost > 0) {
          final engagementRate = (post.likesCount + post.commentsCount) / hoursSincePost;
          if (engagementRate > 10) score += 40;
          else if (engagementRate > 5) score += 20;
          else if (engagementRate > 1) score += 10;
        }
        
        final previousLikes = await _supabase
            .from('post_likes')
            .select('id')
            .eq('user_id', currentUserId)
            .inFilter('post_id', 
                (await _supabase.from('posts').select('id').eq('user_id', post.userId) as List)
                    .map((p) => p['id'] as String).toList());
        if ((previousLikes as List).isNotEmpty) {
          score += 15 * previousLikes.length.clamp(0, 3);
        }
        
        final random = DateTime.now().millisecondsSinceEpoch % 100 / 100;
        score += random * 30;
        
        postsWithScores.add(PostScore(post, score));
      }
      
      postsWithScores.sort((a, b) => b.score.compareTo(a.score));
      return postsWithScores.take(limit).map((e) => e.post).toList();
    } catch (e) {
      debugPrint('❌ Error getSmartFeed: $e');
      return [];
    }
  }

  // ============================================================
  // SECTION 3: POST INDIVIDUEL (GET, CREATE, UPDATE, DELETE)
  // ============================================================

  Future<NetworkPost?> getPostById(String postId) async {
    try {
      final currentUserId = this.currentUserId;
      if (currentUserId.isEmpty) return null;
      
      final response = await _supabase
          .from('posts')
          .select('''
            *,
            users:user_id (
              display_name,
              photo_url,
              profession
            )
          ''')
          .eq('id', postId)
          .maybeSingle();
      
      if (response == null) return null;
      
      final likesData = await _supabase
          .from('post_likes')
          .select('id')
          .eq('post_id', postId);
      
      final commentsData = await _supabase
          .from('comments')
          .select('id')
          .eq('post_id', postId);
      
      final userLikedData = await _supabase
          .from('post_likes')
          .select('id')
          .eq('post_id', postId)
          .eq('user_id', currentUserId);
      
      final userData = response['users'] as Map<String, dynamic>?;
      
      return NetworkPost.fromJson({
        ...response,
        'author_name': userData?['display_name'] ?? 'Utilisateur',
        'author_avatar': userData?['photo_url'],
        'author_title': userData?['profession'],
        'likes_count': (likesData as List).length,
        'comments_count': (commentsData as List).length,
        'is_liked': (userLikedData as List).isNotEmpty,
      });
    } catch (e) {
      debugPrint('❌ Error getPostById: $e');
      return null;
    }
  }

  Future<String> createPost(String content, List<String> images) async {
    final currentUserId = this.currentUserId;
    if (currentUserId.isEmpty) throw Exception('User not logged in');
    
    debugPrint('📝 createPost: création du post...');
    
    final response = await _supabase.from('posts').insert({
      'user_id': currentUserId,
      'content': content,
      'media_url': images.isNotEmpty ? images[0] : null,
      'media_type': images.isNotEmpty ? 'image' : 'none',
      'is_public': true,
      'created_at': DateTime.now().toIso8601String(),
    }).select('id').single();
    
    final postId = response['id'] as String;
    debugPrint('✅ createPost: post créé avec ID: $postId');
    
    return postId;
  }

  Future<String> createCommunityPost({
    required String communityId,
    required String content,
    List<String> images = const [],
  }) async {
    final currentUserId = this.currentUserId;
    if (currentUserId.isEmpty) throw Exception('User not logged in');
    
    debugPrint('📝 createCommunityPost: création du post dans la communauté $communityId');
    
    final response = await _supabase.from('posts').insert({
      'user_id': currentUserId,
      'community_id': communityId,
      'content': content,
      'media_url': images.isNotEmpty ? images[0] : null,
      'media_type': images.isNotEmpty ? 'image' : 'none',
      'created_at': DateTime.now().toIso8601String(),
    }).select('id').single();
    
    final postId = response['id'] as String;
    debugPrint('✅ createCommunityPost: post créé avec ID: $postId');
    
    return postId;
  }

  Future<void> updatePost(String postId, String newContent) async {
    final currentUserId = this.currentUserId;
    if (currentUserId.isEmpty) throw Exception('User not logged in');
    
    final post = await _supabase
        .from('posts')
        .select('user_id')
        .eq('id', postId)
        .single();
    
    if (post['user_id'] != currentUserId) {
      throw Exception('Vous ne pouvez pas modifier cette publication');
    }
    
    await _supabase
        .from('posts')
        .update({
          'content': newContent,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', postId);
    
    debugPrint('✏️ updatePost: post $postId modifié');
  }

  Future<void> deletePost(String postId) async {
    final currentUserId = this.currentUserId;
    if (currentUserId.isEmpty) throw Exception('User not logged in');
    
    final post = await _supabase
        .from('posts')
        .select('user_id')
        .eq('id', postId)
        .single();
    
    if (post['user_id'] != currentUserId) {
      throw Exception('Vous ne pouvez pas supprimer cette publication');
    }
    
    await _supabase.from('posts').delete().eq('id', postId);
    debugPrint('🗑️ deletePost: post $postId supprimé');
  }

  Future<void> hidePost(String postId) async {
    final currentUserId = this.currentUserId;
    if (currentUserId.isEmpty) return;
    
    await _supabase.from('hidden_posts').insert({
      'post_id': postId,
      'user_id': currentUserId,
      'hidden_at': DateTime.now().toIso8601String(),
    });
    debugPrint('🙈 hidePost: post $postId masqué');
  }

  Future<void> reportPost(String postId, String reason) async {
    final currentUserId = this.currentUserId;
    if (currentUserId.isEmpty) return;
    
    await _supabase.from('reported_posts').insert({
      'post_id': postId,
      'user_id': currentUserId,
      'reason': reason,
      'reported_at': DateTime.now().toIso8601String(),
    });
    debugPrint('🚨 reportPost: post $postId signalé pour: $reason');
  }

  // ============================================================
  // SECTION 4: INTERACTIONS (LIKES, COMMENTAIRES, PARTAGES)
  // ============================================================

  Future<void> likePost(String postId) async {
    final currentUserId = this.currentUserId;
    if (currentUserId.isEmpty) return;
    
    await _supabase.from('post_likes').insert({
      'post_id': postId,
      'user_id': currentUserId,
      'created_at': DateTime.now().toIso8601String(),
    });
    
    await _createNotification(
      userId: await _getPostOwnerId(postId),
      type: 'like',
      postId: postId,
    );
  }

  Future<void> unlikePost(String postId) async {
    final currentUserId = this.currentUserId;
    if (currentUserId.isEmpty) return;
    
    await _supabase
        .from('post_likes')
        .delete()
        .eq('post_id', postId)
        .eq('user_id', currentUserId);
  }

  Future<void> addComment(String postId, String content) async {
    final currentUserId = this.currentUserId;
    if (currentUserId.isEmpty) return;
    
    await _supabase.from('comments').insert({
      'post_id': postId,
      'user_id': currentUserId,
      'content': content,
      'created_at': DateTime.now().toIso8601String(),
    });
    
    await _createNotification(
      userId: await _getPostOwnerId(postId),
      type: 'comment',
      postId: postId,
    );
  }

  // ✅ AJOUTÉ: Alias pour addComment qui retourne un booléen
  // Utilisé par FeedProvider.addComment()
  Future<bool> addCommentToPost(String postId, String comment) async {
    try {
      await addComment(postId, comment);
      debugPrint('✅ addCommentToPost: commentaire ajouté avec succès');
      return true;
    } catch (e) {
      debugPrint('❌ addCommentToPost error: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getComments(String postId) async {
    try {
      final response = await _supabase
          .from('comments')
          .select('''
            *,
            users!user_id (
              id,
              display_name,
              photo_url
            )
          ''')
          .eq('post_id', postId)
          .order('created_at', ascending: true);
      
      return (response as List).map((e) => {
        'id': e['id'],
        'user_id': e['user_id'],
        'user_name': e['users']['display_name'],
        'user_avatar': e['users']['photo_url'],
        'content': e['content'],
        'created_at': e['created_at'],
      }).toList();
    } catch (e) {
      debugPrint('Error getComments: $e');
      return [];
    }
  }

  Future<void> deleteComment(String commentId) async {
    final currentUserId = this.currentUserId;
    if (currentUserId.isEmpty) return;
    
    final comment = await _supabase
        .from('comments')
        .select('user_id')
        .eq('id', commentId)
        .single();
    
    if (comment['user_id'] != currentUserId) {
      throw Exception('Vous ne pouvez pas supprimer ce commentaire');
    }
    
    await _supabase.from('comments').delete().eq('id', commentId);
  }

  Future<void> sharePost(String postId) async {
    try {
      final currentUserId = this.currentUserId;
      if (currentUserId.isEmpty) return;
      
      final post = await _supabase
          .from('posts')
          .select('shares_count')
          .eq('id', postId)
          .maybeSingle();
      
      if (post != null) {
        int currentShares = post['shares_count'] ?? 0;
        await _supabase
            .from('posts')
            .update({'shares_count': currentShares + 1})
            .eq('id', postId);
      }
      
      debugPrint('📤 sharePost: post $postId partagé');
    } catch (e) {
      debugPrint('Error sharePost: $e');
    }
  }

  Future<String> _getPostOwnerId(String postId) async {
    final response = await _supabase
        .from('posts')
        .select('user_id')
        .eq('id', postId)
        .single();
    return response['user_id'];
  }

  // ============================================================
  // SECTION 5: ÉPINGLER LES POSTS
  // ============================================================

  Future<void> pinPost(String postId) async {
    final currentUserId = this.currentUserId;
    if (currentUserId.isEmpty) return;
    
    await _supabase
        .from('posts')
        .update({'is_pinned': false})
        .eq('user_id', currentUserId)
        .eq('is_pinned', true);
    
    await _supabase
        .from('posts')
        .update({'is_pinned': true})
        .eq('id', postId);
  }

  Future<NetworkPost?> getPinnedPost(String userId) async {
    final response = await _supabase
        .from('posts')
        .select('*, users:user_id(display_name, photo_url, profession)')
        .eq('user_id', userId)
        .eq('is_pinned', true)
        .maybeSingle();
    
    if (response == null) return null;
    return NetworkPost.fromJson(response);
  }

  Future<List<NetworkPost>> getPinnedPosts(String userId) async {
    final response = await _supabase
        .from('posts')
        .select('*, users:user_id(display_name, photo_url, profession)')
        .eq('user_id', userId)
        .eq('is_pinned', true)
        .order('created_at', ascending: false);
    
    return (response as List).map((e) => NetworkPost.fromJson(e)).toList();
  }

  Future<void> unpinPost(String postId) async {
    await _supabase
        .from('posts')
        .update({'is_pinned': false})
        .eq('id', postId);
  }

  // ============================================================
  // SECTION 6: SAUVEGARDER LES POSTS
  // ============================================================

  Future<void> savePost(String postId) async {
    final currentUserId = this.currentUserId;
    if (currentUserId.isEmpty) return;
    
    try {
      final existing = await _supabase
          .from('saved_posts')
          .select('id')
          .eq('post_id', postId)
          .eq('user_id', currentUserId)
          .maybeSingle();
      
      if (existing == null) {
        await _supabase.from('saved_posts').insert({
          'post_id': postId,
          'user_id': currentUserId,
          'saved_at': DateTime.now().toIso8601String(),
        });
        debugPrint('💾 savePost: post $postId sauvegardé');
      }
    } catch (e) {
      debugPrint('❌ Error savePost: $e');
    }
  }

  Future<void> unsavePost(String postId) async {
    final currentUserId = this.currentUserId;
    if (currentUserId.isEmpty) return;
    
    await _supabase
        .from('saved_posts')
        .delete()
        .eq('post_id', postId)
        .eq('user_id', currentUserId);
    debugPrint('🗑️ unsavePost: post $postId retiré');
  }

  Future<List<NetworkPost>> getSavedPosts() async {
    final currentUserId = this.currentUserId;
    final response = await _supabase
        .from('saved_posts')
        .select('post:post_id(*)')
        .eq('user_id', currentUserId)
        .order('saved_at', ascending: false);
    
    return (response as List).map((e) => NetworkPost.fromJson(e['post'])).toList();
  }

  // ============================================================
  // SECTION 7: REPOSTER
  // ============================================================

  Future<void> repost(String originalPostId, String? quote) async {
    final currentUserId = this.currentUserId;
    await _supabase.from('reposts').insert({
      'original_post_id': originalPostId,
      'user_id': currentUserId,
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

  // ============================================================
  // SECTION 8: STORIES
  // ============================================================

  Future<List<NetworkStory>> getActiveStories() async {
    try {
      final currentUserId = this.currentUserId;
      if (currentUserId.isEmpty) return [];
      
      NetworkStory.setCurrentUserId(currentUserId);
      
      final response = await _supabase
          .from('stories')
          .select('''
            *,
            users!user_id (
              display_name,
              photo_url,
              profession
            )
          ''')
          .eq('is_active', true)
          .gte('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false);
      
      return (response as List).map((e) => NetworkStory.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error getActiveStories: $e');
      return [];
    }
  }

  Future<void> createStory(String mediaUrl, {String mediaType = 'image', int duration = 24}) async {
    final currentUserId = this.currentUserId;
    if (currentUserId.isEmpty) return;
    
    await _supabase.from('stories').insert({
      'user_id': currentUserId,
      'media_url': mediaUrl,
      'media_type': mediaType,
      'is_active': true,
      'created_at': DateTime.now().toIso8601String(),
      'expires_at': DateTime.now().add(Duration(hours: duration)).toIso8601String(),
    });
  }

  Future<void> deleteStory(String storyId) async {
    final currentUserId = this.currentUserId;
    if (currentUserId.isEmpty) return;
    
    await _supabase
        .from('stories')
        .delete()
        .eq('id', storyId)
        .eq('user_id', currentUserId);
  }

  Future<void> markStoryAsViewed(String storyId) async {
    final currentUserId = this.currentUserId;
    if (currentUserId.isEmpty) return;
    
    final existing = await _supabase
        .from('story_views')
        .select('id')
        .eq('story_id', storyId)
        .eq('user_id', currentUserId);
    
    if ((existing as List).isEmpty) {
      await _supabase.from('story_views').insert({
        'story_id': storyId,
        'user_id': currentUserId,
        'viewed_at': DateTime.now().toIso8601String(),
      });
    }
  }

  // ============================================================
  // SECTION 9: STORY HIGHLIGHTS
  // ============================================================

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
    final currentUserId = this.currentUserId;
    await _supabase.from('story_highlights').insert({
      'user_id': currentUserId,
      'name': name,
      'cover_image': coverImage,
      'story_ids': storyIds,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // ============================================================
  // SECTION 10: UPLOAD IMAGES & VIDEOS
  // ============================================================

  Future<String?> uploadImage(String filePath, {String bucket = 'post_images'}) async {
    try {
      final currentUserId = this.currentUserId;
      if (currentUserId.isEmpty) return null;
      
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      
      final extension = filePath.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$extension';
      final storagePath = '$currentUserId/$fileName';
      
      await _supabase.storage
          .from(bucket)
          .uploadBinary(storagePath, bytes);
      
      return _supabase.storage.from(bucket).getPublicUrl(storagePath);
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  Future<List<String>> uploadMultipleImages(List<String> filePaths, {String bucket = 'post_images'}) async {
    final List<String> uploadedUrls = [];
    for (final path in filePaths) {
      final url = await uploadImage(path, bucket: bucket);
      if (url != null) uploadedUrls.add(url);
    }
    return uploadedUrls;
  }

  Future<String?> uploadAvatar(String filePath) async {
    return uploadImage(filePath, bucket: 'avatars');
  }

  Future<String?> uploadStoryImage(String filePath) async {
    return uploadImage(filePath, bucket: 'story_images');
  }

  Future<void> deleteImage(String imageUrl, {String bucket = 'post_images'}) async {
    try {
      final uri = Uri.parse(imageUrl);
      final segments = uri.pathSegments;
      final bucketIndex = segments.indexOf(bucket);
      
      if (bucketIndex != -1 && bucketIndex + 1 < segments.length) {
        final filePath = segments.sublist(bucketIndex + 1).join('/');
        await _supabase.storage.from(bucket).remove([filePath]);
      }
    } catch (e) {
      debugPrint('Error deleting image: $e');
    }
  }

  Future<void> createPostWithImages(String content, List<String> imagePaths) async {
    final imageUrls = await uploadMultipleImages(imagePaths);
    await createPost(content, imageUrls);
  }

  // ============================================================
  // SECTION 11: COMMUNAUTÉS
  // ============================================================

  Future<NetworkCommunity> createCommunity({
    required String name,
    String? description,
    String? bannerUrl,
  }) async {
    final currentUserId = this.currentUserId;
    if (currentUserId.isEmpty) throw Exception('User not logged in');
    
    final response = await _supabase
        .from('communities')
        .insert({
          'name': name,
          'description': description,
          'logo_url': bannerUrl,
          'created_by': currentUserId,
          'created_at': DateTime.now().toIso8601String(),
          'members_count': 1,
          'posts_count': 0,
        })
        .select()
        .single();
    
    await _supabase.from('community_members').insert({
      'community_id': response['id'],
      'user_id': currentUserId,
      'role': 'admin',
      'joined_at': DateTime.now().toIso8601String(),
    });
    
    return NetworkCommunity.fromJson(response);
  }

  Future<List<NetworkCommunity>> getAllCommunities({int limit = 50}) async {
    try {
      final currentUserId = this.currentUserId;
      
      final response = await _supabase
          .from('communities')
          .select('*')
          .order('members_count', ascending: false)
          .limit(limit);
      
      final List<NetworkCommunity> communities = [];
      for (var e in response as List) {
        final isMemberData = await _supabase
            .from('community_members')
            .select('id')
            .eq('community_id', e['id'])
            .eq('user_id', currentUserId);
        
        final isMember = (isMemberData as List).isNotEmpty;
        
        communities.add(NetworkCommunity.fromJson({
          ...e,
          'is_member': isMember,
        }));
      }
      
      return communities;
    } catch (e) {
      debugPrint('Error getAllCommunities: $e');
      return [];
    }
  }

  Future<List<NetworkCommunity>> getSuggestedCommunities({int limit = 10}) async {
    try {
      final currentUserId = this.currentUserId;
      
      final response = await _supabase
          .from('communities')
          .select('*')
          .order('members_count', ascending: false)
          .limit(limit);
      
      final List<NetworkCommunity> communities = [];
      for (var e in response as List) {
        final isMemberData = await _supabase
            .from('community_members')
            .select('id')
            .eq('community_id', e['id'])
            .eq('user_id', currentUserId);
        
        final isMember = (isMemberData as List).isNotEmpty;
        
        if (!isMember) {
          communities.add(NetworkCommunity.fromJson({
            ...e,
            'is_member': isMember,
          }));
        }
      }
      
      return communities;
    } catch (e) {
      debugPrint('Error getSuggestedCommunities: $e');
      return [];
    }
  }

  Future<List<NetworkCommunity>> getMyCommunities() async {
    try {
      final currentUserId = this.currentUserId;
      if (currentUserId.isEmpty) return [];
      
      final response = await _supabase
          .from('community_members')
          .select('community_id')
          .eq('user_id', currentUserId);
      
      final List<NetworkCommunity> communities = [];
      for (var member in response as List) {
        final communityData = await _supabase
            .from('communities')
            .select('*')
            .eq('id', member['community_id'])
            .single();
        
        communities.add(NetworkCommunity.fromJson({
          ...communityData,
          'is_member': true,
        }));
      }
      
      return communities;
    } catch (e) {
      debugPrint('Error getMyCommunities: $e');
      return [];
    }
  }

  Future<NetworkCommunity?> getCommunityById(String communityId) async {
    try {
      final currentUserId = this.currentUserId;
      
      final response = await _supabase
          .from('communities')
          .select('*')
          .eq('id', communityId)
          .single();
      
      final isMemberData = await _supabase
          .from('community_members')
          .select('id')
          .eq('community_id', communityId)
          .eq('user_id', currentUserId);
      
      final isMember = (isMemberData as List).isNotEmpty;
      
      return NetworkCommunity.fromJson({
        ...response,
        'is_member': isMember,
      });
    } catch (e) {
      debugPrint('Error getCommunityById: $e');
      return null;
    }
  }

  Future<void> joinCommunity(String communityId) async {
    final currentUserId = this.currentUserId;
    if (currentUserId.isEmpty) return;
    
    final existing = await _supabase
        .from('community_members')
        .select('id')
        .eq('community_id', communityId)
        .eq('user_id', currentUserId);
    
    if ((existing as List).isEmpty) {
      await _supabase.from('community_members').insert({
        'community_id': communityId,
        'user_id': currentUserId,
        'role': 'member',
        'joined_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> leaveCommunity(String communityId) async {
    final currentUserId = this.currentUserId;
    if (currentUserId.isEmpty) return;
    
    final isAdmin = await _isCommunityAdmin(communityId, currentUserId);
    if (isAdmin) {
      throw Exception('Les administrateurs ne peuvent pas quitter la communauté');
    }
    
    await _supabase
        .from('community_members')
        .delete()
        .eq('community_id', communityId)
        .eq('user_id', currentUserId);
  }

  Future<bool> _isCommunityAdmin(String communityId, String userId) async {
    try {
      final response = await _supabase
          .from('community_members')
          .select('role')
          .eq('community_id', communityId)
          .eq('user_id', userId);
      
      final list = response as List;
      return list.isNotEmpty && list[0]['role'] == 'admin';
    } catch (e) {
      return false;
    }
  }

  // ============================================================
  // SECTION 12: CONNEXIONS & SUGGESTIONS
  // ============================================================

  Future<List<NetworkConnection>> getSuggestedConnections({int limit = 10}) async {
    try {
      final currentUserId = this.currentUserId;
      if (currentUserId.isEmpty) return [];
      
      final response = await _supabase
          .from('users')
          .select('id, display_name, photo_url, profession')
          .neq('id', currentUserId)
          .limit(limit);
      
      final List<NetworkConnection> suggestions = [];
      for (var user in response as List) {
        final mutualData = await _supabase
            .from('connections')
            .select('id')
            .eq('user_id', currentUserId)
            .eq('connection_id', user['id']);
        
        final mutualCount = (mutualData as List).length;
        
        suggestions.add(NetworkConnection(
          id: user['id'],
          name: user['display_name'] ?? 'Utilisateur',
          avatar: user['photo_url'],
          title: user['profession'] ?? 'Membre THIX',
          mutualConnections: mutualCount,
        ));
      }
      
      return suggestions;
    } catch (e) {
      debugPrint('Error getSuggestedConnections: $e');
      return [];
    }
  }

  Future<void> sendConnectionRequest(String targetUserId) async {
    final currentUserId = this.currentUserId;
    if (currentUserId.isEmpty) return;
    
    await _supabase.from('connection_requests').insert({
      'sender_id': currentUserId,
      'receiver_id': targetUserId,
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });
    
    await _createNotification(
      userId: targetUserId,
      type: 'connection',
    );
  }

  Future<void> acceptConnectionRequest(String requestId) async {
    await _supabase
        .from('connection_requests')
        .update({'status': 'accepted'})
        .eq('id', requestId);
    
    final request = await _supabase
        .from('connection_requests')
        .select('sender_id, receiver_id')
        .eq('id', requestId)
        .single();
    
    await _supabase.from('connections').insert({
      'user_id': request['sender_id'],
      'connection_id': request['receiver_id'],
      'status': 'accepted',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // ============================================================
  // SECTION 13: MESSAGES PRIVÉS
  // ============================================================

  Future<List<Conversation>> getConversations() async {
    try {
      final currentUserId = this.currentUserId;
      if (currentUserId.isEmpty) return [];
      
      final response = await _supabase
          .from('messages')
          .select('''
            sender_id,
            receiver_id,
            content,
            created_at,
            is_read,
            sender:users!messages_sender_id (
              id, display_name, photo_url
            ),
            receiver:users!messages_receiver_id (
              id, display_name, photo_url
            )
          ''')
          .or('sender_id.eq.$currentUserId,receiver_id.eq.$currentUserId')
          .order('created_at', ascending: false);
      
      final Map<String, Conversation> conversations = {};
      
      for (var msg in response as List) {
        final otherId = msg['sender_id'] == currentUserId 
            ? msg['receiver_id'] 
            : msg['sender_id'];
        
        final otherUser = msg['sender_id'] == currentUserId
            ? msg['receiver']
            : msg['sender'];
        
        if (!conversations.containsKey(otherId)) {
          conversations[otherId] = Conversation(
            id: otherId,
            otherUserId: otherId,
            otherUserName: otherUser?['display_name'] ?? 'Utilisateur',
            otherUserAvatar: otherUser?['photo_url'],
            lastMessage: msg['content'],
            lastMessageAt: DateTime.parse(msg['created_at']),
            lastMessageIsFromMe: msg['sender_id'] == currentUserId,
            unreadCount: (msg['is_read'] == false && msg['receiver_id'] == currentUserId) ? 1 : 0,
          );
        }
      }
      
      return conversations.values.toList();
    } catch (e) {
      debugPrint('Error getConversations: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> sendMessage(String receiverId, String content) async {
    final currentUserId = this.currentUserId;
    if (currentUserId.isEmpty) throw Exception('User not logged in');
    
    final response = await _supabase
        .from('messages')
        .insert({
          'sender_id': currentUserId,
          'receiver_id': receiverId,
          'content': content,
          'is_read': false,
          'created_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();
    
    return {
      'id': response['id'],
      'content': response['content'],
      'is_sent_by_me': true,
      'created_at': DateTime.parse(response['created_at']),
    };
  }

  Future<List<Map<String, dynamic>>> getMessages(String otherUserId) async {
    try {
      final currentUserId = this.currentUserId;
      if (currentUserId.isEmpty) return [];
      
      final response = await _supabase
          .from('messages')
          .select('*')
          .or('sender_id.eq.$currentUserId,receiver_id.eq.$currentUserId')
          .or('sender_id.eq.$otherUserId,receiver_id.eq.$otherUserId')
          .order('created_at', ascending: true);
      
      return (response as List).map((e) => ({
        'id': e['id'],
        'content': e['content'],
        'is_sent_by_me': e['sender_id'] == currentUserId,
        'created_at': DateTime.parse(e['created_at']),
      })).toList();
    } catch (e) {
      debugPrint('Error getMessages: $e');
      return [];
    }
  }

  Future<void> markMessagesAsRead(String otherUserId) async {
    try {
      final currentUserId = this.currentUserId;
      if (currentUserId.isEmpty) return;
      
      await _supabase
          .from('messages')
          .update({'is_read': true})
          .eq('receiver_id', currentUserId)
          .eq('sender_id', otherUserId);
    } catch (e) {
      debugPrint('Error markMessagesAsRead: $e');
    }
  }

  // ============================================================
  // SECTION 14: NOTIFICATIONS
  // ============================================================

  Future<List<NetworkNotification>> getNotifications() async {
    try {
      final currentUserId = this.currentUserId;
      if (currentUserId.isEmpty) return [];
      
      final response = await _supabase
          .from('notifications')
          .select('''
            *,
            users!sender_id (
              display_name,
              photo_url
            ),
            posts!post_id (
              id, content
            )
          ''')
          .eq('user_id', currentUserId)
          .order('created_at', ascending: false)
          .limit(50);
      
      return (response as List).map((e) => NetworkNotification.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error getNotifications: $e');
      return [];
    }
  }

  Future<int> getUnreadNotificationsCount() async {
    try {
      final currentUserId = this.currentUserId;
      if (currentUserId.isEmpty) return 0;
      
      final response = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', currentUserId)
          .eq('is_read', false);
      
      return (response as List).length;
    } catch (e) {
      debugPrint('Error getUnreadNotificationsCount: $e');
      return 0;
    }
  }

  Future<int> getUnreadMessagesCount() async {
    try {
      final currentUserId = this.currentUserId;
      if (currentUserId.isEmpty) return 0;
      
      final response = await _supabase
          .from('messages')
          .select('id')
          .eq('receiver_id', currentUserId)
          .eq('is_read', false);
      
      return (response as List).length;
    } catch (e) {
      debugPrint('Error getUnreadMessagesCount: $e');
      return 0;
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    try {
      final currentUserId = this.currentUserId;
      if (currentUserId.isEmpty) return;
      
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', currentUserId)
          .eq('is_read', false);
    } catch (e) {
      debugPrint('Error markAllNotificationsAsRead: $e');
    }
  }

  Future<void> _createNotification({
    required String userId,
    required String type,
    String? postId,
  }) async {
    final currentUserId = this.currentUserId;
    if (userId == currentUserId) return;
    
    await _supabase.from('notifications').insert({
      'user_id': userId,
      'type': type,
      'sender_id': currentUserId,
      'post_id': postId,
      'is_read': false,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // ============================================================
  // SECTION 15: PROFIL UTILISATEUR
  // ============================================================

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select('''
            id,
            display_name,
            photo_url,
            profession,
            bio,
            skills
          ''')
          .eq('id', userId)
          .maybeSingle();
      
      if (response == null) return null;
      
      final postsData = await _supabase
          .from('posts')
          .select('id')
          .eq('user_id', userId);
      
      final followersData = await _supabase
          .from('connections')
          .select('id')
          .eq('connection_id', userId)
          .eq('status', 'accepted');
      
      final followingData = await _supabase
          .from('connections')
          .select('id')
          .eq('user_id', userId)
          .eq('status', 'accepted');
      
      return {
        'id': response['id'],
        'display_name': response['display_name'],
        'photo_url': response['photo_url'],
        'profession': response['profession'],
        'bio': response['bio'],
        'skills': response['skills'] ?? [],
        'posts_count': (postsData as List).length,
        'followers_count': (followersData as List).length,
        'following_count': (followingData as List).length,
      };
    } catch (e) {
      debugPrint('Error getUserProfile: $e');
      return null;
    }
  }

  Future<List<NetworkPost>> getUserPosts(String userId) async {
    try {
      final response = await _supabase
          .from('posts')
          .select('''
            *,
            users!user_id (
              display_name, photo_url, profession
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      return (response as List).map((e) => NetworkPost.fromJson({
        ...e,
        'author_name': e['users']?['display_name'],
        'author_avatar': e['users']?['photo_url'],
        'author_title': e['users']?['profession'],
        'likes_count': 0,
        'comments_count': 0,
        'is_liked': false,
      })).toList();
    } catch (e) {
      debugPrint('Error getUserPosts: $e');
      return [];
    }
  }

  // ============================================================
  // SECTION 16: RECHERCHE
  // ============================================================

  Future<List<NetworkCommunity>> searchCommunities(String query) async {
    try {
      final currentUserId = this.currentUserId;
      
      final response = await _supabase
          .from('communities')
          .select('*')
          .ilike('name', '%$query%')
          .order('members_count', ascending: false)
          .limit(20);
      
      final List<NetworkCommunity> communities = [];
      for (var e in response as List) {
        final isMemberData = await _supabase
            .from('community_members')
            .select('id')
            .eq('community_id', e['id'])
            .eq('user_id', currentUserId);
        
        final isMember = (isMemberData as List).isNotEmpty;
        
        communities.add(NetworkCommunity.fromJson({
          ...e,
          'is_member': isMember,
        }));
      }
      
      return communities;
    } catch (e) {
      debugPrint('Error searchCommunities: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      final response = await _supabase
          .from('users')
          .select('id, display_name, photo_url, profession')
          .ilike('display_name', '%$query%')
          .limit(20);
      
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error searchUsers: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> searchPosts(String query) async {
    try {
      final response = await _supabase
          .from('posts')
          .select('''
            id, content, created_at,
            users!user_id (display_name, photo_url)
          ''')
          .ilike('content', '%$query%')
          .order('created_at', ascending: false)
          .limit(20);
      
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error searchPosts: $e');
      return [];
    }
  }

  // ============================================================
  // SECTION 17: ÉVÉNEMENTS
  // ============================================================

  Future<void> markEventInterest(String eventId) async {
    final currentUserId = this.currentUserId;
    if (currentUserId.isEmpty) return;
    
    final existing = await _supabase
        .from('event_interests')
        .select('id')
        .eq('event_id', eventId)
        .eq('user_id', currentUserId);
    
    if ((existing as List).isEmpty) {
      await _supabase.from('event_interests').insert({
        'event_id': eventId,
        'user_id': currentUserId,
        'interested_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<bool> hasEventInterest(String eventId) async {
    try {
      final currentUserId = this.currentUserId;
      if (currentUserId.isEmpty) return false;
      
      final response = await _supabase
          .from('event_interests')
          .select('id')
          .eq('event_id', eventId)
          .eq('user_id', currentUserId);
      
      return (response as List).isNotEmpty;
    } catch (e) {
      debugPrint('Error hasEventInterest: $e');
      return false;
    }
  }

  // ============================================================
  // SECTION 18: RECOMMANDATIONS IA
  // ============================================================

  Future<Map<String, int>> getRecommendationsCount() async {
    final currentUserId = this.currentUserId;
    if (currentUserId.isEmpty) {
      return {'people': 0, 'opportunities': 0, 'communities': 0};
    }
    
    try {
      final people = await _supabase
          .from('users')
          .select('id')
          .neq('id', currentUserId)
          .limit(10);
      
      final communities = await _supabase
          .from('communities')
          .select('id')
          .limit(10);
      
      return {
        'people': (people as List).length,
        'opportunities': 0,
        'communities': (communities as List).length,
      };
    } catch (e) {
      debugPrint('Error getRecommendationsCount: $e');
      return {'people': 0, 'opportunities': 0, 'communities': 0};
    }
  }
}

// ============================================================
// CLASSES AUXILIAIRES
// ============================================================

class Highlight {
  final String id;
  final String name;
  final String? coverImage;
  final List<String> storyIds;
  final DateTime createdAt;

  Highlight({
    required this.id,
    required this.name,
    this.coverImage,
    required this.storyIds,
    required this.createdAt,
  });
}

class Conversation {
  final String id;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;
  final String lastMessage;
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
  final String id;
  final String originalPostId;
  final String userId;
  final String? quote;
  final DateTime createdAt;

  Repost({
    required this.id,
    required this.originalPostId,
    required this.userId,
    this.quote,
    required this.createdAt,
  });

  factory Repost.fromJson(Map<String, dynamic> json) {
    return Repost(
      id: json['id'],
      originalPostId: json['original_post_id'],
      userId: json['user_id'],
      quote: json['quote'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
