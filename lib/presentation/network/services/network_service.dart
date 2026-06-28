// lib/presentation/network/services/network_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/presentation/network/models/post_model.dart';
import 'package:thix_id/presentation/network/models/story_model.dart';
import 'package:thix_id/presentation/network/models/opportunity_model.dart';
import 'package:thix_id/presentation/network/utils/network_constants.dart';

class NetworkService {
  final SupabaseClient supabase;
  final String postsTable = 'posts';
  final String storiesTable = 'stories';
  final String opportunitiesTable = 'opportunities';

  NetworkService({SupabaseClient? client}) : supabase = client ?? Supabase.instance.client;

  Future<List<PostModel>> fetchPosts({int limit = 20, int offset = 0}) async {
    final res = await supabase
        .from(postsTable)
        .select('*, profiles:author(*), post_media(*)')
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1)
        .execute();
    final data = res.data as List<dynamic>? ?? [];

    // Convert storage paths to public URLs for media before mapping to PostModel
    for (final item in data) {
      if (item is Map<String, dynamic> && item['post_media'] is List) {
        final media = item['post_media'] as List;
        for (final m in media) {
          try {
            if (m is Map && m['storage_path'] != null) {
              final path = m['storage_path'] as String;
              final publicUrl = supabase.storage.from(NetworkConstants.postsBucket).getPublicUrl(path).data;
              // prefer explicit url key to avoid mutating original storage_path
              m['url'] = publicUrl ?? path;
            }
          } catch (e) {
            // fallback: leave storage_path as-is
          }
        }
      }
    }

    return data.map((e) => PostModel.fromMap(e as Map<String, dynamic>)).toList();
  }

  Future<List<StoryModel>> fetchStories() async {
    final res = await supabase.from(storiesTable).select('*, profiles:author(*)').order('created_at', ascending: false).limit(50).execute();
    final data = res.data as List<dynamic>? ?? [];
    return data.map((e) => StoryModel.fromMap(e as Map<String, dynamic>)).toList();
  }

  Future<List<OpportunityModel>> fetchOpportunities() async {
    // opportunites could be a custom table or external source; offer a basic select
    final res = await supabase.from(opportunitiesTable).select().limit(20).execute();
    final data = res.data as List<dynamic>? ?? [];
    return data.map((e) => OpportunityModel.fromMap(e as Map<String, dynamic>)).toList();
  }

  Future<void> createPost({required String profileId, required String content}) async {
    await supabase.from(postsTable).insert({'author': profileId, 'content': content}).execute();
  }
}
