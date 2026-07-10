// lib/presentation/mon_pays/providers/ministry_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ministry_model.dart';
import '../repositories/ministry_repository.dart';
import 'mon_pays_provider.dart';

final ministriesProvider = FutureProvider<List<Ministry>>((ref) async {
  final repo = ref.watch(ministryRepositoryProvider);
  return repo.getAll();
});

final ministryProvider = FutureProvider.family<Ministry, String>((ref, id) async {
  final repo = ref.watch(ministryRepositoryProvider);
  return repo.getById(id);
});
