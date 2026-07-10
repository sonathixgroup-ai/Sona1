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

// Constitution
final constitutionProvider = FutureProvider<Value>((ref) async {
  final repo = ref.watch(valuesRepositoryProvider);
  final values = await repo.getAll();
  return values.firstWhere((v) => v.title == 'Constitution');
});

// Lois
final lawsProvider = FutureProvider<List<Value>>((ref) async {
  final repo = ref.watch(valuesRepositoryProvider);
  final values = await repo.getAll();
  return values.where((v) => v.category == 'Lois' || v.title.contains('Loi')).toList();
});

// Institutions
final institutionsProvider = FutureProvider<List<Value>>((ref) async {
  final repo = ref.watch(valuesRepositoryProvider);
  final values = await repo.getAll();
  return values.where((v) => v.category == 'Institutions' || v.title.contains('Institution')).toList();
});

// Droits
final rightsProvider = FutureProvider<List<Value>>((ref) async {
  final repo = ref.watch(valuesRepositoryProvider);
  final values = await repo.getAll();
  return values.where((v) => v.category == 'Droits' || v.title.contains('Droit')).toList();
});

// Devoirs
final dutiesProvider = FutureProvider<List<Value>>((ref) async {
  final repo = ref.watch(valuesRepositoryProvider);
  final values = await repo.getAll();
  return values.where((v) => v.category == 'Devoirs' || v.title.contains('Devoir')).toList();
});

// Justice
final justiceProvider = FutureProvider<Value>((ref) async {
  final repo = ref.watch(valuesRepositoryProvider);
  final values = await repo.getAll();
  return values.firstWhere((v) => v.title == 'Justice');
});
