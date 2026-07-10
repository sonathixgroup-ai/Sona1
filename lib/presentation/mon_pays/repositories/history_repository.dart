// lib/presentation/mon_pays/repositories/history_repository.dart

import '../models/history_model.dart';
import '../services/history_service.dart';

class HistoryRepository {
  final HistoryService _service;

  HistoryRepository(this._service);

  Future<List<HistoricalFigure>> getAll() => _service.getAll();
  Future<HistoricalFigure> getById(String id) => _service.getById(id);
  Future<HistoricalFigure> create(HistoricalFigure figure) => _service.create(figure);
  Future<HistoricalFigure> update(HistoricalFigure figure) => _service.update(figure);
  Future<void> delete(String id) => _service.delete(id);
}
