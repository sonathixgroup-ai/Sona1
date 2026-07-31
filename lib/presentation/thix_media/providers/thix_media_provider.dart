import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/models/media_content.dart';

final selectedCategoryProvider = StateProvider<String>((ref) => "Fil");
final searchQueryProvider = StateProvider<String>((ref) => "");

class ThixMediaNotifier extends StateNotifier<AsyncValue<List<MediaContent>>> {
  ThixMediaNotifier(this.ref) : super(const AsyncValue.loading()) {
    _sessionSeed = Random().nextInt(100000);
    _loadInitial();
    ref.listen(selectedCategoryProvider, (_, __) => refresh());
    ref.listen(searchQueryProvider, (_, __) => refresh());
  }
  
  final Ref ref;
  DateTime? _cursor;
  bool _hasMore = true;
  bool _loadingMore = false;
  late int _sessionSeed;
  static const _limit = 20;

  Future<void> _loadInitial() async => refresh();

  Future<void> refresh() async {
    _cursor = null; 
    _hasMore = true;
    _sessionSeed = Random().nextInt(100000);
    state = const AsyncValue.loading();
    try {
      final list = await _fetch(null);
      state = AsyncValue.data(list);
    } catch (e, st) { 
      state = AsyncValue.error(e, st); 
    }
  }

  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore || state.valueOrNull == null) return;
    _loadingMore = true;
    try {
      final more = await _fetch(_cursor);
      if (more.length < _limit) _hasMore = false;
      state = AsyncValue.data([...state.value!, ...more]);
    } finally { 
      _loadingMore = false; 
    }
  }

  Future<List<MediaContent>> _fetch(DateTime? cursor) async {
    final cat = ref.read(selectedCategoryProvider);
    final search = ref.read(searchQueryProvider).trim();
    
    var query = Supabase.instance.client
        .from('media_content')
        .select('*, media_stats(like_count, view_count, comment_count)');
        
    if (cursor != null) {
      query = query.lt('created_at', cursor.toIso8601String());
    }
    
    if (search.isNotEmpty) {
      query = query.ilike('title', '%$search%');
    } else if (cat != 'Accueil' && cat != 'Fil') {
      query = query.eq('type', cat);
    }

    final res = await query.order('created_at', ascending: false).limit(_limit);
    
    final list = (res as List).map<MediaContent>((dynamic item) {
      final Map<String, dynamic> e = Map<String, dynamic>.from(item as Map);
      if (e['media_stats'] != null) {
        final Map<String, dynamic> stats = Map<String, dynamic>.from(e['media_stats'] as Map);
        e['likeCount'] = stats['like_count'] ?? e['likeCount'] ?? 0;
        e['viewCount'] = stats['view_count'] ?? e['viewCount'] ?? 0;
        e['commentCount'] = stats['comment_count'] ?? e['commentCount'] ?? 0;
      }
      return MediaContent.fromJson(e);
    }).toList();
    
    if (list.isNotEmpty) _cursor = list.last.createdAt;

    // SCALABILITY: Mélange algorithmique par lot basé sur la graine de session
    if (cat == 'Fil' && search.isEmpty) {
      list.shuffle(Random(_sessionSeed));
    }

    return list;
  }
}

final thixMediaListProvider = StateNotifierProvider<ThixMediaNotifier, AsyncValue<List<MediaContent>>>((ref) => ThixMediaNotifier(ref));
final bannerItemsProvider = Provider<List<MediaContent>>((ref) => ref.watch(thixMediaListProvider).valueOrNull?.take(5).toList() ?? []);
final recommendationsProvider = Provider<List<MediaContent>>((ref) => ref.watch(thixMediaListProvider).valueOrNull ?? []);
final newReleasesProvider = Provider<List<MediaContent>>((ref) => ref.watch(thixMediaListProvider).valueOrNull ?? []);
final trendingProvider = Provider<List<MediaContent>>((ref) => ref.watch(thixMediaListProvider).valueOrNull ?? []);
