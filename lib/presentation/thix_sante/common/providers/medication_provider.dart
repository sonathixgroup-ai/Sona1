// 📁 lib/presentation/thix_sante/common/providers/medication_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/health/medication_model.dart';
import '../../../../data/repositories/medication_repository.dart';
import '../../../../core/utils/logger.dart';

final medicationRepositoryProvider = Provider((ref) => MedicationRepository());

final medicationProvider = StateNotifierProvider<MedicationNotifier, AsyncValue<List<MedicationModel>>>((ref) {
  final repo = ref.watch(medicationRepositoryProvider);
  return MedicationNotifier(repo);
});

class MedicationNotifier extends StateNotifier<AsyncValue<List<MedicationModel>>> {
  final MedicationRepository _repository;
  bool _isLoading = false;

  MedicationNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadMedications();
  }

  bool get isLoading => _isLoading;

  Future<void> loadMedications() async {
    state = const AsyncValue.loading();
    _isLoading = true;
    try {
      final medications = await _repository.getMedications();
      state = AsyncValue.data(medications);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      Logger.error('Erreur chargement médicaments', error: e, stackTrace: st);
    } finally {
      _isLoading = false;
    }
  }

  Future<bool> addMedication({
    required String drugName,
    required String dosage,
    required TimeOfDay time,
    required List<String> days,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    _isLoading = true;
    try {
      final newMed = MedicationModel(
        id: '',
        drugName: drugName,
        dosage: dosage,
        time: time,
        days: days,
        startDate: startDate,
        endDate: endDate,
        isActive: true,
      );
      final added = await _repository.addMedication(newMed);
      if (added != null) {
        final currentList = state.value ?? [];
        state = AsyncValue.data([...currentList, added]);
        return true;
      }
      return false;
    } catch (e) {
      Logger.error('Erreur ajout médicament', error: e);
      return false;
    } finally {
      _isLoading = false;
    }
  }

  Future<bool> toggleMedication(String id, bool active) async {
    _isLoading = true;
    try {
      final success = await _repository.toggleMedication(id, active);
      if (success) {
        final currentList = state.value ?? [];
        final updatedList = currentList.map((m) {
          if (m.id == id) return m.copyWith(isActive: active);
          return m;
        }).toList();
        state = AsyncValue.data(updatedList);
        return true;
      }
      return false;
    } catch (e) {
      Logger.error('Erreur mise à jour médicament', error: e);
      return false;
    } finally {
      _isLoading = false;
    }
  }
}
