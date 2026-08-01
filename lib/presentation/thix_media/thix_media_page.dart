import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'video_player_page.dart';
import '../../models/media_content.dart';
import 'providers/thix_media_provider.dart';
import 'package:thix_id/nav.dart' show AppRoutes;
import 'admin/thix_media_admin_page.dart';

const Color kBg = Color(0xFF050507);
const Color kSurface = Color(0xFF121214);
const Color kSurfaceLight = Color(0xFF1E1E28);
const Color kRed = Color(0xFFFF1A1A);
const Color kTextWhite = Color(0xFFFFFFFF);
const Color kTextGrey = Color(0xFF9CA3AF);
const Color kBorderLight = Color(0x14FFFFFF);
const Color kTdiaBlue = Color(0xFF2D6CDF);

// --- MODELS SCALABLES ---
class MediaCounts {
  final int likeCount, viewCount, commentCount;
  MediaCounts({required this.likeCount, required this.viewCount, required this.commentCount});
}

// Batcher entreprise: 1 RPC pour 50 vues
class _AnalyticsBatcher {
  static final Set<String> _pending = {};
  static Timer? _timer;
  static void register(String id) {
    _pending.add(id);
    _timer??= Timer(const Duration(seconds: 8), _flush);
  }
  static Future<void> _flush() async {
    if (_pending.isEmpty) { _timer = null; return; }
    final batch = _pending.toList(); _pending.clear(); _timer = null;
    try { await Supabase.instance.client.rpc('batch_register_views', params: {'p_media_ids': batch}); } catch (_) { _pending.addAll(batch); }
  }
}

// --- PROVIDERS ENTREPRISE ---
final isMediaAdminProvider = FutureProvider.autoDispose<bool>((ref) async {
  final u = Supabase.instance.client.auth.currentUser;
  if (u == null) return false;
  final role = u.appMetadata['role']?? u.userMetadata?['role'];
  return role == 'admin' || role == 'superadmin';
});

class CommentItem {
  final String id, userId, userName, content;
  final String? avatarUrl;
  final DateTime createdAt;
  final String? parentId;
  final int likeCount, replyCount;
  CommentItem({required this.id, required this.userId, required this.userName, required this.content, required this.createdAt, this.avatarUrl, this.parentId, this.likeCount = 0, this.replyCount = 0});
  factory CommentItem.fromMap(Map<String, dynamic> m) => CommentItem(
    id: m['id'] as String,
    userId: m['user_id'] as String,
    userName: (m['user_name'] as String?)?.trim().isNotEmpty == true? m['user_name'] as String : 'Utilisateur',
    avatarUrl: m['avatar_url'] as String?,
    content: m['content'] as String,
    createdAt: DateTime.parse(m['created_at'] as String).toLocal(),
    parentId: m['parent_id'] as String?,
    likeCount: m['like_count'] as int??? 0,
    replyCount: m['reply_count'] as int??? 0,
  );
}

// Scalable: 30 max, pas 300. Et tri indexé
final commentsListProvider = FutureProvider.autoDispose.family<List<CommentItem>, String>((ref, mediaId) async {
  final res = await Supabase.instance.client.from('media_comments').select('id,user_id,user_name,avatar_url,content,created_at,parent_id').eq('media_id', mediaId).order('created_at', ascending: false).limit(30);
  return (res as List).map((e) => CommentItem.fromMap(e as Map<String, dynamic>)).toList();
});

// Scalable: lecture depuis media_stats, pas COUNT(*)
final commentCountProvider = FutureProvider.autoDispose.family<int, String>((ref, mediaId) async {
  final r = await Supabase.instance.client.from('media_stats').select('comment_count').eq('media_id', mediaId).maybeSingle();
  return r?['comment_count'] as int??? 0;
});

// Scalable: polling 12s sur media_stats, pas Realtime (500k sockets = crash)
final mediaCountsStreamProvider = StreamProvider.autoDispose.family<MediaCounts, String>((ref, mediaId) async* {
  while (true) {
    try {
      final r = await Supabase.instance.client.from('media_stats').select('like_count,view_count,comment_count').eq('media_id', mediaId).maybeSingle();
      yield MediaCounts(likeCount: r?['like_count']??0, viewCount: r?['view_count']??0, commentCount: r?['comment_count']??0);
    } catch (_) {}
    await Future.delayed(const Duration(seconds: 12));
  }
});

class _NavItemData { final IconData icon; final String label; final bool selected; final int index; final Color? color; _NavItemData({required this.icon, required this.label, required this.selected, required this.index, this.color}); }

class ThixMediaPage extends ConsumerStatefulWidget { const ThixMediaPage({super.key}); @override ConsumerState<ThixMediaPage> createState() => _ThixMediaPageState(); }

class _ThixMediaPageState extends ConsumerState<ThixMediaPage> {
  late PageController _bannerController, _feedController;
  int _currentBannerIndex = 0; Timer? _bannerTimer, _searchDebounce;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final List<String> _filters = ["Accueil", "Fil", "Tendances", "NOVA Originals", "Live", "Courts", "Musique", "Gaming", "Formation"];
  Set<String> _likedMediaIds = {}; final Set<String> _viewedMediaIds = {};
  bool _immersive = false; int _currentFeedIndex = 0;
  // Fil entreprise avec shuffle_seed
  List<MediaContent> _filItems = []; double _filCursor = 0; bool _filLoading = false; bool _filInitialized = false;
  double _pullDistance = 0; bool _pullTriggering = false; static const double _pullThreshold = 90;

