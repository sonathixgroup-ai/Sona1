// lib/presentation/mon_pays/services/law_service.dart

import 'package:dio/dio.dart';
import '../models/law_model.dart';
import '../utils/mon_pays_constants.dart';

class LawService {
  final Dio _dio;

  LawService(this._dio);

  Future<List<Law>> getAll() async {
    final response = await _dio.get('${MonPaysConstants.baseUrl}${MonPaysConstants.lawsEndpoint}');
    return (response.data as List).map((e) => Law.fromJson(e)).toList();
  }

  Future<Law> getById(String id) async {
    final response = await _dio.get('${MonPaysConstants.baseUrl}${MonPaysConstants.lawsEndpoint}/$id');
    return Law.fromJson(response.data);
  }

  Future<Law> create(Law law) async {
    final response = await _dio.post(
      '${MonPaysConstants.baseUrl}${MonPaysConstants.lawsEndpoint}',
      data: law.toJson(),
    );
    return Law.fromJson(response.data);
  }

  Future<Law> update(Law law) async {
    final response = await _dio.put(
      '${MonPaysConstants.baseUrl}${MonPaysConstants.lawsEndpoint}/${law.id}',
      data: law.toJson(),
    );
    return Law.fromJson(response.data);
  }

  Future<void> delete(String id) async {
    await _dio.delete('${MonPaysConstants.baseUrl}${MonPaysConstants.lawsEndpoint}/$id');
  }
}
