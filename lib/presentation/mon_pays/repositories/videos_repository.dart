// lib/presentation/mon_pays/repositories/videos_repository.dart

import '../models/video_model.dart';
import '../services/videos_service.dart';

class VideosRepository {
  final VideosService _service;

  VideosRepository(this._service);

  Future<List<Video>> getAll() => _service.getAll();
  Future<Video> getById(String id) => _service.getById(id);
  Future<Video> create(Video video) => _service.create(video);
  Future<Video> update(Video video) => _service.update(video);
  Future<void> delete(String id) => _service.delete(id);
}
