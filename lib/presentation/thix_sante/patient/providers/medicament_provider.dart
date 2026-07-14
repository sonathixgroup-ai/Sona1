// lib/presentation/thix_sante/patient/providers/medicament_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/medicament_service.dart';

final medicamentServiceProvider = Provider((ref) => MedicamentService());

final medicamentSearchProvider = StateProvider<String>((ref) => '');
enum MedicamentFilter { dispo, prixAsc, prixDesc, stock }
final medicamentFilterProvider = StateProvider<MedicamentFilter>((ref) => MedicamentFilter.dispo);

final medicamentsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final q = ref.watch(medicamentSearchProvider);
  final filter = ref.watch(medicamentFilterProvider);
  final service = ref.read(medicamentServiceProvider);

  switch (filter) {
    case MedicamentFilter.prixAsc:
      return service.searchMedicaments(query: q, orderBy: 'prix', ascending: true);
    case MedicamentFilter.prixDesc:
      return service.searchMedicaments(query: q, orderBy: 'prix', ascending: false);
    case MedicamentFilter.stock:
      return service.searchMedicaments(query: q, orderBy: 'quantite', ascending: false);
    default:
      return service.searchMedicaments(query: q, orderBy: 'nom', ascending: true);
  }
});

final medicamentDetailProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, id) async {
  return ref.read(medicamentServiceProvider).getStockById(id);
});
