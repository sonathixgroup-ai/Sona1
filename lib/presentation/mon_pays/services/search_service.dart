// lib/presentation/mon_pays/services/search_service.dart

import 'package:dio/dio.dart';
import '../models/search_result_model.dart';
import '../utils/mon_pays_constants.dart';

class SearchService {
  final Dio _dio;

  SearchService(this._dio);

  Future<List<SearchResult>> search(String query) async {
    final response = await _dio.get(
      '${MonPaysConstants.baseUrl}/search',
      queryParameters: {'q': query},
    );
    return (response.data as List).map((e) => SearchResult.fromJson(e)).toList();
  }
}
