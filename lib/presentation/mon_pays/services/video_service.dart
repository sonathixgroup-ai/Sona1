// lib/presentation/mon_pays/services/video_service.dart

import 'package:dio/dio.dart';
import '../models/video_model.dart';

class VideoService {
  final Dio dio;
  final String basePath = '/videos';

  VideoService({required this.dio});

  Future<List<Video>> getAll() async {
    try {
      final response = await dio.get(basePath);
      final List data = response.data;
      return data.map((json) => Video.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur chargement vidéos: $e');
    }
  }

  Future<Video> getById(String id) async {
    try {
      final response = await dio.get('$basePath/$id');
      return Video.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur chargement vidéo: $e');
    }
  }

  Future<Video> add(Video video) async {
    try {
      final response = await dio.post(
        basePath,
        data: video.toJson(),
      );
      return Video.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur ajout vidéo: $e');
    }
  }

  Future<Video> update(Video video) async {
    try {
      final response = await dio.put(
        '$basePath/${video.id}',
        data: video.toJson(),
      );
      return Video.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur mise à jour vidéo: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await dio.delete('$basePath/$id');
    } catch (e) {
      throw Exception('Erreur suppression vidéo: $e');
    }
  }
}
