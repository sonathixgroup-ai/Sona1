// lib/presentation/mon_pays/providers/agencies_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/agency_model.dart';
import '../repositories/agencies_repository.dart';
import 'mon_pays_provider.dart';

final agenciesProvider = FutureProvider<List<Agency>>((ref) async {
  final repo = ref.watch(agenciesRepositoryProvider);
  return repo.getAll();
});

final agencyProvider = FutureProvider.family<Agency, String>((ref, id) async {
  final repo = ref.watch(agenciesRepositoryProvider);
  return repo.getById(id);
});
