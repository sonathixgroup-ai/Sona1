import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/models/media_content.dart';

final selectedCategoryProvider = StateProvider<String>((ref) => "Fil");
final searchQueryProvider = StateProvider<String>((ref) => "");

class ThixMediaNotifier extends StateNotifier<AsyncValue<List<MediaContent>>> {
  ThixMediaNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadInitial();
    ref.listen(selectedCategoryProvider, (_, __) => refresh());
    ref.listen(searchQueryProvider, (_, __) => refresh());
  }
  
  final Ref ref;
  DateTime? _cursor;
  bool _hasMore = true;
  bool _loadingMore = false;
  static const _limit = 20;

  Future<void> _loadInitial() async => refresh();

  Future<void> refresh() async {
    _cursor = null; 
    _hasMore = true;
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
    
    // 1. Déclarer la requête de base (SANS order ni limit)
    var query = Supabase.instance.client
        .from('media_content')
        .select('*, media_stats(like_count, view_count, comment_count)');
        
    // 2. Appliquer les filtres (OBLIGATOIREMENT avant order et limit)
    if (cursor != null) {
      query = query.lt('created_at', cursor.toIso8601String());
    }
    
    if (search.isNotEmpty) {
      query = query.ilike('title', '%$search%');
    } else if (cat != 'Accueil' && cat != 'Fil') {
      query = query.eq('type', cat);
    }

    // 3. Appliquer l'ordre, la limite, et exécuter la requête
    final res = await query.order('created_at', ascending: false).limit(_limit);
    
    // 4. Parser la réponse en forçant le type <MediaContent> et en utilisant fromJson
    final list = (res as List).map<MediaContent>((e) {
      final stats = e['media_stats'] as Map<String, dynamic>?;
      if (stats != null) {
        e = {
          ...e, 
          'likeCount': stats['like_count'] ?? e['likeCount'] ?? 0, 
          'viewCount': stats['view_count'] ?? e['viewCount'] ?? 0, 
          'commentCount': stats['comment_count'] ?? e['commentCount'] ?? 0
        };
      }
      // On utilise bien fromJson ici
      return MediaContent.fromJson(e as Map<String, dynamic>);
    }).toList();
    
    if (list.isNotEmpty) _cursor = list.last.createdAt;
    return list;
  }


final thixMediaListProvider = StateNotifierProvider<ThixMediaNotifier, AsyncValue<List<MediaContent>>>((ref) => ThixMediaNotifier(ref));
final bannerItemsProvider = Provider<List<MediaContent>>((ref) => ref.watch(thixMediaListProvider).valueOrNull?.take(5).toList() ?? []);
final recommendationsProvider = Provider<List<MediaContent>>((ref) => ref.watch(thixMediaListProvider).valueOrNull ?? []);
final newReleasesProvider = Provider<List<MediaContent>>((ref) => ref.watch(thixMediaListProvider).valueOrNull ?? []);
final trendingProvider = Provider<List<MediaContent>>((ref) => ref.watch(thixMediaListProvider).valueOrNull ?? []);

// --- PROVIDERS COMPLÉMENTAIRES (Commentaires & Admin) ---

class CommentItem { 
  final String id, userId, userName, content; 
  final String? avatarUrl; 
  final DateTime createdAt;
  
  CommentItem({required this.id, required this.userId, required this.userName, required this.content, required this.createdAt, this.avatarUrl});
  
  factory CommentItem.fromMap(Map<String, dynamic> m) => CommentItem(
    id: m['id'], 
    userId: m['user_id'], 
    userName: (m['user_name'] as String?)?.isNotEmpty == true ? m['user_name'] : 'Utilisateur', 
    avatarUrl: m['avatar_url'], 
    content: m['content'], 
    createdAt: DateTime.parse(m['created_at']).toLocal()
  );
}

final commentsListProvider = FutureProvider.autoDispose.family<List<CommentItem>, String>((ref, mediaId) async {
  final res = await Supabase.instance.client.from('media_comments').select('id, user_id, user_name, avatar_url, content, created_at').eq('media_id', mediaId).order('created_at', ascending: false).limit(50);
  return (res as List).map((e) => CommentItem.fromMap(e as Map<String, dynamic>)).toList();
});

final commentCountProvider = FutureProvider.autoDispose.family<int, String>((ref, mediaId) async {
  final res = await Supabase.instance.client.from('media_stats').select('comment_count').eq('media_id', mediaId).maybeSingle();
  return res?['comment_count'] as int? ?? 0;
});

final isMediaAdminProvider = FutureProvider.autoDispose<bool>((ref) async {
  final u = Supabase.instance.client.auth.currentUser; 
  if (u == null) return false;
  final role = u.appMetadata['role'] ?? u.userMetadata?['role']; 
  return role == 'admin' || role == 'superadmin';
});
