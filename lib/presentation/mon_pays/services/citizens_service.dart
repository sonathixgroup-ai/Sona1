// lib/presentation/mon_pays/services/citizens_service.dart

import 'package:dio/dio.dart';
import '../models/citizen_model.dart';
import '../utils/mon_pays_constants.dart';

class CitizensService {
  final Dio _dio;

  CitizensService(this._dio);

  Future<List<ExemplaryCitizen>> getAll() async {
    final response = await _dio.get('${MonPaysConstants.baseUrl}${MonPaysConstants.citizensEndpoint}');
    return (response.data as List).map((e) => ExemplaryCitizen.fromJson(e)).toList();
  }

  Future<ExemplaryCitizen> getById(String id) async {
    final response = await _dio.get('${MonPaysConstants.baseUrl}${MonPaysConstants.citizensEndpoint}/$id');
    return ExemplaryCitizen.fromJson(response.data);
  }

  Future<ExemplaryCitizen> create(ExemplaryCitizen citizen) async {
    final response = await _dio.post(
      '${MonPaysConstants.baseUrl}${MonPaysConstants.citizensEndpoint}',
      data: citizen.toJson(),
    );
    return ExemplaryCitizen.fromJson(response.data);
  }

  Future<ExemplaryCitizen> update(ExemplaryCitizen citizen) async {
    final response = await _dio.put(
      '${MonPaysConstants.baseUrl}${MonPaysConstants.citizensEndpoint}/${citizen.id}',
      data: citizen.toJson(),
    );
    return ExemplaryCitizen.fromJson(response.data);
  }

  Future<void> delete(String id) async {
    await _dio.delete('${MonPaysConstants.baseUrl}${MonPaysConstants.citizensEndpoint}/$id');
  }
}
