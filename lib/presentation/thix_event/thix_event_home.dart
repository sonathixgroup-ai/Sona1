// lib/presentation/thix_event/thix_event_home.dart
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/event_provider.dart';
import '../../models/event_model.dart';
import 'widgets/event_card.dart';
import 'widgets/category_chip.dart';

/// Palette Premium Entreprise - inspirée de tes 3 refs
class _ThixColors {
  static const Color navyDeep = Color(0xFF0E0E14);
  static const Color navy = Color(0xFF6B5CFF);
  static const Color primary = Color(0xFF6B5CFF);
  static const Color primaryLight = Color(0xFF8B7CFF);
  static const Color gold = Color(0xFFFFB020);
  static const Color goldLight = Color(0xFFFFD36B);
  static const Color ivory = Color(0xFFF7F7FB);
  static const Color pureWhite = Colors.white;
  static const Color darkText = Color(0xFF171721);
  static const Color mutedText = Color(0xFF8E8EA0);
  static const Color cardBorder = Color(0xFFECECF2);
  static const Color searchBg = Color(0xFFF1F1F6);
}

class ThixEventHome extends StatefulWidget {
  const ThixEventHome({super.key});
  @override
  State<ThixEventHome> createState() => _ThixEventHomeState();
}

class _ThixEventHomeState extends State<ThixEventHome> {
  final ScrollController _scrollController = ScrollController();
  int _selectedNavIndex = 0;
  bool _isInitialized = false;
  String _selectedQuickFilter = 'all';
  String _selectedDateFilter = 'all';

  final PageController _heroController = PageController(viewportFraction: 0.90);
  Timer? _heroAutoScrollTimer;
  int _heroCurrentPage = 0;
  int _heroTrackedCount = -1;

  final ScrollController _recScrollController = ScrollController();
  Timer? _recAutoScrollTimer;
  bool _recScrollingForward = true;
  int _recTrackedCount = -1;

  final List<Map<String, dynamic>> _quickFilters = [
    {'value': 'all', 'label': 'All', 'icon': Icons.grid_view_rounded, 'color': _ThixColors.primary},
    {'value': 'concert', 'label': 'Art', 'icon': Icons.palette_rounded, 'color': const Color(0xFF6B5CFF)},
    {'value': 'spectacle', 'label': 'Music', 'icon': Icons.music_note_rounded, 'color': const Color(0xFFE0578F)},
    {'value': 'conference', 'label': 'Sport', 'icon': Icons.sports_basketball_rounded, 'color': const Color(0xFF17A673)},
    {'value': 'sport', 'label': 'Culture', 'icon': Icons.theater_comedy_rounded, 'color': const Color(0xFFFF8A00)},
    {'value': 'more', 'label': 'More', 'icon': Icons.more_horiz_rounded, 'color': _ThixColors.mutedText},
  ];

