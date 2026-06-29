// 📁 lib/presentation/thix_sante/common/providers/alert_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/alert/alert_model.dart';
import '../../../../data/repositories/alert_repository.dart';
import '../../../../core/utils/logger.dart';

final alertRepositoryProvider = Provider((ref) => AlertRepository());

final alertProvider = StateNotifierProvider<AlertNotifier, AsyncValue<List<AlertModel>>>((ref) {
  final repo = ref.watch(alertRepositoryProvider);
  return AlertNotifier(repo);
});

class AlertNotifier extends StateNotifier<AsyncValue<List<AlertModel>>> {
  final AlertRepository _repository;
  bool _isLoading = false;

  AlertNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadAlerts();
  }

  bool get isLoading => _isLoading;

  Future<void> loadAlerts() async {
    state = const AsyncValue.loading();
    _isLoading = true;
    try {
      final alerts = await _repository.getAlerts();
      state = AsyncValue.data(alerts);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      Logger.error('Erreur chargement alertes', error: e, stackTrace: st);
    } finally {
      _isLoading = false;
    }
  }

  Future<bool> markAsRead(String id) async {
    try {
      final success = await _repository.markAsRead(id);
      if (success) {
        final currentList = state.value ?? [];
        final updatedList = currentList.map((a) {
          if (a.id == id) return a.copyWith(isRead: true);
          return a;
        }).toList();
        state = AsyncValue.data(updatedList);
        return true;
      }
      return false;
    } catch (e) {
      Logger.error('Erreur marquage alerte lue', error: e);
      return false;
    }
  }
}
