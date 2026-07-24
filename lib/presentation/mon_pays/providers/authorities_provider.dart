// lib/presentation/mon_pays/providers/authorities_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/authority.dart';
import '../services/authorities_service.dart';

// ============================================================
// SERVICE PROVIDER
// ============================================================
final authoritiesServiceProvider = Provider<AuthoritiesService>((ref) {
  return AuthoritiesService();
});

// ============================================================
// PAGINATION AVEC STATE NOTIFIER
// ============================================================
final authoritiesPaginatedProvider =
    StateNotifierProvider<AuthoritiesPaginatedNotifier, AsyncValue<PaginatedResult<Authority>>>(
  (ref) => AuthoritiesPaginatedNotifier(ref),
);

class AuthoritiesPaginatedNotifier extends StateNotifier<AsyncValue<PaginatedResult<Authority>>> {
  final Ref _ref;
  String? _currentCategory;
  String? _currentSearch;
  bool? _activeOnly;
  int _currentPage = 0;
  final int _limit = 20;
  bool _hasMore = true;

  AuthoritiesPaginatedNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadFirstPage();
  }

  Future<void> loadFirstPage({
    String? category,
    String? search,
    bool? activeOnly,
  }) async {
    _currentPage = 0;
    _currentCategory = category;
    _currentSearch = search;
    _activeOnly = activeOnly;
    _hasMore = true;
    await _loadPage();
  }

  Future<void> loadNextPage() async {
    if (!_hasMore) return;
    _currentPage++;
    await _loadPage(append: true);
  }

  Future<void> refreshData() async {
    _currentPage = 0;
    _hasMore = true;
    await _loadPage();
  }

  Future<void> _loadPage({bool append = false}) async {
    try {
      final service = _ref.read(authoritiesServiceProvider);
      final result = await service.getAuthoritiesPaginated(
        page: _currentPage,
        limit: _limit,
        category: _currentCategory,
        search: _currentSearch,
        activeOnly: _activeOnly,
      );

      _hasMore = result.hasMore;

      if (append && state.hasValue) {
        final currentData = state.value!;
        final combined = PaginatedResult(
          data: [...currentData.data, ...result.data],
          total: result.total,
          page: result.page,
          limit: result.limit,
          hasMore: result.hasMore,
        );
        state = AsyncValue.data(combined);
      } else {
        state = AsyncValue.data(result);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// ============================================================
// AUTRES PROVIDERS PUBLICS
// ============================================================

/// Les 4 plus hautes autorités (actives) – avec normalisation des titres
final topAuthoritiesProvider = FutureProvider<List<Authority>>((ref) async {
  final service = ref.watch(authoritiesServiceProvider);
  final all = await service.getActiveAuthorities();

  // Fonction de normalisation : minuscule, trim, suppression des accents
  String normalize(String s) {
    s = s.toLowerCase().trim();
    const accents = 'àáâãäåçèéêëìíîïñòóôõöùúûüýÿ';
    const sansAccents = 'aaaaaaceeeeiiiinooooouuuuyy';
    final sb = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final index = accents.indexOf(s[i]);
      if (index != -1) {
        sb.write(sansAccents[index]);
      } else {
        sb.write(s[i]);
      }
    }
    return sb.toString();
  }

  final normalizedTitles = <String>{
    normalize('Président de la République'),
    normalize('Président du Sénat'),
    normalize('Président de l\'Assemblée Nationale'),
    normalize('Première Ministre'),
  };

  return all.where((a) => normalizedTitles.contains(normalize(a.title))).toList();
});

/// Détail d'une autorité avec toutes ses relations
final authorityDetailProvider = FutureProvider.family<Authority, String>((ref, id) async {
  final service = ref.watch(authoritiesServiceProvider);
  return service.getAuthorityWithRelations(id);
});

/// Autorités historiques (inactives)
final historicalAuthoritiesProvider = FutureProvider<List<Authority>>((ref) async {
  final service = ref.watch(authoritiesServiceProvider);
  return service.getHistoricalAuthorities();
});

// ============================================================
// ADMIN
// ============================================================

final adminAuthoritiesProvider =
    StateNotifierProvider<AdminAuthoritiesNotifier, AsyncValue<List<Authority>>>(
  (ref) => AdminAuthoritiesNotifier(ref),
);

class AdminAuthoritiesNotifier extends StateNotifier<AsyncValue<List<Authority>>> {
  final Ref _ref;

  AdminAuthoritiesNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadAuthorities();
  }

  Future<void> loadAuthorities() async {
    state = const AsyncValue.loading();
    try {
      final service = _ref.read(authoritiesServiceProvider);
      final list = await service.getActiveAuthorities();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> createAuthority(Authority authority) async {
    try {
      final service = _ref.read(authoritiesServiceProvider);
      await service.createAuthority(authority);
      _ref.invalidate(topAuthoritiesProvider);
      await loadAuthorities();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      throw e; // 🚀 Permet au formulaire d'attraper l'erreur !
    }
  }

  Future<void> updateAuthority(Authority authority) async {
    try {
      final service = _ref.read(authoritiesServiceProvider);
      await service.updateAuthority(authority);
      
      // 🚀 Vide les caches pour forcer l'interface à se rafraîchir !
      _ref.invalidate(topAuthoritiesProvider);
      _ref.invalidate(authorityDetailProvider(authority.id)); 
      
      await loadAuthorities();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      throw e; // 🚀 Permet au formulaire d'attraper l'erreur !
    }
  }

  Future<void> deleteAuthority(String id) async {
    try {
      final service = _ref.read(authoritiesServiceProvider);
      await service.deleteAuthority(id);
      
      _ref.invalidate(topAuthoritiesProvider);
      _ref.invalidate(authorityDetailProvider(id));
      
      await loadAuthorities();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      throw e; // 🚀
    }
  }

  Future<void> archiveAuthority(String id) async {
    try {
      final service = _ref.read(authoritiesServiceProvider);
      await service.archiveAuthority(id);
      
      _ref.invalidate(topAuthoritiesProvider);
      _ref.invalidate(authorityDetailProvider(id));
      
      await loadAuthorities();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      throw e; // 🚀
    }
  }
}
