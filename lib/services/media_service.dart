import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/models/media_content.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;

typedef ProgressCallback = void Function(double progress);

class FeedPage {
  final List<MediaContent> items;
  final List<Map<String, dynamic>> raw; // pour creator
  FeedPage({required this.items, required this.raw});
}

class MediaService {
  static final MediaService _instance = MediaService._internal();
  factory MediaService() => _instance;
  MediaService._internal();
  SupabaseClient get supabase => Supabase.instance.client;
  final Uuid _uuid = const Uuid();

  // BATCH VUES
  static final Set<String> _pendingViews = {};
  static Timer? _viewTimer;
  void registerView(String id) { _pendingViews.add(id); _viewTimer??= Timer(const Duration(seconds: 8), _flush); }
  static Future<void> _flush() async {
    if(_pendingViews.isEmpty){ _viewTimer=null; return; }
    final b=_pendingViews.toList(); _pendingViews.clear(); _viewTimer=null;
    try{ await Supabase.instance.client.rpc('batch_register_views', params:{'p_media_ids': b}); }catch(_){ _pendingViews.addAll(b); }
  }

  // FEED ENRICHI - 1 requête = media + creator + follow
  Future<FeedPage> fetchEnrichedFeed({required List<String> seenIds, int limit=12}) async {
    final uid = supabase.auth.currentUser?.id;
    final data = await supabase.rpc('get_feed_with_creator', params:{'p_seen_ids': seenIds, 'p_limit': limit, 'p_uid': uid}) as List;
    final items = data.map((e) => MediaContent.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    final raw = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    return FeedPage(items: items, raw: raw);
  }

  Future<FeedPage> fetchShuffledFeed({required List<String> seenIds, int limit=12}) async {
    final data = await supabase.rpc('get_shuffled_feed', params:{'p_seen_ids': seenIds, 'p_limit': limit}) as List;
    return FeedPage(items: data.map((e)=>MediaContent.fromJson(e as Map<String,dynamic>)).toList(), raw: []);
  }

  Future<bool> toggleLike(String id) async { final r=await supabase.rpc('toggle_media_like', params:{'p_media_id': id}); return r as bool; }
  Future<void> toggleFollow(String targetId) async {
    final uid=supabase.auth.currentUser?.id; if(uid==null||targetId.isEmpty||uid==targetId) return;
    final ex=await supabase.from('follows').select().eq('follower_id', uid).eq('following_id', targetId).maybeSingle();
    if(ex!=null) await supabase.from('follows').delete().eq('follower_id', uid).eq('following_id', targetId);
    else await supabase.from('follows').insert({'follower_id': uid, 'following_id': targetId});
  }
  Future<Set<String>> getLikedMediaIds(List<String> ids) async {
    if(ids.isEmpty) return {}; try{ final r=await supabase.rpc('get_liked_media_ids', params:{'p_media_ids': ids}); return (r as List).map((e)=>e as String).toSet(); }
    catch(_){ final uid=supabase.auth.currentUser?.id; if(uid==null) return {}; final r=await supabase.from('media_likes').select('media_id').eq('user_id', uid).inFilter('media_id', ids); return (r as List).map((e)=>e['media_id'] as String).toSet(); }
  }

  // ADMIN - manquait avant
  Future<List<MediaContent>> fetchAllMedia({int page=0, int limit=50}) async {
    final s=page*limit; final data=await supabase.from('media_content').select().order('created_at', ascending:false).range(s, s+limit-1) as List;
    return data.map((e)=>MediaContent.fromJson(e as Map<String,dynamic>)).toList();
  }
  Future<List<MediaContent>> fetchAllMediaPaginated({int limit=30, int offset=0}) async {
    final data=await supabase.from('media_content').select().order('created_at', ascending:false).range(offset, offset+limit-1) as List;
    return data.map((e)=>MediaContent.fromJson(e as Map<String,dynamic>)).toList();
  }
  Future<String> _upload(PlatformFile f, String base) async {
    if(f.bytes==null) throw Exception('withData:true requis');
    final name='${_uuid.v4()}${p.extension(f.name)}'; final path='$base/$name';
    await supabase.storage.from('media').uploadBinary(path, f.bytes!, fileOptions: const FileOptions(cacheControl:'31536000', upsert:true));
    return supabase.storage.from('media').getPublicUrl(path);
  }
  Future<MediaContent> insertWithFiles(MediaContent item, {PlatformFile? coverFile, PlatformFile? videoFile, ProgressCallback? onProgress}) async {
    final nid=_uuid.v4(); String? c=item.coverUrl, v=item.videoUrl;
    if(coverFile!=null) c=await _upload(coverFile, 'thix_media/$nid/covers'); onProgress?.call(0.5);
    if(videoFile!=null) v=await _upload(videoFile, 'thix_media/$nid/videos'); onProgress?.call(1.0);
    final ins=item.copyWith(id:nid, coverUrl:c, videoUrl:v, createdAt:DateTime.now(), updatedAt:DateTime.now()).toJson();
    final res=await supabase.from('media_content').insert(ins).select().single();
    return MediaContent.fromJson(res as Map<String,dynamic>);
  }
  Future<MediaContent> updateWithFiles(MediaContent ex, {PlatformFile? newCoverFile, PlatformFile? newVideoFile, ProgressCallback? onProgress}) async {
    String? c=ex.coverUrl, v=ex.videoUrl;
    if(newCoverFile!=null) c=await _upload(newCoverFile, 'thix_media/${ex.id}/covers'); onProgress?.call(0.5);
    if(newVideoFile!=null) v=await _upload(newVideoFile, 'thix_media/${ex.id}/videos'); onProgress?.call(1.0);
    final up=ex.copyWith(coverUrl:c, videoUrl:v, updatedAt:DateTime.now()).toJson();
    await supabase.from('media_content').update(up).eq('id', ex.id);
    return ex.copyWith(coverUrl:c, videoUrl:v);
  }
  Future<void> deleteMedia(MediaContent item) async { await supabase.from('media_content').delete().eq('id', item.id); }
}
