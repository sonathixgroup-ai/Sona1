// lib/presentation/network/services/network_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/presentation/network/models/post_model.dart';
import 'package:thix_id/presentation/network/models/story_model.dart';
import 'package:thix_id/presentation/network/models/opportunity_model.dart';
import 'package:thix_id/presentation/network/models/bookmark_model.dart';
import 'package:thix_id/presentation/network/utils/network_constants.dart';
import 'package:thix_id/services/media_service.dart';
import 'package:file_picker/file_picker.dart';

class NetworkService {
  final SupabaseClient supabase;
  final String postsTable = 'posts';
  final String storiesTable = 'stories';
  final String opportunitiesTable = 'opportunities';
  final MediaService mediaService;

  NetworkService({SupabaseClient? client, MediaService? media})
      : supabase = client ?? Supabase.instance.client,
        mediaService = media ?? MediaService();

  Future<String?> _currentProfileId() async {
    final authUid = supabase.auth.currentUser?.id;
    if (authUid == null) return null;
    final res = await supabase.from('profiles').select('id').eq('user_id', authUid).maybeSingle();
    if (res == null) return null;
    return (res as Map<String, dynamic>)['id'] as String?;
  }

  Future<List<PostModel>> fetchPosts({int limit = 20, int offset = 0}) async {
    final data = await supabase
        .from(postsTable)
        .select('*, profiles:author(*), post_media(*)')
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1) as List<dynamic>;

    // Convert storage paths to public URLs for media before mapping to PostModel
    for (final item in data) {
      if (item is Map<String, dynamic> && item['post_media'] is List) {
        final media = item['post_media'] as List;
        for (final m in media) {
          try {
            if (m is Map && m['storage_path'] != null) {
              final path = m['storage_path'] as String;
              final publicUrl = supabase.storage.from(NetworkConstants.postsBucket).getPublicUrl(path);
              m['url'] = publicUrl;
            }
          } catch (e) {
            // fallback: leave storage_path as-is
          }
        }
      }
    }

    final posts = data.map((e) => PostModel.fromMap(e as Map<String, dynamic>)).toList();

    // fetch reactions and bookmarks in batch for current user
    final profileId = await _currentProfileId();
    final postIds = posts.map((p) => p.id).where((id) => id.isNotEmpty).toList();
    if (postIds.isNotEmpty) {
      // fetch reactions for these posts
      final reactionsData = await supabase
          .from('reactions')
          .select('id,post_id,type,user_id')
          .inFilter('post_id', postIds) as List<dynamic>;

      // aggregate counts
      final Map<String, Map<String, int>> counts = {};
      final Map<String, String> userReaction = {};
      for (final r in reactionsData) {
        final map = r as Map<String, dynamic>;
        final pid = map['post_id'] as String? ?? '';
        final type = map['type'] as String? ?? 'like';
        counts.putIfAbsent(pid, () => {});
        counts[pid]![type] = (counts[pid]![type] ?? 0) + 1;
        if (profileId != null && map['user_id'] == profileId) {
          userReaction[pid] = type;
        }
      }

      // fetch bookmarks for current user
      final bookmarksData = profileId != null
          ? await supabase
              .from('bookmarks')
              .select('post_id')
              .eq('user_id', profileId)
              .inFilter('post_id', postIds) as List<dynamic>
          : const <dynamic>[];
      final bookmarkedSet = <String>{};
      for (final b in bookmarksData) {
        final m = b as Map<String, dynamic>;
        bookmarkedSet.add(m['post_id'] as String);
      }

      // apply to posts
      for (var i = 0; i < posts.length; i++) {
        final p = posts[i];
        final pc = counts[p.id] ?? {};
        final ur = userReaction[p.id];
        final isBm = bookmarkedSet.contains(p.id);
        posts[i] = p.copyWith(reactionCounts: pc, userReaction: ur, isBookmarked: isBm);
      }
    }

