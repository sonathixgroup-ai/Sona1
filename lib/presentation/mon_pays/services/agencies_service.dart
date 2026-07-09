// lib/presentation/mon_pays/services/agencies_service.dart

import 'package:dio/dio.dart';
import '../models/agency_model.dart';
import '../utils/mon_pays_constants.dart';

class AgenciesService {
  final Dio _dio;

  AgenciesService(this._dio);

  Future<List<Agency>> getAll() async {
    final response = await _dio.get('${MonPaysConstants.baseUrl}${MonPaysConstants.agenciesEndpoint}');
    return (response.data as List).map((e) => Agency.fromJson(e)).toList();
  }

  Future<Agency> getById(String id) async {
    final response = await _dio.get('${MonPaysConstants.baseUrl}${MonPaysConstants.agenciesEndpoint}/$id');
    return Agency.fromJson(response.data);
  }

  Future<Agency> create(Agency agency) async {
    final response = await _dio.post(
      '${MonPaysConstants.baseUrl}${MonPaysConstants.agenciesEndpoint}',
      data: agency.toJson(),
    );
    return Agency.fromJson(response.data);
  }

  Future<Agency> update(Agency agency) async {
    final response = await _dio.put(
      '${MonPaysConstants.baseUrl}${MonPaysConstants.agenciesEndpoint}/${agency.id}',
      data: agency.toJson(),
    );
    return Agency.fromJson(response.data);
  }

  Future<void> delete(String id) async {
    await _dio.delete('${MonPaysConstants.baseUrl}${MonPaysConstants.agenciesEndpoint}/$id');
  }
}
