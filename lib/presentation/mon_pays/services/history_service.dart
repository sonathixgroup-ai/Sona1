// lib/presentation/mon_pays/services/history_service.dart

import 'package:dio/dio.dart';
import '../models/history_model.dart';
import '../utils/mon_pays_constants.dart';

class HistoryService {
  final Dio _dio;

  HistoryService(this._dio);

  Future<List<HistoricalFigure>> getAll() async {
    final response = await _dio.get('${MonPaysConstants.baseUrl}${MonPaysConstants.historyEndpoint}');
    return (response.data as List).map((e) => HistoricalFigure.fromJson(e)).toList();
  }

  Future<HistoricalFigure> getById(String id) async {
    final response = await _dio.get('${MonPaysConstants.baseUrl}${MonPaysConstants.historyEndpoint}/$id');
    return HistoricalFigure.fromJson(response.data);
  }

  Future<HistoricalFigure> create(HistoricalFigure figure) async {
    final response = await _dio.post(
      '${MonPaysConstants.baseUrl}${MonPaysConstants.historyEndpoint}',
      data: figure.toJson(),
    );
    return HistoricalFigure.fromJson(response.data);
  }

  Future<HistoricalFigure> update(HistoricalFigure figure) async {
    final response = await _dio.put(
      '${MonPaysConstants.baseUrl}${MonPaysConstants.historyEndpoint}/${figure.id}',
      data: figure.toJson(),
    );
    return HistoricalFigure.fromJson(response.data);
  }

  Future<void> delete(String id) async {
    await _dio.delete('${MonPaysConstants.baseUrl}${MonPaysConstants.historyEndpoint}/$id');
  }
}
