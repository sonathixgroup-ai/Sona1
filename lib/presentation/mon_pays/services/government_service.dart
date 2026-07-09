// lib/presentation/mon_pays/services/government_service.dart

import 'package:dio/dio.dart';
import '../models/government_model.dart';
import '../utils/mon_pays_constants.dart';

class GovernmentService {
  final Dio _dio;

  GovernmentService(this._dio);

  Future<List<Government>> getAll() async {
    final response = await _dio.get('${MonPaysConstants.baseUrl}/government');
    return (response.data as List).map((e) => Government.fromJson(e)).toList();
  }

  Future<Government> getById(String id) async {
    final response = await _dio.get('${MonPaysConstants.baseUrl}/government/$id');
    return Government.fromJson(response.data);
  }

  Future<Government> create(Government gov) async {
    final response = await _dio.post(
      '${MonPaysConstants.baseUrl}/government',
      data: gov.toJson(),
    );
    return Government.fromJson(response.data);
  }

  Future<Government> update(Government gov) async {
    final response = await _dio.put(
      '${MonPaysConstants.baseUrl}/government/${gov.id}',
      data: gov.toJson(),
    );
    return Government.fromJson(response.data);
  }

  Future<void> delete(String id) async {
    await _dio.delete('${MonPaysConstants.baseUrl}/government/$id');
  }
}
