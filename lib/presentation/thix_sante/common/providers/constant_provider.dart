// 📁 lib/presentation/thix_sante/common/providers/constant_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/health/constant_model.dart';
import '../../../../data/repositories/constant_repository.dart';
import '../../../../core/utils/logger.dart';

final constantRepositoryProvider = Provider((ref) => ConstantRepository());

final constantProvider = StateNotifierProvider<ConstantNotifier, AsyncValue<List<ConstantModel>>>((ref) {
  final repo = ref.watch(constantRepositoryProvider);
  return ConstantNotifier(repo);
});

class ConstantNotifier extends StateNotifier<AsyncValue<List<ConstantModel>>> {
  final ConstantRepository _repository;
  bool _isLoading = false;

  ConstantNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadConstants();
  }

  bool get isLoading => _isLoading;

  Future<void> loadConstants() async {
    state = const AsyncValue.loading();
    _isLoading = true;
    try {
      final constants = await _repository.getConstants();
      state = AsyncValue.data(constants);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      Logger.error('Erreur chargement constantes', error: e, stackTrace: st);
    } finally {
      _isLoading = false;
    }
  }

  Future<bool> addConstant({
    double? tensionSystolic,
    double? tensionDiastolic,
    double? glycemie,
    double? poids,
  }) async {
    _isLoading = true;
    try {
      final newConstant = ConstantModel(
        id: '',
        date: DateTime.now(),
        tensionSystolic: tensionSystolic,
        tensionDiastolic: tensionDiastolic,
        glycemie: glycemie,
        poids: poids,
      );
      final added = await _repository.addConstant(newConstant);
      if (added != null) {
        final currentList = state.value ?? [];
        state = AsyncValue.data([...currentList, added]);
        return true;
      }
      return false;
    } catch (e) {
      Logger.error('Erreur ajout constante', error: e);
      return false;
    } finally {
      _isLoading = false;
    }
  }
}
