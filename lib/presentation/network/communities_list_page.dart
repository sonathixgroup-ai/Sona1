import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/models/network_community.dart';
import 'package:thix_id/features/network/data/network_service_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'communities_list_page.g.dart';

@riverpod
Future<List<NetworkCommunity>> myCommunities(MyCommunitiesRef ref) async {
  return ref.read(networkServiceProvider).getMyCommunities();
}

@riverpod
Future<List<NetworkCommunity>> suggestedCommunities(SuggestedCommunitiesRef ref) async {
  return ref.read(networkServiceProvider).getSuggestedCommunities();
}

@riverpod
class AllCommunities extends _$AllCommunities {
  static const int limit = 20;
  int offset = 0;
  bool hasMoreFlag = true;
  bool get hasMore => hasMoreFlag;

  @override
  Future<List<NetworkCommunity>> build() async {
    offset = 0;
    hasMoreFlag = true;
    final list = await ref.read(networkServiceProvider).getAllCommunities(limit: limit);
    offset = list.length;
    hasMoreFlag = list.length >= limit;
    return list;
  }

  Future<void> loadMore() async {
    if (!hasMoreFlag) return;
    final current = state.valueOrNull ?? [];
    final more = await ref.read(networkServiceProvider).getAllCommunities(limit: limit);
    if (more.isEmpty) {
      hasMoreFlag = false;
      return;
    }
    final ids = current.map((e) => e.id).toSet();
    final filtered = more.where((e) => !ids.contains(e.id)).toList();
    offset += filtered.length;
    state = AsyncData([...current, ...filtered]);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

class CommunitiesListPage extends ConsumerStatefulWidget {
  const CommunitiesListPage({super.key});
  @override
  ConsumerState<CommunitiesListPage> createState() => _CommunitiesListPageState();
}

class _CommunitiesListPageState extends ConsumerState<CommunitiesListPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final ScrollController _allScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _allScroll.addListener(() {
      if (_allScroll.position.pixels >= _allScroll.position.maxScrollExtent - 300) {
        ref.read(allCommunitiesProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _allScroll.dispose();
    super.dispose();
  }

  List<NetworkCommunity> _filter(List<NetworkCommunity> list) {
    if (_searchQuery.isEmpty) return list;
    final q = _searchQuery.toLowerCase();
    return list.where((c) {
      return c.name.toLowerCase().contains(q) || (c.description?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final myAsync = ref.watch(myCommunitiesProvider);
    final suggAsync = ref.watch(suggestedCommunitiesProvider);
    final allAsync = ref.watch(allCommunitiesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text('Communautés', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1A1A2E))),
        actions: [
          IconButton(icon: const Icon(Icons.search, color: Color(0xFF1A1A2E)), onPressed: _showSearchDialog),
          IconButton(icon: const Icon(Icons.add, color: Color(0xFF1A1A2E)), onPressed: () => context.push('/network/community/create')),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFD4AF37),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFD4AF37),
          tabs: const [Tab(text: 'Mes communautés'), Tab(text: 'Suggestions'), Tab(text: 'Toutes')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          myAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _buildErrorState(e.toString()),
            data: (list) => _buildCommunityList(_filter(list), 'Aucune communauté', onRefresh: () => ref.invalidate(myCommunitiesProvider)),
          ),
          suggAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _buildErrorState(e.toString()),
            data: (list) => _buildCommunityList(_filter(list), 'Aucune suggestion', onRefresh: () => ref.invalidate(suggestedCommunitiesProvider)),
          ),
          allAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _buildErrorState(e.toString()),
            data: (list) => _buildCommunityList(_filter(list), 'Aucune communauté', controller: _allScroll, onRefresh: () => ref.read(allCommunitiesProvider.notifier).refresh()),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 56, color: Colors.red),
          const SizedBox(height: 16),
          Text(error, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: () => ref.invalidate(allCommunitiesProvider), child: const Text('Réessayer')),
        ],
      ),
    );
  }

  Widget _buildCommunityList(List<NetworkCommunity> communities, String emptyMessage, {ScrollController? controller, Future<void> Function()? onRefresh}) {
    if (communities.isEmpty) {
      return Center(child: Text(emptyMessage));
    }
    return RefreshIndicator(
      onRefresh: () async {
        if (onRefresh != null) await onRefresh();
      },
      child: ListView.builder(
        controller: controller,
        padding: const EdgeInsets.all(16),
        itemCount: communities.length,
        itemBuilder: (context, index) => _buildCommunityCard(communities[index]),
      ),
    );
  }

  Widget _buildCommunityCard(NetworkCommunity community) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: community.logoUrl != null && community.logoUrl!.isNotEmpty
            ? CachedNetworkImage(imageUrl: community.logoUrl!, width: 50, height: 50, fit: BoxFit.cover)
            : Container(width: 50, height: 50, color: Colors.grey.shade200, child: const Icon(Icons.groups)),
        title: Text(community.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${community.membersCount ?? 0} membres'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/network/community/${community.id}'),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechercher'),
        content: TextField(
          autofocus: true,
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: const InputDecoration(hintText: 'Nom...'),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer'))],
      ),
    );
  }
}
