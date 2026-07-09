// lib/presentation/mon_pays/providers/consultations_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/consultation_model.dart';
import '../repositories/consultations_repository.dart';
import 'mon_pays_provider.dart';

final consultationsProvider = FutureProvider<List<Consultation>>((ref) async {
  final repo = ref.watch(consultationsRepositoryProvider);
  return repo.getAll();
});

final consultationProvider = FutureProvider.family<Consultation, String>((ref, id) async {
  final repo = ref.watch(consultationsRepositoryProvider);
  return repo.getById(id);
});
