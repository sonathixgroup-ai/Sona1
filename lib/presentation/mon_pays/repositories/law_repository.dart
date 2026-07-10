// lib/presentation/mon_pays/repositories/law_repository.dart

import '../models/law_model.dart';
import '../services/law_service.dart';

class LawRepository {
  final LawService _service;

  LawRepository(this._service);

  Future<List<Law>> getAll() => _service.getAll();
  Future<Law> getById(String id) => _service.getById(id);
  Future<Law> create(Law law) => _service.create(law);
  Future<Law> update(Law law) => _service.update(law);
  Future<void> delete(String id) => _service.delete(id);
}
