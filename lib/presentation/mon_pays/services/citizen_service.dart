// lib/presentation/mon_pays/services/citizen_service.dart

import 'package:dio/dio.dart';
import '../models/exemplary_citizen_model.dart';

class CitizenService {
  final Dio dio;
  final String basePath = '/exemplary-citizens';

  CitizenService({required this.dio});

  Future<List<ExemplaryCitizen>> getAll() async {
    try {
      final response = await dio.get(basePath);
      final List data = response.data;
      return data.map((json) => ExemplaryCitizen.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur chargement citoyens exemplaires: $e');
    }
  }

  Future<ExemplaryCitizen> getById(String id) async {
    try {
      final response = await dio.get('$basePath/$id');
      return ExemplaryCitizen.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur chargement citoyen exemplaire: $e');
    }
  }

  Future<ExemplaryCitizen> add(ExemplaryCitizen citizen) async {
    try {
      final response = await dio.post(
        basePath,
        data: citizen.toJson(),
      );
      return ExemplaryCitizen.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur ajout citoyen exemplaire: $e');
    }
  }

  Future<ExemplaryCitizen> update(ExemplaryCitizen citizen) async {
    try {
      final response = await dio.put(
        '$basePath/${citizen.id}',
        data: citizen.toJson(),
      );
      return ExemplaryCitizen.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur mise à jour citoyen exemplaire: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await dio.delete('$basePath/$id');
    } catch (e) {
      throw Exception('Erreur suppression citoyen exemplaire: $e');
    }
  }
}
