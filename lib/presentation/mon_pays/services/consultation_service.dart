// lib/presentation/mon_pays/services/consultation_service.dart

import 'package:dio/dio.dart';
import '../models/consultation_model.dart';

class ConsultationService {
  final Dio dio;
  final String basePath = '/consultations';

  ConsultationService({required this.dio});

  Future<List<Consultation>> getAll() async {
    try {
      final response = await dio.get(basePath);
      final List data = response.data;
      return data.map((json) => Consultation.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur chargement consultations: $e');
    }
  }

  Future<Consultation> getById(String id) async {
    try {
      final response = await dio.get('$basePath/$id');
      return Consultation.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur chargement consultation: $e');
    }
  }

  Future<Consultation> add(Consultation consultation) async {
    try {
      final response = await dio.post(
        basePath,
        data: consultation.toJson(),
      );
      return Consultation.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur ajout consultation: $e');
    }
  }

  Future<Consultation> update(Consultation consultation) async {
    try {
      final response = await dio.put(
        '$basePath/${consultation.id}',
        data: consultation.toJson(),
      );
      return Consultation.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur mise à jour consultation: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await dio.delete('$basePath/$id');
    } catch (e) {
      throw Exception('Erreur suppression consultation: $e');
    }
  }
}
