import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart'; // Ajouté pour debugPrint
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/models/media_content.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;

/// MediaService optimisé pour la production :
/// - Uploads physiques (zéro crash OOM)
/// - Uploads parallèles (vitesse doublée)
/// - Prévention DB corrompue (Upload -> Insert)
/// - Noms de fichiers sécurisés (UUID)
/// - Pagination intégrée
/// - Nettoyage complet du Storage lors des suppressions
class MediaService {
  final SupabaseClient supabase;
  final String bucket;
  final Uuid _uuid = const Uuid();

  MediaService({SupabaseClient? client, this.bucket = 'media'}) 
      : supabase = client ?? Supabase.instance.client;

  /// Back-office : Récupération avec Pagination obligatoire
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

  /// App Client : Récupération avec Pagination
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

  /// Création : Uploade d'abord les fichiers en parallèle, PUIS insère en base.
  Future<MediaContent> insertWithFiles(MediaContent item, {PlatformFile? coverFile, PlatformFile? videoFile}) async {
    // 1. Générer l'UUID côté client pour lier les fichiers AVANT l'insertion DB
    final newId = _uuid.v4();
    
    String? finalCoverUrl;
    String? finalVideoUrl;
    List<Future<void>> uploadTasks = [];

    // 2. Lancer les uploads en parallèle
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

    // Attendre que TOUS les fichiers soient uploadés simultanément
    await Future.wait(uploadTasks);

    // 3. Insérer en base SEULEMENT si les uploads ont réussi
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

  /// Mise à jour : Uploads parallèles puis Update
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

  /// Suppression complète (Fichiers dans Storage + Enregistrement DB)
  Future<void> deleteMedia(MediaContent item) async {
    List<String> pathsToDelete = [];

    // Fonction interne pour extraire le chemin relatif depuis l'URL publique
    String? extractPath(String url) {
      if (url.isEmpty) return null;
      final marker = '/public/$bucket/';
      if (url.contains(marker)) {
        // On récupère la partie après le bucket, et on retire les éventuels paramètres (?t=...)
        return url.split(marker).last.split('?').first;
      }
      return null;
    }

    // Identifier les fichiers à supprimer
    final coverPath = extractPath(item.coverUrl);
    final videoPath = extractPath(item.videoUrl);

    if (coverPath != null) pathsToDelete.add(coverPath);
    if (videoPath != null) pathsToDelete.add(videoPath);

    // Supprimer les fichiers du Storage
    if (pathsToDelete.isNotEmpty) {
      try {
        await supabase.storage.from(bucket).remove(pathsToDelete);
      } catch (e) {
        debugPrint('Avertissement Storage: Impossible de supprimer certains fichiers ($e)');
      }
    }

    // Supprimer l'enregistrement dans la base de données
    await supabase.from('media_content').delete().eq('id', item.id);
  }

  /// Logique interne d'upload optimisée
  Future<String> _uploadPhysicalFile(PlatformFile file, String basePath) async {
    // 1. Sécurisation du nom de fichier
    final extension = p.extension(file.name);
    final secureFileName = '${_uuid.v4()}$extension';
    final fullPath = '$basePath/$secureFileName';

    // 2. Choix de la méthode d'upload (Prévention Out-Of-Memory)
    if (file.path != null) {
      // Mobile & Desktop : On lit le fichier physiquement (Stream) pour ne pas exploser la RAM
      final physicalFile = File(file.path!);
      await supabase.storage.from(bucket).upload(
        fullPath, 
        physicalFile, 
        fileOptions: const FileOptions(cacheControl: '31536000', upsert: true)
      );
    } else if (file.bytes != null) {
      // Web : file.path n'est pas disponible sur navigateur, on fallback sur les bytes
      await supabase.storage.from(bucket).uploadBinary(
        fullPath, 
        file.bytes!, 
        fileOptions: const FileOptions(cacheControl: '31536000', upsert: true)
      );
    } else {
      throw Exception('Impossible de lire le fichier ${file.name}.');
    }

    // 3. Retourne l'URL publique
    return supabase.storage.from(bucket).getPublicUrl(fullPath);
  }
}
