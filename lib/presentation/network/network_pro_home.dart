import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/models/network_story.dart';
import 'package:thix_id/features/network/data/network_service_provider.dart';
import 'package:thix_id/features/network/presentation/providers/feed_provider.dart';
import 'package:thix_id/features/auth/presentation/providers/auth_controller.dart';
import 'widgets/create_post_dialog.dart';
import 'widgets/create_story_dialog.dart';
import 'widgets/post_card.dart';
import 'widgets/story_viewer.dart';

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

class NetworkProHome extends ConsumerStatefulWidget {
  const NetworkProHome({super.key});
  @override
  ConsumerState<NetworkProHome> createState() => _NetworkProHomeState();
}

class _NetworkProHomeState extends ConsumerState<NetworkProHome> with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> _navVisible = ValueNotifier(true);
  String _feedType = 'network'; // FIX: 'network' affiche tout, 'smart' était vide chez toi
  List<NetworkStory> _stories = [];
  bool _loadingStories = true;
  List<dynamic> _suggestions = [];
  bool _isLoadingMore = false;

  @override bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 700 && !_isLoadingMore) {
      final notifier = ref.read(feedProvider.notifier);
      if (!ref.read(feedProvider).isLoading && notifier.hasMore) {
        _isLoadingMore = true;
        notifier.loadMore().whenComplete(() => _isLoadingMore = false);
      }
    }
    final dir = pos.userScrollDirection;
    if (dir == ScrollDirection.reverse && _navVisible.value) _navVisible.value = false;
    else if (dir == ScrollDirection.forward && !_navVisible.value) _navVisible.value = true;
  }

  Future<void> _init() async {
    await ref.read(feedProvider.notifier).loadFeed(feedType: _feedType, force: true);
    await Future.wait([_loadStories(), _loadSuggestions()]);
  }

  Future<void> _loadStories() async {
    try {
      final data = await ref.read(networkServiceProvider).getActiveStories();
      if (mounted) setState(() { _stories = data; _loadingStories = false; });
    } catch (_) { if (mounted) setState(() => _loadingStories = false); }
  }

  Future<void> _loadSuggestions() async {
    try {
      final data = await ref.read(networkServiceProvider).getSuggestedConnections(limit: 5);
      if (mounted) setState(() => _suggestions = data);
    } catch (_) {}
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    await ref.read(feedProvider.notifier).loadFeed(feedType: _feedType, force: true);
    await _loadStories();
  }

  Future<void> _openCreateStory() async {
    final ok = await showDialog<bool>(context: context, builder: (_) => const CreateStoryDialog());
    if (ok == true && mounted) { HapticFeedback.mediumImpact(); await _loadStories(); }
  }

  @override
  void dispose() { _scrollController.dispose(); _navVisible.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final authAsync = ref.watch(authControllerProvider);
    final feedAsync = ref.watch(feedProvider);
    final currentUser = authAsync.value;
    if (currentUser == null) return const Scaffold(backgroundColor: ThixColors.background, body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: ThixColors.background,
      body: Stack(
        children: [
          RefreshIndicator(
            color: ThixColors.primary,
            onRefresh: _onRefresh,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                _buildSliverAppBar(),
                SliverToBoxAdapter(child: _buildStories(currentUser.id)),
                SliverToBoxAdapter(child: _buildFilters()),
                SliverToBoxAdapter(child: _buildCreatePostBar()),
                // FEED FACEBOOK-LIKE
                feedAsync.when(
                  loading: () => SliverToBoxAdapter(child: _buildShimmerFeed()),
                  error: (e, _) => SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(40), child: Center(child: Column(children: [Text('Erreur: $e'), const SizedBox(height:12), ElevatedButton(onPressed: _onRefresh, child: const Text('Réessayer'))])))),
                  data: (posts) {
                    if (posts.isEmpty) return SliverToBoxAdapter(child: _buildEmpty());
                    return SliverList.builder(
                      itemCount: posts.length,
                      itemBuilder: (c, i) {
                        final post = posts[i];
                        return PostCard(
                          key: ValueKey(post.id),
                          post: post,
                          currentProfileId: currentUser.id,
                          onLike: () => ref.read(feedProvider.notifier).toggleLike(post.id),
                          onComment: () => context.push('/network/comments/${post.id}'),
                          onShare: () => _showShareSheet(post),
                          onDelete: () => ref.read(feedProvider.notifier).loadFeed(force: true),
                          onRefresh: () => ref.read(feedProvider.notifier).loadFeed(feedType: _feedType, force: true),
                        );
                      },
                    );
                  },
                ),
                // loader pagination séparé
                SliverToBoxAdapter(
                  child: Consumer(builder: (c, ref, _){
                    final isLoading = ref.watch(feedProvider).isLoading;
                    final hasMore = ref.read(feedProvider.notifier).hasMore;
                    if (isLoading && hasMore) return const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
                    return const SizedBox.shrink();
                  }),
                ),
                if (_suggestions.isNotEmpty) SliverToBoxAdapter(child: _buildSuggestions()),
                const SliverToBoxAdapter(child: SizedBox(height: 110)),
              ],
            ),
          ),
          ValueListenableBuilder<bool>(valueListenable: _navVisible, builder: (context, visible, _) => Positioned(left: 0, right: 0, bottom: 0, child: _buildBottomNav(visible))),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() => SliverAppBar(backgroundColor: ThixColors.white, elevation: 0, scrolledUnderElevation: 1, floating: true, snap: true, toolbarHeight: 50, titleSpacing: 16,
    title: ShaderMask(shaderCallback: (b) => const LinearGradient(colors: [ThixColors.primaryDeep, ThixColors.primary]).createShader(b), child: const Text('THIX PRO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17, letterSpacing: -0.5))),
    actions: [IconButton(icon: const Icon(Icons.search_rounded, size: 21, color: ThixColors.textDark), onPressed: () => context.push('/network/search')), IconButton(icon: const Badge(label: Text('3'), child: Icon(Icons.notifications_none_rounded, size: 21, color: ThixColors.textDark)), onPressed: () => context.push('/network/notifications')), const SizedBox(width: 2), Padding(padding: const EdgeInsets.only(right: 12), child: GestureDetector(onTap: () => context.push('/profile'), child: const CircleAvatar(radius: 14, backgroundColor: ThixColors.softBlue, child: Icon(Icons.person, size: 15))))],
  );

  Widget _buildStories(String currentUserId) {
    if (_loadingStories) return const SizedBox(height: 88, child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))));
    final myStories = _stories.where((s) => s.userId == currentUserId).toList();
    final otherStories = _stories.where((s) => s.userId != currentUserId).toList();
    return Container(color: ThixColors.white, height: 88, padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: ListView.separated(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 14), itemCount: otherStories.length + 1, separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (c, i) {
          if (i == 0) return _MyStoryItem(hasStory: myStories.isNotEmpty, avatarUrl: myStories.isNotEmpty ? myStories.first.userAvatar : null, onView: myStories.isNotEmpty ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => StoryViewer(stories: myStories, initialIndex: 0))) : _openCreateStory, onAdd: _openCreateStory);
          final s = otherStories[i - 1];
          return _StoryItem(story: s, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StoryViewer(stories: otherStories, initialIndex: i - 1))));
        },
      ),
    );
  }

  Widget _buildFilters() {
    final filters = {'network': ('Pour vous', Icons.auto_awesome_rounded), 'popular': ('Tendance', Icons.local_fire_department_rounded), 'recent': ('Réseau', Icons.people_alt_rounded)};
    return Container(color: ThixColors.white, padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: filters.entries.map((e) {
        final sel = _feedType == e.key;
        return Padding(padding: const EdgeInsets.only(right: 8), child: InkWell(borderRadius: BorderRadius.circular(30), onTap: () { if (sel) return; setState(() => _feedType = e.key); ref.read(feedProvider.notifier).loadFeed(feedType: e.key, force: true); HapticFeedback.selectionClick(); },
          child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9), decoration: BoxDecoration(color: sel ? ThixColors.primary : ThixColors.softBlue, borderRadius: BorderRadius.circular(30)), child: Row(children: [Icon(e.value.$2, size: 16, color: sel ? Colors.white : ThixColors.primaryDeep), const SizedBox(width: 6), Text(e.value.$1, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: sel ? Colors.white : ThixColors.textDark))]))));
      }).toList())),
    );
  }

  Widget _buildCreatePostBar() => Container(margin: const EdgeInsets.all(14), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: ThixColors.border), boxShadow: [BoxShadow(color: ThixColors.shadow, blurRadius: 12, offset: const Offset(0, 4))]),
    child: Row(children: [const CircleAvatar(radius: 18, backgroundColor: ThixColors.softBlue, child: Icon(Icons.person, size: 18)), const SizedBox(width: 10), Expanded(child: GestureDetector(onTap: () => showDialog(context: context, builder: (_) => const CreatePostDialog()).then((v) { if (v == true) ref.read(feedProvider.notifier).loadFeed(force: true); }), child: Container(height: 40, padding: const EdgeInsets.symmetric(horizontal: 14), decoration: BoxDecoration(color: ThixColors.background, borderRadius: BorderRadius.circular(30)), alignment: Alignment.centerLeft, child: const Text('Quoi de neuf pro?', style: TextStyle(color: ThixColors.textSecondary, fontSize: 13))))), IconButton(icon: const Icon(Icons.image_rounded, color: ThixColors.primary), onPressed: () {})]),
  );

  Widget _buildSuggestions() => Container(margin: const EdgeInsets.all(14), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: ThixColors.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Personnes à découvrir', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)), const SizedBox(height: 10), ..._suggestions.map((u) => ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: CircleAvatar(backgroundImage: u.avatar != null ? NetworkImage(u.avatar!) : null), title: Text(u.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)), subtitle: Text(u.title ?? '', style: const TextStyle(fontSize: 11)), trailing: FilledButton.tonal(onPressed: () async { await ref.read(networkServiceProvider).sendConnectionRequest(u.id); setState(() => _suggestions.remove(u)); }, child: const Text('Suivre'))))]),
  );

  Widget _buildBottomNav(bool visible) => AnimatedSlide(duration: const Duration(milliseconds: 260), curve: Curves.easeInOutCubic, offset: visible ? Offset.zero : const Offset(0, 1.6), child: AnimatedOpacity(duration: const Duration(milliseconds: 200), opacity: visible ? 1 : 0, child: IgnorePointer(ignoring: !visible, child: SafeArea(top: false, child: Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 10), child: SizedBox(height: 56, child: Stack(clipBehavior: Clip.none, alignment: Alignment.bottomCenter, children: [Container(height: 50, decoration: BoxDecoration(color: ThixColors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: ThixColors.shadow, blurRadius: 14, offset: const Offset(0, 5))]), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_navBtn(Icons.home_rounded, 'Accueil', true, () => _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut)), _navBtn(Icons.explore_outlined, 'Découvrir', false, () => context.push('/network/discover')), const SizedBox(width: 42), _navBtn(Icons.groups_outlined, 'Réseau', false, () => context.push('/network/connections')), _navBtn(Icons.person_outline, 'Profil', false, () => context.push('/profile'))])), Positioned(top: -12, child: _buildFab())]))))));
  Widget _buildFab() => SizedBox(width: 48, height: 48, child: Container(decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [ThixColors.primaryDeep, ThixColors.primary]), boxShadow: [BoxShadow(color: ThixColors.primary.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 5))]), child: FloatingActionButton(elevation: 0, backgroundColor: Colors.transparent, onPressed: () => showDialog(context: context, builder: (_) => const CreatePostDialog()), child: const Icon(Icons.add_rounded, size: 24, color: Colors.white))));
  Widget _navBtn(IconData ic, String label, bool active, VoidCallback tap) => InkWell(onTap: tap, borderRadius: BorderRadius.circular(12), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(ic, size: 19, color: active ? ThixColors.primary : ThixColors.textSecondary), const SizedBox(height: 1), Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: active ? ThixColors.primary : ThixColors.textSecondary))])));

  Widget _buildShimmerFeed() => Column(children: List.generate(3, (i) => Container(margin: const EdgeInsets.all(14), height: 180, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)))));
  Widget _buildEmpty() => Padding(padding: const EdgeInsets.all(60), child: Column(children: [const Icon(Icons.feed_outlined, size: 48, color: ThixColors.textSecondary), const SizedBox(height: 12), const Text('Aucune publication pour ce filtre', style: TextStyle(color: ThixColors.textSecondary)), const SizedBox(height: 16), FilledButton(onPressed: _onRefresh, child: const Text('Actualiser'))]));
  void _showShareSheet(post) => showModalBottomSheet(context: context, builder: (_) => SafeArea(child: Wrap(children: [ListTile(leading: const Icon(Icons.link), title: const Text('Copier lien'), onTap: () => Navigator.pop(context)), ListTile(leading: const Icon(Icons.share), title: const Text('Partager'), onTap: () => Navigator.pop(context))])));
}