  @override void initState() {
    super.initState();
    _bannerController = PageController(viewportFraction: 1.0); _feedController = PageController();
    _scrollController.addListener(() { if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 600) ref.read(thixMediaListProvider.notifier).loadMore(); });
    WidgetsBinding.instance.addPostFrameCallback((_) { ref.read(selectedCategoryProvider.notifier).state = "Fil"; _initFilFeed(); });
  }
  @override void dispose() { _bannerTimer?.cancel(); _searchDebounce?.cancel(); _bannerController.dispose(); _feedController.dispose(); _searchController.dispose(); _searchFocusNode.dispose(); _scrollController.dispose(); super.dispose(); }

  MediaContent _mapMedia(Map<String,dynamic> e){
    final s = e['media_stats'] as Map<String,dynamic>?;
    if(s!=null){ e = {...e, 'likeCount': s['like_count']??e['likeCount']??0, 'viewCount': s['view_count']??e['viewCount']??0, 'commentCount': s['comment_count']??e['commentCount']??0}; }
    return MediaContent.fromMap(e);
  }

  Future<void> _initFilFeed({bool reshuffle=false}) async {
    if(_filLoading) return; setState(()=>_filLoading=true);
    try{
      final seed = math.Random().nextDouble();
      final res = await Supabase.instance.client.from('media_content').select('*, media_stats(like_count,view_count,comment_count)').gt('shuffle_seed', seed).order('shuffle_seed').limit(12);
      var items = (res as List).map((e)=>_mapMedia(e as Map<String,dynamic>)).toList();
      if(items.length<12){ final res2 = await Supabase.instance.client.from('media_content').select('*, media_stats(like_count,view_count,comment_count)').lt('shuffle_seed', seed).order('shuffle_seed').limit(12-items.length); items.addAll((res2 as List).map((e)=>_mapMedia(e as Map<String,dynamic>))); }
      if(!mounted) return;
      setState((){ _filItems=items; _filCursor=items.isNotEmpty? (items.last.toJson()['shuffle_seed'] as double??? seed) : seed; _filInitialized=true; _currentFeedIndex=0; });
      await _syncLiked(items); if(_filItems.isNotEmpty) _registerView(_filItems.first);
      if(reshuffle && _feedController.hasClients) _feedController.jumpToPage(0);
    } finally{ if(mounted) setState(()=>_filLoading=false); }
  }

  Future<void> _loadMoreFil() async {
    if(_filLoading) return; setState(()=>_filLoading=true);
    try{
      final res = await Supabase.instance.client.from('media_content').select('*, media_stats(like_count,view_count,comment_count)').gt('shuffle_seed', _filCursor).order('shuffle_seed').limit(12);
      var items = (res as List).map((e)=>_mapMedia(e as Map<String,dynamic>)).toList();
      if(items.isEmpty){ final res2 = await Supabase.instance.client.from('media_content').select('*, media_stats(like_count,view_count,comment_count)').order('shuffle_seed').limit(12); items = (res2 as List).map((e)=>_mapMedia(e as Map<String,dynamic>)).toList(); }
      final existing = _filItems.map((e)=>e.id).toSet();
      if(!mounted) return; setState((){ _filItems.addAll(items.where((e)=>!existing.contains(e.id))); if(_filItems.isNotEmpty) _filCursor = _filItems.last.toJson()['shuffle_seed'] as double??? _filCursor; });
      await _syncLiked(items);
    } finally{ if(mounted) setState(()=>_filLoading=false); }
  }

  Future<void> _syncLiked(List<MediaContent> items) async {
    if(items.isEmpty) return; final uid = Supabase.instance.client.auth.currentUser?.id; if(uid==null) return;
    final ids = items.map((e)=>e.id).toList();
    final res = await Supabase.instance.client.from('media_likes').select('media_id').eq('user_id', uid).inFilter('media_id', ids);
    if(mounted) setState(()=>_likedMediaIds.addAll((res as List).map((e)=>e['media_id'] as String)));
  }

  void _startAutoScroll(int count){ _bannerTimer?.cancel(); if(count==0) return; _bannerTimer=Timer.periodic(const Duration(seconds: 8), (_){ if(!mounted||!_bannerController.hasClients) return; final next=(_currentBannerIndex+1)%count; _bannerController.animateToPage(next, duration: const Duration(milliseconds: 800), curve: Curves.fastOutSlowIn); }); }
  void _onSearchChanged(String v){ _searchDebounce?.cancel(); _searchDebounce=Timer(const Duration(milliseconds: 300), ()=>ref.read(searchQueryProvider.notifier).state=v); }
  void _navigateToVideo(MediaContent item)=>Navigator.push(context, MaterialPageRoute(builder: (_)=>VideoPlayerPage(title: item.title, videoUrl: item.videoUrl)));
  String _formatNumber(int n){ if(n>=1000000) return '${(n/1000000).toStringAsFixed(1)}M'; if(n>=1000) return '${(n/1000).toStringAsFixed(1)}k'; return n.toString(); }
  Widget _buildImage(String url,{double? width,double? height,BoxFit fit=BoxFit.cover}){ if(url.isEmpty) return Container(color:kSurface, child:const Icon(Icons.broken_image_rounded,color:kTextGrey)); return Image.network(url, width:width,height:height,fit:fit, cacheWidth: kIsWeb?null:(width!=null?(width*2).toInt():600), loadingBuilder: (c,child,p){ if(p==null) return child; return Container(color:kSurface, child:const Center(child:CircularProgressIndicator(color:kRed,strokeWidth:2))); }, errorBuilder: (c,e,s)=>Container(color:kSurface, child:const Icon(Icons.broken_image_rounded,color:kTextGrey))); }

  void _registerView(MediaContent item){ if(_viewedMediaIds.contains(item.id)) return; _viewedMediaIds.add(item.id); _AnalyticsBatcher.register(item.id); }
  Future<void> _toggleLike(MediaContent item) async {
    if(Supabase.instance.client.auth.currentUser==null){ ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez vous connecter'), backgroundColor:kSurface)); return; }
    final was=_likedMediaIds.contains(item.id); setState(()=>was?_likedMediaIds.remove(item.id):_likedMediaIds.add(item.id));
    try{ await Supabase.instance.client.rpc('toggle_like', params:{'p_media_id':item.id}); }catch(e){ if(!mounted) return; setState(()=>was?_likedMediaIds.add(item.id):_likedMediaIds.remove(item.id)); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Erreur: $e'), backgroundColor:kRed)); }
  }
  void _openComments(MediaContent item){ showModalBottomSheet(context:context, backgroundColor:Colors.transparent, isScrollControlled:true, builder:(_)=>_CommentsSheet(mediaId:item.id, mediaTitle:item.title)).then((_){ ref.invalidate(commentCountProvider(item.id)); }); }
  void _showViewsInfo(MediaContent item){ ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('${item.viewCount} vues'), backgroundColor:kSurface)); }
  void _handlePageChanged(int index){ if(index<0||index>=_filItems.length) return; if(index>=_filItems.length-4) _loadMoreFil(); _registerView(_filItems[index]); }

  @override Widget build(BuildContext context){
    final asyncMedia = ref.watch(thixMediaListProvider); final bannerItems = ref.watch(bannerItemsProvider); final selectedCategory = ref.watch(selectedCategoryProvider);
    ref.listen<List<MediaContent>>(bannerItemsProvider, (p,n){ if(n.isNotEmpty) _startAutoScroll(n.length); });
    return Scaffold(backgroundColor:kBg, body: asyncMedia.when(loading: ()=>const Center(child:CircularProgressIndicator(color:kRed)), error:(e,st)=>Center(child:Text('Erreur: $e', style:TextStyle(color:kTextWhite))), data:(mediaList){
      final currentItem = _filItems.isNotEmpty? _filItems[_currentFeedIndex.clamp(0,_filItems.length-1)] : null; final showBars =!(_immersive && selectedCategory=='Fil');
      return Stack(children:[
        if(selectedCategory=='Fil') _buildTikTokFeed() else RefreshIndicator(color:kRed, backgroundColor:kSurface, onRefresh:()=>ref.read(thixMediaListProvider.notifier).refresh(), child: CustomScrollView(controller:_scrollController, physics:const BouncingScrollPhysics(parent:AlwaysScrollableScrollPhysics()), slivers:[ SliverToBoxAdapter(child: Column(crossAxisAlignment:CrossAxisAlignment.start, children:[ const SizedBox(height:100), if(bannerItems.isNotEmpty) _heroBanner(bannerItems), Transform.translate(offset:const Offset(0,-40), child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter, colors:[Colors.transparent,kBg.withOpacity(0.6),kBg], stops:[0.0,0.1,0.3])), child: Column(children:[ const SizedBox(height:20), _buildRow(title:'Continuer à regarder', subtitle:'Reprise intelligente', provider:recommendationsProvider, aspectRatio:16/9, height:180, width:320, itemBuilder:(item,[i])=>_continueWatchingCard(item)), const SizedBox(height:40), _buildRow(title:'TDIA Originals Exclusifs', subtitle:'Produit par TDIA Studios', provider:newReleasesProvider, aspectRatio:2/3, height:240, width:160, itemBuilder:(item,[i])=>_originalCard(item)), const SizedBox(height:40), _buildRow(title:'Top 10 cette semaine', subtitle:'Classement', provider:trendingProvider, aspectRatio:16/9, height:160, width:300, itemBuilder:(item,[i])=>_top10Card(item,i??0)), const SizedBox(height:120), ])), ), ])), ])),
        Positioned(top:0,left:0,right:0, child:IgnorePointer(ignoring:!showBars, child:AnimatedOpacity(duration:const Duration(milliseconds:250), opacity:showBars?1:0, child:Column(children:[_header(), _filtersRow(selectedCategory)])))),
        Positioned(bottom:0,left:0,right:0, child:IgnorePointer(ignoring:!showBars, child:AnimatedOpacity(duration:const Duration(milliseconds:250), opacity:showBars?1:0, child:_bottomNav(selectedCategory, currentItem)))),
      ]);
    }));
  }

  Widget _buildTikTokFeed(){
    if(!_filInitialized) return const Center(child:CircularProgressIndicator(color:kRed));
    if(_filItems.isEmpty) return const Center(child:Text("Aucun contenu", style:TextStyle(color:Colors.white)));
    return GestureDetector(
      onVerticalDragUpdate: (d){ if(_currentFeedIndex==0 && d.delta.dy>0 &&!_filLoading) setState(()=>_pullDistance=(_pullDistance+d.delta.dy).clamp(0,_pullThreshold*1.6)); },
      onVerticalDragEnd: (d) async { if(_pullDistance>=_pullThreshold &&!_pullTriggering){ _pullTriggering=true; await _initFilFeed(reshuffle:true); _pullTriggering=false; } setState(()=>_pullDistance=0); },
      child: Stack(children:[
        NotificationListener<UserScrollNotification>(onNotification:(n){ if(n.direction!=ScrollDirection.idle &&!_immersive){ WidgetsBinding.instance.addPostFrameCallback((_){ if(mounted) setState(()=>_immersive=true); }); } return false; },
          child: PageView.builder(controller:_feedController, scrollDirection:Axis.vertical, itemCount:_filItems.length, onPageChanged:(i){ setState((){ _currentFeedIndex=i; _immersive=true; }); _handlePageChanged(i); }, itemBuilder:(c,idx){
            final item=_filItems[idx]; final isFocused=_currentFeedIndex==idx; final textBottom=_immersive?20.0:110.0;
            return Stack(fit:StackFit.expand, children:[
              FeedVideoPlayer(videoUrl:item.videoUrl, coverUrl:item.coverUrl, isPlaying:isFocused, isImmersive:_immersive, onPlayStateChanged:(paused){ setState(()=>_immersive=!paused); }),
              AnimatedPositioned(duration:const Duration(milliseconds:250), curve:Curves.easeOutCubic, left:20, bottom:textBottom, right:20, child:IgnorePointer(child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[ Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:4), decoration:BoxDecoration(color:kTdiaBlue.withOpacity(0.2), borderRadius:BorderRadius.circular(8), border:Border.all(color:kTdiaBlue.withOpacity(0.5))), child:Text(item.type, style:TextStyle(color:Colors.white,fontSize:10,fontWeight:FontWeight.w700))), const SizedBox(height:10), Text(item.title, style:TextStyle(color:Colors.white,fontSize:22,fontWeight:FontWeight.w900, height:1.1, shadows:[Shadow(color:Colors.black87,blurRadius:6)])), if(item.subtitle!=null)...[const SizedBox(height:6), Text(item.subtitle!, maxLines:2, overflow:TextOverflow.ellipsis, style:TextStyle(color:Colors.white, fontSize:13, shadows:[Shadow(color:Colors.black87,blurRadius:6)]))], ]))),
            ]);
          })),
        if(_pullDistance>0||_filLoading) Positioned(top:90,left:0,right:0, child:Center(child:Container(padding:const EdgeInsets.all(10), decoration:BoxDecoration(color:Colors.black54, shape:BoxShape.circle), child:_filLoading?const SizedBox(width:18,height:18, child:CircularProgressIndicator(color:kRed,strokeWidth:2)):Icon(Icons.autorenew_rounded, color:Colors.white, size: (18+(_pullDistance/_pullThreshold)*6).clamp(18,26))))),
      ]),
    );
  }

  Widget _header(){ final isAdminAsync=ref.watch(isMediaAdminProvider); final isAdmin=isAdminAsync.valueOrNull??false; return ClipRRect(child:BackdropFilter(filter:ImageFilter.blur(sigmaX:20,sigmaY:20), child:Container(height:60, padding:const EdgeInsets.only(top:8,left:12,right:12,bottom:8), decoration:BoxDecoration(color:Colors.black.withOpacity(0.7), border:const Border(bottom:BorderSide(color:kBorderLight))), child:Row(children:[ ShaderMask(shaderCallback:(b)=>const LinearGradient(colors:[kTdiaBlue, Color(0xFF00E5FF)]).createShader(b), child:const Text('TDIA', style:TextStyle(color:Colors.white,fontWeight:FontWeight.w900,fontSize:18,letterSpacing:-0.5))), const SizedBox(width:14), Expanded(child:Container(height:36, padding:const EdgeInsets.symmetric(horizontal:12), decoration:BoxDecoration(color:const Color(0xFF0D0D10), borderRadius:BorderRadius.circular(20), border:Border.all(color:Colors.white.withOpacity(0.08))), child:Row(children:[ const Icon(Icons.search_rounded,color:Colors.white30,size:16), const SizedBox(width:8), Expanded(child:TextField(controller:_searchController, focusNode:_searchFocusNode, onChanged:_onSearchChanged, style:const TextStyle(color:Colors.white,fontSize:13), decoration:const InputDecoration(hintText:"Rechercher...", hintStyle:TextStyle(color:Colors.white30,fontSize:13), border:InputBorder.none, isDense:true, contentPadding:EdgeInsets.zero)))]))), const SizedBox(width:12), if(isAdmin)...[GestureDetector(onTap:()=>Navigator.push(context, MaterialPageRoute(builder:(_)=>const ThixMediaAdminPage())), child:Container(width:32,height:32, decoration:BoxDecoration(shape:BoxShape.circle, color:kRed.withOpacity(0.15), border:Border.all(color:kRed.withOpacity(0.3))), child:const Icon(Icons.admin_panel_settings_rounded,color:kRed,size:16))), const SizedBox(width:10)], Container(width:32,height:32, decoration:const BoxDecoration(shape:BoxShape.circle,color:Colors.white10), child:const Icon(Icons.notifications_none_rounded,color:Colors.white70,size:18)), ])))); }
  Widget _filtersRow(String selCat)=>ClipRRect(child:BackdropFilter(filter:ImageFilter.blur(sigmaX:20,sigmaY:20), child:Container(color:kBg.withOpacity(0.85), padding:const EdgeInsets.symmetric(vertical:10), child:SingleChildScrollView(scrollDirection:Axis.horizontal, padding:const EdgeInsets.symmetric(horizontal:16), child:Row(children:_filters.map((f){ final sel=selCat==f; return Padding(padding:const EdgeInsets.only(right:8), child:GestureDetector(onTap:(){ ref.read(selectedCategoryProvider.notifier).state=f; if(f!='Fil') setState(()=>_immersive=false); }, child:AnimatedContainer(duration:const Duration(milliseconds:200), padding:const EdgeInsets.symmetric(horizontal:16,vertical:8), decoration:BoxDecoration(color:sel?Colors.white:Colors.white.withOpacity(0.06), borderRadius:BorderRadius.circular(20), border:Border.all(color:sel?Colors.white:kBorderLight)), child:Text(f, style:TextStyle(color:sel?Colors.black:Colors.white60,fontSize:12,fontWeight:sel?FontWeight.w700:FontWeight.w500))))); }).toList()))));
  Widget _heroBanner(List<MediaContent> items)=>SizedBox(height:MediaQuery.of(context).size.height*0.82, child:PageView.builder(controller:_bannerController, onPageChanged:(i)=>setState(()=>_currentBannerIndex=i), itemCount:items.length, itemBuilder:(c,idx){ final item=items[idx]; return Stack(fit:StackFit.expand, children:[_buildImage(item.coverUrl), Container(decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.bottomCenter,end:Alignment.topCenter,colors:[kBg,kBg.withOpacity(0.7),kBg.withOpacity(0.1),Colors.transparent]))), Container(decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.centerLeft,end:Alignment.centerRight,colors:[kBg,kBg.withOpacity(0.6),Colors.transparent]))), Positioned(bottom:80,left:24,right:24, child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[Text(item.title.toUpperCase(), style:const TextStyle(color:Colors.white,fontSize:48,fontWeight:FontWeight.w900,height:0.9,letterSpacing:-2)), const SizedBox(height:16), Row(children:[if(item.year!=null)...[Text("${item.year}", style:const TextStyle(color:Colors.white54,fontSize:13)), const SizedBox(width:10)], Text(item.type, style:const TextStyle(color:Colors.white54,fontSize:13))]), if(item.subtitle!=null)...[const SizedBox(height:16), Text(item.subtitle!, style:const TextStyle(color:Colors.white70,fontSize:14.5,height:1.5), maxLines:3, overflow:TextOverflow.ellipsis)], const SizedBox(height:24), Row(children:[ElevatedButton.icon(onPressed:()=>_navigateToVideo(item), icon:const Icon(Icons.play_arrow_rounded,color:Colors.black,size:22), label:const Text('Lecture', style:TextStyle(color:Colors.black,fontSize:15,fontWeight:FontWeight.bold)), style:ElevatedButton.styleFrom(backgroundColor:Colors.white, padding:const EdgeInsets.symmetric(horizontal:26,vertical:13), shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(28)))), const SizedBox(width:10), ElevatedButton.icon(onPressed:(){}, icon:const Icon(Icons.add,color:Colors.white,size:22), label:const Text('Ma Liste', style:TextStyle(color:Colors.white,fontSize:14,fontWeight:FontWeight.w600)), style:ElevatedButton.styleFrom(backgroundColor:Colors.white.withOpacity(0.1), padding:const EdgeInsets.symmetric(horizontal:22,vertical:13), shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(28)), side:BorderSide(color:Colors.white.withOpacity(0.1)))), ])]))]); }));
  Widget _buildRow({required String title,required String subtitle,required ProviderListenable<List<MediaContent>> provider,required double aspectRatio,required double height,required double width,required Widget Function(MediaContent item,[int? index]) itemBuilder}){ final list=ref.watch(provider); if(list.isEmpty) return const SizedBox.shrink(); return Column(crossAxisAlignment:CrossAxisAlignment.start, children:[Padding(padding:const EdgeInsets.symmetric(horizontal:24), child:Row(crossAxisAlignment:CrossAxisAlignment.end, children:[Text(title, style:const TextStyle(color:Colors.white,fontSize:18,fontWeight:FontWeight.bold)), const SizedBox(width:12), Text(subtitle, style:const TextStyle(color:Colors.white38,fontSize:12))])), const SizedBox(height:16), SizedBox(height:height, child:ListView.builder(padding:const EdgeInsets.symmetric(horizontal:24), scrollDirection:Axis.horizontal, itemCount:list.length, itemBuilder:(c,i)=>Padding(padding:const EdgeInsets.only(right:16), child:SizedBox(width:width, child:itemBuilder(list[i],i)))))]); }
  Widget _continueWatchingCard(MediaContent item)=>GestureDetector(onTap:()=>_navigateToVideo(item), child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[Expanded(child:ClipRRect(borderRadius:BorderRadius.circular(12), child:Stack(fit:StackFit.expand, children:[_buildImage(item.coverUrl), Container(color:Colors.black.withOpacity(0.3)), const Center(child:Icon(Icons.play_circle_fill_rounded,color:Colors.white,size:44))]))), const SizedBox(height:8), Text(item.title, maxLines:1, overflow:TextOverflow.ellipsis, style:const TextStyle(color:Colors.white,fontSize:14,fontWeight:FontWeight.w600))]));
  Widget _originalCard(MediaContent item)=>GestureDetector(onTap:()=>_navigateToVideo(item), child:ClipRRect(borderRadius:BorderRadius.circular(14), child:Stack(fit:StackFit.expand, children:[_buildImage(item.coverUrl), Container(decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.bottomCenter,end:Alignment.topCenter,colors:[Colors.black.withOpacity(0.9),Colors.transparent]))), Positioned(bottom:12,left:12,right:12, child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[Text(item.title, maxLines:2, overflow:TextOverflow.ellipsis, style:const TextStyle(color:Colors.white,fontSize:14,fontWeight:FontWeight.bold)), if(item.year!=null)...[const SizedBox(height:4), Text("${item.year}", style:const TextStyle(color:Colors.white54,fontSize:11))]]))])));
  Widget _top10Card(MediaContent item,int index)=>GestureDetector(onTap:()=>_navigateToVideo(item), child:Stack(clipBehavior:Clip.none, children:[Positioned(left:-20,bottom:-10, child:Text((index+1).toString().padLeft(2,'0'), style:TextStyle(fontSize:100,fontWeight:FontWeight.w900,color:Colors.transparent, shadows:[Shadow(color:Colors.white.withOpacity(0.2),blurRadius:2)]))), Positioned(left:40,top:0,bottom:0,right:0, child:ClipRRect(borderRadius:BorderRadius.circular(12), child:Stack(fit:StackFit.expand, children:[_buildImage(item.coverUrl), Container(decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.bottomCenter,end:Alignment.topCenter,colors:[Colors.black.withOpacity(0.8),Colors.transparent]))), Positioned(bottom:8,left:8,right:8, child:Text(item.title, maxLines:1, overflow:TextOverflow.ellipsis, style:const TextStyle(color:Colors.white,fontSize:13,fontWeight:FontWeight.bold)))])))]));
  Widget _bottomNav(String selCat, MediaContent? cur){ final isFil=selCat=='Fil'; final isLiked=cur!=null&&_likedMediaIds.contains(cur.id); MediaCounts? live; if(isFil&&cur!=null) live=ref.watch(mediaCountsStreamProvider(cur.id)).valueOrNull; final items=isFil?[_NavItemData(icon:Icons.movie_filter_rounded,label:'TDIA',selected:true,index:0), _NavItemData(icon:isLiked?Icons.favorite_rounded:Icons.favorite_outline_rounded,label:cur!=null?_formatNumber(live?.likeCount??cur.likeCount):"J'aime",selected:false,index:1,color:isLiked?kRed:null), _NavItemData(icon:Icons.chat_bubble_outline_rounded,label:cur!=null?_formatNumber(live?.commentCount??cur.commentCount):'Commenter',selected:false,index:2), _NavItemData(icon:Icons.remove_red_eye_rounded,label:cur!=null?_formatNumber(live?.viewCount??cur.viewCount):'Vu',selected:false,index:3)] : [_NavItemData(icon:Icons.movie_filter_rounded,label:'TDIA',selected:true,index:0), _NavItemData(icon:Icons.search_rounded,label:'Recherche',selected:false,index:1), _NavItemData(icon:Icons.favorite_rounded,label:'Favoris',selected:false,index:2), _NavItemData(icon:Icons.person_rounded,label:'Profil',selected:false,index:3)]; return Padding(padding:const EdgeInsets.fromLTRB(24,0,24,20), child:ClipRRect(borderRadius:BorderRadius.circular(26), child:BackdropFilter(filter:ImageFilter.blur(sigmaX:30,sigmaY:30), child:Container(height:60, decoration:BoxDecoration(color:const Color(0xFF12121A).withOpacity(0.85), borderRadius:BorderRadius.circular(26), border:Border.all(color:Colors.white.withOpacity(0.1))), child:Row(mainAxisAlignment:MainAxisAlignment.spaceEvenly, children:items.map((d)=>_navItem(d.icon,d.label,d.selected,d.index,isFil:isFil,currentItem:cur,color:d.color)).toList()))))); }
  Widget _navItem(IconData icon,String label,bool sel,int idx,{required bool isFil,MediaContent? currentItem,Color? color})=>InkWell(onTap:(){ if(idx==0){ if(ref.read(selectedCategoryProvider.notifier).state=='Fil') _feedController.animateTo(0, duration:const Duration(milliseconds:500), curve:Curves.easeOutCubic); else ref.read(selectedCategoryProvider.notifier).state='Fil'; return; } if(isFil){ switch(idx){ case 1: if(currentItem!=null) _toggleLike(currentItem); break; case 2: if(currentItem!=null) _openComments(currentItem); break; case 3: if(currentItem!=null) _showViewsInfo(currentItem); break; } } else { if(idx==3) context.go(AppRoutes.userDashboard); } }, child:Column(mainAxisSize:MainAxisSize.min, mainAxisAlignment:MainAxisAlignment.center, children:[Icon(icon,color:color??(sel?Colors.white:Colors.white38),size:22), const SizedBox(height:4), Text(label, style:TextStyle(fontSize:10,fontWeight:sel?FontWeight.bold:FontWeight.w500,color:color??(sel?Colors.white:Colors.white38))) ]));
}

