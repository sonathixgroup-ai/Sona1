// lib/presentation/mon_pays/repositories/authorities_repository.dart

import '../models/authority_model.dart';
import '../services/authorities_service.dart';

class AuthoritiesRepository {
  final AuthoritiesService _service;

  AuthoritiesRepository(this._service);

  Future<List<Authority>> getAll() => _service.getAll();
  Future<Authority> getById(String id) => _service.getById(id);
  Future<Authority> create(Authority authority) => _service.create(authority);
  Future<Authority> update(Authority authority) => _service.update(authority);
  Future<void> delete(String id) => _service.delete(id);
}
