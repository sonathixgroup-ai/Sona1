// 📁 lib/presentation/thix_sante/pharmacy/providers/pharmacy_order_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/prescription/prescription_model.dart';
import '../../../../data/repositories/prescription_repository.dart';
import '../../../../core/utils/logger.dart';

final pharmacyPrescriptionRepositoryProvider = Provider((ref) => PrescriptionRepository());

// État des commandes pour la pharmacie
class PharmacyOrderState {
  final List<PrescriptionModel> orders;
  final List<PrescriptionModel> filteredOrders;
  final String filterStatus; // 'all', 'pending', 'preparing', 'ready', 'delivered'
  final bool isLoading;
  final String? error;

  PharmacyOrderState({
    this.orders = const [],
    this.filteredOrders = const [],
    this.filterStatus = 'all',
    this.isLoading = false,
    this.error,
  });

  PharmacyOrderState copyWith({
    List<PrescriptionModel>? orders,
    List<PrescriptionModel>? filteredOrders,
    String? filterStatus,
    bool? isLoading,
    String? error,
  }) {
    return PharmacyOrderState(
      orders: orders ?? this.orders,
      filteredOrders: filteredOrders ?? this.filteredOrders,
      filterStatus: filterStatus ?? this.filterStatus,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

final pharmacyOrderProvider = StateNotifierProvider<PharmacyOrderNotifier, PharmacyOrderState>((ref) {
  return PharmacyOrderNotifier(ref);
});

class PharmacyOrderNotifier extends StateNotifier<PharmacyOrderState> {
  final Ref _ref;

  PharmacyOrderNotifier(this._ref) : super(PharmacyOrderState(isLoading: true)) {
    loadOrders();
  }

  Future<void> loadOrders() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = _ref.read(pharmacyPrescriptionRepositoryProvider);
      final orders = await repo.getPrescriptions(); // à adapter pour ne récupérer que celles de la pharmacie
      state = PharmacyOrderState(
        orders: orders,
        filteredOrders: orders,
        isLoading: false,
        filterStatus: state.filterStatus,
      );
    } catch (e, st) {
      Logger.error('Erreur chargement commandes', error: e, stackTrace: st);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setFilter(String status) {
    final filtered = status == 'all'
        ? state.orders
        : state.orders.where((o) => o.status == status).toList();
    state = state.copyWith(
      filterStatus: status,
      filteredOrders: filtered,
    );
  }

  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    try {
      final repo = _ref.read(pharmacyPrescriptionRepositoryProvider);
      final success = await repo.updatePrescriptionStatus(orderId, newStatus);
      if (success) {
        // Mettre à jour la liste
        final updatedOrders = state.orders.map((o) {
          if (o.id == orderId) return o.copyWith(status: newStatus);
          return o;
        }).toList();
        // Recalculer les filtrés
        final filtered = state.filterStatus == 'all'
            ? updatedOrders
            : updatedOrders.where((o) => o.status == state.filterStatus).toList();
        state = state.copyWith(
          orders: updatedOrders,
          filteredOrders: filtered,
        );
        return true;
      }
      return false;
    } catch (e) {
      Logger.error('Erreur mise à jour statut commande', error: e);
      return false;
    }
  }

  Future<bool> validatePrescription(String orderId) async {
    return updateOrderStatus(orderId, 'validated');
  }

  Future<bool> preparePrescription(String orderId) async {
    return updateOrderStatus(orderId, 'preparing');
  }

  Future<bool> markAsDelivered(String orderId) async {
    return updateOrderStatus(orderId, 'delivered');
  }
}
