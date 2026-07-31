import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/models/media_content.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;

typedef ProgressCallback = void Function(double progress);

class MediaService {
  final SupabaseClient supabase;
  final String bucket;
  final Uuid _uuid = const Uuid();

  // Constructeur compatible avec ton panneau d'administration
  MediaService({SupabaseClient? client, this.bucket = 'media'})
      : supabase = client ?? Supabase.instance.client;

  // =========================================================================
  // BATCHING DES VUES (Optimisation critique pour des millions d'utilisateurs)
  // =========================================================================
  
  static final Set<String> _pendingViews = {};
  static Timer? _timer;

  /// Enregistre une vue localement. L'envoi au serveur est différé pour
  /// éviter de saturer la base de données (Write Amplification).
  Future<void> registerView(String mediaId) async {
    _pendingViews.add(mediaId);
    _timer ??= Timer(const Duration(seconds: 10), _flushViews);
  }

  static Future<void> _flushViews() async {
    if (_pendingViews.isEmpty) {
      _timer = null;
      return;
    }
    final batch = _pendingViews.toList();
    _pendingViews.clear();
    _timer = null;

    try {
      await Supabase.instance.client.rpc('batch_register_views', params: {'p_media_ids': batch});
    } catch (_) {
      // En cas d'échec réseau, on remet les IDs dans la file d'attente
      _pendingViews.addAll(batch);
    }
  }

  // =========================================================================
  // ACTIONS UTILISATEUR (Likes, etc.)
  // =========================================================================

  /// Bascule l'état "J'aime" via une fonction RPC pour éviter les conflits
  Future<void> toggleLike(String mediaId) async {
    await supabase.rpc('toggle_like', params: {'p_media_id': mediaId});
  }

  /// Récupère en une seule requête les IDs likés par l'utilisateur parmi une liste
  Future<Set<String>> getLikedMediaIds(List<String> mediaIds) async {
    if (mediaIds.isEmpty) return {};
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return {};

    try {
      final res = await supabase
          .from('media_likes')
          .select('media_id')
          .eq('user_id', uid)
          .inFilter('media_id', mediaIds);
      
      return (res as List).map((e) => e['media_id'] as String).toSet();
    } catch (_) {
      return {};
    }
  }

  // =========================================================================
  // LECTURE & PAGINATION
  // =========================================================================

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

  Future<List<MediaContent>> fetchPublishedMedia({int page = 0, int limit = 50}) async {
    final start = page * limit;
    final end = start + limit - 1;
    final data = await supabase.from('media_content').select().eq('is_published', true).order('rank_position', ascending: true, nullsFirst: false).order('created_at', ascending: false).range(start, end) as List<dynamic>;
    return data.map((e) => MediaContent.fromJson(e as Map<String, dynamic>)).toList(growable: false);
  }

  Future<List<MediaContent>> fetchPublishedMediaPaginated({int limit = 30, int offset = 0}) async {
    final data = await supabase.from('media_content').select().eq('is_published', true).order('rank_position', ascending: true, nullsFirst: false).range(offset, offset + limit - 1) as List<dynamic>;
    return data.map((e) => MediaContent.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<MediaContent>> fetchAllMediaLegacy() async {
    return fetchAllMediaPaginated(limit: 100, offset: 0);
  }

  Future<List<MediaContent>> fetchPublishedMediaLegacy() async {
    return fetchPublishedMediaPaginated(limit: 100, offset: 0);
  }

  // =========================================================================
  // GESTION DES FICHIERS (Administration)
  // =========================================================================

  Future<MediaContent> insertWithFiles(
    MediaContent item, {
    PlatformFile? coverFile,
    PlatformFile? videoFile,
    ProgressCallback? onProgress,
  }) async {
    final newId = _uuid.v4();
    String? finalCoverUrl;
    String? finalVideoUrl;

    int totalTasks = (coverFile != null ? 1 : 0) + (videoFile != null ? 1 : 0);
    int doneTasks = 0;

    void tick() {
      doneTasks++;
      if (onProgress != null && totalTasks > 0) onProgress(doneTasks / totalTasks);
    }

    final tasks = <Future<void>>[];

    if (coverFile != null) {
      tasks.add(_uploadPhysicalFile(coverFile, 'thix_media/$newId/covers').then((url) {
        finalCoverUrl = url;
        tick();
      }));
    }
    if (videoFile != null) {
      tasks.add(_uploadPhysicalFile(videoFile, 'thix_media/$newId/videos').then((url) {
        finalVideoUrl = url;
        tick();
      }));
    }

    if (tasks.isNotEmpty) await Future.wait(tasks);

    final newItem = item.copyWith(
      id: newId,
      coverUrl: finalCoverUrl ?? item.coverUrl,
      videoUrl: finalVideoUrl ?? item.videoUrl,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final inserted = await _retry(() => supabase.from('media_content').insert(newItem.toJson()).select().single());
    return MediaContent.fromJson(inserted as Map<String, dynamic>);
  }

  Future<MediaContent> updateWithFiles(
    MediaContent existing, {
    PlatformFile? newCoverFile,
    PlatformFile? newVideoFile,
    ProgressCallback? onProgress,
  }) async {
    String? finalCoverUrl;
    String? finalVideoUrl;

    int totalTasks = (newCoverFile != null ? 1 : 0) + (newVideoFile != null ? 1 : 0);
    int doneTasks = 0;
    
    void tick() {
      doneTasks++;
      if (onProgress != null && totalTasks > 0) onProgress(doneTasks / totalTasks);
    }

    final tasks = <Future<void>>[];
    
    if (newCoverFile != null) {
      tasks.add(_uploadPhysicalFile(newCoverFile, 'thix_media/${existing.id}/covers').then((url) {
        finalCoverUrl = url;
        tick();
      }));
    }
    
    if (newVideoFile != null) {
      tasks.add(_uploadPhysicalFile(newVideoFile, 'thix_media/${existing.id}/videos').then((url) {
        finalVideoUrl = url;
        tick();
      }));
    }

    if (tasks.isNotEmpty) await Future.wait(tasks);

    final updatedItem = existing.copyWith(
      coverUrl: finalCoverUrl ?? existing.coverUrl,
      videoUrl: finalVideoUrl ?? existing.videoUrl,
      updatedAt: DateTime.now(),
    );

    await _retry(() => supabase.from('media_content').update(updatedItem.toJson()).eq('id', existing.id));
    return updatedItem;
  }

  Future<void> deleteMedia(MediaContent item) async {
    final paths = <String>[];

    String? extractPath(String url) {
      if (url.isEmpty) return null;
      final marker = '/public/$bucket/';
      if (url.contains(marker)) return url.split(marker).last.split('?').first;
      final marker2 = '/object/public/$bucket/';
      if (url.contains(marker2)) return url.split(marker2).last.split('?').first;
      // fallback si url stockée est déjà un path
      if (!url.startsWith('http')) return url;
      return null;
    }

    final cp = extractPath(item.coverUrl);
    final vp = extractPath(item.videoUrl);
    
    if (cp != null) paths.add(cp);
    if (vp != null) paths.add(vp);

    if (paths.isNotEmpty) {
      try {
        await supabase.storage.from(bucket).remove(paths);
      } catch (e) {
        debugPrint('Storage delete warn: $e');
      }
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
        // fallback desktop sans path
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
      try {
        return await fn();
      } catch (e) {
        attempt++;
        if (attempt >= max) rethrow;
        await Future.delayed(Duration(milliseconds: 300 * attempt));
      }
    }
  }
}
