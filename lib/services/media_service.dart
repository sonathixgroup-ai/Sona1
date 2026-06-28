// lib/services/media_service.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MediaService {
  final SupabaseClient supabase;
  final String bucket;

  MediaService({SupabaseClient? client, this.bucket = 'posts'}) : supabase = client ?? Supabase.instance.client;

  Future<String> uploadFile({required PlatformFile file, required String path}) async {
    final key = '$path/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
    if (kIsWeb) {
      final bytes = file.bytes;
      if (bytes == null) throw Exception('Web file bytes are null');
      await supabase.storage.from(bucket).uploadBinary(key, bytes, fileOptions: FileOptions(cacheControl: '3600'));
    } else {
      if (file.path == null) throw Exception('File path is null');
      final f = File(file.path!);
      await supabase.storage.from(bucket).upload(key, f);
    }
    final url = supabase.storage.from(bucket).getPublicUrl(key).data;
    return url ?? key;
  }

  Future<String> uploadBytes({required Uint8List bytes, required String path, required String filename}) async {
    final key = '$path/${DateTime.now().millisecondsSinceEpoch}_$filename';
    await supabase.storage.from(bucket).uploadBinary(key, bytes, fileOptions: FileOptions(cacheControl: '3600'));
    final url = supabase.storage.from(bucket).getPublicUrl(key).data;
    return url ?? key;
  }
}
