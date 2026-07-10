// lib/presentation/mon_pays/services/ministry_service.dart

import 'package:dio/dio.dart';
import '../models/ministry_model.dart';
import '../utils/mon_pays_constants.dart';

class MinistryService {
  final Dio _dio;

  MinistryService(this._dio);

  Future<List<Ministry>> getAll() async {
    final response = await _dio.get('${MonPaysConstants.baseUrl}${MonPaysConstants.ministriesEndpoint}');
    return (response.data as List).map((e) => Ministry.fromJson(e)).toList();
  }

  Future<Ministry> getById(String id) async {
    final response = await _dio.get('${MonPaysConstants.baseUrl}${MonPaysConstants.ministriesEndpoint}/$id');
    return Ministry.fromJson(response.data);
  }

  Future<Ministry> create(Ministry ministry) async {
    final response = await _dio.post(
      '${MonPaysConstants.baseUrl}${MonPaysConstants.ministriesEndpoint}',
      data: ministry.toJson(),
    );
    return Ministry.fromJson(response.data);
  }

  Future<Ministry> update(Ministry ministry) async {
    final response = await _dio.put(
      '${MonPaysConstants.baseUrl}${MonPaysConstants.ministriesEndpoint}/${ministry.id}',
      data: ministry.toJson(),
    );
    return Ministry.fromJson(response.data);
  }

  Future<void> delete(String id) async {
    await _dio.delete('${MonPaysConstants.baseUrl}${MonPaysConstants.ministriesEndpoint}/$id');
  }
}
