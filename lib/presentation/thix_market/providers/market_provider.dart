import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================
// CORE
// ============================================================
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// ============================================================
// REPOSITORY - SCALABLE POUR MILLIONS
// ============================================================
class MarketRepository {
  final SupabaseClient db;
  MarketRepository(this.db);

  static const _productCols =
      'id,title,price,discount_price,original_price,currency,image_url,images,rating,reviews_count,shop_id,shop_name,city,is_flash_sale,discount_percent,created_at,stock';
  static const _shopCols = 'id,name,logo_url,city,is_featured,is_supermarket,followers_count';

  Future<List<Map<String, dynamic>>> fetchProducts({
    int page = 0,
    int limit = 20,
    bool flashOnly = false,
    String orderBy = 'created_at',
    bool ascending = false,
  }) async {
    final from = page * limit;
    final to = from + limit - 1;

    var query = db.from('products').select(_productCols).eq('status', 'active').gt('stock', 0);

    if (flashOnly) {
      query = query.eq('is_flash_sale', true);
    }

    final res = orderBy == 'rating'
       ? await query.order('rating', ascending: ascending).range(from, to)
        : await query.order(orderBy, ascending: ascending).range(from, to);

    return (res as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> fetchBanners() async {
    try {
      final res = await db
         .from('promo_banners')
         .select('id,title,subtitle,image_url,link,display_order')
         .eq('active', true)
         .order('display_order')
         .limit(5);
      return (res as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('fetchBanners error $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchFeaturedShops({int limit = 8}) async {
    try {
      final res = await db.from('shops').select(_shopCols).eq('is_featured', true).order('followers_count', ascending: false).limit(limit);
      return (res as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('fetchFeaturedShops error $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchSupermarkets({int limit = 8}) async {
    try {
      // Si tu as une colonne is_supermarket, sinon fallback featured
      final res = await db.from('shops').select(_shopCols).eq('is_supermarket', true).limit(limit);
      if ((res as List).isEmpty) {
        return fetchFeaturedShops(limit: limit);
      }
      return (res as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return fetchFeaturedShops(limit: limit);
    }
  }

  Future<String?> fetchMyShopId() async {
    final uid = db.auth.currentUser?.id;
    if (uid == null) return null;
    try {
      final r = await db.from('shops').select('id').eq('owner_id', uid).limit(1).maybeSingle();
      return r?['id'] as String?;
    } catch (e) {
      debugPrint('fetchMyShopId $e');
      return null;
    }
  }

  Future<int> fetchUnread() async {
    final uid = db.auth.currentUser?.id;
    if (uid == null) return 0;
    try {
      final r = await db.from('notifications').select('id').eq('user_id', uid).eq('is_read', false).count(CountOption.exact);
      return r.count;
    } catch (e) {
      debugPrint('fetchUnread $e');
      return 0;
    }
  }
}

final marketRepositoryProvider = Provider<MarketRepository>((ref) {
  return MarketRepository(ref.watch(supabaseClientProvider));
});

// ============================================================
// PROVIDERS SIMPLES
// ============================================================
final bannersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(marketRepositoryProvider).fetchBanners();
});

final flashSalesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(marketRepositoryProvider).fetchProducts(page: 0, limit: 8, flashOnly: true, orderBy: 'created_at');
});

final featuredShopsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(marketRepositoryProvider).fetchFeaturedShops(limit: 8);
});

final supermarketsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(marketRepositoryProvider).fetchSupermarkets(limit: 8);
});

final myShopIdProvider = FutureProvider<String?>((ref) {
  return ref.watch(marketRepositoryProvider).fetchMyShopId();
});

final unreadNotificationsProvider = FutureProvider<int>((ref) {
  return ref.watch(marketRepositoryProvider).fetchUnread();
});

// ============================================================
// PAGINATION - FOR YOU / ALL PRODUCTS
// ============================================================
class ForYouNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  int _page = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  @override
  Future<List<Map<String, dynamic>>> build() async {
    _page = 0;
    _hasMore = true;
    _isLoadingMore = false;
    final repo = ref.read(marketRepositoryProvider);
    final first = await repo.fetchProducts(page: 0, limit: 20, orderBy: 'created_at');
    _page = 1;
    _hasMore = first.length == 20;
    return first;
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore) return;
    final current = state.valueOrNull?? [];
    if (current.isEmpty) return;

    _isLoadingMore = true;
    state = AsyncLoading<List<Map<String, dynamic>>>().copyWithPrevious(AsyncData(current));

    try {
      final repo = ref.read(marketRepositoryProvider);
      final more = await repo.fetchProducts(page: _page, limit: 20);
      if (more.length < 20) _hasMore = false;
      _page++;
      state = AsyncData([...current,...more]);
    } catch (e, st) {
      state = AsyncError<List<Map<String, dynamic>>>(e, st).copyWithPrevious(AsyncData(current));
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> refresh() async {
    _page = 0;
    _hasMore = true;
    ref.invalidateSelf();
    await future;
  }

  // Pour compatibilité avec ancien code
  double parsePrice(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString())?? 0;
  }
}

final forYouProvider = AsyncNotifierProvider<ForYouNotifier, List<Map<String, dynamic>>>(
  ForYouNotifier.new,
);

// Compat: ancien noms utilisés dans l'app
final recommendedProductsProvider = forYouProvider;
final forYouProductsProvider = forYouProvider;

// ============================================================
// MERGED + DEDUPLICATED ALL PRODUCTS
// ============================================================
final allMarketProductsProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final flash = ref.watch(flashSalesProvider).valueOrNull?? [];
  final forYou = ref.watch(forYouProvider).valueOrNull?? [];

  final map = <String, Map<String, dynamic>>{};
  for (final p in [...flash,...forYou]) {
    final id = p['id']?.toString();
    if (id == null) continue;
    // garde le plus récent si doublon
    if (!map.containsKey(id)) {
      map[id] = p;
    }
  }
  return map.values.toList();
});

// ============================================================
// HELPER POUR COMPAT ANCIEN PROVIDER
// ============================================================
class MarketProviderCompat {
  static double parsePrice(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString()?? '')?? 0;
  }
}