    return posts;
  }

  Future<List<StoryModel>> fetchStories({int limit = 30}) async {
    final data = await supabase
        .from(storiesTable)
        .select('*, profiles:author(*)')
        .order('created_at', ascending: false)
        .limit(limit) as List<dynamic>;
    return data.map((e) => StoryModel.fromMap(e as Map<String, dynamic>)).toList(growable: false);
  }

  Future<List<OpportunityModel>> fetchOpportunities({int limit = 30}) async {
    final data = await supabase
        .from(opportunitiesTable)
        .select()
        .order('created_at', ascending: false)
        .limit(limit) as List<dynamic>;
    return data.map((e) => OpportunityModel.fromMap(e as Map<String, dynamic>)).toList(growable: false);
  }

  Future<void> createPost({required String profileId, required String content, List<PlatformFile>? mediaFiles}) async {
    // Insert post and get id
    final insertRes = await supabase.from(postsTable).insert({'author': profileId, 'content': content}).select().single();
    if (insertRes == null) return;
    final postId = insertRes['id'] as String;

    if (mediaFiles != null && mediaFiles.isNotEmpty) {
      for (var i = 0; i < mediaFiles.length; i++) {
        final f = mediaFiles[i];
        // upload via MediaService
        final uploaded = await mediaService.uploadFile(file: f, path: 'posts/$postId');
        final key = uploaded['key'] ?? uploaded['url'] ?? '';
        final ext = (f.extension ?? '').toLowerCase();
        final mime = ext.isEmpty ? 'application/octet-stream' : 'application/$ext';
        final size = f.size;
        await supabase.from('post_media').insert({'post_id': postId, 'storage_path': key, 'mime': mime, 'size': size, 'ordering': i});
      }
    }
  }

  // Reactions
  Future<void> addReaction({required String postId, required String type}) async {
    final profileId = await _currentProfileId();
    if (profileId == null) throw Exception('No profile');
    // check existing reaction by user on that post
    final existing = await supabase.from('reactions').select('id,type').eq('post_id', postId).eq('user_id', profileId).maybeSingle();
    if (existing != null) {
      final existingType = (existing as Map<String, dynamic>)['type'] as String?;
      if (existingType == type) {
        // remove
        await supabase.from('reactions').delete().eq('post_id', postId).eq('user_id', profileId);
        return;
      } else {
        // update
        await supabase.from('reactions').update({'type': type}).eq('id', (existing as Map<String, dynamic>)['id']);
        return;
      }
    }
    await supabase.from('reactions').insert({'post_id': postId, 'user_id': profileId, 'type': type});
  }

  // bookmarks
  Future<void> toggleBookmark({required String postId}) async {
    final profileId = await _currentProfileId();
    if (profileId == null) throw Exception('No profile');
    final existing = await supabase.from('bookmarks').select('id').eq('post_id', postId).eq('user_id', profileId).maybeSingle();
    if (existing != null) {
      await supabase.from('bookmarks').delete().eq('id', (existing as Map<String, dynamic>)['id']);
    } else {
      await supabase.from('bookmarks').insert({'post_id': postId, 'user_id': profileId});
    }
  }

  Future<List<BookmarkModel>> fetchBookmarks({required String profileId, int limit = 50}) async {
    final data = await supabase.from('bookmarks').select().eq('user_id', profileId).limit(limit) as List<dynamic>;
    return data.map((e) => BookmarkModel.fromMap(e as Map<String, dynamic>)).toList();
  }

  // shares
  Future<void> sharePost({required String postId, required String targetType, String? targetId}) async {
    final profileId = await _currentProfileId();
    if (profileId == null) throw Exception('No profile');
    await supabase.from('shares').insert({'post_id': postId, 'user_id': profileId, 'target_type': targetType, 'target_id': targetId});
    // optionally increment share count in posts
    await supabase.rpc('increment_post_share_count', params: {'post_id': postId});
  }
}
