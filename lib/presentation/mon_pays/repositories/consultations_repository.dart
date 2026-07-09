// lib/presentation/mon_pays/repositories/consultations_repository.dart

import '../models/consultation_model.dart';
import '../services/consultations_service.dart';

class ConsultationsRepository {
  final ConsultationsService _service;

  ConsultationsRepository(this._service);

  Future<List<Consultation>> getAll() => _service.getAll();
  Future<Consultation> getById(String id) => _service.getById(id);
  Future<Consultation> create(Consultation consultation) => _service.create(consultation);
  Future<Consultation> update(Consultation consultation) => _service.update(consultation);
  Future<void> delete(String id) => _service.delete(id);
}
