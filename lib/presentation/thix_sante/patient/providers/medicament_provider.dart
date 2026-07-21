// lib/presentation/thix_sante/patient/providers/medicament_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum MedicamentFilter { all, dispo, prixAsc, prixDesc, stock }

// ============ LEGACY (pour ton ancienne page) ============
final medicamentSearchProvider = StateProvider<String>((ref) => '');
final medicamentFilterProvider = StateProvider<MedicamentFilter>((ref) => MedicamentFilter.all);

// Liste globale avec filtres réels Supabase
final medicamentsProvider = FutureProvider<List<Map<String,dynamic>>>((ref) async {
  final supabase = Supabase.instance.client;
  final search = ref.watch(medicamentSearchProvider).toLowerCase();
  final filter = ref.watch(medicamentFilterProvider);

  var query = supabase.from('thix_medicines').select('*, thix_pharmacies(nom, adresse)');

  if (search.isNotEmpty) {
    query = query.or('nom.ilike.%$search%,dci.ilike.%$search%');
  }

  // Filtres prod
  switch (filter) {
    case MedicamentFilter.dispo:
      query = query.gt('stock', 0);
      break;
    case MedicamentFilter.stock:
      query = query.order('stock', ascending: false);
      break;
    case MedicamentFilter.prixAsc:
      query = query.order('prix', ascending: true);
      break;
    case MedicamentFilter.prixDesc:
      query = query.order('prix', ascending: false);
      break;
    case MedicamentFilter.all:
      query = query.order('nom', ascending: true);
      break;
  }

  // Si pas de order déjà mis par filtre
  if (filter == MedicamentFilter.all || filter == MedicamentFilter.dispo) {
    query = query.order('nom');
  }

  final res = await query.limit(100);
  return List<Map<String,dynamic>>.from(res);
});

// ============ NOUVEAU FLOW ORDER MEDICINE (photo) ============
final searchQueryProvider = StateProvider<String>((ref) {
  // Sync avec l'ancien search pour pas avoir 2 champs
  return ref.watch(medicamentSearchProvider);
});

final selectedCategoryProvider = StateProvider<String?>((ref) => null);
final selectedPharmacyProvider = StateProvider<Map<String,dynamic>?>((ref) => null);

final nearbyPharmaciesProvider = FutureProvider<List<Map<String,dynamic>>>((ref) async {
  final supabase = Supabase.instance.client;
  final query = ref.watch(searchQueryProvider);
  final cat = ref.watch(selectedCategoryProvider);

  var req = supabase.from('thix_pharmacies').select();
  if (query.isNotEmpty) {
    req = req.ilike('nom', '%$query%');
  }
  final res = await req.eq('is_open', true).order('rating', ascending: false).limit(20);
  var list = List<Map<String,dynamic>>.from(res);

  if (cat != null) {
    final meds = await supabase.from('thix_medicines').select('pharmacy_id').eq('categorie', cat).gt('stock', 0);
    final ids = meds.map((e) => e['pharmacy_id']).toSet();
    list = list.where((p) => ids.contains(p['id'])).toList();
  }
  return list;
});

final medicinesByPharmacyProvider = FutureProvider.family<List<Map<String,dynamic>>, String>((ref, pharmacyId) async {
  final supabase = Supabase.instance.client;
  final res = await supabase
      .from('thix_medicines')
      .select()
      .eq('pharmacy_id', pharmacyId)
      .gt('stock', 0)
      .order('nom');
  return List<Map<String,dynamic>>.from(res);
});

final cartProvider = FutureProvider<List<Map<String,dynamic>>>((ref) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;
  if (user == null) return [];
  final res = await supabase
      .from('thix_medicine_cart')
      .select('*, thix_medicines(*)')
      .eq('user_id', user.id)
      .order('created_at');
  return List<Map<String,dynamic>>.from(res);
});

final cartTotalProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider).value ?? [];
  double total = 0;
  for (final c in cart) {
    final med = c['thix_medicines'];
    if (med != null) {
      total += (med['prix'] as num? ?? 0) * (c['quantity'] as int? ?? 1);
    }
  }
  return total;
});
