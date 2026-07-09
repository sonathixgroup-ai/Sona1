// lib/presentation/mon_pays/services/law_service.dart

import 'package:dio/dio.dart';
import '../models/law_model.dart';

class LawService {
  final Dio dio;
  final String basePath = '/laws';

  LawService({required this.dio});

  Future<List<Law>> getAll() async {
    try {
      final response = await dio.get(basePath);
      final List data = response.data;
      return data.map((json) => Law.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur chargement lois: $e');
    }
  }

  Future<Law> getById(String id) async {
    try {
      final response = await dio.get('$basePath/$id');
      return Law.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur chargement loi: $e');
    }
  }

  Future<Law> add(Law law) async {
    try {
      final response = await dio.post(
        basePath,
        data: law.toJson(),
      );
      return Law.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur ajout loi: $e');
    }
  }

  Future<Law> update(Law law) async {
    try {
      final response = await dio.put(
        '$basePath/${law.id}',
        data: law.toJson(),
      );
      return Law.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur mise à jour loi: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await dio.delete('$basePath/$id');
    } catch (e) {
      throw Exception('Erreur suppression loi: $e');
    }
  }
}
