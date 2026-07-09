// lib/presentation/mon_pays/services/news_service.dart

import 'package:dio/dio.dart';
import '../models/news_model.dart';

class NewsService {
  final Dio dio;
  final String basePath = '/news';

  NewsService({required this.dio});

  Future<List<News>> getAll() async {
    try {
      final response = await dio.get(basePath);
      final List data = response.data;
      return data.map((json) => News.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur chargement actualités: $e');
    }
  }

  Future<News> getById(String id) async {
    try {
      final response = await dio.get('$basePath/$id');
      return News.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur chargement actualité: $e');
    }
  }

  Future<News> add(News news) async {
    try {
      final response = await dio.post(
        basePath,
        data: news.toJson(),
      );
      return News.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur ajout actualité: $e');
    }
  }

  Future<News> update(News news) async {
    try {
      final response = await dio.put(
        '$basePath/${news.id}',
        data: news.toJson(),
      );
      return News.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur mise à jour actualité: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await dio.delete('$basePath/$id');
    } catch (e) {
      throw Exception('Erreur suppression actualité: $e');
    }
  }
}
