// lib/presentation/mon_pays/providers/laws_provider.dart
// Riverpod providers pour le module Lois

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/law.dart';
import '../services/laws_service.dart';

final lawsServiceProvider = Provider((ref) => LawsService());

// Liste publique avec filtre
final lawsProvider = FutureProvider.family<List<Law>, String?>((ref, category) async {
  final service = ref.watch(lawsServiceProvider);
  return service.getLaws(category: category);
});

// Détail d'une loi
final lawDetailProvider = FutureProvider.family<Law, String>((ref, id) async {
  final service = ref.watch(lawsServiceProvider);
  return service.getLawById(id);
});

// Recherche
final searchLawsProvider = FutureProvider.family<List<Law>, String>((ref, query) async {
  final service = ref.watch(lawsServiceProvider);
  return service.searchLaws(query);
});

// ADMIN : gestion avec StateNotifier
final adminLawsProvider = StateNotifierProvider<AdminLawsNotifier, AsyncValue<List<Law>>>((ref) {
  return AdminLawsNotifier(ref);
});

class AdminLawsNotifier extends StateNotifier<AsyncValue<List<Law>>> {
  final Ref _ref;

  AdminLawsNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadLaws();
  }

  Future<void> loadLaws() async {
    state = const AsyncValue.loading();
    try {
      final service = _ref.read(lawsServiceProvider);
      final list = await service.getLaws();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> createLaw(Law law) async {
    try {
      final service = _ref.read(lawsServiceProvider);
      await service.createLaw(law);
      await loadLaws();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateLaw(Law law) async {
    try {
      final service = _ref.read(lawsServiceProvider);
      await service.updateLaw(law);
      await loadLaws();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteLaw(String id) async {
    try {
      final service = _ref.read(lawsServiceProvider);
      await service.deleteLaw(id);
      await loadLaws();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
