// lib/presentation/mon_pays/services/wanted_service.dart

import 'package:dio/dio.dart';
import '../models/wanted_person_model.dart';

class WantedService {
  final Dio dio;
  final String basePath = '/wanted-persons';

  WantedService({required this.dio});

  Future<List<WantedPerson>> getAll() async {
    try {
      final response = await dio.get(basePath);
      final List data = response.data;
      return data.map((json) => WantedPerson.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur chargement personnes recherchées: $e');
    }
  }

  Future<WantedPerson> getById(String id) async {
    try {
      final response = await dio.get('$basePath/$id');
      return WantedPerson.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur chargement personne recherchée: $e');
    }
  }

  Future<WantedPerson> add(WantedPerson person) async {
    try {
      final response = await dio.post(
        basePath,
        data: person.toJson(),
      );
      return WantedPerson.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur ajout personne recherchée: $e');
    }
  }

  Future<WantedPerson> update(WantedPerson person) async {
    try {
      final response = await dio.put(
        '$basePath/${person.id}',
        data: person.toJson(),
      );
      return WantedPerson.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur mise à jour personne recherchée: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await dio.delete('$basePath/$id');
    } catch (e) {
      throw Exception('Erreur suppression personne recherchée: $e');
    }
  }

  /// Signalement d'une personne par un citoyen
  Future<void> reportPerson(String personId, {required String details, String? location}) async {
    try {
      await dio.post(
        '$basePath/$personId/report',
        data: {
          'details': details,
          'location': location ?? '',
        },
      );
    } catch (e) {
      throw Exception('Erreur lors du signalement: $e');
    }
  }
}
