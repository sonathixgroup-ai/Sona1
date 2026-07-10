// lib/presentation/mon_pays/services/consultations_service.dart

import 'package:dio/dio.dart';
import '../models/consultation_model.dart';
import '../utils/mon_pays_constants.dart';

class ConsultationsService {
  final Dio _dio;

  ConsultationsService(this._dio);

  Future<List<Consultation>> getAll() async {
    final response = await _dio.get('${MonPaysConstants.baseUrl}${MonPaysConstants.consultationsEndpoint}');
    return (response.data as List).map((e) => Consultation.fromJson(e)).toList();
  }

  Future<Consultation> getById(String id) async {
    final response = await _dio.get('${MonPaysConstants.baseUrl}${MonPaysConstants.consultationsEndpoint}/$id');
    return Consultation.fromJson(response.data);
  }

  Future<Consultation> create(Consultation consultation) async {
    final response = await _dio.post(
      '${MonPaysConstants.baseUrl}${MonPaysConstants.consultationsEndpoint}',
      data: consultation.toJson(),
    );
    return Consultation.fromJson(response.data);
  }

  Future<Consultation> update(Consultation consultation) async {
    final response = await _dio.put(
      '${MonPaysConstants.baseUrl}${MonPaysConstants.consultationsEndpoint}/${consultation.id}',
      data: consultation.toJson(),
    );
    return Consultation.fromJson(response.data);
  }

  Future<void> delete(String id) async {
    await _dio.delete('${MonPaysConstants.baseUrl}${MonPaysConstants.consultationsEndpoint}/$id');
  }
}
