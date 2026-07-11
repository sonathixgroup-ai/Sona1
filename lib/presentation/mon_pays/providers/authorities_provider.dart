// lib/presentation/mon_pays/providers/authorities_provider.dart
// Riverpod : liste, détail, recherche, admin CRUD

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/authority.dart';
import '../services/authorities_service.dart';

final authoritiesServiceProvider = Provider((ref) => AuthoritiesService());

// --- PROVIDERS PUBLICS ---

// Liste avec filtre
final authoritiesProvider = FutureProvider.family<List<Authority>, String?>((ref, category) async {
  final service = ref.watch(authoritiesServiceProvider);
  return service.getAuthorities(category: category);
});

// Détail d'une autorité
final authorityDetailProvider = FutureProvider.family<Authority, String>((ref, id) async {
  final service = ref.watch(authoritiesServiceProvider);
  return service.getAuthorityById(id);
});

// Recherche
final searchAuthoritiesProvider = FutureProvider.family<List<Authority>, String>((ref, query) async {
  final service = ref.watch(authoritiesServiceProvider);
  if (query.isEmpty) return [];
  return service.searchAuthorities(query);
});

// Autorités par parti
final authoritiesByPartyProvider = FutureProvider.family<List<Authority>, String>((ref, party) async {
  final service = ref.watch(authoritiesServiceProvider);
  return service.getAuthoritiesByParty(party);
});

// --- PROVIDERS ADMIN ---

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
      await loadAuthorities();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateAuthority(Authority authority) async {
    try {
      final service = _ref.read(authoritiesServiceProvider);
      await service.updateAuthority(authority);
      await loadAuthorities();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteAuthority(String id) async {
    try {
      final service = _ref.read(authoritiesServiceProvider);
      await service.deleteAuthority(id);
      await loadAuthorities();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
