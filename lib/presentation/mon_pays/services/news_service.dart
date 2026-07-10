// lib/presentation/mon_pays/services/news_service.dart

import 'package:dio/dio.dart';
import '../models/news_model.dart';
import '../utils/mon_pays_constants.dart';

class NewsService {
  final Dio _dio;

  NewsService(this._dio);

  Future<List<News>> getAll() async {
    final response = await _dio.get('${MonPaysConstants.baseUrl}${MonPaysConstants.newsEndpoint}');
    return (response.data as List).map((e) => News.fromJson(e)).toList();
  }

  Future<News> getById(String id) async {
    final response = await _dio.get('${MonPaysConstants.baseUrl}${MonPaysConstants.newsEndpoint}/$id');
    return News.fromJson(response.data);
  }

  Future<News> create(News news) async {
    final response = await _dio.post(
      '${MonPaysConstants.baseUrl}${MonPaysConstants.newsEndpoint}',
      data: news.toJson(),
    );
    return News.fromJson(response.data);
  }

  Future<News> update(News news) async {
    final response = await _dio.put(
      '${MonPaysConstants.baseUrl}${MonPaysConstants.newsEndpoint}/${news.id}',
      data: news.toJson(),
    );
    return News.fromJson(response.data);
  }

  Future<void> delete(String id) async {
    await _dio.delete('${MonPaysConstants.baseUrl}${MonPaysConstants.newsEndpoint}/$id');
  }
}
