// lib/presentation/mon_pays/providers/citizens_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/citizen_model.dart';
import '../repositories/citizens_repository.dart';
import 'mon_pays_provider.dart';

final citizensProvider = FutureProvider<List<ExemplaryCitizen>>((ref) async {
  final repo = ref.watch(citizensRepositoryProvider);
  return repo.getAll();
});

final citizenProvider = FutureProvider.family<ExemplaryCitizen, String>((ref, id) async {
  final repo = ref.watch(citizensRepositoryProvider);
  return repo.getById(id);
});
