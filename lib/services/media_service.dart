import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart'; // ✅ Indispensable pour kIsWeb
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/models/media_content.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;

/// MediaService optimisé pour la production :
/// - Uploads physiques sur Mobile (zéro crash OOM)
/// - Uploads binaires sur Web (compatible navigateurs)
/// - Uploads parallèles (vitesse doublée)
/// - Noms de fichiers sécurisés (UUID)
class MediaService {
  final SupabaseClient supabase;
  final String bucket;
  final Uuid _uuid = const Uuid();

  MediaService({SupabaseClient? client, this.bucket = 'media'}) 
      : supabase = client ?? Supabase.instance.client;

  Future<List<MediaContent>> fetchAllMedia({int page = 0, int limit = 50}) async {
    final start = page * limit;
    final end = start + limit - 1;

    final data = await supabase
        .from('media_content')
        .select()
        .order('created_at', ascending: false)
        .range(start, end) as List<dynamic>;
        
    return data.map((e) => MediaContent.fromJson(e as Map<String, dynamic>)).toList(growable: false);
  }

  Future<List<MediaContent>> fetchPublishedMedia({int page = 0, int limit = 50}) async {
    final start = page * limit;
    final end = start + limit - 1;

    final data = await supabase
        .from('media_content')
        .select()
        .eq('is_published', true)
        .order('rank_position', ascending: true)
        .range(start, end) as List<dynamic>;
        
    return data.map((e) => MediaContent.fromJson(e as Map<String, dynamic>)).toList(growable: false);
  }

  Future<MediaContent> insertWithFiles(MediaContent item, {PlatformFile? coverFile, PlatformFile? videoFile}) async {
    final newId = _uuid.v4();
    
    String? finalCoverUrl;
    String? finalVideoUrl;
    List<Future<void>> uploadTasks = [];

    if (coverFile != null) {
      uploadTasks.add(
        _uploadPhysicalFile(coverFile, 'thix_media/$newId/covers')
            .then((url) => finalCoverUrl = url)
      );
    }
    
    if (videoFile != null) {
      uploadTasks.add(
        _uploadPhysicalFile(videoFile, 'thix_media/$newId/videos')
            .then((url) => finalVideoUrl = url)
      );
    }

    await Future.wait(uploadTasks);

    final newItem = item.copyWith(
      id: newId,
      coverUrl: finalCoverUrl ?? item.coverUrl,
      videoUrl: finalVideoUrl ?? item.videoUrl,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final inserted = await supabase.from('media_content').insert(newItem.toJson()).select().single() as Map<String, dynamic>;
    return MediaContent.fromJson(inserted);
  }

  Future<MediaContent> updateWithFiles(MediaContent existing, {PlatformFile? newCoverFile, PlatformFile? newVideoFile}) async {
    String? finalCoverUrl;
    String? finalVideoUrl;
    List<Future<void>> uploadTasks = [];

    if (newCoverFile != null) {
      uploadTasks.add(
        _uploadPhysicalFile(newCoverFile, 'thix_media/${existing.id}/covers')
            .then((url) => finalCoverUrl = url)
      );
    }
    
    if (newVideoFile != null) {
      uploadTasks.add(
        _uploadPhysicalFile(newVideoFile, 'thix_media/${existing.id}/videos')
            .then((url) => finalVideoUrl = url)
      );
    }

    await Future.wait(uploadTasks);

    final updatedItem = existing.copyWith(
      coverUrl: finalCoverUrl ?? existing.coverUrl,
      videoUrl: finalVideoUrl ?? existing.videoUrl,
      updatedAt: DateTime.now(),
    );

    await supabase.from('media_content').update(updatedItem.toJson()).eq('id', existing.id);
    return updatedItem;
  }

  Future<void> deleteMedia(MediaContent item) async {
    List<String> pathsToDelete = [];

    String? extractPath(String url) {
      if (url.isEmpty) return null;
      final marker = '/public/$bucket/';
      if (url.contains(marker)) {
        return url.split(marker).last.split('?').first;
      }
      return null;
    }

    final coverPath = extractPath(item.coverUrl);
    final videoPath = extractPath(item.videoUrl);

    if (coverPath != null) pathsToDelete.add(coverPath);
    if (videoPath != null) pathsToDelete.add(videoPath);

    if (pathsToDelete.isNotEmpty) {
      try {
        await supabase.storage.from(bucket).remove(pathsToDelete);
      } catch (e) {
        debugPrint('Avertissement Storage: Impossible de supprimer certains fichiers ($e)');
      }
    }

    await supabase.from('media_content').delete().eq('id', item.id);
  }

  /// Logique interne d'upload optimisée Web / Mobile
  Future<String> _uploadPhysicalFile(PlatformFile file, String basePath) async {
    // 1. Sécurisation du nom de fichier
    final extension = p.extension(file.name);
    final secureFileName = '${_uuid.v4()}$extension';
    final fullPath = '$basePath/$secureFileName';

    // ✅ 2. Vérification stricte de la plateforme
    if (kIsWeb) {
      // SUR LE WEB : Interdiction de toucher à file.path. On utilise les bytes.
      if (file.bytes == null) {
        throw Exception('Impossible de lire les données du fichier sur le web. Vérifiez que withData est à true.');
      }
      await supabase.storage.from(bucket).uploadBinary(
        fullPath, 
        file.bytes!, 
        fileOptions: const FileOptions(cacheControl: '31536000', upsert: true)
      );
    } else {
      // SUR MOBILE/DESKTOP : On utilise le path physique pour économiser la RAM
      if (file.path != null) {
        final physicalFile = File(file.path!);
        await supabase.storage.from(bucket).upload(
          fullPath, 
          physicalFile, 
          fileOptions: const FileOptions(cacheControl: '31536000', upsert: true)
        );
      } else {
        throw Exception('Impossible de trouver le chemin du fichier sur cet appareil.');
      }
    }

    // 3. Retourne l'URL publique
    return supabase.storage.from(bucket).getPublicUrl(fullPath);
  }
}
