// lib/presentation/mon_pays/repositories/government_repository.dart

import '../models/government_model.dart';
import '../services/government_service.dart';

class GovernmentRepository {
  final GovernmentService _service;

  GovernmentRepository(this._service);

  Future<List<Government>> getAll() => _service.getAll();
  Future<Government> getById(String id) => _service.getById(id);
  Future<Government> create(Government gov) => _service.create(gov);
  Future<Government> update(Government gov) => _service.update(gov);
  Future<void> delete(String id) => _service.delete(id);
}
