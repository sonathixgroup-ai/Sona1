import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'market_providers.dart';

// ================= MY SHOPS =================
class MyShopsNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override Future<List<Map<String, dynamic>>> build() async => _load();

  Future<List<Map<String, dynamic>>> _load() async {
    final db = ref.read(supabaseClientProvider);
    final uid = db.auth.currentUser?.id;
    if (uid == null) return [];
    final res = await db.from('shops').select().eq('owner_id', uid).order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> create(Map<String, dynamic> data) async {
    final db = ref.read(supabaseClientProvider);
    final uid = db.auth.currentUser?.id;
    if (uid == null) return;
    final cur = state.valueOrNull ?? [];
    try {
      final res = await db.from('shops').insert({...data, 'owner_id': uid, 'status': 'pending'}).select().single();
      state = AsyncData([res, ...cur]);
    } catch (e) {
      debugPrint('createShop $e');
      rethrow;
    }
  }

  Future<void> update(String shopId, Map<String, dynamic> updates) async {
    final db = ref.read(supabaseClientProvider);
    final cur = state.valueOrNull ?? [];
    try {
      final res = await db.from('shops').update({...updates, 'updated_at': DateTime.now().toIso8601String()}).eq('id', shopId).select().single();
      state = AsyncData(cur.map((s) => s['id'] == shopId ? res : s).toList());
      // aussi mettre à jour le detail si ouvert
      ref.read(currentShopProvider.notifier).patchIfSameShop(res);
    } catch (e) {
      debugPrint('updateShop $e');
      rethrow;
    }
  }

  bool get hasShop => (state.valueOrNull?.isNotEmpty ?? false);
  String? get myShopId => state.valueOrNull?.isNotEmpty == true ? state.valueOrNull!.first['id'] as String? : null;

  Future<void> refresh() async => ref.invalidateSelf();
}

final myShopsProvider = AsyncNotifierProvider<MyShopsNotifier, List<Map<String, dynamic>>>(MyShopsNotifier.new);
final hasShopProvider = Provider<bool>((ref) => ref.watch(myShopsProvider).valueOrNull?.isNotEmpty ?? false);
final myShopIdProvider = Provider<String?>((ref) {
  final list = ref.watch(myShopsProvider).valueOrNull;
  if (list == null || list.isEmpty) return null;
  return list.first['id'] as String?;
});

// ================= FOLLOWED SHOPS =================
class FollowedShopsNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override Future<List<Map<String, dynamic>>> build() async {
    final db = ref.read(supabaseClientProvider);
    final uid = db.auth.currentUser?.id;
    if (uid == null) return [];
    final res = await db.from('shop_followers').select('shop:shops(*)').eq('user_id', uid);
    return res.map((e) => Map<String, dynamic>.from(e['shop'] as Map)).toList();
  }

  Future<void> refresh() async => ref.invalidateSelf();
}

final followedShopsProvider = AsyncNotifierProvider<FollowedShopsNotifier, List<Map<String, dynamic>>>(FollowedShopsNotifier.new);

// ================= CURRENT SHOP DETAIL =================
class CurrentShopNotifier extends AsyncNotifier<Map<String, dynamic>?> {
  String? _currentId;
  @override Future<Map<String, dynamic>?> build() async => null;

  Future<void> load(String shopId) async {
    _currentId = shopId;
    state = const AsyncLoading();
    try {
      final db = ref.read(supabaseClientProvider);
      final uid = db.auth.currentUser?.id;

      final shop = await db.from('shops').select('*, products:products(*)').eq('id', shopId).single();

      bool isFollowed = false;
      if (uid != null) {
        final check = await db.from('shop_followers').select('id').match({'user_id': uid, 'shop_id': shopId}).maybeSingle();
        isFollowed = check != null;
      }
      shop['is_followed'] = isFollowed;
      state = AsyncData(shop);
    } catch (e, st) {
      debugPrint('loadShopDetails $e');
      state = AsyncValue.error(e, st);
    }
  }

  void patchIfSameShop(Map<String, dynamic> updated) {
    final cur = state.valueOrNull;
    if (cur != null && cur['id'] == updated['id']) {
      state = AsyncData({...cur, ...updated});
    }
  }

  Future<void> toggleFollow(String shopId) async {
    final db = ref.read(supabaseClientProvider);
    final uid = db.auth.currentUser?.id;
    if (uid == null) return;
    final cur = state.valueOrNull;
    final wasFollowed = cur?['is_followed'] == true;

    // optimistic
    if (cur != null && cur['id'] == shopId) {
      state = AsyncData({...cur, 'is_followed': !wasFollowed});
    }

    try {
      final existing = await db.from('shop_followers').select().match({'user_id': uid, 'shop_id': shopId}).maybeSingle();
      if (existing != null) {
        await db.from('shop_followers').delete().match({'user_id': uid, 'shop_id': shopId});
        try { await db.rpc('decrement_shop_followers', params: {'shop_id': shopId}); } catch (_) {}
      } else {
        await db.from('shop_followers').insert({'user_id': uid, 'shop_id': shopId});
        try { await db.rpc('increment_shop_followers', params: {'shop_id': shopId}); } catch (_) {}
      }
      ref.invalidate(followedShopsProvider);
    } catch (e) {
      debugPrint('toggleFollow $e');
      if (cur != null) state = AsyncData(cur);
    }
  }
}

final currentShopProvider = AsyncNotifierProvider<CurrentShopNotifier, Map<String, dynamic>?>(CurrentShopNotifier.new);
