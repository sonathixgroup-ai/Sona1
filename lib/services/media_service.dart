// lib/services/media_service.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/models/media_content.dart';

/// MediaService uploads files to Supabase Storage and returns the storage key and public URL.
class MediaService {
  final SupabaseClient supabase;
  final String bucket;

  MediaService({SupabaseClient? client, this.bucket = 'posts'}) : supabase = client ?? Supabase.instance.client;

  /// Back-office: fetch all media items.
  Future<List<MediaContent>> fetchAllMedia() async {
    final data = await supabase.from('media_content').select().order('created_at', ascending: false) as List<dynamic>;
    return data.map((e) => MediaContent.fromJson(e as Map<String, dynamic>)).toList(growable: false);
  }

  Future<List<MediaContent>> fetchPublishedMedia({int limit = 50}) async {
    final data = await supabase
        .from('media_content')
        .select()
        .eq('is_published', true)
        .order('rank_position', ascending: true)
        .limit(limit) as List<dynamic>;
    return data.map((e) => MediaContent.fromJson(e as Map<String, dynamic>)).toList(growable: false);
  }

  Future<MediaContent> insertWithFiles(MediaContent item, {File? coverFile, File? videoFile}) async {
    final inserted = await supabase.from('media_content').insert(item.toJson()).select().single() as Map<String, dynamic>;
    var updated = MediaContent.fromJson(inserted);
    if (coverFile != null) {
      final up = await _uploadIoFile(file: coverFile, path: 'media/${updated.id}', filename: coverFile.path.split('/').last);
      updated = updated.copyWith(coverUrl: up['url'] ?? updated.coverUrl);
    }
    if (videoFile != null) {
      final up = await _uploadIoFile(file: videoFile, path: 'media/${updated.id}', filename: videoFile.path.split('/').last);
      updated = updated.copyWith(videoUrl: up['url'] ?? updated.videoUrl);
    }
    if (updated.id.isNotEmpty) {
      await supabase.from('media_content').update(updated.toJson()).eq('id', updated.id);
    }
    return updated;
  }

  Future<MediaContent> updateWithFiles(MediaContent existing, {File? newCoverFile, File? newVideoFile}) async {
    var updated = existing.copyWith(updatedAt: DateTime.now());
    if (newCoverFile != null) {
      final up = await _uploadIoFile(file: newCoverFile, path: 'media/${existing.id}', filename: newCoverFile.path.split('/').last);
      updated = updated.copyWith(coverUrl: up['url']);
    }
    if (newVideoFile != null) {
      final up = await _uploadIoFile(file: newVideoFile, path: 'media/${existing.id}', filename: newVideoFile.path.split('/').last);
      updated = updated.copyWith(videoUrl: up['url']);
    }
    await supabase.from('media_content').update(updated.toJson()).eq('id', existing.id);
    return updated;
  }

  Future<void> deleteMedia(MediaContent item) async {
    await supabase.from('media_content').delete().eq('id', item.id);
  }

  /// Upload a [PlatformFile] and return a map containing `key` and `url`.
  /// `path` is the folder prefix inside the bucket (e.g. 'posts/{postId}').
  Future<Map<String, String>> uploadFile({required PlatformFile file, required String path}) async {
    final filename = file.name;
    final key = '$path/${DateTime.now().millisecondsSinceEpoch}_$filename';

    if (kIsWeb) {
      final bytes = file.bytes;
      if (bytes == null) throw Exception('Web file bytes are null');
      await supabase.storage.from(bucket).uploadBinary(key, bytes, fileOptions: FileOptions(cacheControl: '3600'));
    } else {
      if (file.path == null) throw Exception('File path is null');
      final f = File(file.path!);
      await supabase.storage.from(bucket).upload(key, f);
    }

    final url = supabase.storage.from(bucket).getPublicUrl(key);
    return {'key': key, 'url': url};
  }

  Future<Map<String, String>> uploadBytes({required Uint8List bytes, required String path, required String filename}) async {
    final key = '$path/${DateTime.now().millisecondsSinceEpoch}_$filename';
    await supabase.storage.from(bucket).uploadBinary(key, bytes, fileOptions: FileOptions(cacheControl: '3600'));
    final url = supabase.storage.from(bucket).getPublicUrl(key);
    return {'key': key, 'url': url};
  }

  Future<Map<String, String>> _uploadIoFile({required File file, required String path, required String filename}) async {
    final key = '$path/${DateTime.now().millisecondsSinceEpoch}_$filename';
    await supabase.storage.from(bucket).upload(key, file);
    final url = supabase.storage.from(bucket).getPublicUrl(key);
    return {'key': key, 'url': url};
  }
}
