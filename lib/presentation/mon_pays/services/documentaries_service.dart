// lib/presentation/mon_pays/services/documentaries_service.dart

import 'package:dio/dio.dart';
import '../models/documentary_model.dart';
import '../utils/mon_pays_constants.dart';

class DocumentariesService {
  final Dio _dio;

  DocumentariesService(this._dio);

  Future<List<Documentary>> getAll() async {
    final response = await _dio.get('${MonPaysConstants.baseUrl}${MonPaysConstants.documentariesEndpoint}');
    return (response.data as List).map((e) => Documentary.fromJson(e)).toList();
  }

  Future<Documentary> getById(String id) async {
    final response = await _dio.get('${MonPaysConstants.baseUrl}${MonPaysConstants.documentariesEndpoint}/$id');
    return Documentary.fromJson(response.data);
  }

  Future<Documentary> create(Documentary documentary) async {
    final response = await _dio.post(
      '${MonPaysConstants.baseUrl}${MonPaysConstants.documentariesEndpoint}',
      data: documentary.toJson(),
    );
    return Documentary.fromJson(response.data);
  }

  Future<Documentary> update(Documentary documentary) async {
    final response = await _dio.put(
      '${MonPaysConstants.baseUrl}${MonPaysConstants.documentariesEndpoint}/${documentary.id}',
      data: documentary.toJson(),
    );
    return Documentary.fromJson(response.data);
  }

  Future<void> delete(String id) async {
    await _dio.delete('${MonPaysConstants.baseUrl}${MonPaysConstants.documentariesEndpoint}/$id');
  }
}
