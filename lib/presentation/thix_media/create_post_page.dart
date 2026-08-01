import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/models/media_content.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;

typedef ProgressCallback = void Function(double progress);

class FeedPage {
  final List<MediaContent> items;
  final List<Map<String, dynamic>> raw;
  FeedPage({required this.items, required this.raw});
}

class MediaService {
  static final MediaService _instance = MediaService._internal();
  factory MediaService({SupabaseClient? client, String? bucket}) => _instance;
  MediaService._internal();
  
  SupabaseClient get supabase => Supabase.instance.client;
  final Uuid _uuid = const Uuid();

  // ---- BATCH VUES 1M ----
  static final Set<String> _pendingViews = {};
  static Timer? _viewTimer;
  
  void registerView(String id) { 
    _pendingViews.add(id); 
    _viewTimer ??= Timer(const Duration(seconds: 8), _flush); 
  }
  
  static Future<void> _flush() async {
    if (_pendingViews.isEmpty) { 
      _viewTimer = null; 
      return; 
    }
    final b = _pendingViews.toList(); 
    _pendingViews.clear(); 
    _viewTimer = null;
    try { 
      await Supabase.instance.client.rpc('batch_register_views', params: {'p_media_ids': b}); 
    } catch (_) { 
      _pendingViews.addAll(b); 
    }
  }

