// lib/presentation/mon_pays/providers/government_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/government_model.dart';
import '../repositories/government_repository.dart';
import 'mon_pays_provider.dart';

final governmentProvider = FutureProvider<List<Government>>((ref) async {
  final repo = ref.watch(governmentRepositoryProvider);
  return repo.getAll();
});

final governmentItemProvider = FutureProvider.family<Government, String>((ref, id) async {
  final repo = ref.watch(governmentRepositoryProvider);
  return repo.getById(id);
});
