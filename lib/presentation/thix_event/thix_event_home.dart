// lib/presentation/thix_event/thix_event_home.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/event_provider.dart';
import '../../models/event_model.dart';
import 'widgets/event_card.dart';
import 'widgets/category_chip.dart';
import 'widgets/upcoming_event_item.dart';

class _ThixColors {
  // Violet THIX Vibrant et "réflectant"
  static const Color primary = Color(0xFF6B3CE2); 
  static const Color primaryLight = Color(0xFF8B5CF6);
  static const Color primaryGradientEnd = Color(0xFF5A2ECA); // Pour donner de la profondeur
  
  static const Color lightBg = Color(0xFFF8F7FF);
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

  // --- HERO BANNER : carrousel auto-scrollant sur eventProvider.featuredEvents ---
  final PageController _heroController = PageController(viewportFraction: 0.92);
  Timer? _heroAutoScrollTimer;
  int _heroCurrentPage = 0;
  int _heroTrackedCount = -1; 

  final List<Map<String, dynamic>> _quickFilters = [
    {'value': 'all', 'label': 'Tous les\névénements', 'icon': Icons.calendar_month_rounded, 'color': _ThixColors.primary},
    {'value': 'concert', 'label': 'Concerts', 'icon': Icons.music_note_rounded, 'color': const Color(0xFFEC4899)},
    {'value': 'spectacle', 'label': 'Spectacles', 'icon': Icons.theater_comedy_rounded, 'color': const Color(0xFFF59E0B)},
    {'value': 'conference', 'label': 'Conférences', 'icon': Icons.mic_rounded, 'color': const Color(0xFF3B82F6)},
    {'value': 'sport', 'label': 'Sport', 'icon': Icons.emoji_events_rounded, 'color': const Color(0xFF10B981)},
    {'value': 'more', 'label': 'Plus', 'icon': Icons.more_horiz_rounded, 'color': const Color(0xFF9CA3AF)},
  ];

