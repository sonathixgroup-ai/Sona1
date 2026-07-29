// lib/presentation/mon_pays/providers/authorities_provider.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/authority.dart';
import '../services/authorities_service.dart';

part 'authorities_provider.g.dart';

// ============================================================
// SERVICE PROVIDER (KeepAlive pour éviter de recréer l'instance)
// ============================================================
@Riverpod(keepAlive: true)
AuthoritiesService authoritiesService(Ref ref) {
  return AuthoritiesService();
}

// ============================================================
// PAGINATION AVEC ASYNC NOTIFIER (Scalable)
// ============================================================
// Riverpod 2.0 transforme les paramètres de build() en "Family".
// Cela permet d'avoir un cache unique par combinaison de filtres !
@riverpod
class AuthoritiesPaginated extends _$AuthoritiesPaginated {
  int _currentPage = 0;
  final int _limit = 20;
  bool _hasMore = true;

  @override
  FutureOr<PaginatedResult<Authority>> build({
    String? category,
    String? search,
    bool? activeOnly,
  }) async {
    _currentPage = 0;
    _hasMore = true;
    return _fetchPage();
  }

  Future<PaginatedResult<Authority>> _fetchPage({bool append = false}) async {
    final service = ref.read(authoritiesServiceProvider);
    final result = await service.getAuthoritiesPaginated(
      page: _currentPage,
      limit: _limit,
      category: category,
      search: search,
      activeOnly: activeOnly,
    );

    _hasMore = result.hasMore;

    if (append && state.hasValue) {
      final currentData = state.value!;
      return PaginatedResult<Authority>(
        data: [...currentData.data, ...result.data],
        total: result.total,
        page: result.page,
        limit: result.limit,
        hasMore: result.hasMore,
      );
    }
    return result;
  }

  Future<void> loadNextPage() async {
    // Évite les appels simultanés ou si on a atteint la fin
    if (!_hasMore || state.isLoading || state.isReloading) return;

    _currentPage++;
    
    // Ajoute la nouvelle page sans écraser l'état actuel (garde l'UI fluide)
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchPage(append: true));
  }
}

// ============================================================
// LECTURE SEULE (Queries)
// ============================================================

/// Les 4 plus hautes autorités.
/// Note Entreprise : Idéalement, backend devrait avoir un endpoint dédié 
/// pour ne pas fetcher TOUTES les autorités actives côté client.
@riverpod
Future<List<Authority>> topAuthorities(Ref ref) async {
  final service = ref.watch(authoritiesServiceProvider);
  final all = await service.getActiveAuthorities();

  String normalize(String s) {
    s = s.toLowerCase().trim();
    const accents = 'àáâãäåçèéêëìíîïñòóôõöùúûüýÿ';
    const sansAccents = 'aaaaaaceeeeiiiinooooouuuuyy';
    final sb = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final index = accents.indexOf(s[i]);
      sb.write(index != -1 ? sansAccents[index] : s[i]);
    }
    return sb.toString();
  }

  final targetTitles = {
    normalize('Président de la République'),
    normalize('Première Ministre'),
    normalize('Président du Sénat'),
    normalize('Président de l\'Assemblée Nationale'),
  };

  final filtered = all.where((a) => targetTitles.contains(normalize(a.title))).toList();

  // Tri pour garantir l'ordre de préséance institutionnelle
  int getPriority(String title) {
    final t = normalize(title);
    if (t.contains('président de la république')) return 1;
    if (t.contains('première ministre') || t.contains('premier ministre')) return 2;
    if (t.contains('sénat')) return 3;
    if (t.contains('assemblée')) return 4;
    return 99;
  }

  filtered.sort((a, b) => getPriority(a.title).compareTo(getPriority(b.title)));
  return filtered;
}

@riverpod
Future<Authority> authorityDetail(Ref ref, String id) async {
  final service = ref.watch(authoritiesServiceProvider);
  return service.getAuthorityWithRelations(id);
}

@riverpod
Future<List<Authority>> historicalAuthorities(Ref ref) async {
  final service = ref.watch(authoritiesServiceProvider);
  return service.getHistoricalAuthorities();
}

// ============================================================
// ADMIN / MUTATIONS (CUD Operations)
// ============================================================
@riverpod
class AdminAuthorities extends _$AdminAuthorities {
  @override
  FutureOr<List<Authority>> build() async {
    final service = ref.watch(authoritiesServiceProvider);
    return service.getActiveAuthorities();
  }

  Future<void> createAuthority(Authority authority) async {
    final service = ref.read(authoritiesServiceProvider);
    
    // AsyncValue.guard gère automatiquement les try/catch et met à jour l'état
    await AsyncValue.guard(() async {
      await service.createAuthority(authority);
      ref.invalidate(topAuthoritiesProvider);
      
      // Riverpod 2.0 : refetch directement la liste admin après création
      ref.invalidateSelf(); 
    });
  }

  Future<void> updateAuthority(Authority authority) async {
    final service = ref.read(authoritiesServiceProvider);
    
    await AsyncValue.guard(() async {
      await service.updateAuthority(authority);
      
      // Invalidation sélective et intelligente
      ref.invalidate(topAuthoritiesProvider);
      ref.invalidate(authorityDetailProvider(authority.id)); 
      
      // Invalider la pagination pour forcer un refresh si l'admin va sur la liste
      ref.invalidate(authoritiesPaginatedProvider);
      ref.invalidateSelf();
    });
  }

  Future<void> deleteAuthority(String id) async {
    final service = ref.read(authoritiesServiceProvider);
    
    await AsyncValue.guard(() async {
      await service.deleteAuthority(id);
      
      ref.invalidate(topAuthoritiesProvider);
      ref.invalidate(authorityDetailProvider(id));
      ref.invalidate(authoritiesPaginatedProvider);
      ref.invalidateSelf();
    });
  }

  Future<void> archiveAuthority(String id) async {
    final service = ref.read(authoritiesServiceProvider);
    
    await AsyncValue.guard(() async {
      await service.archiveAuthority(id);
      
      ref.invalidate(topAuthoritiesProvider);
      ref.invalidate(historicalAuthoritiesProvider); // Ajouté aux archives
      ref.invalidate(authorityDetailProvider(id));
      ref.invalidate(authoritiesPaginatedProvider);
      ref.invalidateSelf();
    });
  }
}
