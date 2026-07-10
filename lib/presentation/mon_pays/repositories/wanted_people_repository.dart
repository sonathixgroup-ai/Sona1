// lib/presentation/mon_pays/repositories/wanted_people_repository.dart

import '../models/wanted_person_model.dart';
import '../services/wanted_people_service.dart';

class WantedPeopleRepository {
  final WantedPeopleService _service;

  WantedPeopleRepository(this._service);

  Future<List<WantedPerson>> getAll() => _service.getAll();
  Future<WantedPerson> getById(String id) => _service.getById(id);
  Future<WantedPerson> create(WantedPerson person) => _service.create(person);
  Future<WantedPerson> update(WantedPerson person) => _service.update(person);
  Future<void> delete(String id) => _service.delete(id);
}
