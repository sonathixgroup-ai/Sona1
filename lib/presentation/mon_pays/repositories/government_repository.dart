// lib/presentation/mon_pays/repositories/documentaries_repository.dart

import '../models/documentary_model.dart';
import '../services/documentaries_service.dart';

class DocumentariesRepository {
  final DocumentariesService _service;

  DocumentariesRepository(this._service);

  Future<List<Documentary>> getAll() => _service.getAll();
  Future<Documentary> getById(String id) => _service.getById(id);
  Future<Documentary> create(Documentary documentary) => _service.create(documentary);
  Future<Documentary> update(Documentary documentary) => _service.update(documentary);
  Future<void> delete(String id) => _service.delete(id);
}
