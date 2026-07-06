import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:go_router/go_router.dart';
import '../providers/live_provider.dart';

class LivePage extends StatefulWidget {
  const LivePage({super.key});

  @override
  State<LivePage> createState() => _LivePageState();
}

class _LivePageState extends State<LivePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    final provider = context.read<LiveProvider>();
    await Future.wait([
      provider.loadLiveSessions(),
      provider.loadAuctions(),
      provider.loadMyLives(),
    ]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final liveProvider = context.watch<LiveProvider>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'THIX LIVE',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'En direct 🔴'),
            Tab(text: 'Enchères'),
            Tab(text: 'Mes lives'),
          ],
          indicatorColor: const Color(0xFFE5592F),
          labelColor: const Color(0xFFE5592F),
          unselectedLabelColor: Colors.grey,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshData,
          ),
          IconButton(
            icon: const Icon(Icons.videocam, color: Colors.white),
            onPressed: () => context.push('/market/live/create'),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLiveNowTab(liveProvider),
          _buildAuctionsTab(liveProvider),
          _buildMyLivesTab(liveProvider),
        ],
      ),
    );
  }

  // ============================================================
  // TAB 1 : LIVES EN DIRECT
  // ============================================================
  Widget _buildLiveNowTab(LiveProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final liveSessions = provider.liveSessions;
    if (liveSessions.isEmpty) {
      // ✅ Correction : Icons.live_tv_off -> Icons.tv_off
      return _buildEmptyState(
        icon: Icons.tv_off,
        title: 'Aucun live en cours',
        subtitle: 'Revenez plus tard pour découvrir des diffusions',
        buttonText: 'Actualiser',
        onPressed: _refreshData,
      );
    }

    final featuredLives = liveSessions.where((l) => l['is_featured'] == true).toList();
    final otherLives = liveSessions.where((l) => l['is_featured'] != true).toList();

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          if (featuredLives.isNotEmpty)
            SliverToBoxAdapter(
              child: CarouselSlider(
                options: CarouselOptions(
                  height: 380,
                  autoPlay: true,
                  enlargeCenterPage: true,
                  viewportFraction: 0.92,
                  autoPlayInterval: const Duration(seconds: 5),
                ),
                items: featuredLives.map((live) {
                  return _buildLiveCard(live, isFeatured: true);
                }).toList(),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.all(12),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildLiveCard(otherLives[index]),
                childCount: otherLives.length,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveCard(Map<String, dynamic> live, {bool isFeatured = false}) {
    final thumbnail = live['thumbnail'] ?? '';
    final title = live['title'] ?? 'Live sans titre';
    final shopName = live['shop_name'] ?? 'Boutique';
    final shopAvatar = live['shop_avatar'] ?? '';
    final viewers = live['viewers'] ?? 0;

    return GestureDetector(
      onTap: () => context.push('/market/live/${live['id']}'),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isFeatured ? 16 : 12),
          color: Colors.grey[900],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(isFeatured ? 16 : 12),
              child: thumbnail.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: thumbnail,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: Colors.grey[900],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.grey[800],
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    )
                  : Container(
                      color: Colors.grey[800],
                      child: const Icon(Icons.live_tv, size: 40, color: Colors.grey),
                    ),
            ),
            // Badge LIVE
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.fiber_manual_record, color: Colors.white, size: 10),
                    SizedBox(width: 4),
                    Text(
                      'LIVE',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            // Viewers
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.visibility, color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      _formatNumber(viewers),
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
            // Info en bas
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
                  ),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(isFeatured ? 16 : 12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundImage: shopAvatar.isNotEmpty
                              ? CachedNetworkImageProvider(shopAvatar)
                              : null,
                          child: shopAvatar.isEmpty
                              ? const Icon(Icons.store, size: 10, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            shopName,
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TAB 2 : ENCHÈRES
  // ============================================================
  Widget _buildAuctionsTab(LiveProvider provider) {
    if (provider.isLoadingAuctions) {
      return const Center(child: CircularProgressIndicator());
    }

    final auctions = provider.auctions;
    if (auctions.isEmpty) {
      return _buildEmptyState(
        icon: Icons.gavel,
        title: 'Aucune enchère en cours',
        subtitle: 'Revenez plus tard pour participer',
        buttonText: 'Actualiser',
        onPressed: _refreshData,
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: auctions.length,
        itemBuilder: (context, index) {
          final auction = auctions[index];
          return _buildAuctionCard(auction);
        },
      ),
    );
  }

  Widget _buildAuctionCard(Map<String, dynamic> auction) {
    final imageUrl = auction['image_url'] ?? '';
    final title = auction['title'] ?? 'Enchère';
    final bidsCount = auction['bids_count'] ?? 0;
    final currentPrice = auction['current_price'] ?? 0;
    final endTime = auction['end_time'] != null
        ? DateTime.parse(auction['end_time'])
        : DateTime.now().add(const Duration(hours: 2));
    final timeLeft = endTime.difference(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[800]!),
      ),
      color: Colors.grey[900],
      child: InkWell(
        onTap: () => context.push('/market/auction/${auction['id']}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[800],
                          child: const Icon(Icons.image, color: Colors.grey),
                        ),
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[800],
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$bidsCount enchères',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Prix actuel',
                              style: TextStyle(color: Colors.grey[500], fontSize: 10),
                            ),
                            Text(
                              '$currentPrice FCFA',
                              style: const TextStyle(
                                color: Color(0xFFE5592F),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Temps restant',
                              style: TextStyle(color: Colors.grey[500], fontSize: 10),
                            ),
                            _buildCountdownTimer(timeLeft),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownTimer(Duration duration) {
    final hours = duration.inHours.clamp(0, 99);
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
        style: const TextStyle(
          color: Color(0xFFE5592F),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  // ============================================================
  // TAB 3 : MES LIVES
  // ============================================================
  Widget _buildMyLivesTab(LiveProvider provider) {
    if (provider.isLoadingMyLives) {
      return const Center(child: CircularProgressIndicator());
    }

    final myLives = provider.myLives;
    if (myLives.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam_off, size: 80, color: Colors.grey[600]),
            const SizedBox(height: 16),
            const Text(
              'Aucun live',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Créez votre premier live pour vendre en direct',
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.push('/market/live/create'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE5592F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text('Créer un live'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: myLives.length,
        itemBuilder: (context, index) {
          final live = myLives[index];
          return _buildMyLiveCard(live);
        },
      ),
    );
  }

  Widget _buildMyLiveCard(Map<String, dynamic> live) {
    final thumbnail = live['thumbnail'] ?? '';
    final title = live['title'] ?? 'Live';
    final viewers = live['viewers'] ?? 0;
    final productsSold = live['products_sold'] ?? 0;
    final status = live['status'] ?? 'ended';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[800]!),
      ),
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: thumbnail.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: thumbnail,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[800],
                            child: const Icon(Icons.image, color: Colors.grey),
                          ),
                        )
                      : Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[800],
                          child: const Icon(Icons.live_tv, color: Colors.grey),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$viewers vues · $productsSold vendus',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (status == 'live')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'LIVE',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.push('/market/live/${live['id']}/replay'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[700]!),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Replay'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.push('/market/live/${live['id']}/stats'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE5592F),
                    ),
                    child: const Text('Statistiques'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // UTILITAIRES
  // ============================================================
  String _formatNumber(int num) {
    if (num >= 1_000_000) return '${(num / 1_000_000).toStringAsFixed(1)}M';
    if (num >= 1_000) return '${(num / 1_000).toStringAsFixed(1)}k';
    return num.toString();
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE5592F),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }
}
