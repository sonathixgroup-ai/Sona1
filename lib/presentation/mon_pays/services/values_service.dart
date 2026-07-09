// lib/presentation/mon_pays/services/values_service.dart

import 'package:dio/dio.dart';
import '../models/value_model.dart';
import '../utils/mon_pays_constants.dart';

class ValuesService {
  final Dio _dio;

  ValuesService(this._dio);

  Future<List<Value>> getAll() async {
    final response = await _dio.get('${MonPaysConstants.baseUrl}${MonPaysConstants.valuesEndpoint}');
    return (response.data as List).map((e) => Value.fromJson(e)).toList();
  }

  Future<Value> getById(String id) async {
    final response = await _dio.get('${MonPaysConstants.baseUrl}${MonPaysConstants.valuesEndpoint}/$id');
    return Value.fromJson(response.data);
  }

  Future<Value> create(Value value) async {
    final response = await _dio.post(
      '${MonPaysConstants.baseUrl}${MonPaysConstants.valuesEndpoint}',
      data: value.toJson(),
    );
    return Value.fromJson(response.data);
  }

  Future<Value> update(Value value) async {
    final response = await _dio.put(
      '${MonPaysConstants.baseUrl}${MonPaysConstants.valuesEndpoint}/${value.id}',
      data: value.toJson(),
    );
    return Value.fromJson(response.data);
  }

  Future<void> delete(String id) async {
    await _dio.delete('${MonPaysConstants.baseUrl}${MonPaysConstants.valuesEndpoint}/$id');
  }
}
