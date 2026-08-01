import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
  while(true){ try{ final r = await Supabase.instance.client.from('media_stats').select('like_count,view_count,comment_count').eq('media_id', mediaId).maybeSingle(); yield MediaCounts(likeCount: (r?['like_count'] as int?)??0, viewCount: (r?['view_count'] as int?)??0, commentCount: (r?['comment_count'] as int?)??0); }catch(_){} await Future.delayed(const Duration(seconds:30)); }
});

class ThixMediaPage extends ConsumerStatefulWidget { const ThixMediaPage({super.key}); @override ConsumerState<ThixMediaPage> createState()=> _ThixMediaPageState(); }

class _ThixMediaPageState extends ConsumerState<ThixMediaPage> {
  late PageController _bannerController, _feedController;
  Timer? _bannerTimer, _searchDebounce;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final List<String> _filters = ["Accueil","Fil","Tendances","NOVA Originals","Live","Courts","Musique","Gaming","Formation"];
  Set<String> _likedMediaIds = {}; final Set<String> _viewedMediaIds = {}; final Set<String> _newlyFollowedIds = {};
  final Map<String,int> _localLikeCounts = {}; final Map<String,int> _localViewCounts = {};
  bool _immersive=false; int _currentFeedIndex=0;
  List<MediaContent> _filItems=[]; List<Map<String,dynamic>> _filRaw=[]; final Set<String> _seenIds={};
  final Map<String, Map<String,dynamic>> _profiles={}; final Map<String,bool> _followMap={};
  bool _filLoading=false; bool _filInitialized=false; double _pullDistance=0; bool _pullTriggering=false; static const double _pullThreshold=90; int _currentBannerIndex=0;

  @override void initState(){ super.initState(); _bannerController=PageController(viewportFraction:1.0); _feedController=PageController(); _scrollController.addListener((){ if(_scrollController.position.pixels>=_scrollController.position.maxScrollExtent-600) ref.read(thixMediaListProvider.notifier).loadMore(); }); WidgetsBinding.instance.addPostFrameCallback((_){ ref.read(selectedCategoryProvider.notifier).state="Fil"; _initFilFeed(); }); }
  @override void dispose(){ _bannerTimer?.cancel(); _searchDebounce?.cancel(); _bannerController.dispose(); _feedController.dispose(); _searchController.dispose(); _searchFocusNode.dispose(); _scrollController.dispose(); super.dispose(); }

