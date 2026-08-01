import 'dart:async';
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
import '../../services/media_service.dart';
import 'create_post_page.dart';
import 'user_profile_page.dart';

const Color kBg = Color(0xFF050507);
const Color kSurface = Color(0xFF121214);
const Color kSurfaceLight = Color(0xFF1E1E28);
const Color kRed = Color(0xFFFF1A1A);
const Color kTextWhite = Color(0xFFFFFFFF);
const Color kTextGrey = Color(0xFF9CA3AF);
const Color kBorderLight = Color(0x14FFFFFF);
const Color kTdiaBlue = Color(0xFF2D6CDF);

class MediaCounts {
  final int likeCount, viewCount, commentCount;
  const MediaCounts({required this.likeCount, required this.viewCount, required this.commentCount});
}

final isMediaAdminProvider = FutureProvider.autoDispose<bool>((ref) async {
  final u = Supabase.instance.client.auth.currentUser;
  if (u == null) return false;
  final role = u.appMetadata['role']?? u.userMetadata?['role'];
  return role == 'admin' || role == 'superadmin';
});

class CommentItem {
  final String id, userId, userName, content;
  final String? avatarUrl, parentId;
  final DateTime createdAt;
  final int likeCount, replyCount;
  CommentItem({required this.id, required this.userId, required this.userName, required this.content, required this.createdAt, this.avatarUrl, this.parentId, this.likeCount=0, this.replyCount=0});
  factory CommentItem.fromMap(Map<String, dynamic> m) => CommentItem(
    id: m['id'] as String, userId: m['user_id'] as String,
    userName: (m['user_name'] as String?)?.trim().isNotEmpty==true? m['user_name'] as String : 'Utilisateur',
    avatarUrl: m['avatar_url'] as String?, content: m['content'] as String,
    createdAt: DateTime.parse(m['created_at'] as String).toLocal(),
    parentId: m['parent_id'] as String?, likeCount: (m['like_count'] as num?)?.toInt()??0, replyCount: (m['reply_count'] as num?)?.toInt()??0,
  );
}

final commentCountProvider = FutureProvider.autoDispose.family<int, String>((ref, mediaId) async {
  final r = await Supabase.instance.client.from('media_stats').select('comment_count').eq('media_id', mediaId).maybeSingle();
  return (r?['comment_count'] as int?)??0;
});

final mediaCountsStreamProvider = StreamProvider.autoDispose.family<MediaCounts, String>((ref, mediaId) async* {
  while(true){
    try{
      final r = await Supabase.instance.client.from('media_stats').select('like_count,view_count,comment_count').eq('media_id', mediaId).maybeSingle();
      yield MediaCounts(likeCount: (r?['like_count'] as int?)??0, viewCount: (r?['view_count'] as int?)??0, commentCount: (r?['comment_count'] as int?)??0);
    }catch(_){}
    await Future.delayed(const Duration(seconds:30));
  }
});

class ThixMediaPage extends ConsumerStatefulWidget { const ThixMediaPage({super.key}); @override ConsumerState<ThixMediaPage> createState()=> _ThixMediaPageState(); }

class _ThixMediaPageState extends ConsumerState<ThixMediaPage> {
  late PageController _bannerController, _feedController;
  int _currentBannerIndex=0;
  Timer? _bannerTimer, _searchDebounce;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final List<String> _filters = ["Accueil","Fil","Tendances","NOVA Originals","Live","Courts","Musique","Gaming","Formation"];
  Set<String> _likedMediaIds = {};
  final Set<String> _viewedMediaIds = {};
  final Set<String> _newlyFollowedIds = {};
  final Map<String,int> _localLikeCounts = {};
  final Map<String,int> _localViewCounts = {};
  bool _immersive=false;
  int _currentFeedIndex=0;
  List<MediaContent> _filItems=[];
  List<Map<String,dynamic>> _filRaw=[];
  final Set<String> _seenIds={};
  final Map<String, Map<String,dynamic>> _profiles={};
  final Map<String,bool> _followMap={};
  bool _filLoading=false;
  bool _filInitialized=false;
  double _pullDistance=0;
  bool _pullTriggering=false;
  static const double _pullThreshold=90;

