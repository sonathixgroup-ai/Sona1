// lib/presentation/mon_pays/services/news_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/news_model.dart';

class NewsService {
  final SupabaseClient _supabase;

  NewsService(this._supabase);

  Future<List<News>> getAll() async {
    final response = await _supabase
        .from('news')
        .select('*');
    return (response as List).map((e) => News.fromJson(e)).toList();
  }

  Future<News> getById(String id) async {
    final response = await _supabase
        .from('news')
        .select('*')
        .eq('id', id)
        .single();
    return News.fromJson(response);
  }

  Future<News> create(News news) async {
    final response = await _supabase
        .from('news')
        .insert(news.toJson())
        .select()
        .single();
    return News.fromJson(response);
  }

  Future<News> update(News news) async {
    final response = await _supabase
        .from('news')
        .update(news.toJson())
        .eq('id', news.id)
        .select()
        .single();
    return News.fromJson(response);
  }

  Future<void> delete(String id) async {
    await _supabase
        .from('news')
        .delete()
        .eq('id', id);
  }
}
