
// lib/presentation/mon_pays/providers/documentaries_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/documentary_model.dart';
import '../repositories/documentaries_repository.dart';
import 'mon_pays_provider.dart';

final documentariesProvider = FutureProvider<List<Documentary>>((ref) async {
  final repo = ref.watch(documentariesRepositoryProvider);
  return repo.getAll();
});

final documentaryProvider = FutureProvider.family<Documentary, String>((ref, id) async {
  final repo = ref.watch(documentariesRepositoryProvider);
  return repo.getById(id);
});
