// lib/presentation/mon_pays/repositories/citizens_repository.dart

import '../models/citizen_model.dart';
import '../services/citizens_service.dart';

class CitizensRepository {
  final CitizensService _service;

  CitizensRepository(this._service);

  Future<List<ExemplaryCitizen>> getAll() => _service.getAll();
  Future<ExemplaryCitizen> getById(String id) => _service.getById(id);
  Future<ExemplaryCitizen> create(ExemplaryCitizen citizen) => _service.create(citizen);
  Future<ExemplaryCitizen> update(ExemplaryCitizen citizen) => _service.update(citizen);
  Future<void> delete(String id) => _service.delete(id);
}
