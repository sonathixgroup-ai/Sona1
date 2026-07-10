// lib/presentation/mon_pays/services/videos_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/video_model.dart';

class VideosService {
  final SupabaseClient _supabase;

  VideosService(this._supabase);

  Future<List<Video>> getAll() async {
    final response = await _supabase
        .from('videos')
        .select('*');
    return (response as List).map((e) => Video.fromJson(e)).toList();
  }

  Future<Video> getById(String id) async {
    final response = await _supabase
        .from('videos')
        .select('*')
        .eq('id', id)
        .single();
    return Video.fromJson(response);
  }

  Future<Video> create(Video video) async {
    final response = await _supabase
        .from('videos')
        .insert(video.toJson())
        .select()
        .single();
    return Video.fromJson(response);
  }

  Future<Video> update(Video video) async {
    final response = await _supabase
        .from('videos')
        .update(video.toJson())
        .eq('id', video.id)
        .select()
        .single();
    return Video.fromJson(response);
  }

  Future<void> delete(String id) async {
    await _supabase
        .from('videos')
        .delete()
        .eq('id', id);
  }
}
