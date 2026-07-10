// lib/presentation/mon_pays/services/search_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/search_result_model.dart';

class SearchService {
  final SupabaseClient _supabase;

  SearchService(this._supabase);

  Future<List<SearchResult>> search(String query) async {
    if (query.trim().isEmpty) return [];

    // Recherche dans plusieurs tables (exemple)
    // Vous pouvez utiliser une fonction RPC ou plusieurs requêtes
    final authorities = await _supabase
        .from('authorities')
        .select('id, name, title, photo_url')
        .ilike('name', '%$query%')
        .limit(5);

    final news = await _supabase
        .from('news')
        .select('id, title, content, image_url')
        .ilike('title', '%$query%')
        .limit(5);

    final agencies = await _supabase
        .from('agencies')
        .select('id, name, description, logo_url')
        .ilike('name', '%$query%')
        .limit(5);

    final results = <SearchResult>[];

    results.addAll((authorities as List).map((e) => SearchResult(
      id: e['id'],
      title: e['name'] ?? '',
      description: e['title'] ?? '',
      imageUrl: e['photo_url'],
      type: 'authority',
      route: '/mon-pays/authority/${e['id']}',
    )));

    results.addAll((news as List).map((e) => SearchResult(
      id: e['id'],
      title: e['title'] ?? '',
      description: e['content'] ?? '',
      imageUrl: e['image_url'],
      type: 'news',
      route: '/mon-pays/news/${e['id']}',
    )));

    results.addAll((agencies as List).map((e) => SearchResult(
      id: e['id'],
      title: e['name'] ?? '',
      description: e['description'] ?? '',
      imageUrl: e['logo_url'],
      type: 'agency',
      route: '/mon-pays/agency/${e['id']}',
    )));

    return results;
  }
}
