// lib/presentation/mon_pays/providers/values_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/value_model.dart';
import '../repositories/values_repository.dart';
import 'mon_pays_provider.dart';

final valuesProvider = FutureProvider<List<Value>>((ref) async {
  final repo = ref.watch(valuesRepositoryProvider);
  return repo.getAll();
});

final valueProvider = FutureProvider.family<Value, String>((ref, id) async {
  final repo = ref.watch(valuesRepositoryProvider);
  return repo.getById(id);
});
