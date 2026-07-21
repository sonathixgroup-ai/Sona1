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

/// Palette officielle Charte THIX ID
class _ThixColors {
  static const Color navyDeep = Color(0xFF0A1F44);
  static const Color navy = Color(0xFF123B7A);
  static const Color primary = Color(0xFF2D6CDF);
  static const Color primaryLight = Color(0xFF5B93F5);
  static const Color gold = Color(0xFFE3B23C);
  static const Color goldLight = Color(0xFFF3CD6B);
  static const Color ivory = Color(0xFFF6F7FB);
  static const Color pureWhite = Colors.white;
  static const Color darkText = Color(0xFF10192E);
  static const Color mutedText = Color(0xFF8993A8);
  static const Color cardBorder = Color(0xFFE9EDF6);
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

  // --- HERO BANNER (Immersif) ---
  final PageController _heroController = PageController(viewportFraction: 1.0);
  Timer? _heroAutoScrollTimer;
  int _heroCurrentPage = 0;
  int _heroTrackedCount = -1;

  // --- RECOMMANDÉS AUTO-SCROLL ---
  final ScrollController _recScrollController = ScrollController();
  Timer? _recAutoScrollTimer;
  bool _recScrollingForward = true;
  int _recTrackedCount = -1;

  final List<Map<String, dynamic>> _quickFilters = [
    {'value': 'all', 'label': 'Tout', 'icon': Icons.auto_awesome_rounded, 'color': _ThixColors.primary},
    {'value': 'concert', 'label': 'Concerts', 'icon': Icons.music_note_rounded, 'color': const Color(0xFFE0578F)},
    {'value': 'spectacle', 'label': 'Spectacles', 'icon': Icons.theater_comedy_rounded, 'color': _ThixColors.gold},
    {'value': 'conference', 'label': 'Conférences', 'icon': Icons.mic_rounded, 'color': _ThixColors.navy},
    {'value': 'sport', 'label': 'Sports', 'icon': Icons.emoji_events_rounded, 'color': const Color(0xFF17A673)},
    {'value': 'more', 'label': 'Plus', 'icon': Icons.grid_view_rounded, 'color': _ThixColors.mutedText},
  ];