// --- PLAYER ENTREPRISE: 1 controller, pas 2 ---
class FeedVideoPlayer extends StatefulWidget { final String videoUrl, coverUrl; final bool isPlaying, isImmersive; final Function(bool) onPlayStateChanged; const FeedVideoPlayer({super.key, required this.videoUrl, required this.coverUrl, required this.isPlaying, required this.isImmersive, required this.onPlayStateChanged}); @override State<FeedVideoPlayer> createState()=>_FeedVideoPlayerState(); }
class _FeedVideoPlayerState extends State<FeedVideoPlayer> {
  late VideoPlayerController _c; bool _init=false, _paused=false; final ValueNotifier<Duration> _pos=ValueNotifier(Duration.zero); Duration _dur=Duration.zero; Offset? _tapPos; bool _drag=false;
  @override void initState(){ super.initState(); _c=VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl)); _c.initialize().then((_){ if(!mounted) return; _c.setLooping(true); _c.setVolume(1.0); _c.addListener(_lis); setState((){ _init=true; _dur=_c.value.duration; }); if(widget.isPlaying) _c.play(); }); }
  void _lis(){ if(!mounted||!_c.value.isInitialized||_drag) return; _pos.value=_c.value.position; }
  @override void didUpdateWidget(covariant FeedVideoPlayer o){ super.didUpdateWidget(o); if(!_init) return; if(widget.isPlaying&&!o.isPlaying){ _paused=false; _c.play(); } else if(!widget.isPlaying&&o.isPlaying){ _c.pause(); _c.seekTo(Duration.zero); _paused=false; } }
  void _toggle(){ if(!_init) return; setState((){ if(_c.value.isPlaying){ _c.pause(); _paused=true; } else { _c.play(); _paused=false; } }); widget.onPlayStateChanged(_paused); }
  void _seek(int s){ if(!_init) return; var p=_pos.value+Duration(seconds:s); if(p<Duration.zero) p=Duration.zero; if(p>_dur) p=_dur; _c.seekTo(p); }
  String _fmt(Duration d){ String two(int n)=>n.toString().padLeft(2,'0'); return '${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}'; }
  @override void dispose(){ _c.removeListener(_lis); _c.dispose(); _pos.dispose(); super.dispose(); }
  @override Widget build(BuildContext context){
    if(!_init) return Image.network(widget.coverUrl, fit:BoxFit.cover, errorBuilder:(c,e,s)=>Container(color:kSurface));
    return GestureDetector(onTapDown:(d)=>_tapPos=d.globalPosition, onTap:_toggle, onDoubleTap:(){ if(_tapPos==null) return; final w=MediaQuery.of(context).size.width; if(_tapPos!.dx<w/2) _seek(-10); else _seek(10); },
      child: Stack(fit:StackFit.expand, children:[
        SizedBox.expand(child:FittedBox(fit:BoxFit.cover, child:SizedBox(width:_c.value.size.width,height:_c.value.size.height, child:VideoPlayer(_c)))),
        if(_paused) Center(child:Container(padding:const EdgeInsets.all(16), decoration:const BoxDecoration(color:Colors.black45,shape:BoxShape.circle), child:const Icon(Icons.play_arrow_rounded,color:Colors.white,size:64))),
        AnimatedPositioned(duration:const Duration(milliseconds:250), curve:Curves.easeOutCubic, left:0,right:0,bottom:widget.isImmersive?0:80, child:IgnorePointer(ignoring:widget.isImmersive, child:AnimatedOpacity(duration:const Duration(milliseconds:250), opacity:widget.isImmersive?0:1, child:ValueListenableBuilder<Duration>(valueListenable:_pos, builder:(c,pos,_){ final pct=_dur.inMilliseconds==0?0.0:pos.inMilliseconds/_dur.inMilliseconds; return Container(height:24, color:Colors.transparent, alignment:Alignment.bottomCenter, child:Stack(alignment:Alignment.bottomLeft, children:[Container(height:_drag?6:2,width:double.infinity,color:Colors.white.withOpacity(0.3)), Container(height:_drag?6:2,width:MediaQuery.of(context).size.width*pct,color:kRed)])); }))))]));
  }
}

