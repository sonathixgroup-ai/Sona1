import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/models/network_community.dart';
import 'package:thix_id/features/network/data/network_service_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'communities_list_page.g.dart';

// ── PROVIDERS SCALABLES ──
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
  static const _limit = 20;
  int _offset = 0;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  @override
  Future<List<NetworkCommunity>> build() async {
    _offset = 0; _hasMore = true;
    final list = await ref.read(networkServiceProvider).getAllCommunities(limit: _limit);
    _offset = list.length;
    _hasMore = list.length >= _limit;
    return list;
  }

  Future<void> loadMore() async {
    if (!_hasMore) return;
    final current = state.valueOrNull?? [];
    final more = await ref.read(networkServiceProvider).getAllCommunities(limit: _limit);
    // Si ton service supporte offset, fais: getAllCommunities(limit: _limit, offset: _offset)
    if (more.isEmpty || more.length < _limit) _hasMore = false;
    // évite doublons
    final ids = current.map((e) => e.id).toSet();
    final filtered = more.where((e) => !ids.contains(e.id)).toList();
    _offset += filtered.length;
    state = AsyncData([...current, ...filtered]);
  }

  Future<void> refresh() async { ref.invalidateSelf(); }
}

class CommunitiesListPage extends ConsumerStatefulWidget {
  const CommunitiesListPage({super.key});
  @override
  ConsumerState<CommunitiesListPage> createState() => _CommunitiesListPageState();
}

class _CommunitiesListPageState extends ConsumerState<CommunitiesListPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final _allScroll = ScrollController();

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
  void dispose() { _tabController.dispose(); _allScroll.dispose(); super.dispose(); }

  List<NetworkCommunity> _filter(List<NetworkCommunity> list) {
    if (_searchQuery.isEmpty) return list;
    final q = _searchQuery.toLowerCase();
    return list.where((c) => c.name.toLowerCase().contains(q) || (c.description?.toLowerCase().contains(q)?? false)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final myAsync = ref.watch(myCommunitiesProvider);
    final suggAsync = ref.watch(suggestedCommunitiesProvider);
    final allAsync = ref.watch(allCommunitiesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0.5,
        title: const Text('Communautés', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1A1A2E))),
        actions: [
          IconButton(icon: const Icon(Icons.search, color: Color(0xFF1A1A2E)), onPressed: _showSearchDialog),
          IconButton(icon: const Icon(Icons.add, color: Color(0xFF1A1A2E)), onPressed: () => context.push('/network/community/create')),
        ],
        bottom: TabBar(controller: _tabController, labelColor: const Color(0xFFD4AF37), unselectedLabelColor: Colors.grey.shade600, indicatorColor: const Color(0xFFD4AF37), labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), tabs: const [Tab(text: 'Mes communautés'), Tab(text: 'Suggestions'), Tab(text: 'Toutes')]),
      ),
      body: TabBarView(controller: _tabController, children: [
        myAsync.when(loading: () => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFFD4AF37)))), error: (e, _) => _buildErrorState(e.toString()), data: (list) => _buildCommunityList(_filter(list), 'Vous n\'avez pas encore rejoint de communauté.', onRefresh: () => ref.invalidate(myCommunitiesProvider))),
        suggAsync.when(loading: () => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFFD4AF37)))), error: (e, _) => _buildErrorState(e.toString()), data: (list) => _buildCommunityList(_filter(list), 'Aucune suggestion pour le moment.', onRefresh: () => ref.invalidate(suggestedCommunitiesProvider))),
        allAsync.when(loading: () => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFFD4AF37)))), error: (e, _) => _buildErrorState(e.toString()), data: (list) => _buildCommunityList(_filter(list), 'Aucune communauté disponible.', controller: _allScroll, onRefresh: () => ref.read(allCommunitiesProvider.notifier).refresh())),
      ]),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.error_outline, size: 56, color: Colors.red.shade400),
      const SizedBox(height: 16), const Text('Erreur de chargement', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8), Text(error, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
      const SizedBox(height: 24),
      ElevatedButton.icon(onPressed: () { ref.invalidate(myCommunitiesProvider); ref.invalidate(suggestedCommunitiesProvider); ref.invalidate(allCommunitiesProvider); }, icon: const Icon(Icons.refresh), label: const Text('Réessayer'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.white)),
    ]));
  }

  Widget _buildCommunityList(List<NetworkCommunity> communities, String emptyMessage, {ScrollController? controller, Future<void> Function()? onRefresh}) {
    if (communities.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.groups, size: 56, color: Colors.grey.shade400), const SizedBox(height: 16), Text(emptyMessage, style: TextStyle(fontSize: 14, color: Colors.grey.shade600), textAlign: TextAlign.center)]));
    }
    return RefreshIndicator(color: const Color(0xFFD4AF37), onRefresh: () async { if (onRefresh!= null) await onRefresh(); }, child: ListView.builder(controller: controller, padding: const EdgeInsets.all(16), itemCount: communities.length, itemBuilder: (context, index) => _buildCommunityCard(communities[index])));
  }

  Widget _buildCommunityCard(NetworkCommunity community) {
    final isMember = community.isMember?? false;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))]),
      child: ListTile(
        leading: ClipRRect(borderRadius: BorderRadius.circular(12), child: community.logoUrl!= null && community.logoUrl!.isNotEmpty? CachedNetworkImage(imageUrl: community.logoUrl!, width: 50, height: 50, fit: BoxFit.cover, placeholder: (_, __) => Container(width: 50, height: 50, color: Colors.grey.shade200, child: const Icon(Icons.groups, color: Colors.grey)), errorWidget: (_, __, ___) => Container(width: 50, height: 50, color: Colors.grey.shade200, child: const Icon(Icons.groups, color: Colors.grey))) : Container(width: 50, height: 50, color: const Color(0xFFD4AF37).withOpacity(0.1), child: const Icon(Icons.groups, color: Color(0xFFD4AF37))))),
        title: Text(community.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF1A1A2E))),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (community.description!= null && community.description!.isNotEmpty) Text(community.description!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Row(children: [const Icon(Icons.people, size: 14, color: Colors.grey), const SizedBox(width: 4), Text('${community.membersCount?? 0} membres', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)), const SizedBox(width: 12), if (isMember) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Text('Membre', style: TextStyle(fontSize: 9, color: Colors.green, fontWeight: FontWeight.w600)))]),
        ]),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () => context.push('/network/community/${community.id}'),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(context: context, builder: (context) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), title: const Text('Rechercher une communauté'), content: TextField(autofocus: true, decoration: const InputDecoration(hintText: 'Nom, description...', border: OutlineInputBorder(), prefixIcon: Icon(Icons.search)), onChanged: (v) => setState(() => _searchQuery = v)), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer'))]));
  }
}