  final List<Map<String, String>> _dateFilters = [
    {'value': 'all', 'label': 'Toutes les dates'},
    {'value': 'today', 'label': 'Aujourd\'hui'},
    {'value': 'week', 'label': 'Cette semaine'},
    {'value': 'month', 'label': 'Ce mois-ci'},
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
    _heroAutoScrollTimer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (!mounted || !_heroController.hasClients) return;
      final provider = Provider.of<EventProvider>(context, listen: false);
      final total = provider.featuredEvents.length;
      if (total == 0) return;
      final nextPage = (_heroCurrentPage + 1) % total;
      _heroController.animateToPage(nextPage, duration: const Duration(milliseconds: 800), curve: Curves.fastOutSlowIn);
    });
  }

  void _maybeRestartRecAutoScroll(int count) {
    if (count == _recTrackedCount) return;
    _recTrackedCount = count;
    _recAutoScrollTimer?.cancel();
    if (count > 4) {
      _recAutoScrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (!mounted || !_recScrollController.hasClients) return;
        double maxScroll = _recScrollController.position.maxScrollExtent;
        double currentScroll = _recScrollController.position.pixels;
        double itemWidth = 260.0;
        if (_recScrollingForward) {
          if (currentScroll >= maxScroll - 20) _recScrollingForward = false;
          else _recScrollController.animateTo(currentScroll + itemWidth, duration: const Duration(milliseconds: 1000), curve: Curves.fastOutSlowIn);
        } else {
          if (currentScroll <= 20) _recScrollingForward = true;
          else _recScrollController.animateTo(currentScroll - itemWidth, duration: const Duration(milliseconds: 1000), curve: Curves.fastOutSlowIn);
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
    final upcomingEvents = events.where((e) => !e.isRecommended && !e.isFeatured).take(6).toList();
    final allEvents = events;
    final isLoading = eventProvider.isLoading;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeRestartHeroAutoScroll(featuredEvents.length);
      _maybeRestartRecAutoScroll(recommendedEvents.length);
    });

    if (!_isInitialized && isLoading) {
      return const Scaffold(
        backgroundColor: _ThixColors.navyDeep,
        body: Center(child: CircularProgressIndicator(color: _ThixColors.gold)),
      );
    }

    return Scaffold(
      backgroundColor: _ThixColors.ivory,
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: _buildGlassAppBar(),
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildImmersiveHero(featuredEvents)),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 28),
                _buildQuickFilters(),
                const SizedBox(height: 16),
                _buildDateFilters(),
                const SizedBox(height: 28),

                _buildSectionHeader('Les Plus Attendus', '/thix-event/recommended', isPremium: true),
                const SizedBox(height: 16),
                if (recommendedEvents.isNotEmpty)
                  SizedBox(
                    height: 330,
                    child: ListView.separated(
                      controller: _recScrollController,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      itemCount: recommendedEvents.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 16),
                      itemBuilder: (context, i) => SizedBox(
                        width: 240,
                        child: _buildPremiumEventCard(recommendedEvents[i]),
                      ),
                    ),
                  ),
                const SizedBox(height: 28),

                Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: _buildVIPBanner()),
                const SizedBox(height: 32),

                _buildSectionHeader('À l\'affiche', '/thix-event/upcoming'),
                const SizedBox(height: 16),
              ],
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 20,
                crossAxisSpacing: 16,
                childAspectRatio: 0.65,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => EventCard(
                  event: upcomingEvents.isNotEmpty ? upcomingEvents[index] : allEvents[index],
                  onTap: () => _goToEventDetail(upcomingEvents.isNotEmpty ? upcomingEvents[index].id : allEvents[index].id),
                ),
                childCount: upcomingEvents.isNotEmpty ? upcomingEvents.length : (allEvents.length > 6 ? 6 : allEvents.length),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 130)),
        ],
      ),
      bottomNavigationBar: _buildFloatingBottomNav(),
    );
  }

  // AppBar Glassmorphism
  PreferredSizeWidget _buildGlassAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: AppBar(
            backgroundColor: _ThixColors.navyDeep.withOpacity(0.55),
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_ThixColors.gold, _ThixColors.goldLight]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.confirmation_num_rounded, color: _ThixColors.navyDeep, size: 16),
                ),
                const SizedBox(width: 10),
                const Text('THIX', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
                const Text(' EVENT', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w300, color: Colors.white70, letterSpacing: 0.5)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                  onPressed: () {},
                ),
                InkWell(
                  onTap: () => context.push('/thix-event/admin'),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _ThixColors.gold.withOpacity(0.18),
                      border: Border.all(color: _ThixColors.gold, width: 1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('PRO', style: TextStyle(color: _ThixColors.gold, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Hero cinématique + barre de recherche flottante
  Widget _buildImmersiveHero(List<Event> featuredEvents) {
    if (featuredEvents.isEmpty) {
      return const SizedBox(height: 380, child: Center(child: CircularProgressIndicator(color: _ThixColors.primary)));
    }

    return SizedBox(
      height: 520,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            height: 480,
            child: PageView.builder(
              controller: _heroController,
              itemCount: featuredEvents.length,
              onPageChanged: (index) => setState(() => _heroCurrentPage = index),
              itemBuilder: (context, index) {
                final event = featuredEvents[index];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      event.imageUrl ?? '',
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      errorBuilder: (_, __, ___) => Container(color: _ThixColors.navy),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            _ThixColors.navyDeep.withOpacity(0.75),
                            Colors.transparent,
                            _ThixColors.navyDeep.withOpacity(0.55),
                            _ThixColors.navyDeep.withOpacity(0.92),
                          ],
                          stops: const [0.0, 0.28, 0.65, 1.0],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 56,
                      left: 20,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [_ThixColors.gold, _ThixColors.goldLight]),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text('À L\'AFFICHE', style: TextStyle(color: _ThixColors.navyDeep, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                event.categoryLabel.toUpperCase(),
                                style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 2),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            event.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900, height: 1.1, letterSpacing: -0.5),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, color: _ThixColors.gold, size: 14),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(event.location, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _goToEventDetail(event.id),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _ThixColors.gold,
                                    foregroundColor: _ThixColors.navyDeep,
                                    padding: const EdgeInsets.symmetric(vertical: 15),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    elevation: 8,
                                    shadowColor: _ThixColors.gold.withOpacity(0.5),
                                  ),
                                  child: const Text('RÉSERVER MES PLACES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.8)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.share_rounded, color: Colors.white),
                                  onPressed: () {},
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Indicateurs façon "stories" (barres fines en haut du hero)
          Positioned(
            top: 70,
            left: 20,
            right: 20,
            child: Row(
              children: List.generate(featuredEvents.length, (index) {
                final isActive = index == _heroCurrentPage;
                return Expanded(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: isActive ? _ThixColors.gold : Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Barre de recherche flottante, à cheval sur le hero
          Positioned(
            bottom: 0,
            left: 20,
            right: 20,
            child: GestureDetector(
              onTap: () => context.push('/thix-event/search'),
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: _ThixColors.navyDeep.withOpacity(0.18), blurRadius: 24, offset: const Offset(0, 10))],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: _ThixColors.primary, size: 22),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('Rechercher un événement, un artiste...', style: TextStyle(color: _ThixColors.mutedText, fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: _ThixColors.ivory, shape: BoxShape.circle),
                      child: const Icon(Icons.tune_rounded, color: _ThixColors.navy, size: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Cartes VIP pour les "Recommandés"
  Widget _buildPremiumEventCard(Event event) {
    return GestureDetector(
      onTap: () => _goToEventDetail(event.id),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white,
          boxShadow: [BoxShadow(color: _ThixColors.navy.withOpacity(0.10), blurRadius: 24, offset: const Offset(0, 12))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(event.imageUrl ?? '', fit: BoxFit.cover),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, _ThixColors.navyDeep.withOpacity(0.35)],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          color: Colors.black.withOpacity(0.3),
                          child: Text(event.formattedDate.split(',').first, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 10)),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [_ThixColors.gold, _ThixColors.goldLight]),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.local_fire_department_rounded, size: 11, color: _ThixColors.navyDeep),
                          SizedBox(width: 3),
                          Text('TOP', style: TextStyle(color: _ThixColors.navyDeep, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(event.categoryLabel.toUpperCase(), style: const TextStyle(color: _ThixColors.primary, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        const SizedBox(height: 4),
                        Text(event.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: _ThixColors.darkText, height: 1.15)),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(event.formattedPrice, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: _ThixColors.navyDeep)),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(colors: [_ThixColors.primary, _ThixColors.navy]),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
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

  // Bannière VIP / Écosystème
  Widget _buildVIPBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_ThixColors.navyDeep, _ThixColors.navy]),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: _ThixColors.navyDeep.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_ThixColors.gold, _ThixColors.goldLight]),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: _ThixColors.gold.withOpacity(0.5), blurRadius: 10)],
            ),
            child: const Icon(Icons.workspace_premium_rounded, color: _ThixColors.navyDeep, size: 28),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sécurisé par THIX ID', style: TextStyle(color: _ThixColors.gold, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                SizedBox(height: 4),
                Text('Bénéficiez d\'un accès coupe-file et de billets infalsifiables.', style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.white54),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String route, {bool isPremium = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isPremium ? _ThixColors.navyDeep : _ThixColors.darkText, letterSpacing: -0.5)),
          GestureDetector(
            onTap: () => context.push(route),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: _ThixColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: const Row(
                children: [
                  Text('Tout voir', style: TextStyle(fontSize: 10, color: _ThixColors.primary, fontWeight: FontWeight.w800)),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 12, color: _ThixColors.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilters() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _quickFilters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final f = _quickFilters[index];
          final isSelected = _selectedQuickFilter == f['value'];
          return InkWell(
            onTap: () {
              if (f['value'] == 'more') { context.push('/thix-event/categories'); return; }
              setState(() => _selectedQuickFilter = f['value'] as String);
              context.read<EventProvider>().setCategory(f['value'] == 'all' ? 'all' : f['value'] as String);
            },
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? _ThixColors.navyDeep : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? _ThixColors.navyDeep : _ThixColors.cardBorder),
                boxShadow: isSelected ? [BoxShadow(color: _ThixColors.navyDeep.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 4))] : [],
              ),
              child: Row(
                children: [
                  Icon(f['icon'] as IconData, color: isSelected ? _ThixColors.gold : f['color'] as Color, size: 16),
                  const SizedBox(width: 8),
                  Text(f['label'] as String, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600, color: isSelected ? Colors.white : _ThixColors.darkText)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateFilters() {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _dateFilters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _dateFilters[index];
          final isSelected = _selectedDateFilter == filter['value'];
          return InkWell(
            onTap: () {
              setState(() => _selectedDateFilter = filter['value']!);
              context.read<EventProvider>().setDateFilter(filter['value']!);
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? _ThixColors.primary.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? _ThixColors.primary : Colors.grey.shade300, width: 1.5),
              ),
              child: Center(
                child: Text(filter['label']!, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600, color: isSelected ? _ThixColors.primary : _ThixColors.mutedText)),
              ),
            ),
          );
        },
      ),
    );
  }

  // Barre de navigation flottante avec accent or actif
  Widget _buildFloatingBottomNav() {
    return Container(
      margin: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: _ThixColors.navyDeep.withOpacity(0.97),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [BoxShadow(color: _ThixColors.navyDeep.withOpacity(0.4), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _navItem(Icons.explore_rounded, 'Explore', 0),
            _navItem(Icons.search_rounded, 'Recherche', 1),
            _centerNavItem(),
            _navItem(Icons.favorite_rounded, 'Favoris', 3),
            _navItem(Icons.person_rounded, 'Profil', 4),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final isSelected = _selectedNavIndex == index;
    return InkWell(
      onTap: () => _onNavTap(index),
      borderRadius: BorderRadius.circular(30),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _ThixColors.gold.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Icon(icon, color: isSelected ? _ThixColors.gold : Colors.white54, size: 24),
      ),
    );
  }

  Widget _centerNavItem() {
    return InkWell(
      onTap: () => _onNavTap(2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_ThixColors.primary, _ThixColors.navy]),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: _ThixColors.primary.withOpacity(0.5), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: const Row(
          children: [
            Icon(Icons.confirmation_num_rounded, color: Colors.white, size: 20),
            SizedBox(width: 6),
            Text('Billets', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}
