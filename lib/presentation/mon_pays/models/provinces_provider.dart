// lib/presentation/mon_pays/providers/provinces_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/province.dart';
import '../services/provinces_service.dart';

// Service instance
final provincesServiceProvider = Provider((ref) => ProvincesService());

// Liste des provinces
final provincesListProvider = FutureProvider<List<Province>>((ref) async {
  return ref.watch(provincesServiceProvider).getProvinces();
});

// Détail d'une province spécifique
final provinceDetailProvider = FutureProvider.family<Province, String>((ref, id) async {
  return ref.watch(provincesServiceProvider).getProvinceById(id);
});

// Logic de gestion (Notifier)
class ProvincesNotifier extends StateNotifier<AsyncValue<List<Province>>> {
  final ProvincesService _service;
  
  ProvincesNotifier(this._service) : super(const AsyncValue.loading());

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final data = await _service.getProvinces();
      state = AsyncValue.data(data);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final provincesNotifierProvider = StateNotifierProvider<ProvincesNotifier, AsyncValue<List<Province>>>((ref) {
  return ProvincesNotifier(ref.watch(provincesServiceProvider));
});
