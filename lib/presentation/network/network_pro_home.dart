import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/feed_provider.dart';
import '../services/network_service.dart';
import 'widgets/post_card.dart';

class NetworkProHome extends StatefulWidget { const NetworkProHome({super.key}); @override State<NetworkProHome> createState() => _NetworkProHomeState(); }

class _NetworkProHomeState extends State<NetworkProHome> {
  final _scrollController = ScrollController();
  String _feedType = 'smart';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 400) {
        context.read<FeedProvider>().loadMore();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FeedProvider>().loadFeed(feedType: _feedType);
      context.read<FeedProvider>().initRealtime();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FF),
      appBar: AppBar(title: const Text('THIX PRO', style: TextStyle(fontWeight: FontWeight.w900)), actions: [
        IconButton(icon: const Icon(Icons.search), onPressed: () {}),
      ]),
      body: Consumer<FeedProvider>(builder: (context, feed, _) {
        if (feed.isLoading && feed.posts.isEmpty) return const Center(child: CircularProgressIndicator());
        return RefreshIndicator(
          onRefresh: () => feed.loadFeed(feedType: _feedType, force: true),
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(child: _FilterChips(selected: _feedType, onSelect: (v){ setState(()=>_feedType=v); feed.loadFeed(feedType: v, force:true); })),
              if (feed.posts.isEmpty) const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(40), child: Center(child: Text('Aucun post'))))
              else SliverList.builder(itemCount: feed.posts.length, itemBuilder: (c,i) => PostCard(post: feed.posts[i], onLike: ()=>feed.toggleLike(feed.posts[i].id))),
              if (feed.isLoadingMore) const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(onPressed: (){}, child: const Icon(Icons.add)),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final String selected; final Function(String) onSelect;
  const _FilterChips({required this.selected, required this.onSelect});
  @override Widget build(BuildContext context) {
    final filters = {'smart':'Pour vous','network':'Réseau','popular':'Tendance'};
    return SizedBox(height: 50, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.all(8), children: filters.entries.map((e){
      final sel = selected==e.key;
      return Padding(padding: const EdgeInsets.only(right:8), child: ChoiceChip(label: Text(e.value), selected: sel, onSelected: (_)=>onSelect(e.key)));
    }).toList()));
  }
}