  Future<void> _initFilFeed({bool reshuffle=false}) async {
    if(_filLoading) return; setState(()=>_filLoading=true);
    try{
      if(reshuffle){ _seenIds.clear(); _profiles.clear(); _followMap.clear(); _filRaw.clear(); }
      if(_seenIds.length>200){ _seenIds.removeAll(_seenIds.take(_seenIds.length-200).toList()); }
      final page=await MediaService().fetchEnrichedFeed(seenIds:_seenIds.toList(), limit:12);
      if(!mounted) return;
      setState((){
        if(reshuffle){ _filItems=page.items; _filRaw=page.raw; } else { final newItems=page.items.where((x)=>!_seenIds.contains(x.id)).toList(); final newRaw=page.raw.where((r)=>!_seenIds.contains(r['id'] as String)).toList(); _filItems=[..._filItems,...newItems]; _filRaw=[..._filRaw,...newRaw]; }
        _seenIds.addAll(_filItems.map((e)=>e.id));
        for(var r in page.raw){ final uid=r['user_id'] as String?; if(uid!=null){ _profiles[uid]={'username': r['username'], 'avatar_url': r['avatar_url']}; _followMap[uid]=(r['is_following'] as bool?)?? false; } }
        _filInitialized=true; if(reshuffle) _currentFeedIndex=0;
      });
      await _syncLiked(_filItems.isNotEmpty? [_filItems.first] : []);
      if(_filItems.isNotEmpty) _registerView(_filItems.first);
      if(reshuffle && _feedController.hasClients) _feedController.jumpToPage(0);
    }catch(_){ final res=await Supabase.instance.client.from('media_content').select('*').order('created_at', ascending:false).limit(12); final items=(res as List).map((e)=>MediaContent.fromJson(e as Map<String,dynamic>)).toList(); if(mounted) setState((){ _filItems=items; _filInitialized=true; }); }
    finally{ if(mounted) setState(()=>_filLoading=false); }
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

  Future<void> _syncLiked(List<MediaContent> items) async { if(items.isEmpty) return; try{ final res=await Supabase.instance.client.rpc('get_liked_media_ids', params:{'p_media_ids': items.map((e)=>e.id).toList()}); if(mounted) setState(()=>_likedMediaIds.addAll((res as List).map((e)=>e as String))); }catch(_){} }
  void _startAutoScroll(int count){ _bannerTimer?.cancel(); if(count==0) return; _bannerTimer=Timer.periodic(const Duration(seconds:8), (_){ if(!mounted||!_bannerController.hasClients) return; final next=(_currentBannerIndex+1)%count; _bannerController.animateToPage(next, duration: const Duration(milliseconds:800), curve: Curves.fastOutSlowIn); }); }
  void _onSearchChanged(String v){ _searchDebounce?.cancel(); _searchDebounce=Timer(const Duration(milliseconds:300), ()=>ref.read(searchQueryProvider.notifier).state=v); }
  void _navigateToVideo(MediaContent item)=>Navigator.push(context, MaterialPageRoute(builder:(_)=>VideoPlayerPage(title:item.title, videoUrl:item.videoUrl)));
  String _formatNumber(int n){ if(n>=1000000) return '${(n/1000000).toStringAsFixed(1)}M'; if(n>=1000) return '${(n/1000).toStringAsFixed(1)}k'; return n.toString(); }
  Widget _buildImage(String url,{double? w,double? h,BoxFit fit=BoxFit.cover}){ if(url.isEmpty) return Container(color:kSurface, child:const Icon(Icons.broken_image_rounded,color:kTextGrey)); return Image.network(url, width:w, height:h, fit:fit, cacheWidth:kIsWeb?null:(w!=null?(w*2).toInt():600), loadingBuilder:(c,child,p){ if(p==null) return child; return Container(color:kSurface, child:const Center(child:CircularProgressIndicator(color:kRed,strokeWidth:2))); }, errorBuilder:(c,e,s)=>Container(color:kSurface, child:const Icon(Icons.broken_image_rounded,color:kTextGrey))); }
  void _registerView(MediaContent item){ if(_viewedMediaIds.contains(item.id)) return; _viewedMediaIds.add(item.id); setState(()=>_localViewCounts[item.id]=(_localViewCounts[item.id]??item.viewCount)+1); MediaService().registerView(item.id); }
  Future<void> _toggleLike(MediaContent item) async { final was=_likedMediaIds.contains(item.id); setState((){ if(was){ _likedMediaIds.remove(item.id); _localLikeCounts[item.id]=(_localLikeCounts[item.id]??item.likeCount)-1; } else { _likedMediaIds.add(item.id); _localLikeCounts[item.id]=(_localLikeCounts[item.id]??item.likeCount)+1; } }); try{ await Supabase.instance.client.rpc('toggle_media_like', params:{'p_media_id': item.id}); }catch(_){ if(mounted) setState((){ if(was){ _likedMediaIds.add(item.id); _localLikeCounts[item.id]=(_localLikeCounts[item.id]??item.likeCount)+1; } else { _likedMediaIds.remove(item.id); _localLikeCounts[item.id]=(_localLikeCounts[item.id]??item.likeCount)-1; } }); } }
  void _openComments(MediaContent item){ showModalBottomSheet(context:context, backgroundColor:Colors.transparent, isScrollControlled:true, builder:(_)=>_CommentsSheet(mediaId:item.id, mediaTitle:item.title)).then((_){ ref.invalidate(commentCountProvider(item.id)); }); }
  void _handlePageChanged(int i){ if(i<0||i>=_filItems.length) return; if(i>=_filItems.length-4) _loadMoreFil(); _registerView(_filItems[i]); }

  @override Widget build(BuildContext context){
    final asyncMedia=ref.watch(thixMediaListProvider); final bannerItems=ref.watch(bannerItemsProvider); final selCat=ref.watch(selectedCategoryProvider);
    ref.listen<List<MediaContent>>(bannerItemsProvider, (p,n){ if(n.isNotEmpty) _startAutoScroll(n.length); });
    return Scaffold(backgroundColor:kBg, body: asyncMedia.when(loading:()=>const Center(child:CircularProgressIndicator(color:kRed)), error:(e,st)=>Center(child:Text('Erreur: $e', style:const TextStyle(color:kTextWhite))), data:(mediaList){
      final cur=_filItems.isNotEmpty? _filItems[_currentFeedIndex.clamp(0,_filItems.length-1)] : null; final showTop=!(_immersive && selCat=='Fil');
      return Stack(children:[
        if(selCat=='Fil') _buildTikTokFeed() else RefreshIndicator(color:kRed, backgroundColor:kSurface, onRefresh:()=>ref.read(thixMediaListProvider.notifier).refresh(), child: CustomScrollView(controller:_scrollController, physics:const BouncingScrollPhysics(parent:AlwaysScrollableScrollPhysics()), slivers:[SliverToBoxAdapter(child: Column(crossAxisAlignment:CrossAxisAlignment.start, children:[const SizedBox(height:100), if(bannerItems.isNotEmpty) _heroBanner(bannerItems), const SizedBox(height:120)])) ])),
        AnimatedPositioned(duration:const Duration(milliseconds:250), top:showTop?0:-100, left:0, right:0, child:IgnorePointer(ignoring:!showTop, child:AnimatedOpacity(duration:const Duration(milliseconds:250), opacity:showTop?1:0, child:Column(children:[_header(), _filtersRow(selCat)])))),
        Positioned(bottom:0, left:0, right:0, child:_bottomNav(selCat, cur)),
      ]);
    }));
  }

  Widget _buildTikTokFeed(){
    if(!_filInitialized) return const Center(child:CircularProgressIndicator(color:kRed));
    if(_filItems.isEmpty) return const Center(child:Text("Aucun contenu", style:TextStyle(color:Colors.white)));
    return Stack(children:[
      PageView.builder(controller:_feedController, scrollDirection:Axis.vertical, itemCount:_filItems.length, onPageChanged:(i){ setState((){ _currentFeedIndex=i; _immersive=false; }); _handlePageChanged(i); }, itemBuilder:(c,idx){
        final item=_filItems[idx]; final isFocused=_currentFeedIndex==idx;
        return Stack(fit:StackFit.expand, children:[
          FeedVideoPlayer(videoUrl:item.videoUrl, coverUrl:item.coverUrl, isPlaying:isFocused, onPlayStateChanged:(p){ if(p) setState(()=>_immersive=false); }),
          Positioned(left:20, bottom:110, right:20, child:Text(item.title, style:const TextStyle(color:Colors.white,fontSize:22,fontWeight:FontWeight.w900))),
        ]);
      }),
    ]);
  }

  Widget _header(){ final isAdmin=ref.watch(isMediaAdminProvider).valueOrNull??false; return ClipRRect(child:BackdropFilter(filter:ImageFilter.blur(sigmaX:20,sigmaY:20), child:Container(height:60, padding:const EdgeInsets.all(12), decoration:BoxDecoration(color:Colors.black.withOpacity(0.7), border:const Border(bottom:BorderSide(color:kBorderLight))), child:Row(children:[ const Text('TDIA', style:TextStyle(color:Colors.white,fontWeight:FontWeight.w900)), const Spacer(), if(isAdmin) GestureDetector(onTap:()=>Navigator.push(context, MaterialPageRoute(builder:(_)=>const ThixMediaAdminPage())), child:Container(width:32,height:32, decoration:BoxDecoration(shape:BoxShape.circle,color:kRed.withOpacity(0.15)), child:const Icon(Icons.admin_panel_settings_rounded,color:kRed,size:16))), ])))); }
  Widget _filtersRow(String sel)=>Container(color:kBg.withOpacity(0.85), padding:const EdgeInsets.symmetric(vertical:10), child:SingleChildScrollView(scrollDirection:Axis.horizontal, padding:const EdgeInsets.symmetric(horizontal:16), child:Row(children:_filters.map((f){ final s=sel==f; return Padding(padding:const EdgeInsets.only(right:8), child:GestureDetector(onTap:(){ ref.read(selectedCategoryProvider.notifier).state=f; }, child:Container(padding:const EdgeInsets.symmetric(horizontal:16,vertical:8), decoration:BoxDecoration(color:s?Colors.white:Colors.white.withOpacity(0.06), borderRadius:BorderRadius.circular(20)), child:Text(f, style:TextStyle(color:s?Colors.black:Colors.white60,fontSize:12))))); }).toList())));
  Widget _heroBanner(List<MediaContent> items)=>SizedBox(height:300, child:PageView.builder(controller:_bannerController, itemCount:items.length, itemBuilder:(c,i)=>_buildImage(items[i].coverUrl)));
  Widget _buildRow({required String title,required String subtitle,required ProviderListenable<List<MediaContent>> provider,required double aspectRatio,required double height,required double width,required Widget Function(MediaContent item,[int? index]) itemBuilder}){ final list=ref.watch(provider); return SizedBox(height:height, child:ListView.builder(scrollDirection:Axis.horizontal, itemCount:list.length, itemBuilder:(c,i)=>SizedBox(width:width, child:itemBuilder(list[i])))); }
  Widget _continueWatchingCard(MediaContent it)=>_buildImage(it.coverUrl);
  Widget _originalCard(MediaContent it)=>_buildImage(it.coverUrl);
  Widget _top10Card(MediaContent it,int idx)=>_buildImage(it.coverUrl);

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
      padding:const EdgeInsets.fromLTRB(24,0,24,20),
      child:ClipRRect(
        borderRadius:BorderRadius.circular(26),
        child:BackdropFilter(
          filter:ImageFilter.blur(sigmaX:30,sigmaY:30),
          child:Container(
            height:60,
            decoration:BoxDecoration(color:const Color(0xFF12121A).withOpacity(0.85), borderRadius:BorderRadius.circular(26)),
            child:Row(
              mainAxisAlignment:MainAxisAlignment.spaceEvenly,
              children:[
                GestureDetector(onTap:(){ if(creatorId.isNotEmpty) Navigator.push(context, MaterialPageRoute(builder:(_)=>UserProfilePage(userId:creatorId))); }, child:Text(displayName, style:const TextStyle(color:Colors.white70,fontSize:10))),
                _navItem(isLiked? Icons.favorite:Icons.favorite_border, _formatNumber(displayLikes), false, 1, color:isLiked?kRed:null, onTap:(){ if(cur!=null) _toggleLike(cur); }),
                _navItem(Icons.chat_bubble_outline, _formatNumber(live?.commentCount??cur?.commentCount??0), false, 2, onTap:(){ if(cur!=null) _openComments(cur); }),
                _navItem(Icons.remove_red_eye, _formatNumber(displayViews), false, 3, onTap:(){}),
                GestureDetector(onTap:()=>Navigator.push(context, MaterialPageRoute(builder:(_)=>const CreatePostPage())), child:const Icon(Icons.add_circle_outline,color:kRed)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool sel, int idx, {Color? color, required VoidCallback onTap})=>InkWell(onTap:onTap, child:Column(mainAxisSize:MainAxisSize.min, children:[Icon(icon,color:color??Colors.white38,size:22), const SizedBox(height:4), Text(label, style:const TextStyle(fontSize:10,color:Colors.white38))]));
} // <-- FIN de _ThixMediaPageState

class FeedVideoPlayer extends StatefulWidget { final String videoUrl, coverUrl; final bool isPlaying; final Function(bool) onPlayStateChanged; const FeedVideoPlayer({super.key, required this.videoUrl, required this.coverUrl, required this.isPlaying, required this.onPlayStateChanged}); @override State<FeedVideoPlayer> createState()=> _FeedVideoPlayerState(); }
class _FeedVideoPlayerState extends State<FeedVideoPlayer> {
  late VideoPlayerController _c; bool _init=false;
  @override void initState(){ super.initState(); _c=VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl)); _c.initialize().then((_){ if(!mounted) return; _c.setLooping(true); setState(()=>_init=true); if(widget.isPlaying) _c.play(); }); }
  @override void didUpdateWidget(covariant FeedVideoPlayer o){ super.didUpdateWidget(o); if(!_init) return; if(widget.isPlaying) _c.play(); else _c.pause(); }
  @override void dispose(){ _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context){ if(!_init) return Image.network(widget.coverUrl, fit:BoxFit.cover); return VideoPlayer(_c); }
}

class _CommentsSheet extends ConsumerStatefulWidget { final String mediaId, mediaTitle; const _CommentsSheet({required this.mediaId, required this.mediaTitle}); @override ConsumerState<_CommentsSheet> createState()=> _CommentsSheetState(); }
class _CommentsSheetState extends ConsumerState<_CommentsSheet> {
  final _controller=TextEditingController(); List<CommentItem> _roots=[]; bool _loading=true;
  @override void initState(){ super.initState(); _fetch(); }
  Future<void> _fetch() async { try{ final res=await Supabase.instance.client.from('media_comments').select().eq('media_id',widget.mediaId).order('created_at',ascending:false).limit(50); if(mounted) setState((){ _roots=(res as List).map((e)=>CommentItem.fromMap(e as Map<String,dynamic>)).toList(); _loading=false; }); }catch(_){ if(mounted) setState(()=>_loading=false); } }
  @override Widget build(BuildContext context){ return Container(height:400, color:kSurface, child: _loading? const Center(child:CircularProgressIndicator(color:kRed)) : ListView.builder(itemCount:_roots.length, itemBuilder:(c,i)=>ListTile(title:Text(_roots[i].content, style:const TextStyle(color:Colors.white))))); }
}
