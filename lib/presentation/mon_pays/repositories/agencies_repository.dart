// lib/presentation/mon_pays/repositories/agencies_repository.dart

import '../models/agency_model.dart';
import '../services/agencies_service.dart';

class AgenciesRepository {
  final AgenciesService _service;

  AgenciesRepository(this._service);

  Future<List<Agency>> getAll() => _service.getAll();
  Future<Agency> getById(String id) => _service.getById(id);
  Future<Agency> create(Agency agency) => _service.create(agency);
  Future<Agency> update(Agency agency) => _service.update(agency);
  Future<void> delete(String id) => _service.delete(id);
}
