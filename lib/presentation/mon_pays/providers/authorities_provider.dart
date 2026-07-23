// lib/presentation/mon_pays/providers/authorities_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/authority.dart';
import '../services/authorities_service.dart';

final authoritiesServiceProvider = Provider((ref) => AuthoritiesService());

// Liste publique par catégorie
final authoritiesProvider = FutureProvider.family<List<Authority>, String?>((ref, category) async {
  final service = ref.watch(authoritiesServiceProvider);
  return service.getAuthorities(category: category);
});

// Détail d'une autorité
final authorityDetailProvider = FutureProvider.family<Authority, String>((ref, id) async {
  final service = ref.watch(authoritiesServiceProvider);
  return service.getAuthorityById(id);
});

// Recherche publique
final searchAuthoritiesProvider = FutureProvider.family<List<Authority>, String>((ref, query) async {
  final service = ref.watch(authoritiesServiceProvider);
  if (query.isEmpty) return [];
  return service.searchAuthorities(query);
});

// Par parti politique
final authoritiesByPartyProvider = FutureProvider.family<List<Authority>, String>((ref, party) async {
  final service = ref.watch(authoritiesServiceProvider);
  return service.getAuthoritiesByParty(party);
});

// ════════════════════════════════════════════════════════════════
// Hautes Autorités (4 principales)
// ════════════════════════════════════════════════════════════════
final topAuthoritiesProvider = FutureProvider<List<Authority>>((ref) async {
  final service = ref.watch(authoritiesServiceProvider);
  final all = await service.getAuthorities();
  const topTitles = {
    'Président de la République',
    'Président du Sénat',
    'Président de l\'Assemblée Nationale',
    'Première Ministre',
  };
  return all.where((a) => topTitles.contains(a.title)).toList();
});

// --- ADMIN STATE NOTIFIER ---
final adminAuthoritiesProvider = StateNotifierProvider<AdminAuthoritiesNotifier, AsyncValue<List<Authority>>>((ref) {
  return AdminAuthoritiesNotifier(ref);
});

class AdminAuthoritiesNotifier extends StateNotifier<AsyncValue<List<Authority>>> {
  final Ref _ref;

  AdminAuthoritiesNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadAuthorities();
  }

  Future<void> loadAuthorities() async {
    state = const AsyncValue.loading();
    try {
      final service = _ref.read(authoritiesServiceProvider);
      final list = await service.getAuthorities();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> createAuthority(Authority authority) async {
    try {
      final service = _ref.read(authoritiesServiceProvider);
      await service.createAuthority(authority);
      _ref.invalidate(authoritiesProvider);
      await loadAuthorities();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateAuthority(Authority authority) async {
    try {
      final service = _ref.read(authoritiesServiceProvider);
      await service.updateAuthority(authority);
      _ref.invalidate(authoritiesProvider);
      await loadAuthorities();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteAuthority(String id) async {
    try {
      final service = _ref.read(authoritiesServiceProvider);
      await service.deleteAuthority(id);
      _ref.invalidate(authoritiesProvider);
      await loadAuthorities();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