class _CommentsSheet extends ConsumerStatefulWidget { final String mediaId, mediaTitle; const _CommentsSheet({required this.mediaId, required this.mediaTitle}); @override ConsumerState<_CommentsSheet> createState()=>_CommentsSheetState(); }
class _CommentsSheetState extends ConsumerState<_CommentsSheet> {
  final _controller=TextEditingController(); final _focus=FocusNode(); bool _sending=false;
  String _rel(DateTime d){ final diff=DateTime.now().difference(d); if(diff.inSeconds<60) return "à l'instant"; if(diff.inMinutes<60) return '${diff.inMinutes} min'; if(diff.inHours<24) return '${diff.inHours} h'; if(diff.inDays<7) return '${diff.inDays} j'; return '${d.day}/${d.month}'; }
  Future<void> _submit() async { final t=_controller.text.trim(); if(t.isEmpty||_sending) return; final uid=Supabase.instance.client.auth.currentUser?.id; if(uid==null) return; setState(()=>_sending=true); try{ final p=await Supabase.instance.client.from('profiles').select('username,avatar_url').eq('id',uid).maybeSingle(); final name=(p?['username'] as String?)?.trim().isNotEmpty==true?p!['username']: 'Utilisateur'; await Supabase.instance.client.from('media_comments').insert({'media_id':widget.mediaId,'user_id':uid,'user_name':name,'avatar_url':p?['avatar_url'],'content':t}); _controller.clear(); ref.invalidate(commentsListProvider(widget.mediaId)); ref.invalidate(commentCountProvider(widget.mediaId)); }finally{ if(mounted) setState(()=>_sending=false); } }
  @override Widget build(BuildContext context){ final async=ref.watch(commentsListProvider(widget.mediaId)); final insets=MediaQuery.of(context).viewInsets.bottom; return AnimatedPadding(duration:const Duration(milliseconds:150), padding:EdgeInsets.only(bottom:insets), child:Container(height:MediaQuery.of(context).size.height*0.75, decoration:const BoxDecoration(color:kSurface, borderRadius:BorderRadius.vertical(top:Radius.circular(20))), child:SafeArea(top:false, child:Column(children:[const SizedBox(height:10), Container(width:40,height:4,decoration:BoxDecoration(color:Colors.white24,borderRadius:BorderRadius.circular(4))), const SizedBox(height:14), async.when(loading:()=>const Text('Commentaires',style:TextStyle(color:Colors.white,fontWeight:FontWeight.bold)), error:(_,__)=>const Text('Commentaires',style:TextStyle(color:Colors.white)), data:(l)=>Text('${l.length} commentaires',style:const TextStyle(color:Colors.white,fontWeight:FontWeight.bold))), const Divider(color:kBorderLight,height:1), Expanded(child:async.when(loading:()=>const Center(child:CircularProgressIndicator(color:kRed)), error:(e,s)=>const Center(child:Text('Erreur',style:TextStyle(color:kTextGrey))), data:(cs){ if(cs.isEmpty) return const Center(child:Text('Aucun commentaire',style:TextStyle(color:kTextGrey))); return ListView.separated(padding:const EdgeInsets.all(16), itemCount:cs.length, separatorBuilder:(_,__)=>const SizedBox(height:16), itemBuilder:(c,i){ final com=cs[i]; return Row(crossAxisAlignment:CrossAxisAlignment.start, children:[CircleAvatar(radius:16,backgroundColor:kSurfaceLight, backgroundImage:com.avatarUrl!=null&&com.avatarUrl!.isNotEmpty?NetworkImage(com.avatarUrl!):null, child:com.avatarUrl==null||com.avatarUrl!.isEmpty?const Icon(Icons.person_rounded,size:16,color:kTextGrey):null), const SizedBox(width:10), Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[Row(children:[Text(com.userName,style:const TextStyle(color:Colors.white,fontSize:13,fontWeight:FontWeight.w700)), const SizedBox(width:8), Text(_rel(com.createdAt),style:const TextStyle(color:kTextGrey,fontSize:11))]), const SizedBox(height:4), Text(com.content,style:const TextStyle(color:Colors.white70,fontSize:13.5))]))]); }); })), const Divider(color:kBorderLight,height:1), Padding(padding:const EdgeInsets.fromLTRB(12,10,12,10), child:Row(children:[Expanded(child:Container(padding:const EdgeInsets.symmetric(horizontal:14), decoration:BoxDecoration(color:kSurfaceLight,borderRadius:BorderRadius.circular(24)), child:TextField(controller:_controller, focusNode:_focus, minLines:1,maxLines:4, onSubmitted:(_)=>_submit(), style:const TextStyle(color:Colors.white,fontSize:13.5), decoration:const InputDecoration(hintText:'Ajouter un commentaire...', hintStyle:TextStyle(color:kTextGrey), border:InputBorder.none, isDense:true)))), const SizedBox(width:8), GestureDetector(onTap:_submit, child:Container(width:42,height:42, decoration:BoxDecoration(color:_sending?kSurfaceLight:kRed,shape:BoxShape.circle), child:_sending?const Padding(padding:EdgeInsets.all(11), child:CircularProgressIndicator(color:Colors.white,strokeWidth:2)):const Icon(Icons.send_rounded,color:Colors.white,size:18))) ])), ])))); }
}
