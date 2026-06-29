// 📁 lib/presentation/thix_sante/pharmacy/providers/pharmacy_inventory_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/prescription/drug_model.dart';
import '../../../../data/repositories/drug_repository.dart';
import '../../../../core/utils/logger.dart';

final drugRepositoryProvider = Provider((ref) => DrugRepository());

// État de l'inventaire
class PharmacyInventoryState {
  final List<DrugModel> drugs;
  final List<DrugModel> filteredDrugs;
  final bool isLoading;
  final String? error;
  final String searchQuery;

  PharmacyInventoryState({
    this.drugs = const [],
    this.filteredDrugs = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
  });

  PharmacyInventoryState copyWith({
    List<DrugModel>? drugs,
    List<DrugModel>? filteredDrugs,
    bool? isLoading,
    String? error,
    String? searchQuery,
  }) {
    return PharmacyInventoryState(
      drugs: drugs ?? this.drugs,
      filteredDrugs: filteredDrugs ?? this.filteredDrugs,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

final pharmacyInventoryProvider = StateNotifierProvider<PharmacyInventoryNotifier, PharmacyInventoryState>((ref) {
  return PharmacyInventoryNotifier(ref);
});

class PharmacyInventoryNotifier extends StateNotifier<PharmacyInventoryState> {
  final Ref _ref;

  PharmacyInventoryNotifier(this._ref) : super(PharmacyInventoryState(isLoading: true)) {
    loadInventory();
  }

  Future<void> loadInventory() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = _ref.read(drugRepositoryProvider);
      final drugs = await repo.getDrugs(); // à adapter selon pharmacie
      state = PharmacyInventoryState(
        drugs: drugs,
        filteredDrugs: drugs,
        isLoading: false,
      );
    } catch (e, st) {
      Logger.error('Erreur chargement inventaire', error: e, stackTrace: st);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void searchDrugs(String query) {
    final lowerQuery = query.toLowerCase().trim();
    if (lowerQuery.isEmpty) {
      state = state.copyWith(
        filteredDrugs: state.drugs,
        searchQuery: '',
      );
      return;
    }
    final filtered = state.drugs.where((d) =>
      d.name.toLowerCase().contains(lowerQuery) ||
      d.dosage.toLowerCase().contains(lowerQuery)
    ).toList();
    state = state.copyWith(
      filteredDrugs: filtered,
      searchQuery: query,
    );
  }

  Future<bool> updateStock(String drugId, int newQuantity) async {
    try {
      final repo = _ref.read(drugRepositoryProvider);
      final success = await repo.updateStock(drugId, newQuantity);
      if (success) {
        // Mettre à jour la liste
        final updatedDrugs = state.drugs.map((d) {
          if (d.id == drugId) return d.copyWith(quantity: newQuantity);
          return d;
        }).toList();
        // Recalculer les filtrés
        final filtered = state.searchQuery.isEmpty
            ? updatedDrugs
            : updatedDrugs.where((d) =>
                d.name.toLowerCase().contains(state.searchQuery.toLowerCase()) ||
                d.dosage.toLowerCase().contains(state.searchQuery.toLowerCase())
              ).toList();
        state = state.copyWith(
          drugs: updatedDrugs,
          filteredDrugs: filtered,
        );
        return true;
      }
      return false;
    } catch (e) {
      Logger.error('Erreur mise à jour stock', error: e);
      return false;
    }
  }

  Future<bool> addDrug(DrugModel drug) async {
    try {
      final repo = _ref.read(drugRepositoryProvider);
      final added = await repo.addDrug(drug);
      if (added != null) {
        final updatedDrugs = [...state.drugs, added];
        state = state.copyWith(
          drugs: updatedDrugs,
          filteredDrugs: updatedDrugs,
        );
        return true;
      }
      return false;
    } catch (e) {
      Logger.error('Erreur ajout médicament', error: e);
      return false;
    }
  }
}
