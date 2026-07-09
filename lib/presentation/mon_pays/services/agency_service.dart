// lib/presentation/mon_pays/services/agency_service.dart

import 'package:dio/dio.dart';
import '../models/agency_model.dart';

class AgencyService {
  final Dio dio;
  final String basePath = '/agencies';

  AgencyService({required this.dio});

  Future<List<Agency>> getAll() async {
    try {
      final response = await dio.get(basePath);
      final List data = response.data;
      return data.map((json) => Agency.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur chargement agences: $e');
    }
  }

  Future<Agency> getById(String id) async {
    try {
      final response = await dio.get('$basePath/$id');
      return Agency.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur chargement agence: $e');
    }
  }

  Future<Agency> add(Agency agency) async {
    try {
      final response = await dio.post(
        basePath,
        data: agency.toJson(),
      );
      return Agency.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur ajout agence: $e');
    }
  }

  Future<Agency> update(Agency agency) async {
    try {
      final response = await dio.put(
        '$basePath/${agency.id}',
        data: agency.toJson(),
      );
      return Agency.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur mise à jour agence: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await dio.delete('$basePath/$id');
    } catch (e) {
      throw Exception('Erreur suppression agence: $e');
    }
  }
}
