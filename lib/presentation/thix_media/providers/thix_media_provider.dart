import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/media_content.dart';
import '../../../services/media_service.dart';

final mediaServiceProvider = Provider<MediaService>((ref) {
  return MediaService(client: Supabase.instance.client, bucket: 'media');
});

final thixMediaListProvider = AsyncNotifierProvider<ThixMediaNotifier, List<MediaContent>>(() => ThixMediaNotifier());

class ThixMediaNotifier extends AsyncNotifier<List<MediaContent>> {
  DateTime? _lastFetch;
  @override
  Future<List<MediaContent>> build() async {
    return _fetchWithCache(force: false);
  }

  Future<List<MediaContent>> _fetchWithCache({bool force = false}) async {
    if (!force && _lastFetch!= null && DateTime.now().difference(_lastFetch!).inMinutes < 5 && state.hasValue) {
      return state.value!;
    }
    final service = ref.read(mediaServiceProvider);
    final data = await service.fetchPublishedMediaPaginated(limit: 100, offset: 0);
    _lastFetch = DateTime.now();
    return data;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchWithCache(force: true));
  }
}

final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedCategoryProvider = StateProvider<String>((ref) => 'Accueil');

final filteredBaseProvider = Provider<List<MediaContent>>((ref) {
  final all = ref.watch(thixMediaListProvider).valueOrNull?? [];
  final q = ref.watch(searchQueryProvider).trim().toLowerCase();
  if (q.isEmpty) return all;
  return all.where((m) => m.title.toLowerCase().contains(q) || (m.subtitle?.toLowerCase().contains(q)?? false)).toList();
});

final bannerItemsProvider = Provider<List<MediaContent>>((ref) {
  final base = ref.watch(filteredBaseProvider);
  var b = base.where((m) => m.isNewRelease).toList();
  if (b.isEmpty) b = base.take(5).toList();
  return b;
});

final trendingProvider = Provider<List<MediaContent>>((ref) {
  final base = ref.watch(filteredBaseProvider);
  var t = base.where((e) => e.rankPosition!= null).toList();
  t.sort((a, b) => (a.rankPosition?? 99).compareTo(b.rankPosition?? 99));
  return t;
});

final recommendationsProvider = Provider<List<MediaContent>>((ref) {
  final base = ref.watch(filteredBaseProvider);
  final cat = ref.watch(selectedCategoryProvider);
  var r = base.where((e) => e.rankPosition== null).toList();
  if (cat!= 'Accueil') r = r.where((e) => e.type == cat).toList();
  return r;
});

final newReleasesProvider = Provider<List<MediaContent>>((ref) {
  final base = ref.watch(filteredBaseProvider);
  final cat = ref.watch(selectedCategoryProvider);
  var list = base.where((e) => e.isNewRelease).toList();
  if (cat!= 'Accueil') list = list.where((e) => e.type == cat).toList();
  return list;
});

final upcomingProvider = Provider<List<MediaContent>>((ref) {
  final base = ref.watch(filteredBaseProvider);
  return base.where((e) =>!e.isNewRelease).take(20).toList();
});