  @override void initState(){
    super.initState();
    _bannerController=PageController(viewportFraction:1.0);
    _feedController=PageController();
    _scrollController.addListener((){ if(_scrollController.position.pixels>=_scrollController.position.maxScrollExtent-600) ref.read(thixMediaListProvider.notifier).loadMore(); });
    WidgetsBinding.instance.addPostFrameCallback((_){ ref.read(selectedCategoryProvider.notifier).state="Fil"; _initFilFeed(); });
  }
  @override void dispose(){
    _bannerTimer?.cancel(); _searchDebounce?.cancel();
    _bannerController.dispose(); _feedController.dispose();
    _searchController.dispose(); _searchFocusNode.dispose(); _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initFilFeed({bool reshuffle=false}) async {
    if(_filLoading) return;
    setState(()=>_filLoading=true);
    try{
      if(reshuffle){ _seenIds.clear(); _profiles.clear(); _followMap.clear(); _filRaw.clear(); }
      if(_seenIds.length>200){ _seenIds.removeAll(_seenIds.take(_seenIds.length-200).toList()); }
      final page=await MediaService().fetchEnrichedFeed(seenIds:_seenIds.toList(), limit:12);
      if(!mounted) return;
      setState((){
        if(reshuffle){ _filItems=page.items; _filRaw=page.raw; }
        else { final newItems=page.items.where((x)=>!_seenIds.contains(x.id)).toList(); final newRaw=page.raw.where((r)=>!_seenIds.contains(r['id'] as String)).toList(); _filItems=[..._filItems,...newItems]; _filRaw=[..._filRaw,...newRaw]; }
        _seenIds.addAll(_filItems.map((e)=>e.id));
        for(var r in page.raw){ final uid=r['user_id'] as String?; if(uid!=null){ _profiles[uid]={'username': r['username'], 'avatar_url': r['avatar_url']}; _followMap[uid]=(r['is_following'] as bool?)?? false; } }
        _filInitialized=true; if(reshuffle) _currentFeedIndex=0;
      });
      await _syncLiked(_filItems.isNotEmpty? [_filItems.first] : []);
      if(_filItems.isNotEmpty) _registerView(_filItems.first);
      if(reshuffle && _feedController.hasClients) _feedController.jumpToPage(0);
    }catch(_){
      final res=await Supabase.instance.client.from('media_content').select('*').order('created_at', ascending:false).limit(12);
      final items=(res as List).map((e)=>MediaContent.fromJson(e as Map<String,dynamic>)).toList();
      if(mounted) setState((){ _filItems=items; _filInitialized=true; });
    } finally{ if(mounted) setState(()=>_filLoading=false); }
  }

  Future<void> _loadMoreFil() async {
    if(_filLoading) return; setState(()=>_filLoading=true);
    try{
      if(_seenIds.length>200){ _seenIds.removeAll(_seenIds.take(_seenIds.length-200).toList()); }
      final page=await MediaService().fetchEnrichedFeed(seenIds:_seenIds.toList(), limit:12);
      if(!mounted) return;
      final newItems=page.items.where((e)=>!_seenIds.contains(e.id)).toList();
      final newRaw=page.raw.where((r)=>!_seenIds.contains(r['id'] as String)).toList();
      setState((){
        _filItems.addAll(newItems); _filRaw.addAll(newRaw); _seenIds.addAll(newItems.map((e)=>e.id));
        for(var r in page.raw){ final uid=r['user_id'] as String?; if(uid!=null){ _profiles[uid]={'username': r['username'], 'avatar_url': r['avatar_url']}; _followMap[uid]=(r['is_following'] as bool?)?? false; } }
      });
      await _syncLiked(newItems);
    }catch(_){} finally{ if(mounted) setState(()=>_filLoading=false); }
  }

  Future<void> _syncLiked(List<MediaContent> items) async {
    if(items.isEmpty) return; final uid=Supabase.instance.client.auth.currentUser?.id; if(uid==null) return;
    try{ final res=await Supabase.instance.client.rpc('get_liked_media_ids', params:{'p_media_ids': items.map((e)=>e.id).toList()}); if(mounted) setState(()=>_likedMediaIds.addAll((res as List).map((e)=>e as String))); }catch(_){}
  }

  void _startAutoScroll(int count){ _bannerTimer?.cancel(); if(count==0) return; _bannerTimer=Timer.periodic(const Duration(seconds:8), (_){ if(!mounted||!_bannerController.hasClients) return; final next=(_currentBannerIndex+1)%count; _bannerController.animateToPage(next, duration: const Duration(milliseconds:800), curve: Curves.fastOutSlowIn); }); }
  void _onSearchChanged(String v){ _searchDebounce?.cancel(); _searchDebounce=Timer(const Duration(milliseconds:300), ()=>ref.read(searchQueryProvider.notifier).state=v); }
  void _navigateToVideo(MediaContent item)=>Navigator.push(context, MaterialPageRoute(builder:(_)=>VideoPlayerPage(title:item.title, videoUrl:item.videoUrl)));
  String _formatNumber(int n){ if(n>=1000000) return '${(n/1000000).toStringAsFixed(1)}M'; if(n>=1000) return '${(n/1000).toStringAsFixed(1)}k'; return n.toString(); }
  Widget _buildImage(String url,{double? w,double? h,BoxFit fit=BoxFit.cover}){ if(url.isEmpty) return Container(color:kSurface, child:const Icon(Icons.broken_image_rounded,color:kTextGrey)); return Image.network(url, width:w, height:h, fit:fit, cacheWidth:kIsWeb?null:(w!=null?(w*2).toInt():600), loadingBuilder:(c,child,p){ if(p==null) return child; return Container(color:kSurface, child:const Center(child:CircularProgressIndicator(color:kRed,strokeWidth:2))); }, errorBuilder:(c,e,s)=>Container(color:kSurface, child:const Icon(Icons.broken_image_rounded,color:kTextGrey))); }
  void _registerView(MediaContent item){ if(_viewedMediaIds.contains(item.id)) return; _viewedMediaIds.add(item.id); setState(()=>_localViewCounts[item.id]=(_localViewCounts[item.id]??item.viewCount)+1); MediaService().registerView(item.id); }
  Future<void> _toggleLike(MediaContent item) async { final uid=Supabase.instance.client.auth.currentUser?.id; if(uid==null) return; final was=_likedMediaIds.contains(item.id); setState((){ if(was){ _likedMediaIds.remove(item.id); _localLikeCounts[item.id]=(_localLikeCounts[item.id]??item.likeCount)-1; } else { _likedMediaIds.add(item.id); _localLikeCounts[item.id]=(_localLikeCounts[item.id]??item.likeCount)+1; } }); try{ await Supabase.instance.client.rpc('toggle_media_like', params:{'p_media_id': item.id}); }catch(_){ if(mounted) setState((){ if(was){ _likedMediaIds.add(item.id); _localLikeCounts[item.id]=(_localLikeCounts[item.id]??item.likeCount)+1; } else { _likedMediaIds.remove(item.id); _localLikeCounts[item.id]=(_localLikeCounts[item.id]??item.likeCount)-1; } }); } }
  void _openComments(MediaContent item){ showModalBottomSheet(context:context, backgroundColor:Colors.transparent, isScrollControlled:true, builder:(_)=>_CommentsSheet(mediaId:item.id, mediaTitle:item.title)).then((_){ ref.invalidate(commentCountProvider(item.id)); }); }
  void _handlePageChanged(int i){ if(i<0||i>=_filItems.length) return; if(i>=_filItems.length-4) _loadMoreFil(); _registerView(_filItems[i]); }

  @override Widget build(BuildContext context){
    final asyncMedia=ref.watch(thixMediaListProvider); final bannerItems=ref.watch(bannerItemsProvider); final selCat=ref.watch(selectedCategoryProvider);
    ref.listen<List<MediaContent>>(bannerItemsProvider, (p,n){ if(n.isNotEmpty) _startAutoScroll(n.length); });
    return Scaffold(backgroundColor:kBg, body: asyncMedia.when(loading:()=>const Center(child:CircularProgressIndicator(color:kRed)), error:(e,st)=>Center(child:Text('Erreur: $e', style:const TextStyle(color:kTextWhite))), data:(mediaList){
      final cur=_filItems.isNotEmpty? _filItems[_currentFeedIndex.clamp(0,_filItems.length-1)] : null; final showTop=!(_immersive && selCat=='Fil');
      return Stack(children:[
        if(selCat=='Fil') _buildTikTokFeed() else RefreshIndicator(color:kRed, backgroundColor:kSurface, onRefresh:()=>ref.read(thixMediaListProvider.notifier).refresh(), child: CustomScrollView(controller:_scrollController, physics:const BouncingScrollPhysics(parent:AlwaysScrollableScrollPhysics()), slivers:[SliverToBoxAdapter(child: Column(crossAxisAlignment:CrossAxisAlignment.start, children:[const SizedBox(height:100), if(bannerItems.isNotEmpty) _heroBanner(bannerItems), Transform.translate(offset:const Offset(0,-40), child: Container(decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter, colors:[Colors.transparent,kBg.withOpacity(0.6),kBg], stops:const [0.0,0.1,0.3])), child: Column(children:[ _buildRow(title:'Continuer à regarder', subtitle:'Reprise intelligente', provider:recommendationsProvider, aspectRatio:16/9, height:180, width:320, itemBuilder:(it,[i])=>_continueWatchingCard(it)), const SizedBox(height:40), _buildRow(title:'TDIA Originals Exclusifs', subtitle:'Produit par TDIA Studios', provider:newReleasesProvider, aspectRatio:2/3, height:240, width:160, itemBuilder:(it,[i])=>_originalCard(it)), const SizedBox(height:40), _buildRow(title:'Top 10 cette semaine', subtitle:'Classement', provider:trendingProvider, aspectRatio:16/9, height:160, width:300, itemBuilder:(it,[i])=>_top10Card(it,i??0)), const SizedBox(height:120)])))])) ])),
        AnimatedPositioned(duration:const Duration(milliseconds:250), curve:Curves.easeInOutCubic, top:showTop?0:-100, left:0, right:0, child:IgnorePointer(ignoring:!showTop, child:AnimatedOpacity(duration:const Duration(milliseconds:250), opacity:showTop?1:0, child:Column(children:[_header(), _filtersRow(selCat)])))),
        Positioned(bottom:0, left:0, right:0, child:_bottomNav(selCat, cur)),
      ]);
    }));
  }

  Widget _buildTikTokFeed(){
    if(!_filInitialized) return const Center(child:CircularProgressIndicator(color:kRed));
    if(_filItems.isEmpty) return const Center(child:Text("Aucun contenu", style:TextStyle(color:Colors.white)));
    return GestureDetector(
      onVerticalDragUpdate:(d){ if(_currentFeedIndex==0 && d.delta.dy>0 &&!_filLoading) setState(()=>_pullDistance=(_pullDistance+d.delta.dy).clamp(0,_pullThreshold*1.6)); },
      onVerticalDragEnd:(d) async { if(_pullDistance>=_pullThreshold &&!_pullTriggering){ _pullTriggering=true; await _initFilFeed(reshuffle:true); _pullTriggering=false; } setState(()=>_pullDistance=0); },
      child: Stack(children:[
        NotificationListener<ScrollNotification>(
          onNotification:(n){ if(n is ScrollUpdateNotification || n is ScrollStartNotification){ if(!_immersive) setState(()=>_immersive=true); } return false; },
          child: PageView.builder(
            controller:_feedController, scrollDirection:Axis.vertical, itemCount:_filItems.length,
            onPageChanged:(i){ setState((){ _currentFeedIndex=i; _immersive=false; }); _handlePageChanged(i); },
            itemBuilder:(c,idx){
              final item=_filItems[idx]; final isFocused=_currentFeedIndex==idx;
              return Stack(fit:StackFit.expand, children:[
                FeedVideoPlayer(videoUrl:item.videoUrl, coverUrl:item.coverUrl, isPlaying:isFocused, onPlayStateChanged:(p){ if(p) setState(()=>_immersive=false); }),
                Positioned(left:20, bottom:110, right:20, child:IgnorePointer(child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
                  Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:4), decoration:BoxDecoration(color:kTdiaBlue.withOpacity(0.2), borderRadius:BorderRadius.circular(8), border:Border.all(color:kTdiaBlue.withOpacity(0.5))), child:Text(item.type, style:const TextStyle(color:Colors.white,fontSize:10,fontWeight:FontWeight.w700))),
                  const SizedBox(height:10),
                  Text(item.title, style:const TextStyle(color:Colors.white,fontSize:22,fontWeight:FontWeight.w900,height:1.1,shadows:[Shadow(color:Colors.black87,blurRadius:6)])),
                  if(item.subtitle!=null)...[const SizedBox(height:6), Text(item.subtitle!, maxLines:2, overflow:TextOverflow.ellipsis, style:const TextStyle(color:Colors.white,fontSize:13,shadows:[Shadow(color:Colors.black87,blurRadius:6)]))]
                ]))),
              ]);
            }
          )
        ),
        Positioned(top:0, left:0, right:0, height:150, child:GestureDetector(behavior:HitTestBehavior.translucent, onTap:(){ if(_immersive) setState(()=>_immersive=false); }, child:Container(color:Colors.transparent))),
        if(_pullDistance>0||_filLoading) Positioned(top:90, left:0, right:0, child:Center(child:Container(padding:const EdgeInsets.all(10), decoration:const BoxDecoration(color:Colors.black54,shape:BoxShape.circle), child:_filLoading? const SizedBox(width:18,height:18,child:CircularProgressIndicator(color:kRed,strokeWidth:2)) : Icon(Icons.autorenew_rounded,color:Colors.white,size: (18+(_pullDistance/_pullThreshold)*6).clamp(18,26))))),
      ]),
    );
  }

  Widget _header(){
    final isAdmin=ref.watch(isMediaAdminProvider).valueOrNull??false;
    return ClipRRect(child:BackdropFilter(filter:ImageFilter.blur(sigmaX:20,sigmaY:20), child:Container(height:60, padding:const EdgeInsets.only(top:8,left:12,right:12,bottom:8), decoration:BoxDecoration(color:Colors.black.withOpacity(0.7), border:const Border(bottom:BorderSide(color:kBorderLight))), child:Row(children:[
      ShaderMask(shaderCallback:(b)=>const LinearGradient(colors:[kTdiaBlue, Color(0xFF00E5FF)]).createShader(b), child:const Text('TDIA', style:TextStyle(color:Colors.white,fontWeight:FontWeight.w900,fontSize:18))),
      const SizedBox(width:14),
      Expanded(child:Container(height:36, padding:const EdgeInsets.symmetric(horizontal:12), decoration:BoxDecoration(color:const Color(0xFF0D0D10), borderRadius:BorderRadius.circular(20), border:Border.all(color:Colors.white.withOpacity(0.08))), child:Row(children:[const Icon(Icons.search_rounded,color:Colors.white30,size:16), const SizedBox(width:8), Expanded(child:TextField(controller:_searchController, focusNode:_searchFocusNode, onChanged:_onSearchChanged, style:const TextStyle(color:Colors.white,fontSize:13), decoration:const InputDecoration(hintText:"Rechercher...", hintStyle:TextStyle(color:Colors.white30,fontSize:13), border:InputBorder.none, isDense:true, contentPadding:EdgeInsets.zero)))]))),
      const SizedBox(width:12),
      if(isAdmin)...[GestureDetector(onTap:()=>Navigator.push(context, MaterialPageRoute(builder:(_)=>const ThixMediaAdminPage())), child:Container(width:32,height:32, decoration:BoxDecoration(shape:BoxShape.circle,color:kRed.withOpacity(0.15), border:Border.all(color:kRed.withOpacity(0.3))), child:const Icon(Icons.admin_panel_settings_rounded,color:kRed,size:16))), const SizedBox(width:10)],
      Container(width:32,height:32, decoration:const BoxDecoration(shape:BoxShape.circle,color:Colors.white10), child:const Icon(Icons.notifications_none_rounded,color:Colors.white70,size:18)),
    ]))));
  }

  Widget _filtersRow(String sel)=>ClipRRect(child:BackdropFilter(filter:ImageFilter.blur(sigmaX:20,sigmaY:20), child:Container(color:kBg.withOpacity(0.85), padding:const EdgeInsets.symmetric(vertical:10), child:SingleChildScrollView(scrollDirection:Axis.horizontal, padding:const EdgeInsets.symmetric(horizontal:16), child:Row(children:_filters.map((f){ final s=sel==f; return Padding(padding:const EdgeInsets.only(right:8), child:GestureDetector(onTap:(){ ref.read(selectedCategoryProvider.notifier).state=f; if(f!='Fil') setState(()=>_immersive=false); }, child:AnimatedContainer(duration:const Duration(milliseconds:200), padding:const EdgeInsets.symmetric(horizontal:16,vertical:8), decoration:BoxDecoration(color:s?Colors.white:Colors.white.withOpacity(0.06), borderRadius:BorderRadius.circular(20), border:Border.all(color:s?Colors.white:kBorderLight)), child:Text(f, style:TextStyle(color:s?Colors.black:Colors.white60,fontSize:12,fontWeight:s?FontWeight.w700:FontWeight.w500))))); }).toList())))));
  Widget _heroBanner(List<MediaContent> items)=>SizedBox(height:MediaQuery.of(context).size.height*0.82, child:PageView.builder(controller:_bannerController, onPageChanged:(i)=>setState(()=>_currentBannerIndex=i), itemCount:items.length, itemBuilder:(c,idx){ final it=items[idx]; return Stack(fit:StackFit.expand, children:[_buildImage(it.coverUrl), Container(decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.bottomCenter,end:Alignment.topCenter,colors:[kBg,kBg.withOpacity(0.7),Colors.transparent]))), Positioned(bottom:80,left:24,right:24, child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[Text(it.title.toUpperCase(), style:const TextStyle(color:Colors.white,fontSize:38,fontWeight:FontWeight.w900,height:0.9)), const SizedBox(height:12), Text(it.type, style:const TextStyle(color:Colors.white54,fontSize:13)), const SizedBox(height:20), ElevatedButton.icon(onPressed:()=>_navigateToVideo(it), icon:const Icon(Icons.play_arrow_rounded,color:Colors.black), label:const Text('Lecture', style:TextStyle(color:Colors.black,fontWeight:FontWeight.bold)), style:ElevatedButton.styleFrom(backgroundColor:Colors.white, shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(28))))]))]); }));
  Widget _buildRow({required String title,required String subtitle,required ProviderListenable<List<MediaContent>> provider,required double aspectRatio,required double height,required double width,required Widget Function(MediaContent item,[int? index]) itemBuilder}){ final list=ref.watch(provider); if(list.isEmpty) return const SizedBox.shrink(); return Column(crossAxisAlignment:CrossAxisAlignment.start, children:[Padding(padding:const EdgeInsets.symmetric(horizontal:24), child:Row(children:[Text(title, style:const TextStyle(color:Colors.white,fontSize:18,fontWeight:FontWeight.bold)), const SizedBox(width:12), Text(subtitle, style:const TextStyle(color:Colors.white38,fontSize:12))])), const SizedBox(height:16), SizedBox(height:height, child:ListView.builder(padding:const EdgeInsets.symmetric(horizontal:24), scrollDirection:Axis.horizontal, itemCount:list.length, itemBuilder:(c,i)=>Padding(padding:const EdgeInsets.only(right:16), child:SizedBox(width:width, child:itemBuilder(list[i],i)))))]); }
  Widget _continueWatchingCard(MediaContent it)=>GestureDetector(onTap:()=>_navigateToVideo(it), child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[Expanded(child:ClipRRect(borderRadius:BorderRadius.circular(12), child:Stack(fit:StackFit.expand, children:[_buildImage(it.coverUrl), Container(color:Colors.black.withOpacity(0.3)), const Center(child:Icon(Icons.play_circle_fill_rounded,color:Colors.white,size:44))]))), const SizedBox(height:8), Text(it.title, maxLines:1, overflow:TextOverflow.ellipsis, style:const TextStyle(color:Colors.white,fontSize:14,fontWeight:FontWeight.w600))]));
  Widget _originalCard(MediaContent it)=>GestureDetector(onTap:()=>_navigateToVideo(it), child:ClipRRect(borderRadius:BorderRadius.circular(14), child:Stack(fit:StackFit.expand, children:[_buildImage(it.coverUrl), Container(decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.bottomCenter,end:Alignment.topCenter,colors:[Colors.black.withOpacity(0.9),Colors.transparent]))), Positioned(bottom:12,left:12,right:12, child:Text(it.title, maxLines:2, style:const TextStyle(color:Colors.white,fontSize:14,fontWeight:FontWeight.bold)))])));
  Widget _top10Card(MediaContent it,int idx)=>GestureDetector(onTap:()=>_navigateToVideo(it), child:Stack(clipBehavior:Clip.none, children:[Positioned(left:-20,bottom:-10, child:Text((idx+1).toString().padLeft(2,'0'), style:TextStyle(fontSize:90,fontWeight:FontWeight.w900,color:Colors.transparent,shadows:[Shadow(color:Colors.white.withOpacity(0.2),blurRadius:2)]))), Positioned(left:40,top:0,bottom:0,right:0, child:ClipRRect(borderRadius:BorderRadius.circular(12), child:_buildImage(it.coverUrl)))]));

  Widget _bottomNav(String selCat, MediaContent? cur){
    final isFil = selCat == 'Fil';
    final isLiked = cur!= null && _likedMediaIds.contains(cur.id);
    int displayLikes = cur?.likeCount?? 0;
    int displayViews = cur?.viewCount?? 0;
    MediaCounts? live;
    if(isFil && cur!= null){
      live = ref.watch(mediaCountsStreamProvider(cur.id)).valueOrNull;
      displayLikes = _localLikeCounts[cur.id]?? live?.likeCount?? cur.likeCount;
      displayViews = _localViewCounts[cur.id]?? live?.viewCount?? cur.viewCount;
    }
    String creatorId = '';
    String displayName = 'TDIA';
    String? avatar;
    bool showPlus = false;
    if(isFil && _filRaw.isNotEmpty && _currentFeedIndex < _filRaw.length){
      final raw = _filRaw[_currentFeedIndex];
      creatorId = (raw['user_id'] as String?)?? '';
      final prof = _profiles[creatorId];
      if(prof!= null){
        displayName = (prof['username'] as String?)?? 'Utilisateur';
        avatar = prof['avatar_url'] as String?;
      }
      final isFollowing = _followMap[creatorId]?? true;
      showPlus =!isFollowing &&!_newlyFollowedIds.contains(creatorId);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF12121A).withOpacity(0.85),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () {
                    if (creatorId.isNotEmpty) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfilePage(userId: creatorId)));
                    } else {
                      context.go(AppRoutes.login);
                    }
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.bottomCenter,
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white70, width: 1.5),
                              image: avatar != null && avatar.isNotEmpty
                                  ? DecorationImage(image: NetworkImage(avatar), fit: BoxFit.cover)
                                  : null,
                            ),
                            child: avatar == null || avatar.isEmpty
                                ? const Icon(Icons.person, size: 14, color: Colors.white70)
                                : null,
                          ),
                          if (showPlus)
                            Positioned(
                              bottom: -4,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _newlyFollowedIds.add(creatorId));
                                  MediaService().toggleFollow(creatorId);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(color: kRed, shape: BoxShape.circle),
                                  child: const Icon(Icons.add, color: Colors.white, size: 10),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 55,
                        child: Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
                _navItem(
                  isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                  cur != null ? _formatNumber(displayLikes) : "J'aime",
                  false,
                  1,
                  color: isLiked ? kRed : null,
                  onTap: () {
                    if (cur != null) _toggleLike(cur);
                  },
                ),
                _navItem(
                  Icons.chat_bubble_outline_rounded,
                  cur != null ? _formatNumber(live?.commentCount ?? cur.commentCount) : 'Commenter',
                  false,
                  2,
                  onTap: () {
                    if (cur != null) _openComments(cur);
                  },
                ),
                _navItem(
                  Icons.remove_red_eye_rounded,
                  cur != null ? _formatNumber(displayViews) : 'Vu',
                  false,
                  3,
                  onTap: () {},
                ),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePostPage())),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.add_circle_outline_rounded, color: kRed, size: 22),
                      SizedBox(height: 4),
                      Text('Poster', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: kRed)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool sel, int idx, {Color? color, required VoidCallback onTap}) => InkWell(
    onTap: onTap,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color ?? (sel ? Colors.white : Colors.white38), size: 22),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: sel ? FontWeight.bold : FontWeight.w500, color: color ?? (sel ? Colors.white : Colors.white38))),
      ],
    ),
  );
}

