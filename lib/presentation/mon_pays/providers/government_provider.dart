// lib/presentation/mon_pays/providers/government_provider.dart
// Riverpod : Gouvernement

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/government.dart';
import '../services/government_service.dart';

final governmentServiceProvider = Provider((ref) => GovernmentService());

// Liste des gouvernements
final governmentsProvider = FutureProvider<List<Government>>((ref) async {
  final service = ref.watch(governmentServiceProvider);
  return service.getAllGovernments();
});

// Gouvernement actuel
final currentGovernmentProvider = FutureProvider<Government?>((ref) async {
  final service = ref.watch(governmentServiceProvider);
  try {
    return await service.getCurrentGovernment();
  } catch (e) {
    return null;
  }
});

// Détail d'un gouvernement
final governmentDetailProvider = FutureProvider.family<Government, String>((ref, id) async {
  final service = ref.watch(governmentServiceProvider);
  return service.getGovernmentById(id);
});

// ADMIN
final adminGovernmentsProvider = StateNotifierProvider<AdminGovernmentsNotifier, AsyncValue<List<Government>>>((ref) {
  return AdminGovernmentsNotifier(ref);
});

class AdminGovernmentsNotifier extends StateNotifier<AsyncValue<List<Government>>> {
  final Ref _ref;

  AdminGovernmentsNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadGovernments();
  }

  Future<void> loadGovernments() async {
    state = const AsyncValue.loading();
    try {
      final service = _ref.read(governmentServiceProvider);
      final list = await service.getAllGovernments();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> createGovernment(Government government) async {
    try {
      final service = _ref.read(governmentServiceProvider);
      await service.createGovernment(government);
      await loadGovernments();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateGovernment(Government government) async {
    try {
      final service = _ref.read(governmentServiceProvider);
      await service.updateGovernment(government);
      await loadGovernments();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteGovernment(String id) async {
    try {
      final service = _ref.read(governmentServiceProvider);
      await service.deleteGovernment(id);
      await loadGovernments();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
