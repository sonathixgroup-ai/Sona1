// lib/presentation/mon_pays/services/documentary_service.dart

import 'package:dio/dio.dart';
import '../models/documentary_model.dart';

class DocumentaryService {
  final Dio dio;
  final String basePath = '/documentaries';

  DocumentaryService({required this.dio});

  Future<List<Documentary>> getAll() async {
    try {
      final response = await dio.get(basePath);
      final List data = response.data;
      return data.map((json) => Documentary.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur chargement documentaires: $e');
    }
  }

  Future<Documentary> getById(String id) async {
    try {
      final response = await dio.get('$basePath/$id');
      return Documentary.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur chargement documentaire: $e');
    }
  }

  Future<Documentary> add(Documentary doc) async {
    try {
      final response = await dio.post(
        basePath,
        data: doc.toJson(),
      );
      return Documentary.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur ajout documentaire: $e');
    }
  }

  Future<Documentary> update(Documentary doc) async {
    try {
      final response = await dio.put(
        '$basePath/${doc.id}',
        data: doc.toJson(),
      );
      return Documentary.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur mise à jour documentaire: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await dio.delete('$basePath/$id');
    } catch (e) {
      throw Exception('Erreur suppression documentaire: $e');
    }
  }
}