  // ---- FEED ENRICHI ----
  Future<FeedPage> fetchEnrichedFeed({required List<String> seenIds, int limit = 12}) async {
    try {
      final uid = supabase.auth.currentUser?.id;
      final data = await supabase.rpc('get_feed_with_creator', params: {'p_seen_ids': seenIds, 'p_limit': limit, 'p_uid': uid}) as List;
      final items = data.map((e) => MediaContent.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      final raw = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      return FeedPage(items: items, raw: raw);
    } catch (_) {
      return FeedPage(items: [], raw: []);
    }
  }

  Future<FeedPage> fetchShuffledFeed({required List<String> seenIds, int limit = 12}) async {
    try {
      final data = await supabase.rpc('get_shuffled_feed', params: {'p_seen_ids': seenIds, 'p_limit': limit}) as List;
      return FeedPage(items: data.map((e) => MediaContent.fromJson(e as Map<String, dynamic>)).toList(), raw: []);
    } catch (_) {
      return FeedPage(items: [], raw: []);
    }
  }

  // ---- LIKES / FOLLOW ----
  Future<bool> toggleLike(String id) async { 
    try {
      final r = await supabase.rpc('toggle_media_like', params: {'p_media_id': id}); 
      if (r is bool) return r;
      return true; 
    } catch (_) {
      return false;
    }
  }

  Future<bool> toggleFollow(String targetId) async {
    final uid = supabase.auth.currentUser?.id; 
    if (uid == null || targetId.isEmpty || uid == targetId) return false;
    
    try {
      final ex = await supabase.from('follows').select().eq('follower_id', uid).eq('following_id', targetId).maybeSingle();
      if (ex != null) { 
        await supabase.from('follows').delete().eq('follower_id', uid).eq('following_id', targetId); 
        return false; 
      } else { 
        await supabase.from('follows').insert({'follower_id': uid, 'following_id': targetId}); 
        return true; 
      }
    } catch (_) {
      return false;
    }
  }

  Future<bool> isFollowing(String targetId) async {
    final uid = supabase.auth.currentUser?.id; 
    if (uid == null || targetId.isEmpty || uid == targetId) return false;
    try {
      final ex = await supabase.from('follows').select().eq('follower_id', uid).eq('following_id', targetId).maybeSingle();
      return ex != null;
    } catch (_) {
      return false;
    }
  }

  Future<Set<String>> getLikedMediaIds(List<String> ids) async {
    if (ids.isEmpty) return {}; 
    try { 
      final r = await supabase.rpc('get_liked_media_ids', params: {'p_media_ids': ids}); 
      return (r as List).map((e) => e.toString()).toSet(); 
    } catch (_) { 
      final uid = supabase.auth.currentUser?.id; 
      if (uid == null) return {}; 
      final r = await supabase.from('media_likes').select('media_id').eq('user_id', uid).in_('media_id', ids); 
      return (r as List).map((e) => e['media_id'].toString()).toSet(); 
    }
  }

  // ---- PROFILE ----
  Future<Map<String, dynamic>?> fetchProfile(String userId) async {
    try {
      return await supabase.from('profiles').select().eq('id', userId).maybeSingle();
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> fetchUserStats(String userId) async {
    try {
      final followersCount = await supabase.from('follows').count(CountOption.exact).eq('following_id', userId);
      final followingCount = await supabase.from('follows').count(CountOption.exact).eq('follower_id', userId);
      final postsCount = await supabase.from('media_content').count(CountOption.exact).eq('user_id', userId);
      
      return {
        'followers': followersCount, 
        'following': followingCount, 
        'posts': postsCount
      };
    } catch (_) {
      return {'followers': 0, 'following': 0, 'posts': 0};
    }
  }

  // ---- UPLOAD ----
  Future<String> _upload(PlatformFile f, String base) async {
    if (f.bytes == null) throw Exception('withData:true requis');
    final name = '${_uuid.v4()}${p.extension(f.name)}'; 
    final path = '$base/$name';
    await supabase.storage.from('media').uploadBinary(path, f.bytes!, fileOptions: const FileOptions(cacheControl: '31536000', upsert: true));
    return supabase.storage.from('media').getPublicUrl(path);
  }

  // 🚀 PUBLICATION AVEC MONÉTISATION, SÉRIES ET FILTRES 🚀
  Future<MediaContent> insertWithFiles(
    MediaContent item, {
    PlatformFile? coverFile,
    PlatformFile? videoFile,
    List<PlatformFile>? extraEpisodes, // Pour les Séries
    bool isPaid = false,
    double price = 0.0,
    String filter = 'Normal',
    ProgressCallback? onProgress,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception("Utilisateur non connecté. Impossible de publier.");
    }

    final nid = _uuid.v4(); 
    String? c = item.coverUrl, v = item.videoUrl;
    
    // 1. Upload Couverture
    if (coverFile != null) {
      c = await _upload(coverFile, 'thix_media/$nid/covers'); 
    }
    onProgress?.call(0.3);
    
    // 2. Upload Vidéo Principale
    if (videoFile != null) {
      v = await _upload(videoFile, 'thix_media/$nid/videos'); 
    }
    onProgress?.call(0.6);

    // 3. Upload Épisodes supplémentaires (si c'est une Série)
    List<String> episodesUrls = [];
    if (extraEpisodes != null && extraEpisodes.isNotEmpty) {
      for (var ep in extraEpisodes) {
        final epUrl = await _upload(ep, 'thix_media/$nid/episodes');
        episodesUrls.add(epUrl);
      }
    }
    onProgress?.call(0.9);
    
    // 4. Préparation du JSON de base
    final ins = item.copyWith(
      id: nid, 
      userId: user.id, 
      coverUrl: c, 
      videoUrl: v, 
      createdAt: DateTime.now(), 
      updatedAt: DateTime.now()
    ).toJson();

    // 5. Injection dynamique des nouveaux paramètres
    ins['is_paid'] = isPaid;
    ins['price'] = price;
    ins['filter_applied'] = filter;
    
    if (episodesUrls.isNotEmpty) {
      ins['episodes_urls'] = episodesUrls; // Tableau texte en BDD
    }

    final res = await supabase.from('media_content').insert(ins).select().single();
    onProgress?.call(1.0);
    
    return MediaContent.fromJson(res as Map<String, dynamic>);
  }

  Future<void> deleteMedia(MediaContent item) async { 
    try {
      await supabase.from('media_content').delete().eq('id', item.id); 
    } catch (_) {}
  }
}