  final List<Map<String, String>> _dateFilters = [
    {'value': 'all', 'label': 'All Dates'},
    {'value': 'today', 'label': "Today"},
    {'value': 'week', 'label': 'This Week'},
    {'value': 'month', 'label': 'This Month'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await Future.delayed(Duration.zero);
    if (!mounted) return;
    final eventProvider = Provider.of<EventProvider>(context, listen: false);
    try {
      await Future.wait([
        eventProvider.fetchEvents(),
        eventProvider.fetchFeaturedEvents(),
      ]);
    } catch (e) {
      debugPrint('Erreur chargement: $e');
    }
    if (mounted) {
      setState(() => _isInitialized = true);
      _maybeRestartHeroAutoScroll(eventProvider.featuredEvents.length);
      _maybeRestartRecAutoScroll(eventProvider.upcomingEvents.where((e) => e.isRecommended).length);
    }
  }

  void _maybeRestartHeroAutoScroll(int count) {
    if (count == _heroTrackedCount) return;
    _heroTrackedCount = count;
    _heroCurrentPage = 0;
    _heroAutoScrollTimer?.cancel();
    if (count <= 1) return;
    _heroAutoScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted ||!_heroController.hasClients) return;
      final provider = Provider.of<EventProvider>(context, listen: false);
      final total = provider.featuredEvents.length;
      if (total == 0) return;
      final nextPage = (_heroCurrentPage + 1) % total;
      _heroController.animateToPage(nextPage, duration: const Duration(milliseconds: 700), curve: Curves.easeOutCubic);
    });
  }

  void _maybeRestartRecAutoScroll(int count) {
    if (count == _recTrackedCount) return;
    _recTrackedCount = count;
    _recAutoScrollTimer?.cancel();
    if (count > 3) {
      _recAutoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
        if (!mounted ||!_recScrollController.hasClients) return;
        double maxScroll = _recScrollController.position.maxScrollExtent;
        double currentScroll = _recScrollController.position.pixels;
        double itemWidth = 280.0;
        if (_recScrollingForward) {
          if (currentScroll >= maxScroll - 20) _recScrollingForward = false;
          else _recScrollController.animateTo(currentScroll + itemWidth, duration: const Duration(milliseconds: 900), curve: Curves.easeOutCubic);
        } else {
          if (currentScroll <= 20) _recScrollingForward = true;
          else _recScrollController.animateTo(currentScroll - itemWidth, duration: const Duration(milliseconds: 900), curve: Curves.easeOutCubic);
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _heroAutoScrollTimer?.cancel();
    _heroController.dispose();
    _recScrollController.dispose();
    _recAutoScrollTimer?.cancel();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == 2) { context.push('/thix-event/my-tickets'); return; }
    setState(() => _selectedNavIndex = index);
    HapticFeedback.lightImpact();
    switch (index) {
      case 0: break;
      case 1: context.push('/thix-event/search'); break;
      case 3: context.push('/thix-event/favorites'); break;
      case 4: context.push('/profile'); break;
    }
  }

  void _goToEventDetail(String eventId) => context.push('/thix-event/event/$eventId');

  @override
  Widget build(BuildContext context) {
    final eventProvider = Provider.of<EventProvider>(context);
    final featuredEvents = eventProvider.featuredEvents;
    final events = eventProvider.upcomingEvents;

    final recommendedEvents = events.where((e) => e.isRecommended).toList();
    final upcomingEvents = events.where((e) =>!e.isRecommended &&!e.isFeatured).take(6).toList();
    final allEvents = events;
    final isLoading = eventProvider.isLoading;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeRestartHeroAutoScroll(featuredEvents.length);
      _maybeRestartRecAutoScroll(recommendedEvents.length);
    });

    if (!_isInitialized && isLoading) {
      return Scaffold(backgroundColor: _ThixColors.ivory, body: Center(child: CircularProgressIndicator(color: _ThixColors.primary)));
    }

    return Scaffold(
      backgroundColor: _ThixColors.ivory,
      appBar: _buildEnterpriseAppBar(),
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                _buildEnterpriseSearch(),
                const SizedBox(height: 18),
                _buildEnterpriseHero(featuredEvents),
                const SizedBox(height: 14),
                _buildEnterpriseDots(featuredEvents.length),
                const SizedBox(height: 24),
                _buildEnterpriseSectionHeader('Trending', onSeeAll: () => context.push('/thix-event/recommended')),
                const SizedBox(height: 14),
                _buildEnterpriseQuickFilters(),
                const SizedBox(height: 10),
                _buildEnterpriseDateFilters(),
                const SizedBox(height: 18),
                if (recommendedEvents.isNotEmpty)
                  SizedBox(
                    height: 298,
                    child: ListView.separated(
                      controller: _recScrollController,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: recommendedEvents.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemBuilder: (context, i) => _buildEnterpriseTrendingCard(recommendedEvents[i]),
                    ),
                  ),
                const SizedBox(height: 24),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _buildEnterprisePromoBanner()),
                const SizedBox(height: 28),
                _buildEnterpriseSectionHeader('Recently Viewed', onSeeAll: () => context.push('/thix-event/upcoming')),
                const SizedBox(height: 14),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 12,
                childAspectRatio: 0.68,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final ev = upcomingEvents.isNotEmpty? upcomingEvents[index] : allEvents[index];
                  return _buildEnterpriseTrendingCard(ev, isGrid: true);
                },
                childCount: upcomingEvents.isNotEmpty? upcomingEvents.length : (allEvents.length > 6? 6 : allEvents.length),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
      bottomNavigationBar: _buildEnterpriseBottomNav(),
    );
  }

  PreferredSizeWidget _buildEnterpriseAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      leading: IconButton(icon: const Icon(Icons.menu_rounded, color: _ThixColors.primary, size: 26), onPressed: () {}),
      title: const Text('Home', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _ThixColors.primary)),
      actions: [
        IconButton(icon: const Icon(Icons.search_rounded, color: _ThixColors.primary, size: 24), onPressed: () => context.push('/thix-event/search')),
        IconButton(icon: const Icon(Icons.notifications_rounded, color: _ThixColors.primary, size: 24), onPressed: () {}),
        Padding(
          padding: const EdgeInsets.only(right: 14, left: 4),
          child: InkWell(
            onTap: () => context.push('/thix-event/admin'),
            child: Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const SweepGradient(colors: [Color(0xFFFF3B7F), Color(0xFFFFB020), Color(0xFF6B5CFF), Color(0xFF3DD598), Color(0xFFFF3B7F)]),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6)],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnterpriseSearch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => context.push('/thix-event/search'),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(color: _ThixColors.searchBg, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              const Expanded(child: Text('Search event', style: TextStyle(color: _ThixColors.mutedText, fontSize: 14, fontWeight: FontWeight.w500))),
              Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.search_rounded, size: 18, color: _ThixColors.darkText)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnterpriseHero(List<Event> featuredEvents) {
    if (featuredEvents.isEmpty) {
      return Container(height: 240, margin: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)), child: const Center(child: CircularProgressIndicator(color: _ThixColors.primary)));
    }
    return SizedBox(
      height: 270,
      child: PageView.builder(
        controller: _heroController,
        itemCount: featuredEvents.length,
        onPageChanged: (i) => setState(() => _heroCurrentPage = i),
        itemBuilder: (context, index) {
          final event = featuredEvents[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 20, offset: const Offset(0, 8))]),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(event.imageUrl?? '', fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: _ThixColors.navyDeep)),
                Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, _ThixColors.navyDeep.withOpacity(0.75)]))),
                Positioned(
                  left: 18, right: 18, bottom: 18,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(event.title, maxLines: 2, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, height: 1.1, shadows: [Shadow(blurRadius: 8, color: Colors.black45)])),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () => _goToEventDetail(event.id),
                          style: ElevatedButton.styleFrom(backgroundColor: _ThixColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)), elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 28)),
                          child: const Text('Book Now', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEnterpriseDots(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == _heroCurrentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: active? 10 : 8,
          height: active? 10 : 8,
          decoration: BoxDecoration(color: active? _ThixColors.primary : _ThixColors.cardBorder, shape: BoxShape.circle),
        );
      }),
    );
  }

  Widget _buildEnterpriseSectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _ThixColors.darkText)),
          if (onSeeAll!= null)
            GestureDetector(
              onTap: onSeeAll,
              child: const Text('See All', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _ThixColors.primary)),
            ),
        ],
      ),
    );
  }

  Widget _buildEnterpriseQuickFilters() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _quickFilters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final f = _quickFilters[index];
          final isSelected = _selectedQuickFilter == f['value'];
          return GestureDetector(
            onTap: () {
              if (f['value'] == 'more') { context.push('/thix-event/categories'); return; }
              setState(() => _selectedQuickFilter = f['value'] as String);
              context.read<EventProvider>().setCategory(f['value'] == 'all'? 'all' : f['value'] as String);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: isSelected? _ThixColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected? _ThixColors.primary : _ThixColors.cardBorder),
              ),
              child: Center(child: Text(f['label'] as String, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isSelected? Colors.white : _ThixColors.primary))),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEnterpriseDateFilters() {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _dateFilters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _dateFilters[index];
          final isSelected = _selectedDateFilter == filter['value'];
          return GestureDetector(
            onTap: () {
              setState(() => _selectedDateFilter = filter['value']!);
              context.read<EventProvider>().setDateFilter(filter['value']!);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected? _ThixColors.primary.withOpacity(0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected? _ThixColors.primary : _ThixColors.cardBorder),
              ),
              child: Center(child: Text(filter['label']!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected? _ThixColors.primary : _ThixColors.mutedText))),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEnterpriseTrendingCard(Event event, {bool isGrid = false}) {
    final dateLabel = event.formattedDate.split(',').first;
    return GestureDetector(
      onTap: () => _goToEventDetail(event.id),
      child: Container(
        width: isGrid? null : 268,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _ThixColors.cardBorder),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: isGrid? 1.15 : 1.7,
                  child: Image.network(event.imageUrl?? '', fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: _ThixColors.ivory)),
                ),
                Positioned(
                  top: 10, right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)]),
                    child: Text(dateLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _ThixColors.primary)),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _ThixColors.primary)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: _ThixColors.primary.withOpacity(0.4)), borderRadius: BorderRadius.circular(20)),
                        child: Text(event.categoryLabel, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _ThixColors.primary)),
                      ),
                      const SizedBox(width: 8),
                      _buildAvatarStack(),
                      const SizedBox(width: 6),
                      const Expanded(child: Text('20K+ Going', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _ThixColors.darkText))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 16, color: _ThixColors.primary),
                      const SizedBox(width: 4),
                      Expanded(child: Text(event.location, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: _ThixColors.darkText, fontWeight: FontWeight.w500))),
                      const Icon(Icons.bookmark_border_rounded, size: 18, color: _ThixColors.primary),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarStack() {
    return SizedBox(
      width: 56,
      height: 22,
      child: Stack(
        children: [
          Positioned(left: 0, child: _avatarCircle(const Color(0xFFFF6B6B))),
          Positioned(left: 14, child: _avatarCircle(const Color(0xFFFFB020))),
          Positioned(left: 28, child: _avatarCircle(const Color(0xFF6B5CFF), icon: Icons.person_rounded)),
        ],
      ),
    );
  }

  Widget _avatarCircle(Color color, {IconData? icon}) {
    return Container(
      width: 22, height: 22,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
      child: Icon(icon?? Icons.person_rounded, size: 12, color: Colors.white),
    );
  }

  Widget _buildEnterprisePromoBanner() {
    return Container(
      height: 92,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(colors: [Color(0xFFE9F0FF), Color(0xFFD6E4FF)]),
        border: Border.all(color: _ThixColors.cardBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RichText(text: const TextSpan(children: [
                  TextSpan(text: 'MEGA\n', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: _ThixColors.darkText)),
                  TextSpan(text: 'FASHION\n', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _ThixColors.primary)),
                  TextSpan(text: 'SALE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: _ThixColors.darkText)),
                ])),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Column(children: const [Text('GET', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: _ThixColors.mutedText)), Text('50% OFF', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: _ThixColors.primary))]),
          ),
          const SizedBox(width: 12),
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10)]),
            child: const Icon(Icons.person_rounded, size: 36, color: _ThixColors.mutedText),
          ),
        ],
      ),
    );
  }

  Widget _buildEnterpriseBottomNav() {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: _ThixColors.cardBorder))),
      padding: const EdgeInsets.only(top: 6, bottom: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItemEnterprise(Icons.home_rounded, 'Homes', 0),
          _navItemEnterprise(Icons.calendar_month_rounded, 'Event', 1),
          _navItemEnterpriseCentral(),
          _navItemEnterprise(Icons.location_on_rounded, 'Events Around', 3),
          _navItemEnterprise(Icons.person_rounded, 'Profile', 4),
        ],
      ),
    );
  }

  Widget _navItemEnterprise(IconData icon, String label, int index) {
    final isSelected = _selectedNavIndex == index;
    return InkWell(
      onTap: () => _onNavTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 26, color: isSelected? _ThixColors.primary : _ThixColors.mutedText),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: isSelected? FontWeight.w700 : FontWeight.w500, color: isSelected? _ThixColors.primary : _ThixColors.mutedText)),
        ],
      ),
    );
  }

  Widget _navItemEnterpriseCentral() {
    return InkWell(
      onTap: () => _onNavTap(2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: _ThixColors.cardBorder, width: 2), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12)]),
            child: Center(child: Container(width: 36, height: 36, decoration: BoxDecoration(color: _ThixColors.ivory, shape: BoxShape.circle, border: Border.all(color: _ThixColors.primary.withOpacity(0.3))), child: const Icon(Icons.add_rounded, color: _ThixColors.primary))),
          ),
          const SizedBox(height: 4),
          const Text('Add Events', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: _ThixColors.mutedText)),
        ],
      ),
    );
  }
}
