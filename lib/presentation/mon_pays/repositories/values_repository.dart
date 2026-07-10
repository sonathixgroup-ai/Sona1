// lib/presentation/mon_pays/repositories/values_repository.dart

import '../models/value_model.dart';
import '../services/values_service.dart';

class ValuesRepository {
  final ValuesService _service;

  ValuesRepository(this._service);

  Future<List<Value>> getAll() => _service.getAll();
  Future<Value> getById(String id) => _service.getById(id);
  Future<Value> create(Value value) => _service.create(value);
  Future<Value> update(Value value) => _service.update(value);
  Future<void> delete(String id) => _service.delete(id);
}