  final List<Map<String, String>> _dateFilters = [
    {'value': 'all', 'label': 'Tous'},
    {'value': 'today', 'label': 'Aujourd\'hui'},
    {'value': 'week', 'label': 'Cette semaine'},
    {'value': 'month', 'label': 'Ce mois'},
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
    }
  }

  void _maybeRestartHeroAutoScroll(int count) {
    if (count == _heroTrackedCount) return;
    _heroTrackedCount = count;
    _heroCurrentPage = 0;
    _heroAutoScrollTimer?.cancel();
    if (count <= 1) return;
    _heroAutoScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted || !_heroController.hasClients) return;
      final provider = Provider.of<EventProvider>(context, listen: false);
      final total = provider.featuredEvents.length;
      if (total == 0) return;
      final nextPage = (_heroCurrentPage + 1) % total;
      _heroController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _heroAutoScrollTimer?.cancel();
    _heroController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == 2) {
      context.push('/thix-event/my-tickets');
      return;
    }
    setState(() => _selectedNavIndex = index);
    HapticFeedback.lightImpact();
    switch (index) {
      case 0: break;
      case 1: context.push('/thix-event/search'); break;
      case 3: context.push('/thix-event/favorites'); break;
      case 4: context.push('/profile'); break;
    }
  }

  void _onDateFilterTap(String value) {
    if (_selectedDateFilter == value) return;
    setState(() => _selectedDateFilter = value);
    HapticFeedback.selectionClick();
    context.read<EventProvider>().setDateFilter(value);
  }

  void _goToEventDetail(String eventId) => context.push('/thix-event/event/$eventId');

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Notifications', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _ThixColors.darkText)),
        content: const Text('Recevoir les alertes des nouveaux événements ?', style: TextStyle(fontSize: 11, color: _ThixColors.mutedText)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Plus tard', style: TextStyle(fontSize: 11, color: Colors.grey))),
          ElevatedButton(
            onPressed: () { Navigator.pop(ctx); _requestNotificationPermission(); },
            style: ElevatedButton.styleFrom(
              backgroundColor: _ThixColors.primary, 
              foregroundColor: Colors.white, 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), 
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)
            ),
            child: const Text('Activer', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  void _requestNotificationPermission() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Notifications activées', style: TextStyle(fontSize: 11)), 
      backgroundColor: _ThixColors.primary,
      duration: Duration(seconds: 2)
    ));
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = Provider.of<EventProvider>(context);
    final featuredEvents = eventProvider.featuredEvents;
    final events = eventProvider.upcomingEvents;
    
    // 🟢 VRAIE LOGIQUE DE FILTRAGE
    // Événements Recommandés (Ceux dont la case a été cochée dans l'admin)
    final recommendedEvents = events.where((e) => e.isRecommended).toList();
    
    // Prochains événements (Les événements à venir qui ne sont ni recommandés ni à la une)
    final upcomingEvents = events.where((e) => !e.isRecommended && !e.isFeatured).take(5).toList();
    
    // Tous les événements (Pour la section du bas)
    final allEvents = events;
    
    final isLoading = eventProvider.isLoading;
    final hasError = eventProvider.error != null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeRestartHeroAutoScroll(featuredEvents.length);
    });

    if (!_isInitialized && isLoading) {
      return const Scaffold(backgroundColor: _ThixColors.lightBg, body: Center(child: CircularProgressIndicator(color: _ThixColors.primary, strokeWidth: 2)));
    }
    
    if (hasError && events.isEmpty) {
      return Scaffold(
        backgroundColor: _ThixColors.lightBg,
        body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 64, height: 64, decoration: BoxDecoration(color: _ThixColors.primary.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.error_outline_rounded, size: 28, color: _ThixColors.primary)),
            const SizedBox(height: 12),
            const Text('Impossible de charger', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _ThixColors.darkText)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () { eventProvider.clearError(); eventProvider.fetchEvents(); eventProvider.fetchFeaturedEvents(); }, 
              style: ElevatedButton.styleFrom(backgroundColor: _ThixColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)), 
              child: const Text('Réessayer', style: TextStyle(color: Colors.white, fontSize: 11))
            )
          ]),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _ThixColors.lightBg,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildTopBar(),
          SliverToBoxAdapter(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 8),
              _buildHeroBanner(featuredEvents),
              const SizedBox(height: 10),
              _buildQuickFilters(),
              const SizedBox(height: 10),
              _buildDateFilters(),
              const SizedBox(height: 12),
              _buildCategorySection(),
              const SizedBox(height: 18),
              
              // --- SECTION: RECOMMANDÉS ---
              _buildSectionHeader('Événements recommandés', '/thix-event/recommended'),
              const SizedBox(height: 8),
              if (isLoading && recommendedEvents.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: _ThixColors.primary, strokeWidth: 2)))
              else if (recommendedEvents.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Aucune recommandation pour le moment.', style: TextStyle(color: _ThixColors.mutedText, fontSize: 11))))
              else
                SizedBox(
                  height: 210,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: recommendedEvents.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) => SizedBox(width: 140, child: EventCard(event: recommendedEvents[i], onTap: () => _goToEventDetail(recommendedEvents[i].id))),
                  ),
                ),
              const SizedBox(height: 18),
              
              // --- BANNIÈRE DE NOTIFICATION ---
              Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: _buildNotificationBanner()),
              const SizedBox(height: 18),
              
              // --- SECTION: PROCHAINS ÉVÉNEMENTS ---
              _buildSectionHeader('Prochains événements', '/thix-event/upcoming'),
              const SizedBox(height: 8),
            ]),
          ),
          
          // LISTE PROCHAINS ÉVÉNEMENTS
          if (isLoading && upcomingEvents.isEmpty)
            const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: _ThixColors.primary, strokeWidth: 2))))
          else if (upcomingEvents.isEmpty)
            const SliverToBoxAdapter(
              child: Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Aucun événement à venir.', style: TextStyle(color: _ThixColors.mutedText, fontSize: 11)))),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(padding: const EdgeInsets.only(bottom: 8), child: UpcomingEventItem(event: upcomingEvents[index], onTap: () => _goToEventDetail(upcomingEvents[index].id))),
                  childCount: upcomingEvents.length,
                ),
              ),
            ),
            
          // --- SECTION: TOUS LES ÉVÉNEMENTS (NOUVEAU) ---
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildSectionHeader('Tous les événements', '/thix-event/search'),
                const SizedBox(height: 8),
              ],
            ),
          ),
          
          // LISTE TOUS LES ÉVÉNEMENTS
          if (allEvents.isEmpty)
            const SliverToBoxAdapter(
              child: Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Aucun événement disponible.', style: TextStyle(color: _ThixColors.mutedText, fontSize: 11)))),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(padding: const EdgeInsets.only(bottom: 8), child: UpcomingEventItem(event: allEvents[index], onTap: () => _goToEventDetail(allEvents[index].id))),
                  childCount: allEvents.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 90)), // Espace pour la BottomNavBar
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildTopBar() {
    const int unreadCount = 0;

    return SliverAppBar(
      pinned: true,
      floating: true,
      elevation: 0,
      backgroundColor: _ThixColors.pureWhite,
      toolbarHeight: 54,
      automaticallyImplyLeading: false,
      title: Row(children: [
        Container(width: 32, height: 32, decoration: BoxDecoration(color: _ThixColors.lightBg, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.menu_rounded, color: _ThixColors.darkText, size: 18)),
        const SizedBox(width: 8),
        Container(width: 28, height: 28, decoration: BoxDecoration(gradient: const LinearGradient(colors: [_ThixColors.primaryLight, _ThixColors.primary]), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 16)),
        const SizedBox(width: 6),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Row(children: [
            Text('THIX ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: _ThixColors.darkText, letterSpacing: -0.3)),
            Text('ÉVÉNEMENT', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: _ThixColors.primary, letterSpacing: -0.3))
          ]),
          Text('Découvrez, réservez, vivez l\'exceptionnel.', style: TextStyle(fontSize: 8.5, color: _ThixColors.mutedText, fontWeight: FontWeight.w500, height: 1)),
        ])),
        Stack(clipBehavior: Clip.none, children: [
          InkWell(onTap: _showNotificationSettings, borderRadius: BorderRadius.circular(16), child: Container(width: 32, height: 32, decoration: BoxDecoration(color: _ThixColors.lightBg, shape: BoxShape.circle, border: Border.all(color: _ThixColors.cardBorder, width: 0.8)), child: const Icon(Icons.notifications_none_rounded, size: 16, color: _ThixColors.darkText))),
          if (unreadCount > 0)
            Positioned(
              top: -2, right: -1,
              child: Container(
                width: 14, height: 14,
                decoration: const BoxDecoration(color: _ThixColors.primary, shape: BoxShape.circle),
                child: Center(child: Text(unreadCount > 9 ? '9+' : '$unreadCount', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white))),
              ),
            ),
        ]),
        const SizedBox(width: 8),
        InkWell(
          onTap: () => context.push('/thix-event/admin'),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF0A1F44), // Bleu Marine Admin
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE3B23C), width: 1.5), // Or Admin
            ),
            child: const Icon(Icons.admin_panel_settings_rounded, size: 16, color: Color(0xFFE3B23C)),
          ),
        ),
      ]),
    );
  }

  Widget _buildHeroBanner(List<Event> featuredEvents) {
    if (featuredEvents.isEmpty) {
      return _buildHeroBannerEmptyState();
    }

    return SizedBox(
      height: 172,
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _heroController,
              itemCount: featuredEvents.length,
              onPageChanged: (index) => setState(() => _heroCurrentPage = index),
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _buildHeroSlide(featuredEvents[index]),
              ),
            ),
          ),
          if (featuredEvents.length > 1) ...[
            const SizedBox(height: 8),
            _buildHeroDotsIndicator(featuredEvents.length),
          ],
        ],
      ),
    );
  }

  Widget _buildHeroSlide(Event event) {
    final title = event.title;
    final subtitle = event.city.isNotEmpty ? '${event.categoryLabel} • ${event.city}' : event.categoryLabel;

    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: _ThixColors.primary),
      clipBehavior: Clip.antiAlias,
      child: Stack(fit: StackFit.expand, children: [
        if (event.imageUrl != null && event.imageUrl!.isNotEmpty)
          Image.network(
            event.imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: _ThixColors.primary),
          )
        else
          Container(
            decoration: const BoxDecoration(gradient: LinearGradient(colors: [_ThixColors.primaryLight, _ThixColors.primaryGradientEnd])),
          ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [_ThixColors.primary.withOpacity(0.9), _ThixColors.primary.withOpacity(0.6), Colors.transparent],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (event.isFeatured)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(5)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.star_rounded, size: 9, color: Colors.white),
                    SizedBox(width: 3),
                    Text('À LA UNE', style: TextStyle(color: Colors.white, fontSize: 7.5, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  ]),
                ),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, height: 1.1),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xEEFFFFFF), fontSize: 9, height: 1.2),
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: () => _goToEventDetail(event.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: _ThixColors.primaryLight, borderRadius: BorderRadius.circular(8)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(
                      event.isFree ? 'Voir l\'événement gratuit' : 'Réserver maintenant',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded, size: 10, color: Colors.white),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildHeroBannerEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        height: 148,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: _ThixColors.primary),
        clipBehavior: Clip.antiAlias,
        child: Stack(children: [
          Positioned.fill(
            child: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [_ThixColors.primaryLight, _ThixColors.primaryGradientEnd]))),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Vivez des moments\ninoubliables.', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, height: 1.1)),
                const SizedBox(height: 4),
                const Text('Concerts, festivals, conférences,\nspectacles et plus encore.', style: TextStyle(color: Color(0xEEFFFFFF), fontSize: 9, height: 1.2)),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () => context.push('/thix-event/search'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: _ThixColors.primaryLight, borderRadius: BorderRadius.circular(8)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('Découvrir les événements', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 10, color: Colors.white),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildHeroDotsIndicator(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == _heroCurrentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: isActive ? 16 : 5,
          height: 5,
          decoration: BoxDecoration(
            color: isActive ? _ThixColors.primary : _ThixColors.cardBorder,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  Widget _buildQuickFilters() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: _ThixColors.cardBorder, width: 0.8)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(children: _quickFilters.map((f) {
          final isSelected = _selectedQuickFilter == f['value'];
          final color = f['color'] as Color;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () {
                if (f['value'] == 'more') { context.push('/thix-event/categories'); return; }
                setState(() => _selectedQuickFilter = f['value'] as String);
                context.read<EventProvider>().setCategory(f['value'] == 'all' ? 'all' : f['value'] as String);
              },
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 48,
                child: Column(children: [
                  Container(width: 32, height: 32, decoration: BoxDecoration(color: isSelected ? color.withOpacity(0.18) : color.withOpacity(0.08), borderRadius: BorderRadius.circular(9), border: isSelected ? Border.all(color: color, width: 1) : null), child: Icon(f['icon'] as IconData, color: color, size: 16)),
                  const SizedBox(height: 3),
                  Text(f['label'] as String, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 8, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600, color: isSelected ? _ThixColors.darkText : _ThixColors.mutedText, height: 1.1)),
                ]),
              ),
            ),
          );
        }).toList()),
      ),
    );
  }

  Widget _buildDateFilters() {
    return SizedBox(
      height: 30,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _dateFilters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final filter = _dateFilters[index];
          final isSelected = _selectedDateFilter == filter['value'];
          return InkWell(
            onTap: () => _onDateFilterTap(filter['value']!),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? _ThixColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? _ThixColors.primary : _ThixColors.cardBorder, width: 1),
              ),
              child: Center(
                child: Text(
                  filter['label']!,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? Colors.white : _ThixColors.mutedText,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategorySection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Catégories populaires', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _ThixColors.darkText)), GestureDetector(onTap: () => context.push('/thix-event/categories'), child: const Row(children: [Text('Voir tout', style: TextStyle(fontSize: 10, color: _ThixColors.primary, fontWeight: FontWeight.w700)), SizedBox(width: 1), Icon(Icons.chevron_right_rounded, size: 14, color: _ThixColors.primary)]))])),
      const SizedBox(height: 6),
      const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: CategoryChipsList()),
    ]);
  }

  Widget _buildSectionHeader(String title, String route) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _ThixColors.darkText)), GestureDetector(onTap: () => context.push(route), child: const Row(children: [Text('Voir tout', style: TextStyle(fontSize: 10, color: _ThixColors.primary, fontWeight: FontWeight.w700)), Icon(Icons.chevron_right_rounded, size: 14, color: _ThixColors.primary)]))]));
  }

  Widget _buildNotificationBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_ThixColors.primaryLight, _ThixColors.primary]), 
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: _ThixColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.confirmation_number_rounded, color: Colors.white, size: 18)),
        const SizedBox(width: 10),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Ne manquez aucun événement !', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)), SizedBox(height: 1), Text('Activez les notifications pour être informé.', style: TextStyle(color: Color(0xEEFFFFFF), fontSize: 8.5, height: 1.2))])),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: _requestNotificationPermission, 
          icon: const Icon(Icons.notifications_active_rounded, size: 12, color: _ThixColors.primary), 
          label: const Text('Activer', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: _ThixColors.primary)), 
          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), minimumSize: const Size(0, 0))
        ),
      ]),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 6))], border: Border.all(color: _ThixColors.cardBorder, width: 0.8)),
      child: SafeArea(top: false, child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_navItem(Icons.home_rounded, 'Accueil', 0), _navItem(Icons.search_rounded, 'Rechercher', 1), _centerNavItem(), _navItem(Icons.favorite_border_rounded, 'Favoris', 3), _navItem(Icons.person_outline_rounded, 'Profil', 4)])),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final isSelected = _selectedNavIndex == index;
    return InkWell(onTap: () => _onNavTap(index), borderRadius: BorderRadius.circular(12), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: isSelected ? _ThixColors.primary : _ThixColors.mutedText, size: 18), const SizedBox(height: 1), Text(label, style: TextStyle(fontSize: 8, color: isSelected ? _ThixColors.primary : _ThixColors.mutedText, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500))])));
  }

  Widget _centerNavItem() {
    return InkWell(
      onTap: () => _onNavTap(2), 
      child: Container(
        width: 52, height: 52, 
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_ThixColors.primaryLight, _ThixColors.primary]), 
          shape: BoxShape.circle, 
          boxShadow: [BoxShadow(color: _ThixColors.primary.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))]
        ), 
        child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.confirmation_number_rounded, color: Colors.white, size: 16), SizedBox(height: 1), Text('Mes billets', style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.w800))])
      )
    );
  }
}
