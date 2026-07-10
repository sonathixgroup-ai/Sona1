// lib/presentation/mon_pays/repositories/news_repository.dart

import '../models/news_model.dart';
import '../services/news_service.dart';

class NewsRepository {
  final NewsService _service;

  NewsRepository(this._service);

  Future<List<News>> getAll() => _service.getAll();
  Future<News> getById(String id) => _service.getById(id);
  Future<News> create(News news) => _service.create(news);
  Future<News> update(News news) => _service.update(news);
  Future<void> delete(String id) => _service.delete(id);
}
