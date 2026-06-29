import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Lightweight upload helper used by the Network module.
///
/// This keeps the compilation green and provides real uploads when the
/// corresponding Supabase Storage buckets exist.
///
/// Buckets expected (public):
/// - [avatarBucket] for profile avatars
/// - [storyBucket] for stories
class UploadService {
  static const String avatarBucket = 'avatars';
  static const String storyBucket = 'stories';

  final SupabaseClient _client;
  UploadService({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  Future<String> uploadAvatar(File file, String userId) async {
    final ext = _extOf(file.path);
    final path = 'avatars/$userId/${DateTime.now().toIso8601String().replaceAll(':', '-')}$ext';
    return _uploadPublic(bucket: avatarBucket, file: file, objectPath: path);
  }

  Future<String> uploadStoryImage(File file) async {
    final uid = _client.auth.currentUser?.id ?? 'anon';
    final ext = _extOf(file.path);
    final path = 'stories/$uid/${DateTime.now().toIso8601String().replaceAll(':', '-')}$ext';
    return _uploadPublic(bucket: storyBucket, file: file, objectPath: path);
  }

  Future<String> _uploadPublic({required String bucket, required File file, required String objectPath}) async {
    try {
      final bytes = await file.readAsBytes();
      await _client.storage.from(bucket).uploadBinary(
            objectPath,
            bytes,
            fileOptions: FileOptions(upsert: true, cacheControl: '3600', contentType: _contentTypeForPath(file.path)),
          );
      final url = _client.storage.from(bucket).getPublicUrl(objectPath);
      if (url.trim().isEmpty) throw Exception('Storage: getPublicUrl returned empty.');
      return url;
    } catch (e) {
      debugPrint('UploadService: upload failed bucket=$bucket path=$objectPath err=$e');
      final msg = e.toString();
      if (msg.contains('Bucket') && msg.contains('not found')) {
        throw Exception("Bucket Supabase Storage introuvable: '$bucket'. Crée-le (public) dans Supabase → Storage.");
      }
      rethrow;
    }
  }

  String _extOf(String path) {
    final dot = path.lastIndexOf('.');
    if (dot == -1) return '.jpg';
    final ext = path.substring(dot).toLowerCase();
    if (ext.length > 6) return '.jpg';
    return ext;
  }

  String _contentTypeForPath(String path) {
    final p = path.toLowerCase();
    if (p.endsWith('.png')) return 'image/png';
    if (p.endsWith('.webp')) return 'image/webp';
    if (p.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }
}
