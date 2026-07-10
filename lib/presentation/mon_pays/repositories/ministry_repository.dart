// lib/presentation/mon_pays/repositories/ministry_repository.dart

import '../models/ministry_model.dart';
import '../services/ministry_service.dart';

class MinistryRepository {
  final MinistryService _service;

  MinistryRepository(this._service);

  Future<List<Ministry>> getAll() => _service.getAll();
  Future<Ministry> getById(String id) => _service.getById(id);
  Future<Ministry> create(Ministry ministry) => _service.create(ministry);
  Future<Ministry> update(Ministry ministry) => _service.update(ministry);
  Future<void> delete(String id) => _service.delete(id);
}
