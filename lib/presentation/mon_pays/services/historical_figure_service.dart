// lib/presentation/mon_pays/services/historical_figure_service.dart

import 'package:dio/dio.dart';
import '../models/historical_figure_model.dart';

class HistoricalFigureService {
  final Dio dio;
  final String basePath = '/historical-figures';

  HistoricalFigureService({required this.dio});

  Future<List<HistoricalFigure>> getAll() async {
    try {
      final response = await dio.get(basePath);
      final List data = response.data;
      return data.map((json) => HistoricalFigure.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur chargement figures historiques: $e');
    }
  }

  Future<HistoricalFigure> getById(String id) async {
    try {
      final response = await dio.get('$basePath/$id');
      return HistoricalFigure.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur chargement figure historique: $e');
    }
  }

  Future<HistoricalFigure> add(HistoricalFigure figure) async {
    try {
      final response = await dio.post(
        basePath,
        data: figure.toJson(),
      );
      return HistoricalFigure.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur ajout figure historique: $e');
    }
  }

  Future<HistoricalFigure> update(HistoricalFigure figure) async {
    try {
      final response = await dio.put(
        '$basePath/${figure.id}',
        data: figure.toJson(),
      );
      return HistoricalFigure.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur mise à jour figure historique: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await dio.delete('$basePath/$id');
    } catch (e) {
      throw Exception('Erreur suppression figure historique: $e');
    }
  }
}
