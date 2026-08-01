import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/models/media_content.dart';
import 'package:thix_id/services/media_service.dart';

final selectedCategoryProvider = StateProvider<String>((ref) => "Fil");
final searchQueryProvider = StateProvider<String>((ref) => "");

class ThixMediaNotifier extends StateNotifier<AsyncValue<List<MediaContent>>> {
  ThixMediaNotifier(this.ref): super(const AsyncValue.loading()){ _load(); ref.listen(selectedCategoryProvider, (_,__)=>refresh()); ref.listen(searchQueryProvider, (_,__)=>refresh()); }
  final Ref ref; DateTime? _cursor; bool _hasMore=true,_loading=false; final Set<String> _seen={}; static const _limit=20;
  Future<void> _load()=>refresh();
  Future<void> refresh() async { _cursor=null; _hasMore=true; _seen.clear(); state=const AsyncValue.loading(); try{ final l=await _fetch(null); state=AsyncValue.data(l); }catch(e,st){ state=AsyncValue.error(e,st); } }
  Future<void> loadMore() async { if(_loading||!_hasMore||state.value==null) return; _loading=true; try{ final m=await _fetch(_cursor); if(m.length<_limit) _hasMore=false; state=AsyncValue.data([...state.value!,...m]); }finally{ _loading=false; } }
  Future<List<MediaContent>> _fetch(DateTime? cur) async {
    final cat=ref.read(selectedCategoryProvider); final search=ref.read(searchQueryProvider).trim(); final svc=MediaService();
    if(cat=='Fil' && search.isEmpty){ final p=await svc.fetchShuffledFeed(seenIds:_seen.toList(), limit:_limit); _seen.addAll(p.items.map((e)=>e.id)); if(p.items.isNotEmpty) _cursor=p.items.last.createdAt; return p.items; }
    var q=Supabase.instance.client.from('media_content').select('*, media_stats(like_count,view_count,comment_count)');
    if(cur!=null) q=q.lt('created_at', cur.toIso8601String());
    if(search.isNotEmpty) q=q.ilike('title', '%$search%'); else if(cat!='Accueil') q=q.eq('type', cat);
    final res=await q.order('created_at', ascending:false).limit(_limit);
    final list=(res as List).map((it){ final e=Map<String,dynamic>.from(it as Map); final s=e['media_stats'] as Map<String,dynamic>?; if(s!=null){ e['likeCount']=s['like_count']??0; e['viewCount']=s['view_count']??0; e['commentCount']=s['comment_count']??0; } return MediaContent.fromJson(e); }).toList();
    if(list.isNotEmpty) _cursor=list.last.createdAt; _seen.addAll(list.map((e)=>e.id)); return list;
  }
}
final thixMediaListProvider = StateNotifierProvider<ThixMediaNotifier, AsyncValue<List<MediaContent>>>((ref)=>ThixMediaNotifier(ref));
final bannerItemsProvider = Provider<List<MediaContent>>((ref)=>ref.watch(thixMediaListProvider).valueOrNull?.take(5).toList()??[]);
final recommendationsProvider = Provider<List<MediaContent>>((ref)=>ref.watch(thixMediaListProvider).valueOrNull??[]);
final newReleasesProvider = Provider<List<MediaContent>>((ref)=>ref.watch(thixMediaListProvider).valueOrNull??[]);
final trendingProvider = Provider<List<MediaContent>>((ref)=>ref.watch(thixMediaListProvider).valueOrNull??[]);
