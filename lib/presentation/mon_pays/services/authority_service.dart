// lib/presentation/mon_pays/services/authority_service.dart

import 'package:dio/dio.dart';
import '../models/authority_model.dart';

class AuthorityService {
  final Dio dio;
  final String basePath = '/authorities';

  AuthorityService({required this.dio});

  Future<List<Authority>> getAll() async {
    try {
      final response = await dio.get(basePath);
      final List data = response.data;
      return data.map((json) => Authority.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur chargement autorités: $e');
    }
  }

  Future<Authority> getById(String id) async {
    try {
      final response = await dio.get('$basePath/$id');
      return Authority.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur chargement autorité: $e');
    }
  }

  Future<Authority> add(Authority authority) async {
    try {
      final response = await dio.post(
        basePath,
        data: authority.toJson(),
      );
      return Authority.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur ajout autorité: $e');
    }
  }

  Future<Authority> update(Authority authority) async {
    try {
      final response = await dio.put(
        '$basePath/${authority.id}',
        data: authority.toJson(),
      );
      return Authority.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur mise à jour autorité: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await dio.delete('$basePath/$id');
    } catch (e) {
      throw Exception('Erreur suppression autorité: $e');
    }
  }
}
