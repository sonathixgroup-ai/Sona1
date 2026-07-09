// lib/presentation/mon_pays/repositories/search_repository.dart

import '../models/search_result_model.dart';
import '../services/search_service.dart';

class SearchRepository {
  final SearchService _service;

  SearchRepository(this._service);

  Future<List<SearchResult>> search(String query) => _service.search(query);
}
