import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/media_content.dart';

class MediaService {
  final SupabaseClient _supabase;

  MediaService(this._supabase);

  // ==================== MÉTHODES PUBLIQUES (page THIX MEDIA) ====================

  Future<List<MediaContent>> fetchPublishedMedia() async {
    final response = await _supabase
        .from('media_contents')
        .select('*')
        .eq('is_published', true)
        .order('created_at', ascending: false);
    if (response is List) {
      return response.map((json) => MediaContent.fromJson(json)).toList();
    }
    return [];
  }

  Future<List<MediaContent>> fetchTrending() async {
    final response = await _supabase
        .from('media_contents')
        .select('*')
        .eq('is_published', true)
        .eq('is_trending', true)
        .order('rank_position', ascending: true);
    if (response is List) {
      return response.map((json) => MediaContent.fromJson(json)).toList();
    }
    return [];
  }

  Future<List<MediaContent>> fetchNewReleases() async {
    final response = await _supabase
        .from('media_contents')
        .select('*')
        .eq('is_published', true)
        .eq('is_new_release', true)
        .order('created_at', ascending: false);
    if (response is List) {
      return response.map((json) => MediaContent.fromJson(json)).toList();
    }
    return [];
  }

  Future<List<MediaContent>> fetchRecommendations() async {
    final response = await _supabase
        .from('media_contents')
        .select('*')
        .eq('is_published', true)
        .eq('is_recommended', true)
        .order('created_at', ascending: false);
    if (response is List) {
      return response.map((json) => MediaContent.fromJson(json)).toList();
    }
    return [];
  }

  Future<MediaContent?> fetchById(String id) async {
    final response = await _supabase
        .from('media_contents')
        .select('*')
        .eq('id', id)
        .maybeSingle();
    if (response != null) {
      return MediaContent.fromJson(response);
    }
    return null;
  }

  // ==================== MÉTHODES D'ADMINISTRATION ====================

  Future<List<MediaContent>> fetchAllMedia() async {
    final response = await _supabase
        .from('media_contents')
        .select('*')
        .order('created_at', ascending: false);
    if (response is List) {
      return response.map((json) => MediaContent.fromJson(json)).toList();
    }
    return [];
  }

  // Insertion simple (sans fichiers locaux)
  Future<void> insert(MediaContent item) async {
    await _supabase.from('media_contents').insert(item.toJson());
  }

  // Mise à jour simple
  Future<void> update(MediaContent item) async {
    await _supabase.from('media_contents').update(item.toJson()).eq('id', item.id);
  }

  // Insertion avec upload de fichiers (image + vidéo)
  Future<void> insertWithFiles(MediaContent item, {File? coverFile, File? videoFile}) async {
    String? coverUrl = item.coverUrl;
    String? videoUrl = item.videoUrl;

    if (coverFile != null) {
      final coverExt = coverFile.path.split('.').last;
      final coverName = 'covers/${DateTime.now().millisecondsSinceEpoch}.$coverExt';
      await _uploadFile('media_covers', coverFile, coverName);
      coverUrl = _supabase.storage.from('media_covers').getPublicUrl(coverName);
    }
    if (videoFile != null) {
      final videoExt = videoFile.path.split('.').last;
      final videoName = 'videos/${DateTime.now().millisecondsSinceEpoch}.$videoExt';
      await _uploadFile('media_videos', videoFile, videoName);
      videoUrl = _supabase.storage.from('media_videos').getPublicUrl(videoName);
    }

    final newItem = item.copyWith(
      coverUrl: coverUrl!,
      videoUrl: videoUrl!,
    );
    await insert(newItem);
  }

  // Mise à jour avec possibilité de remplacer l'image ou la vidéo
  Future<void> updateWithFiles(MediaContent item, {File? newCoverFile, File? newVideoFile}) async {
    String? coverUrl = item.coverUrl;
    String? videoUrl = item.videoUrl;

    if (newCoverFile != null) {
      // Supprimer l'ancienne image si elle est dans Supabase Storage
      if (item.coverUrl.contains('supabase.co')) {
        final oldPath = _extractStoragePath(item.coverUrl);
        if (oldPath != null) {
          await _supabase.storage.from('media_covers').remove([oldPath]);
        }
      }
      final coverExt = newCoverFile.path.split('.').last;
      final coverName = 'covers/${DateTime.now().millisecondsSinceEpoch}.$coverExt';
      await _uploadFile('media_covers', newCoverFile, coverName);
      coverUrl = _supabase.storage.from('media_covers').getPublicUrl(coverName);
    }

    if (newVideoFile != null) {
      if (item.videoUrl.contains('supabase.co')) {
        final oldPath = _extractStoragePath(item.videoUrl);
        if (oldPath != null) {
          await _supabase.storage.from('media_videos').remove([oldPath]);
        }
      }
      final videoExt = newVideoFile.path.split('.').last;
      final videoName = 'videos/${DateTime.now().millisecondsSinceEpoch}.$videoExt';
      await _uploadFile('media_videos', newVideoFile, videoName);
      videoUrl = _supabase.storage.from('media_videos').getPublicUrl(videoName);
    }

    final updatedItem = item.copyWith(
      coverUrl: coverUrl!,
      videoUrl: videoUrl!,
      updatedAt: DateTime.now(),
    );
    await update(updatedItem);
  }

  // Suppression complète (base + fichiers Storage)
  Future<void> deleteMedia(MediaContent item) async {
    try {
      if (item.coverUrl.contains('supabase.co')) {
        final coverPath = _extractStoragePath(item.coverUrl);
        if (coverPath != null) {
          await _supabase.storage.from('media_covers').remove([coverPath]);
        }
      }
      if (item.videoUrl.contains('supabase.co')) {
        final videoPath = _extractStoragePath(item.videoUrl);
        if (videoPath != null) {
          await _supabase.storage.from('media_videos').remove([videoPath]);
        }
      }
    } catch (e) {
      print('Erreur suppression fichiers: $e');
    }
    await _supabase.from('media_contents').delete().eq('id', item.id);
  }

  // ==================== MÉTHODES PRIVÉES ====================

  Future<void> _uploadFile(String bucket, File file, String path) async {
    final bytes = await file.readAsBytes();
    await _supabase.storage.from(bucket).uploadBinary(path, bytes);
  }

  String? _extractStoragePath(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    final segments = uri.pathSegments;
    final publicIndex = segments.indexOf('public');
    if (publicIndex != -1 && publicIndex + 2 < segments.length) {
      return segments.sublist(publicIndex + 2).join('/');
    }
    return null;
  }
}
