import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category.dart';
import '../models/formation.dart';
import '../models/certificate.dart';

// Ne casse pas la DB - on garde le même client
final supabaseClientProvider = Provider((ref) => Supabase.instance.client);
final currentUserIdProvider = Provider<String?>((ref) => Supabase.instance.client.auth.currentUser?.id);

// SCABLE 1M+ : Categories = keepAlive, 1 seule requête pour tous
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final res = await client.from('categories')
   .select('id,name,icon,created_at')
   .order('name');
  return res.map((e) => Category.fromJson(e)).toList();
});

// État paginé scalable
class PaginatedFormations {
  final List<Formation> items;
  final bool hasMore;
  final bool isLoadingMore;
  const PaginatedFormations({required this.items, this.hasMore = true, this.isLoadingMore = false});
  PaginatedFormations copyWith({List<Formation>? items, bool? hasMore, bool? isLoadingMore}) =>
    PaginatedFormations(items: items?? this.items, hasMore: hasMore?? this.hasMore, isLoadingMore: isLoadingMore?? this.isLoadingMore);
}

// SCABLE 1M+ : Formation avec range + select light
class FormationsNotifier extends AsyncNotifier<PaginatedFormations> {
  static const _limit = 20;
  int _offset = 0;
  String? _categoryId;
  String? get currentCategory => _categoryId;

  @override
  Future<PaginatedFormations> build() async {
    _offset = 0;
    final client = ref.watch(supabaseClientProvider);
    var query = client.from('formations').select('id,title,image_url,rating,price,currency,is_free,category_id,created_at');
    if (_categoryId!= null) query = query.eq('category_id', _categoryId!);
    final res = await query.order('created_at', ascending: false).range(0, _limit - 1);
    final items = res.map((e) => Formation.fromJson(e)).toList();
    _offset = items.length;
    return PaginatedFormations(items: items, hasMore: items.length == _limit);
  }

  Future<void> loadMore() async {
    if (state.value == null ||!state.value!.hasMore || state.value!.isLoadingMore) return;
    state = AsyncData(state.value!.copyWith(isLoadingMore: true));
    final client = ref.read(supabaseClientProvider);
    var query = client.from('formations').select('id,title,image_url,rating,price,currency,is_free,category_id,created_at');
    if (_categoryId!= null) query = query.eq('category_id', _categoryId!);
    final res = await query.order('created_at', ascending: false).range(_offset, _offset + _limit - 1);
    final newItems = res.map((e) => Formation.fromJson(e)).toList();
    _offset += newItems.length;
    state = AsyncData(PaginatedFormations(items: [...state.value!.items,...newItems], hasMore: newItems.length == _limit));
  }

  Future<void> filterByCategory(String? categoryId) async {
    _categoryId = categoryId;
    state = const AsyncLoading();
    ref.invalidateSelf();
  }
}

final formationsProvider = AsyncNotifierProvider<FormationsNotifier, PaginatedFormations>(FormationsNotifier.new);

// Mes cours - paginé par user_id + RLS
final myEnrollmentsProvider = FutureProvider.family((ref, String userId) async {
  final client = ref.watch(supabaseClientProvider);
  final res = await client.from('enrollments')
   .select('id,progress,created_at,formation:formations(id,title,image_url,rating,price,currency,is_free)')
   .eq('user_id', userId).order('created_at', ascending: false).range(0, 49);
  return res;
});

// Certificats
final certificatesProvider = FutureProvider.family<List<Certificate>, String>((ref, String userId) async {
  final client = ref.watch(supabaseClientProvider);
  final res = await client.from('certificates').select().eq('user_id', userId).order('issued_at', ascending: false);
  return res.map((e) => Certificate.fromJson(e)).toList();
});

// Recommandations
final recommendationsProvider = FutureProvider.family<List<Formation>, String>((ref, String userId) async {
  final client = ref.watch(supabaseClientProvider);
  final res = await client.from('recommendations').select('formation:formations(id,title,image_url,rating,price,currency,is_free)').eq('user_id', userId).limit(10);
  return res.map((e) => Formation.fromJson(e['formation'])).toList();
});
