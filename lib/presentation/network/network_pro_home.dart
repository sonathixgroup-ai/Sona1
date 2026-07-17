import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/models/network_post.dart';
import 'package:thix_id/models/network_story.dart';
import 'package:thix_id/providers/feed_provider.dart';
import 'package:thix_id/services/network_service.dart';
import 'widgets/create_post_dialog.dart';
import 'widgets/create_story_dialog.dart';
import 'widgets/post_card.dart';
import 'widgets/story_viewer.dart';

// ─── COULEURS THIX ───
class ThixColors {
  static const background = Color(0xFFF6F9FF);
  static const white = Color(0xFFFFFFFF);
  static const primary = Color(0xFF2D6CDF);
  static const primaryDeep = Color(0xFF123B7A);
  static const softBlue = Color(0xFFEAF1FF);
  static const gold = Color(0xFFD9A63C);
  static const textDark = Color(0xFF10192E);
  static const textSecondary = Color(0xFF7386A8);
  static const border = Color(0xFFE7EEFC);
  static const shadow = Color(0x142D6CDF);
}

class NetworkProHome extends StatefulWidget {
  const NetworkProHome({super.key});
  @override State<NetworkProHome> createState() => _NetworkProHomeState();
}

class _NetworkProHomeState extends State<NetworkProHome> with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  String _feedType = 'smart';
  List<NetworkStory> _stories = [];
  bool _loadingStories = true;
  List<dynamic> _suggestions = [];

  @override bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 600) {
      context.read<FeedProvider>().loadMore();
    }
  }

  Future<void> _init() async {
    final service = context.read<NetworkService>();
    final feed = context.read<FeedProvider>();
    await Future.wait([
      feed.loadFeed(feedType: _feedType, force: true),
      _loadStories(service),
      _loadSuggestions(service),
    ]);
    feed.initRealtime();
  }

  Future<void> _loadStories(NetworkService s) async {
    try { final data = await s.getActiveStories(); if(mounted) setState((){ _stories = data; _loadingStories = false; }); }
    catch(_){ if(mounted) setState(()=> _loadingStories = false); }
  }
  Future<void> _loadSuggestions(NetworkService s) async {
    try { final data = await s.getSuggestedConnections(limit: 5); if(mounted) setState(()=> _suggestions = data); } catch(_){}
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    await context.read<FeedProvider>().loadFeed(feedType: _feedType, force: true);
    if(mounted) await _loadStories(context.read<NetworkService>());
  }

  @override void dispose(){ _scrollController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final auth = context.watch<AuthController>();
    if (auth.currentUser == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: ThixColors.background,
      appBar: _buildAppBar(context),
      body: Consumer<FeedProvider>(
        builder: (context, feed, _) {
          return RefreshIndicator(
            color: ThixColors.primary,
            onRefresh: _onRefresh,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                SliverToBoxAdapter(child: _buildStories()),
                SliverToBoxAdapter(child: _buildFilters(feed)),
                SliverToBoxAdapter(child: _buildCreatePostBar()),

                if (feed.isLoading && feed.posts.isEmpty)
                  SliverToBoxAdapter(child: _buildShimmerFeed())
                else if (feed.posts.isEmpty)
                  SliverToBoxAdapter(child: _buildEmpty())
                else
                  SliverList.builder(
                    itemCount: feed.posts.length,
                    itemBuilder: (c, i) {
                      final post = feed.posts[i];
                      return PostCard(
                        key: ValueKey(post.id),
                        post: post,
                        currentProfileId: auth.currentUser!.id,
                        onLike: () => feed.toggleLike(post.id),
                        onComment: () => context.push('/network/comments/${post.id}'),
                        onShare: () => _showShareSheet(post),
                        onDelete: () => feed.loadFeed(force: true),
                      );
                    },
                  ),

                if (feed.isLoadingMore)
                  const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator(strokeWidth: 2)))),

                if (_suggestions.isNotEmpty)
                  SliverToBoxAdapter(child: _buildSuggestions()),

                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: _buildFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ─── APP BAR ───
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: ThixColors.white, elevation: 0, scrolledUnderElevation: 1,
      title: ShaderMask(
        shaderCallback: (b) => const LinearGradient(colors: [ThixColors.primaryDeep, ThixColors.primary]).createShader(b),
        child: const Text('THIX PRO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 19, letterSpacing: -0.5)),
      ),
      actions: [
        IconButton(icon: const Icon(Icons.search_rounded, color: ThixColors.textDark), onPressed: ()=> context.push('/network/search')),
        IconButton(icon: const Badge(label: Text('3'), child: Icon(Icons.notifications_none_rounded, color: ThixColors.textDark)), onPressed: ()=> context.push('/network/notifications')),
        const SizedBox(width: 8),
        Padding(padding: const EdgeInsets.only(right: 12), child: GestureDetector(onTap: ()=> context.push('/profile'), child: const CircleAvatar(radius: 16, backgroundColor: ThixColors.softBlue, child: Icon(Icons.person, size: 18)))),
      ],
    );
  }

  // ─── STORIES ───
  Widget _buildStories() {
    if (_loadingStories) return const SizedBox(height: 76, child: Center(child: SizedBox(width:20,height:20, child: CircularProgressIndicator(strokeWidth:2))));
    return Container(
      color: ThixColors.white,
      height: 88,
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: _stories.length + 1,
        separatorBuilder: (_,__)=> const SizedBox(width: 12),
        itemBuilder: (c,i){
          if(i==0) return _AddStoryBtn(onTap: () async { final ok = await showDialog<bool>(context: context, builder: (_)=> const CreateStoryDialog()); if(ok==true) _loadStories(context.read<NetworkService>()); });
          final s = _stories[i-1];
          return _StoryItem(story: s, onTap: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> StoryViewer(stories: _stories, initialIndex: i-1))));
        },
      ),
    );
  }

  // ─── FILTERS ───
  Widget _buildFilters(FeedProvider feed) {
    final filters = {'smart':('Pour vous', Icons.auto_awesome_rounded),'network':('Réseau', Icons.people_alt_rounded),'popular':('Tendance', Icons.local_fire_department_rounded)};
    return Container(
      color: ThixColors.white,
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: filters.entries.map((e){
        final sel = _feedType == e.key;
        return Padding(padding: const EdgeInsets.only(right: 8), child: InkWell(borderRadius: BorderRadius.circular(30), onTap: (){ if(sel) return; setState(()=>_feedType=e.key); feed.loadFeed(feedType: e.key, force:true); HapticFeedback.selectionClick(); },
          child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(color: sel? ThixColors.primary : ThixColors.softBlue, borderRadius: BorderRadius.circular(30), boxShadow: sel? [BoxShadow(color: ThixColors.primary.withValues(alpha:0.3), blurRadius: 8, offset: const Offset(0,3))] : null),
            child: Row(children: [Icon(e.value.$2, size: 16, color: sel? Colors.white: ThixColors.primaryDeep), const SizedBox(width:6), Text(e.value.$1, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: sel? Colors.white: ThixColors.textDark))]),
          ),
        ));
      }).toList())),
    );
  }

  // ─── CREATE POST BAR ───
  Widget _buildCreatePostBar() {
    return Container(margin: const EdgeInsets.all(14), padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: ThixColors.border), boxShadow: [BoxShadow(color: ThixColors.shadow, blurRadius: 12, offset: const Offset(0,4))]),
      child: Row(children: [
        const CircleAvatar(radius: 18, backgroundColor: ThixColors.softBlue, child: Icon(Icons.person, size: 18)),
        const SizedBox(width: 10),
        Expanded(child: GestureDetector(onTap: ()=> showDialog(context: context, builder: (_)=> const CreatePostDialog()).then((v){ if(v==true) context.read<FeedProvider>().loadFeed(force:true); }),
          child: Container(height: 40, padding: const EdgeInsets.symmetric(horizontal: 14), decoration: BoxDecoration(color: ThixColors.background, borderRadius: BorderRadius.circular(30)), alignment: Alignment.centerLeft, child: const Text('Quoi de neuf pro?', style: TextStyle(color: ThixColors.textSecondary, fontSize: 13))))),
        IconButton(icon: const Icon(Icons.image_rounded, color: ThixColors.primary), onPressed: (){}),
      ]),
    );
  }

  // ─── SUGGESTIONS ───
  Widget _buildSuggestions() {
    return Container(margin: const EdgeInsets.all(14), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: ThixColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Personnes à découvrir', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        const SizedBox(height: 10),
       ..._suggestions.map((u) => ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: CircleAvatar(backgroundImage: u.avatar!=null? NetworkImage(u.avatar!) : null), title: Text(u.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)), subtitle: Text(u.title?? '', style: const TextStyle(fontSize: 11)), trailing: FilledButton.tonal(onPressed: () async { await context.read<NetworkService>().sendConnectionRequest(u.id); setState(()=> _suggestions.remove(u)); }, child: const Text('Suivre')))),
      ]),
    );
  }

  Widget _buildFab() => Container(decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [ThixColors.primaryDeep, ThixColors.primary]), boxShadow: [BoxShadow(color: ThixColors.primary.withValues(alpha:0.4), blurRadius: 12, offset: const Offset(0,6))]),
    child: FloatingActionButton(elevation: 0, backgroundColor: Colors.transparent, onPressed: ()=> showDialog(context: context, builder: (_)=> const CreatePostDialog()), child: const Icon(Icons.add_rounded, size: 28, color: Colors.white)));

  Widget _buildBottomNav() => BottomAppBar(height: 64, shape: const CircularNotchedRectangle(), notchMargin: 8, child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
    _NavBtn(Icons.home_rounded, 'Accueil', true, () => _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut)),
    _NavBtn(Icons.explore_outlined, 'Découvrir', false, ()=> context.push('/network/discover')),
    const SizedBox(width: 40),
    _NavBtn(Icons.groups_outlined, 'Réseau', false, ()=> context.push('/network/connections')),
    _NavBtn(Icons.person_outline, 'Profil', false, ()=> context.push('/profile')),
  ]));

  Widget _NavBtn(IconData ic, String label, bool active, VoidCallback tap) => InkWell(onTap: tap, borderRadius: BorderRadius.circular(12), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(ic, size: 22, color: active? ThixColors.primary: ThixColors.textSecondary), Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: active? ThixColors.primary: ThixColors.textSecondary))])));

  Widget _buildShimmerFeed() => Column(children: List.generate(3, (i)=> Container(margin: const EdgeInsets.all(14), height: 180, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)))));
  Widget _buildEmpty() => const Padding(padding: EdgeInsets.all(60), child: Column(children: [Icon(Icons.feed_outlined, size: 48, color: ThixColors.textSecondary), SizedBox(height: 12), Text('Aucune publication pour ce filtre', style: TextStyle(color: ThixColors.textSecondary))]));
  void _showShareSheet(post) => showModalBottomSheet(context: context, builder: (_)=> SafeArea(child: Wrap(children: [ListTile(leading: const Icon(Icons.link), title: const Text('Copier lien'), onTap: ()=> Navigator.pop(context)), ListTile(leading: const Icon(Icons.share), title: const Text('Partager'), onTap: ()=> Navigator.pop(context))])));
}

// ─── SOUS-WIDGETS STORIES ───
class _AddStoryBtn extends StatelessWidget { final VoidCallback onTap; const _AddStoryBtn({required this.onTap}); @override Widget build(BuildContext context){ return GestureDetector(onTap: onTap, child: Column(children: [Container(width: 52, height: 52, decoration: BoxDecoration(shape: BoxShape.circle, color: ThixColors.softBlue, border: Border.all(color: ThixColors.gold, width: 1.5)), child: const Icon(Icons.add, color: ThixColors.gold)), const SizedBox(height: 4), const Text('Ajouter', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))])) ;}}
class _StoryItem extends StatelessWidget { final NetworkStory story; final VoidCallback onTap; const _StoryItem({required this.story, required this.onTap}); @override Widget build(BuildContext context){ return GestureDetector(onTap: onTap, child: Column(children: [Container(padding: const EdgeInsets.all(2.5), decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [ThixColors.primary, ThixColors.gold])), child: CircleAvatar(radius: 23, backgroundImage: story.userAvatar!=null? NetworkImage(story.userAvatar!) : null)), const SizedBox(height: 4), SizedBox(width: 56, child: Text(story.userName.split(' ').first, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)))])); }}
