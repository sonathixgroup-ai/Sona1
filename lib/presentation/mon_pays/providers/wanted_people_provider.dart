
// lib/presentation/mon_pays/providers/wanted_people_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wanted_person_model.dart';
import '../repositories/wanted_people_repository.dart';
import 'mon_pays_provider.dart';

final wantedPeopleProvider = FutureProvider<List<WantedPerson>>((ref) async {
  final repo = ref.watch(wantedPeopleRepositoryProvider);
  return repo.getAll();
});

final wantedPersonProvider = FutureProvider.family<WantedPerson, String>((ref, id) async {
  final repo = ref.watch(wantedPeopleRepositoryProvider);
  return repo.getById(id);
});
