// 📁 lib/presentation/thix_sante/pharmacy/providers/pharmacy_delivery_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/delivery/delivery_model.dart';
import '../../../../data/repositories/delivery_repository.dart';
import '../../../../core/utils/logger.dart';

final deliveryRepositoryProvider = Provider((ref) => DeliveryRepository());

// État des livraisons
class PharmacyDeliveryState {
  final List<DeliveryModel> deliveries;
  final List<DeliveryModel> activeDeliveries;
  final List<DeliveryModel> completedDeliveries;
  final bool isLoading;
  final String? error;

  PharmacyDeliveryState({
    this.deliveries = const [],
    this.activeDeliveries = const [],
    this.completedDeliveries = const [],
    this.isLoading = false,
    this.error,
  });

  PharmacyDeliveryState copyWith({
    List<DeliveryModel>? deliveries,
    List<DeliveryModel>? activeDeliveries,
    List<DeliveryModel>? completedDeliveries,
    bool? isLoading,
    String? error,
  }) {
    return PharmacyDeliveryState(
      deliveries: deliveries ?? this.deliveries,
      activeDeliveries: activeDeliveries ?? this.activeDeliveries,
      completedDeliveries: completedDeliveries ?? this.completedDeliveries,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

final pharmacyDeliveryProvider = StateNotifierProvider<PharmacyDeliveryNotifier, PharmacyDeliveryState>((ref) {
  return PharmacyDeliveryNotifier(ref);
});

class PharmacyDeliveryNotifier extends StateNotifier<PharmacyDeliveryState> {
  final Ref _ref;

  PharmacyDeliveryNotifier(this._ref) : super(PharmacyDeliveryState(isLoading: true)) {
    loadDeliveries();
  }

  Future<void> loadDeliveries() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = _ref.read(deliveryRepositoryProvider);
      final deliveries = await repo.getDeliveries(); // à adapter selon pharmacie
      final active = deliveries.where((d) => d.status != 'delivered').toList();
      final completed = deliveries.where((d) => d.status == 'delivered').toList();
      state = PharmacyDeliveryState(
        deliveries: deliveries,
        activeDeliveries: active,
        completedDeliveries: completed,
        isLoading: false,
      );
    } catch (e, st) {
      Logger.error('Erreur chargement livraisons', error: e, stackTrace: st);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> updateDeliveryStatus(String deliveryId, String newStatus) async {
    try {
      final repo = _ref.read(deliveryRepositoryProvider);
      final success = await repo.updateDeliveryStatus(deliveryId, newStatus);
      if (success) {
        // Mettre à jour les listes
        final updatedDeliveries = state.deliveries.map((d) {
          if (d.id == deliveryId) return d.copyWith(status: newStatus);
          return d;
        }).toList();
        final active = updatedDeliveries.where((d) => d.status != 'delivered').toList();
        final completed = updatedDeliveries.where((d) => d.status == 'delivered').toList();
        state = state.copyWith(
          deliveries: updatedDeliveries,
          activeDeliveries: active,
          completedDeliveries: completed,
        );
        return true;
      }
      return false;
    } catch (e) {
      Logger.error('Erreur mise à jour livraison', error: e);
      return false;
    }
  }

  Future<bool> startDelivery(String deliveryId) async {
    return updateDeliveryStatus(deliveryId, 'in_transit');
  }

  Future<bool> completeDelivery(String deliveryId) async {
    return updateDeliveryStatus(deliveryId, 'delivered');
  }
}
