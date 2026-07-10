// lib/presentation/mon_pays/services/videos_service.dart

import 'package:dio/dio.dart';
import '../models/video_model.dart';
import '../utils/mon_pays_constants.dart';

class VideosService {
  final Dio _dio;

  VideosService(this._dio);

  Future<List<Video>> getAll() async {
    final response = await _dio.get('${MonPaysConstants.baseUrl}${MonPaysConstants.videosEndpoint}');
    return (response.data as List).map((e) => Video.fromJson(e)).toList();
  }

  Future<Video> getById(String id) async {
    final response = await _dio.get('${MonPaysConstants.baseUrl}${MonPaysConstants.videosEndpoint}/$id');
    return Video.fromJson(response.data);
  }

  Future<Video> create(Video video) async {
    final response = await _dio.post(
      '${MonPaysConstants.baseUrl}${MonPaysConstants.videosEndpoint}',
      data: video.toJson(),
    );
    return Video.fromJson(response.data);
  }

  Future<Video> update(Video video) async {
    final response = await _dio.put(
      '${MonPaysConstants.baseUrl}${MonPaysConstants.videosEndpoint}/${video.id}',
      data: video.toJson(),
    );
    return Video.fromJson(response.data);
  }

  Future<void> delete(String id) async {
    await _dio.delete('${MonPaysConstants.baseUrl}${MonPaysConstants.videosEndpoint}/$id');
  }
}
