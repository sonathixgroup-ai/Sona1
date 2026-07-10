// lib/presentation/mon_pays/providers/authorities_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/authority_model.dart';
import '../repositories/authorities_repository.dart';
import 'mon_pays_provider.dart';

final authoritiesProvider = FutureProvider<List<Authority>>((ref) async {
  final repo = ref.watch(authoritiesRepositoryProvider);
  return repo.getAll();
});

final authorityProvider = FutureProvider.family<Authority, String>((ref, id) async {
  final repo = ref.watch(authoritiesRepositoryProvider);
  return repo.getById(id);
});
