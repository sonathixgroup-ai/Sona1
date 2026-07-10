// lib/presentation/mon_pays/providers/ministry_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ministry_model.dart';
import '../repositories/ministry_repository.dart';
import '../services/ministry_service.dart';
import 'mon_pays_provider.dart';

final ministryServiceProvider = Provider<MinistryService>(
  (ref) => MinistryService(ref.watch(dioProvider)),
);

final ministryRepositoryProvider = Provider<MinistryRepository>(
  (ref) => MinistryRepository(ref.watch(ministryServiceProvider)),
);

final ministriesProvider = FutureProvider<List<Ministry>>((ref) async {
  final repo = ref.watch(ministryRepositoryProvider);
  return repo.getAll();
});

final ministryProvider = FutureProvider.family<Ministry, String>((ref, id) async {
  final repo = ref.watch(ministryRepositoryProvider);
  return repo.getById(id);
});