class _MyStoryItem extends StatelessWidget {
  final bool hasStory; final String? avatarUrl; final VoidCallback onView; final VoidCallback onAdd;
  const _MyStoryItem({required this.hasStory, required this.avatarUrl, required this.onView, required this.onAdd});
  @override Widget build(BuildContext context) => GestureDetector(onTap: onView, child: Column(children: [Stack(clipBehavior: Clip.none, children: [hasStory ? Container(padding: const EdgeInsets.all(2.5), decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [ThixColors.primary, ThixColors.gold])), child: CircleAvatar(radius: 23, backgroundColor: ThixColors.softBlue, backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty ? NetworkImage(avatarUrl!) : null, child: avatarUrl == null || avatarUrl!.isEmpty ? const Icon(Icons.person, size: 22, color: ThixColors.primaryDeep) : null)) : Container(width: 52, height: 52, decoration: BoxDecoration(shape: BoxShape.circle, color: ThixColors.softBlue, border: Border.all(color: ThixColors.border, width: 1.5)), child: const Icon(Icons.person, size: 24, color: ThixColors.primaryDeep)), Positioned(bottom: -2, right: -2, child: GestureDetector(onTap: onAdd, child: Container(width: 20, height: 20, decoration: BoxDecoration(shape: BoxShape.circle, color: ThixColors.gold, border: Border.all(color: ThixColors.white, width: 2)), child: const Icon(Icons.add_rounded, size: 13, color: Colors.white))))]), const SizedBox(height: 4), Text(hasStory ? 'Votre story' : 'Ajouter', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: ThixColors.textDark))]));
}

class _StoryItem extends StatelessWidget {
  final NetworkStory story; final VoidCallback onTap;
  const _StoryItem({required this.story, required this.onTap});
  @override Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: Column(children: [Container(padding: const EdgeInsets.all(2.5), decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [ThixColors.primary, ThixColors.gold])), child: CircleAvatar(radius: 23, backgroundImage: story.userAvatar != null ? NetworkImage(story.userAvatar!) : null)), const SizedBox(height: 4), SizedBox(width: 56, child: Text(story.userName.split(' ').first, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)))]));
}
