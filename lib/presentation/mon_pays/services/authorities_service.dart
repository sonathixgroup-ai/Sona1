// lib/presentation/mon_pays/services/authorities_service.dart

import 'package:dio/dio.dart';
import '../models/authority_model.dart';
import '../utils/mon_pays_constants.dart';

class AuthoritiesService {
  final Dio _dio;

  AuthoritiesService(this._dio);

  Future<List<Authority>> getAll() async {
    final response = await _dio.get('${MonPaysConstants.baseUrl}${MonPaysConstants.authoritiesEndpoint}');
    return (response.data as List).map((e) => Authority.fromJson(e)).toList();
  }

  Future<Authority> getById(String id) async {
    final response = await _dio.get('${MonPaysConstants.baseUrl}${MonPaysConstants.authoritiesEndpoint}/$id');
    return Authority.fromJson(response.data);
  }

  Future<Authority> create(Authority authority) async {
    final response = await _dio.post(
      '${MonPaysConstants.baseUrl}${MonPaysConstants.authoritiesEndpoint}',
      data: authority.toJson(),
    );
    return Authority.fromJson(response.data);
  }

  Future<Authority> update(Authority authority) async {
    final response = await _dio.put(
      '${MonPaysConstants.baseUrl}${MonPaysConstants.authoritiesEndpoint}/${authority.id}',
      data: authority.toJson(),
    );
    return Authority.fromJson(response.data);
  }

  Future<void> delete(String id) async {
    await _dio.delete('${MonPaysConstants.baseUrl}${MonPaysConstants.authoritiesEndpoint}/$id');
  }
}
