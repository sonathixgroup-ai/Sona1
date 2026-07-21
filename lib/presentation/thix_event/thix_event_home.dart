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

class _ThixColors {
  static const Color primary = Color(0xFF6B3CE2); 
  static const Color primaryLight = Color(0xFF8B5CF6);
  static const Color primaryGradientEnd = Color(0xFF3B1D82); // Plus sombre pour la profondeur
  
  static const Color premiumDark = Color(0xFF0A0A14); // Noir profond
  static const Color premiumGold = Color(0xFFE3B23C); // Or VIP
  
  static const Color lightBg = Color(0xFFF8F9FB); // Gris très très clair pour le contraste
  static const Color pureWhite = Colors.white;
  static const Color darkText = Color(0xFF1E1B4B);
  static const Color mutedText = Color(0xFF8B8BA7);
  static const Color cardBorder = Color(0xFFEEE9FF);
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
    {'value': 'all', 'label': 'Tout', 'icon': Icons.whatshot_rounded, 'color': _ThixColors.primary},
    {'value': 'concert', 'label': 'Concerts', 'icon': Icons.music_note_rounded, 'color': const Color(0xFFEC4899)},
    {'value': 'spectacle', 'label': 'Spectacles', 'icon': Icons.theater_comedy_rounded, 'color': const Color(0xFFF59E0B)},
    {'value': 'conference', 'label': 'Conférences', 'icon': Icons.mic_rounded, 'color': const Color(0xFF3B82F6)},
    {'value': 'sport', 'label': 'Sports', 'icon': Icons.emoji_events_rounded, 'color': const Color(0xFF10B981)},
    {'value': 'more', 'label': 'Plus', 'icon': Icons.grid_view_rounded, 'color': const Color(0xFF9CA3AF)},
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
      return const Scaffold(backgroundColor: _ThixColors.premiumDark, body: Center(child: CircularProgressIndicator(color: _ThixColors.premiumGold)));
    }

    return Scaffold(
      backgroundColor: _ThixColors.lightBg,
      extendBodyBehindAppBar: true,
      extendBody: true, // Pour la bottom nav bar flottante
      appBar: _buildGlassAppBar(),
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // --- HERO IMMERSIF (Prend le haut de l'écran derrière l'AppBar) ---
          SliverToBoxAdapter(
            child: _buildImmersiveHero(featuredEvents),
          ),
          
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                _buildQuickFilters(),
                const SizedBox(height: 16),
                _buildDateFilters(),
                const SizedBox(height: 24),
                
                // --- SECTION: ÉVÉNEMENTS GRANDIOSE ---
                _buildSectionHeader('Les Plus Attendus', '/thix-event/recommended', isPremium: true),
                const SizedBox(height: 16),
                if (recommendedEvents.isNotEmpty)
                  SizedBox(
                    height: 320, // Plus grand pour donner un aspect "Affiche de cinéma"
                    child: ListView.separated(
                      controller: _recScrollController,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      itemCount: recommendedEvents.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 16),
                      itemBuilder: (context, i) => SizedBox(
                        width: 240, 
                        child: _buildPremiumEventCard(recommendedEvents[i])
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                
                // --- BANNIÈRE VIP ---
                Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: _buildVIPBanner()),
                const SizedBox(height: 32),
                
                // --- SECTION: GRILLES ---
                _buildSectionHeader('À l\'affiche', '/thix-event/upcoming'),
                const SizedBox(height: 16),
              ]
            ),
          ),
          
          // --- GRILLE ÉVÉNEMENTS ---
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
                  onTap: () => _goToEventDetail(upcomingEvents.isNotEmpty ? upcomingEvents[index].id : allEvents[index].id)
                ),
                childCount: upcomingEvents.isNotEmpty ? upcomingEvents.length : (allEvents.length > 6 ? 6 : allEvents.length),
              ),
            ),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 120)), // Espace pour la bottom bar
        ],
      ),
      bottomNavigationBar: _buildFloatingBottomNav(),
    );
  }

  // 🟢 NOUVEAU: AppBar en Glassmorphism Premium
  PreferredSizeWidget _buildGlassAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: AppBar(
            backgroundColor: _ThixColors.premiumDark.withOpacity(0.6),
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            title: Row(
              children: [
                const Icon(Icons.flash_on_rounded, color: _ThixColors.premiumGold, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'THIX',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1),
                ),
                const Text(
                  ' EVENT',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w300, color: Colors.white, letterSpacing: 1),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                  onPressed: () {},
                ),
                InkWell(
                  onTap: () => context.push('/thix-event/admin'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _ThixColors.premiumGold.withOpacity(0.2),
                      border: Border.all(color: _ThixColors.premiumGold, width: 1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('PRO', style: TextStyle(color: _ThixColors.premiumGold, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🟢 NOUVEAU: Hero Section Edge-to-Edge Façon "Netflix/Cinéma"
  Widget _buildImmersiveHero(List<Event> featuredEvents) {
    if (featuredEvents.isEmpty) return const SizedBox(height: 350, child: Center(child: CircularProgressIndicator()));
    
    return SizedBox(
      height: 480, // Massive hauteur
      child: Stack(
        children: [
          PageView.builder(
            controller: _heroController,
            itemCount: featuredEvents.length,
            onPageChanged: (index) => setState(() => _heroCurrentPage = index),
            itemBuilder: (context, index) {
              final event = featuredEvents[index];
              return Stack(
                fit: StackFit.expand,
                children: [
                  // Image avec un effet zoom léger constant (si on voulait animer, ici juste plein écran)
                  Image.network(
                    event.imageUrl ?? '',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    errorBuilder: (_, __, ___) => Container(color: _ThixColors.primary),
                  ),
                  // Gradient cinématographique: sombre en haut (pour l'AppBar), très sombre en bas
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _ThixColors.premiumDark.withOpacity(0.6),
                          Colors.transparent,
                          _ThixColors.premiumDark.withOpacity(0.4),
                          _ThixColors.lightBg, // Se fond parfaitement avec le fond de l'app
                        ],
                        stops: const [0.0, 0.3, 0.7, 1.0],
                      ),
                    ),
                  ),
                  // Contenu du Hero
                  Positioned(
                    bottom: 40,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: _ThixColors.premiumGold, borderRadius: BorderRadius.circular(4)),
                              child: const Text('À L\'AFFICHE', style: TextStyle(color: _ThixColors.premiumDark, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                            ),
                            const SizedBox(width: 8),
                            Text(event.categoryLabel.toUpperCase(), style: const TextStyle(color: _ThixColors.premiumGold, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 2, shadows: [Shadow(color: Colors.black, blurRadius: 4)])),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          event.title,
                          style: const TextStyle(color: Colors.black87, fontSize: 32, fontWeight: FontWeight.w900, height: 1.1, letterSpacing: -1),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, color: _ThixColors.primary, size: 14),
                            const SizedBox(width: 4),
                            Text(event.location, style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _goToEventDetail(event.id),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _ThixColors.premiumDark,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 10,
                                  shadowColor: _ThixColors.premiumDark.withOpacity(0.5),
                                ),
                                child: const Text('RÉSERVER DES PLACES', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 52, height: 52,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.share_rounded, color: _ThixColors.premiumDark),
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
          // Indicateurs alignés à droite
          Positioned(
            right: 20,
            bottom: 200,
            child: Column(
              children: List.generate(featuredEvents.length, (index) {
                final isActive = index == _heroCurrentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  width: 4,
                  height: isActive ? 24 : 8,
                  decoration: BoxDecoration(
                    color: isActive ? _ThixColors.premiumGold : Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: isActive ? [const BoxShadow(color: _ThixColors.premiumGold, blurRadius: 8)] : [],
                  ),
                );
              }),
            ),
          )
        ],
      ),
    );
  }

  // 🟢 NOUVEAU: Cartes VIP Imposantes pour les "Recommandés"
  Widget _buildPremiumEventCard(Event event) {
    return GestureDetector(
      onTap: () => _goToEventDetail(event.id),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white,
          boxShadow: [BoxShadow(color: _ThixColors.primary.withOpacity(0.1), blurRadius: 24, offset: const Offset(0, 12))],
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
                  Positioned(
                    top: 12, right: 12,
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
                  )
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
                        Text(event.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _ThixColors.darkText, height: 1.1)),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(event.formattedPrice, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _ThixColors.premiumDark)),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: _ThixColors.premiumDark, shape: BoxShape.circle),
                          child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🟢 NOUVEAU: Bannière VIP / Écosystème
  Widget _buildVIPBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_ThixColors.premiumDark, Color(0xFF1E1B4B)]), 
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _ThixColors.premiumDark.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_ThixColors.premiumGold, Color(0xFFF59E0B)]),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: _ThixColors.premiumGold.withOpacity(0.5), blurRadius: 10)],
            ),
            child: const Icon(Icons.workspace_premium_rounded, color: _ThixColors.premiumDark, size: 28),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sécurisé par THIX ID', style: TextStyle(color: _ThixColors.premiumGold, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                SizedBox(height: 4),
                Text('Bénéficiez d\'un accès coupe-file et de billets infalsifiables.', style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4)),
              ],
            ),
          ),
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
          Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isPremium ? _ThixColors.premiumDark : _ThixColors.darkText, letterSpacing: -0.5)),
          GestureDetector(
            onTap: () => context.push(route),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: _ThixColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: const Row(children: [Text('Tout voir', style: TextStyle(fontSize: 10, color: _ThixColors.primary, fontWeight: FontWeight.w800)), SizedBox(width: 4), Icon(Icons.arrow_forward_rounded, size: 12, color: _ThixColors.primary)]),
            ),
          )
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
                color: isSelected ? _ThixColors.premiumDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? _ThixColors.premiumDark : _ThixColors.cardBorder),
                boxShadow: isSelected ? [BoxShadow(color: _ThixColors.premiumDark.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
              ),
              child: Row(
                children: [
                  Icon(f['icon'] as IconData, color: isSelected ? Colors.white : f['color'] as Color, size: 16),
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

  // 🟢 NOUVEAU: Barre de navigation flottante et stylisée
  Widget _buildFloatingBottomNav() {
    return Container(
      margin: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: _ThixColors.premiumDark.withOpacity(0.95),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [BoxShadow(color: _ThixColors.premiumDark.withOpacity(0.4), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: SafeArea(
        top: false, bottom: false,
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
          color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Icon(icon, color: isSelected ? Colors.white : Colors.white54, size: 24),
      ),
    );
  }

  Widget _centerNavItem() {
    return InkWell(
      onTap: () => _onNavTap(2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_ThixColors.primaryLight, _ThixColors.primary]),
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