class FeedVideoPlayer extends StatefulWidget {
  final String videoUrl, coverUrl;
  final bool isPlaying;
  final Function(bool) onPlayStateChanged;
  const FeedVideoPlayer({super.key, required this.videoUrl, required this.coverUrl, required this.isPlaying, required this.onPlayStateChanged});
  @override
  State<FeedVideoPlayer> createState() => _FeedVideoPlayerState();
}

class _FeedVideoPlayerState extends State<FeedVideoPlayer> {
  late VideoPlayerController _c;
  bool _init = false, _paused = false;
  final ValueNotifier<Duration> _pos = ValueNotifier(Duration.zero);
  Duration _dur = Duration.zero;
  bool _drag = false;

  @override
  void initState() {
    super.initState();
    _c = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    _c.initialize().then((_) {
      if (!mounted) return;
      _c.setLooping(true);
      _c.setVolume(1.0);
      _c.addListener(() {
        if (mounted && !_drag) _pos.value = _c.value.position;
      });
      setState(() {
        _init = true;
        _dur = _c.value.duration;
      });
      if (widget.isPlaying) _c.play();
    });
  }

  @override
  void didUpdateWidget(covariant FeedVideoPlayer o) {
    super.didUpdateWidget(o);
    if (!_init) return;
    if (widget.isPlaying && !o.isPlaying) {
      _paused = false;
      _c.play();
    } else if (!widget.isPlaying && o.isPlaying) {
      _c.pause();
      _c.seekTo(Duration.zero);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    _pos.dispose();
    super.dispose();
  }

  void _seekToPercent(double pct) {
    if (!_init) return;
    final newPos = Duration(milliseconds: (_dur.inMilliseconds * pct).round());
    _c.seekTo(newPos);
    _pos.value = newPos;
  }

  @override
  Widget build(BuildContext context) {
    if (!_init) return Image.network(widget.coverUrl, fit: BoxFit.cover);
    return GestureDetector(
      onTap: () {
        if (_c.value.isPlaying) {
          _c.pause();
          _paused = true;
        } else {
          _c.play();
          _paused = false;
        }
        setState(() {});
        widget.onPlayStateChanged(_paused);
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(fit: BoxFit.cover, child: SizedBox(width: _c.value.size.width, height: _c.value.size.height, child: VideoPlayer(_c))),
          if (_paused) const Center(child: Icon(Icons.play_arrow_rounded, color: Colors.white70, size: 64)),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutCubic,
            left: 0,
            right: 0,
            bottom: 80,
            child: GestureDetector(
              onHorizontalDragStart: (d) {
                _drag = true;
                _c.pause();
              },
              onHorizontalDragUpdate: (d) {
                final width = context.size!.width;
                final pct = (d.localPosition.dx / width).clamp(0.0, 1.0);
                _pos.value = Duration(milliseconds: (_dur.inMilliseconds * pct).round());
              },
              onHorizontalDragEnd: (d) {
                _drag = false;
                _c.seekTo(_pos.value);
                if (!_paused) _c.play();
              },
              onTapDown: (d) {
                final width = context.size!.width;
                final pct = (d.localPosition.dx / width).clamp(0.0, 1.0);
                _seekToPercent(pct);
              },
              child: Container(
                height: 24,
                color: Colors.transparent,
                alignment: Alignment.bottomCenter,
                child: ValueListenableBuilder<Duration>(
                  valueListenable: _pos,
                  builder: (_, pos, __) {
                    final pct = _dur.inMilliseconds == 0 ? 0.0 : pos.inMilliseconds / _dur.inMilliseconds;
                    return Stack(
                      alignment: Alignment.bottomLeft,
                      children: [
                        Container(height: _drag ? 6 : 3, width: double.infinity, color: Colors.white38),
                        Container(height: _drag ? 6 : 3, width: MediaQuery.of(context).size.width * pct, color: kRed),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentsSheet extends ConsumerStatefulWidget {
  final String mediaId, mediaTitle;
  const _CommentsSheet({required this.mediaId, required this.mediaTitle});
  @override
  ConsumerState<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<_CommentsSheet> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  bool _sending = false, _loading = true;
  List<CommentItem> _roots = [];
  final Map<String, List<CommentItem>> _replies = {};
  final Set<String> _expanded = {};
  CommentItem? _replyingTo, _editing;
  final Set<String> _liked = {};

  @override
  void initState() {
    super.initState();
    _fetchRoots();
  }

  Future<void> _fetchRoots() async {
    try {
      final res = await Supabase.instance.client
          .from('media_comments')
          .select('id,user_id,user_name,avatar_url,content,created_at,parent_id,like_count,reply_count')
          .eq('media_id', widget.mediaId)
          .isFilter('parent_id', null)
          .order('created_at', ascending: false)
          .limit(50);
      if (mounted) {
        setState(() {
          _roots = (res as List).map((e) => CommentItem.fromMap(e as Map<String, dynamic>)).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchReplies(String pid) async {
    try {
      final res = await Supabase.instance.client
          .from('media_comments')
          .select('id,user_id,user_name,avatar_url,content,created_at,parent_id,like_count,reply_count')
          .eq('parent_id', pid)
          .order('created_at', ascending: true);
      if (mounted) {
        setState(() {
          _replies[pid] = (res as List).map((e) => CommentItem.fromMap(e as Map<String, dynamic>)).toList();
          _expanded.add(pid);
        });
      }
    } catch (_) {}
  }

  Future<void> _submit() async {
    final t = _controller.text.trim();
    if (t.isEmpty || _sending) return;
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    setState(() => _sending = true);
    try {
      if (_editing != null) {
        await Supabase.instance.client.from('media_comments').update({'content': t}).eq('id', _editing!.id);
        setState(() => _editing = null);
        _fetchRoots();
      } else {
        final p = await Supabase.instance.client.from('profiles').select('username,full_name,avatar_url').eq('id', uid).maybeSingle();
        final name = (p?['username'] as String?)?.isNotEmpty == true ? p!['username'] : (p?['full_name'] as String?) ?? 'Utilisateur';
        final parentId = _replyingTo?.parentId ?? _replyingTo?.id;
        await Supabase.instance.client.from('media_comments').insert({
          'media_id': widget.mediaId,
          'user_id': uid,
          'user_name': name,
          'avatar_url': p?['avatar_url'],
          'content': t,
          'parent_id': parentId,
        });
        if (parentId != null) _fetchReplies(parentId);
        else _fetchRoots();
      }
      _controller.clear();
      _focus.unfocus();
      setState(() => _replyingTo = null);
      ref.invalidate(commentCountProvider(widget.mediaId));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Widget _tile(CommentItem c, {bool reply = false}) {
    final liked = _liked.contains(c.id);
    return Padding(
      padding: EdgeInsets.only(left: reply ? 40 : 0, top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfilePage(userId: c.userId))),
            child: CircleAvatar(
              radius: reply ? 12 : 16,
              backgroundColor: kSurfaceLight,
              backgroundImage: c.avatarUrl != null && c.avatarUrl!.isNotEmpty ? NetworkImage(c.avatarUrl!) : null,
              child: c.avatarUrl == null ? Icon(Icons.person, size: reply ? 14 : 18, color: kTextGrey) : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfilePage(userId: c.userId))),
                      child: Text(c.userName, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 8),
                    Text(c.createdAt.toString().substring(0, 16), style: const TextStyle(color: kTextGrey, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(c.content, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() => _replyingTo = c);
                        _focus.requestFocus();
                      },
                      child: const Text('Répondre', style: TextStyle(color: kTextGrey, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 20),
                    GestureDetector(
                      onTap: () {
                        setState(() => liked ? _liked.remove(c.id) : _liked.add(c.id));
                        Supabase.instance.client.rpc('toggle_comment_like', params: {'p_comment_id': c.id});
                      },
                      child: Row(
                        children: [
                          Icon(liked ? Icons.favorite : Icons.favorite_border, color: liked ? kRed : kTextGrey, size: 14),
                          const SizedBox(width: 4),
                          Text(c.likeCount > 0 ? '${c.likeCount}' : "J'aime", style: TextStyle(color: liked ? kRed : kTextGrey, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
                if (!reply && (c.replyCount > 0 || _replies.containsKey(c.id))) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () {
                      if (_expanded.contains(c.id)) setState(() => _expanded.remove(c.id));
                      else _fetchReplies(c.id);
                    },
                    child: Row(
                      children: [
                        Container(width: 24, height: 1, color: kBorderLight),
                        const SizedBox(width: 8),
                        Text(_expanded.contains(c.id) ? 'Masquer' : 'Voir ${c.replyCount} réponses', style: const TextStyle(color: kTdiaBlue, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
                if (!reply && _expanded.contains(c.id)) ...[
                  ...(_replies[c.id] ?? []).map((r) => _tile(r, reply: true)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets.bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.only(bottom: insets),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(color: kSurface, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 12),
            const Text('Commentaires', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const Divider(color: kBorderLight, height: 1),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: kRed))
                  : _roots.isEmpty
                      ? const Center(child: Text('Aucun commentaire', style: TextStyle(color: kTextGrey)))
                      : ListView.builder(padding: const EdgeInsets.all(16), itemCount: _roots.length, itemBuilder: (c, i) => _tile(_roots[i])),
            ),
            const Divider(color: kBorderLight, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(color: kSurfaceLight, borderRadius: BorderRadius.circular(24)),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focus,
                        minLines: 1,
                        maxLines: 4,
                        onSubmitted: (_) => _submit(),
                        style: const TextStyle(color: Colors.white, fontSize: 13.5),
                        decoration: InputDecoration(
                          hintText: _editing != null ? 'Modifier...' : _replyingTo != null ? 'Répondre à @${_replyingTo!.userName}' : 'Commenter...',
                          hintStyle: const TextStyle(color: kTextGrey),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _submit,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(color: _sending ? kSurfaceLight : kRed, shape: BoxShape.circle),
                      child: _sending
                          ? const Padding(padding: EdgeInsets.all(11), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
