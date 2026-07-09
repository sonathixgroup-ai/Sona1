// lib/presentation/mon_pays/services/wanted_people_service.dart

import 'package:dio/dio.dart';
import '../models/wanted_person_model.dart';
import '../utils/mon_pays_constants.dart';

class WantedPeopleService {
  final Dio _dio;

  WantedPeopleService(this._dio);

  Future<List<WantedPerson>> getAll() async {
    final response = await _dio.get('${MonPaysConstants.baseUrl}${MonPaysConstants.wantedEndpoint}');
    return (response.data as List).map((e) => WantedPerson.fromJson(e)).toList();
  }

  Future<WantedPerson> getById(String id) async {
    final response = await _dio.get('${MonPaysConstants.baseUrl}${MonPaysConstants.wantedEndpoint}/$id');
    return WantedPerson.fromJson(response.data);
  }

  Future<WantedPerson> create(WantedPerson person) async {
    final response = await _dio.post(
      '${MonPaysConstants.baseUrl}${MonPaysConstants.wantedEndpoint}',
      data: person.toJson(),
    );
    return WantedPerson.fromJson(response.data);
  }

  Future<WantedPerson> update(WantedPerson person) async {
    final response = await _dio.put(
      '${MonPaysConstants.baseUrl}${MonPaysConstants.wantedEndpoint}/${person.id}',
      data: person.toJson(),
    );
    return WantedPerson.fromJson(response.data);
  }

  Future<void> delete(String id) async {
    await _dio.delete('${MonPaysConstants.baseUrl}${MonPaysConstants.wantedEndpoint}/$id');
  }
}
