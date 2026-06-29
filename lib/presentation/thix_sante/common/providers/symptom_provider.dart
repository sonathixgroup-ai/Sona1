// 📁 lib/presentation/thix_sante/common/providers/symptom_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/health/symptom_model.dart';
import '../../../../data/repositories/symptom_repository.dart';
import '../../../../core/utils/logger.dart';

// Repository provider (à injecter)
final symptomRepositoryProvider = Provider((ref) => SymptomRepository());

// Provider principal
final symptomProvider = StateNotifierProvider<SymptomNotifier, AsyncValue<List<SymptomModel>>>((ref) {
  final repo = ref.watch(symptomRepositoryProvider);
  return SymptomNotifier(repo);
});

class SymptomNotifier extends StateNotifier<AsyncValue<List<SymptomModel>>> {
  final SymptomRepository _repository;
  bool _isLoading = false;

  SymptomNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadSymptoms();
  }

  bool get isLoading => _isLoading;

  Future<void> loadSymptoms() async {
    state = const AsyncValue.loading();
    _isLoading = true;
    try {
      final symptoms = await _repository.getSymptoms();
      state = AsyncValue.data(symptoms);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      Logger.error('Erreur chargement symptômes', error: e, stackTrace: st);
    } finally {
      _isLoading = false;
    }
  }

  Future<bool> addSymptom({
    required String nom,
    required int intensité,
    required DateTime date,
    String? notes,
  }) async {
    _isLoading = true;
    try {
      final newSymptom = SymptomModel(
        id: '', // généré par Supabase
        nom: nom,
        intensité: intensité,
        date: date,
        notes: notes,
      );
      final added = await _repository.addSymptom(newSymptom);
      if (added != null) {
        final currentList = state.value ?? [];
        state = AsyncValue.data([...currentList, added]);
        return true;
      }
      return false;
    } catch (e) {
      Logger.error('Erreur ajout symptôme', error: e);
      return false;
    } finally {
      _isLoading = false;
    }
  }

  Future<bool> deleteSymptom(String id) async {
    _isLoading = true;
    try {
      final success = await _repository.deleteSymptom(id);
      if (success) {
        final currentList = state.value ?? [];
        state = AsyncValue.data(currentList.where((s) => s.id != id).toList());
        return true;
      }
      return false;
    } catch (e) {
      Logger.error('Erreur suppression symptôme', error: e);
      return false;
    } finally {
      _isLoading = false;
    }
  }
}
