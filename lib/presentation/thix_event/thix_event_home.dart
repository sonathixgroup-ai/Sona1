// lib/presentation/thix_event/thix_event_home.dart
// ============================================================
// IMPORTS
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../providers/event_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/event_model.dart';
import 'widgets/event_card.dart';
import 'widgets/category_chip.dart';
import 'widgets/featured_event.dart';
import 'widgets/upcoming_event_item.dart';
import 'event_search_page.dart';
import 'event_detail_page.dart';

// ============================================================
// CHARTE GRAPHIQUE UNIFIÉE — Style "Mon Pays"
// ============================================================
class _EventColors {
  static const Color primaryBlue = Color(0xFF0B3D91);
  static const Color lightBg = Color(0xFFF6F8FB);
  static const Color gold = Color(0xFFF7C948);
  static const Color rdcRed = Color(0xFFCE1126);
  static const Color mutedText = Color(0xFF6B7690);
  static const Color cardBorder = Color(0xFFEEF1F7);
  static const Color darkText = Color(0xFF10182B);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color softBlue = Color(0xFFEEF1F7);
}

// ============================================================
// PAGE PRINCIPALE
// ============================================================
class ThixEventHome extends StatefulWidget {
  const ThixEventHome({super.key});

  @override
  State<ThixEventHome> createState() => _ThixEventHomeState();
}

class _ThixEventHomeState extends State<ThixEventHome> {
  // ============================================================
  // VARIABLES
  // ============================================================
  final ScrollController _scrollController = ScrollController();
  int _selectedNavIndex = 0;
  bool _isInitialized = false;

  final List<Map<String, String>> _dateFilters = [
    {'value': 'today', 'label': "Aujourd'hui"},
    {'value': 'week', 'label': 'Cette semaine'},
    {'value': 'month', 'label': 'Ce mois'},
    {'value': 'all', 'label': 'Tous'},
  ];
  String _selectedDateFilter = 'all';

  // ============================================================
  // CYCLE DE VIE
  // ============================================================
  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await Future.delayed(Duration.zero);
    
    if (mounted) {
      final eventProvider = Provider.of<EventProvider>(context, listen: false);
      
      try {
        await Future.wait([
          eventProvider.fetchEvents(),
          eventProvider.fetchFeaturedEvents(),
        ]);
      } catch (e) {
        debugPrint('❌ Erreur lors du chargement initial: $e');
      }
      
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ============================================================
  // NAVIGATION
  // ============================================================
  void _onNavTap(int index) {
    setState(() => _selectedNavIndex = index);
    HapticFeedback.lightImpact();
    
    switch (index) {
      case 0:
        break;
      case 1:
        context.push('/thix-event/search');
        break;
      case 2:
        context.push('/thix-event/my-tickets');
        break;
      case 3:
        context.push('/thix-event/favorites');
        break;
      case 4:
        context.push('/profile');
        break;
    }
  }

  void _goToEventDetail(String eventId) {
    context.push('/thix-event/event/$eventId');
  }

  // ============================================================
  // NOTIFICATIONS
  // ============================================================
  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Notifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _EventColors.darkText)),
        content: const Text('Recevoir les alertes des nouveaux événements ?', style: TextStyle(fontSize: 13, color: _EventColors.mutedText)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Plus tard', style: TextStyle(fontSize: 12))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _requestNotificationPermission();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _EventColors.gold,
              foregroundColor: _EventColors.primaryBlue,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Activer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _requestNotificationPermission() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notifications activées'), duration: Duration(seconds: 1)),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final eventProvider = Provider.of<EventProvider>(context);
    final featuredEvent = eventProvider.featuredEvent;
    final events = eventProvider.upcomingEvents;
    final recommendedEvents = events.take(4).toList();
    final upcomingEvents = events.skip(4).take(6).toList();
    final isLoading = eventProvider.isLoading;
    final hasError = eventProvider.error != null;

    if (!_isInitialized && isLoading) {
      return const Scaffold(
        backgroundColor: _EventColors.lightBg,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_EventColors.primaryBlue),
          ),
        ),
      );
    }

    if (hasError && events.isEmpty) {
      return Scaffold(
        backgroundColor: _EventColors.lightBg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(color: _EventColors.softBlue, shape: BoxShape.circle),
                child: Icon(Icons.error_outline_rounded, size: 38, color: _EventColors.primaryBlue.withOpacity(0.5)),
              ),
              const SizedBox(height: 16),
              const Text(
                'Impossible de charger les événements',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _EventColors.darkText),
              ),
              const SizedBox(height: 8),
              Text(
                eventProvider.error ?? 'Erreur inconnue',
                style: const TextStyle(fontSize: 12, color: _EventColors.mutedText),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  eventProvider.clearError();
                  eventProvider.fetchEvents();
                  eventProvider.fetchFeaturedEvents();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _EventColors.primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Réessayer', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _EventColors.lightBg,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildTopBar(),
          
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 12),
                _buildSearchBar(),
                const SizedBox(height: 16),
                
                if (featuredEvent != null)
                  FeaturedEventWidget(event: featuredEvent),
                
                const SizedBox(height: 20),
                _buildDateFilters(),
                const SizedBox(height: 20),
                _buildCategorySection(),
                const SizedBox(height: 20),
                
                // Section Événements recommandés
                _buildSectionHeader('Événements recommandés', '/thix-event/recommended'),
                const SizedBox(height: 12),
                
                if (isLoading && recommendedEvents.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(_EventColors.primaryBlue),
                      ),
                    ),
                  )
                else if (recommendedEvents.isEmpty && !isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'Aucun événement disponible',
                        style: TextStyle(color: _EventColors.mutedText),
                      ),
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: recommendedEvents.length,
                    itemBuilder: (context, index) => EventCard(
                      event: recommendedEvents[index],
                      onTap: () => _goToEventDetail(recommendedEvents[index].id),
                    ),
                  ),
                
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildNotificationBanner(),
                ),
                const SizedBox(height: 20),
                
                // Section Prochains Événements
                _buildSectionHeader('Prochains événements', '/thix-event/upcoming'),
                const SizedBox(height: 12),
              ],
            ),
          ),
          
          if (isLoading && upcomingEvents.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(_EventColors.primaryBlue),
                  ),
                ),
              ),
            )
          else if (upcomingEvents.isEmpty && !isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    'Aucun événement à venir',
                    style: TextStyle(color: _EventColors.mutedText),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => UpcomingEventItem(
                    event: upcomingEvents[index],
                    onTap: () => _goToEventDetail(upcomingEvents[index].id),
                  ),
                  childCount: upcomingEvents.length,
                ),
              ),
            ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 110)), // Espace pour la barre de navigation
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // ============================================================
  // HEADER — Style "Mon Pays" (AppBar blanche avec badges)
  // ============================================================
  Widget _buildTopBar() {
    return SliverAppBar(
      pinned: true,
      floating: true,
      elevation: 0,
      backgroundColor: Colors.white,
      toolbarHeight: 64,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          const Icon(Icons.menu, color: _EventColors.primaryBlue, size: 28),
          const SizedBox(width: 12),
          Container(
            width: 32, 
            height: 22, 
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(3), color: _EventColors.primaryBlue), 
            child: const Center(
              child: Icon(Icons.event_rounded, color: Colors.white, size: 14)
            )
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('THIX ÉVÉNEMENT\nRÉPUBLIQUE DÉMOCRATIQUE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _EventColors.primaryBlue, height: 1.1))
          ),
          
          _circleIcon(Icons.admin_panel_settings_rounded, () => context.push('/moderator')),
          const SizedBox(width: 8),
          
          Stack(
            clipBehavior: Clip.none, 
            children: [
              _circleIcon(Icons.notifications_none_rounded, _showNotificationSettings),
              Positioned(
                top: -4, 
                right: -4, 
                child: Container(
                  padding: const EdgeInsets.all(4), 
                  decoration: const BoxDecoration(color: _EventColors.gold, shape: BoxShape.circle), 
                  child: const Text('3', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: _EventColors.primaryBlue))
                )
              ),
            ]
          ),
          const SizedBox(width: 8),
          
          InkWell(
            onTap: () => context.push('/profile'), 
            child: const CircleAvatar(radius: 18, backgroundImage: NetworkImage('https://i.pravatar.cc/100'))
          ),
        ],
      ),
    );
  }

  Widget _circleIcon(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(8), 
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _EventColors.cardBorder), color: Colors.white), 
        child: Icon(icon, size: 20, color: _EventColors.primaryBlue)
      ),
    );
  }

  // ============================================================
  // BARRE DE RECHERCHE
  // ============================================================
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => context.push('/thix-event/search'),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: _EventColors.pureWhite,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _EventColors.cardBorder),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: const Row(
            children: [
              Icon(Icons.search_rounded, size: 18, color: _EventColors.mutedText),
              SizedBox(width: 9),
              Text('Rechercher un événement, lieu...', style: TextStyle(fontSize: 12.5, color: _EventColors.mutedText)),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FILTRES DE DATE
  // ============================================================
  Widget _buildDateFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: _dateFilters.map((filter) {
          final isSelected = _selectedDateFilter == filter['value'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                setState(() => _selectedDateFilter = filter['value']!);
                context.read<EventProvider>().fetchEvents(dateFilter: filter['value']);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? _EventColors.primaryBlue : _EventColors.pureWhite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? Colors.transparent : _EventColors.cardBorder),
                  boxShadow: isSelected
                      ? [BoxShadow(color: _EventColors.primaryBlue.withOpacity(0.28), blurRadius: 10, offset: const Offset(0, 4))]
                      : null,
                ),
                child: Text(
                  filter['label']!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : _EventColors.darkText,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ============================================================
  // SECTION CATÉGORIES
  // ============================================================
  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Catégories populaires', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _EventColors.primaryBlue)),
              GestureDetector(
                onTap: () => context.push('/thix-event/categories'),
                child: const Row(
                  children: [
                    Text('Voir tout', style: TextStyle(fontSize: 12, color: Color(0xFF5B8DEF), fontWeight: FontWeight.w700)),
                    SizedBox(width: 2),
                    Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF5B8DEF)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const CategoryChipsList(),
      ],
    );
  }

  // ============================================================
  // EN-TÊTE DE SECTION
  // ============================================================
  Widget _buildSectionHeader(String title, String route) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _EventColors.primaryBlue)),
          GestureDetector(
            onTap: () => context.push(route),
            child: const Row(
              children: [
                Text('Voir tout', style: TextStyle(fontSize: 12, color: Color(0xFF5B8DEF), fontWeight: FontWeight.w700)),
                SizedBox(width: 2),
                Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF5B8DEF)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BANNIÈRE NOTIFICATIONS
  // ============================================================
  Widget _buildNotificationBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _EventColors.primaryBlue,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: _EventColors.primaryBlue.withOpacity(0.2), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.star, color: _EventColors.gold, size: 28),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Alerte Événements', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                SizedBox(height: 2),
                Text('Activez les alertes pour ne rien rater.', style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.3)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _requestNotificationPermission,
            style: ElevatedButton.styleFrom(
              backgroundColor: _EventColors.gold,
              foregroundColor: _EventColors.primaryBlue,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Activer', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BARRE DE NAVIGATION BOTTOM — flottante, style Mon Pays
  // ============================================================
  Widget _buildBottomNavBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16), 
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), 
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(30), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20)]
      ), 
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround, 
          children: [
            _navItem(Icons.home_rounded, 'Accueil', 0), 
            _navItem(Icons.search_rounded, 'Recherche', 1), 
            _navItem(Icons.confirmation_number_rounded, 'Billets', 2), 
            _navItem(Icons.favorite_border_rounded, 'Favoris', 3), 
            _navItem(Icons.person_outline_rounded, 'Profil', 4),
          ]
        ),
      )
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final isSelected = _selectedNavIndex == index;
    return InkWell(
      onTap: () => _onNavTap(index), 
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? _EventColors.primaryBlue : _EventColors.mutedText, size: 22), 
          Text(label, style: TextStyle(fontSize: 10, color: isSelected ? _EventColors.primaryBlue : _EventColors.mutedText, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal))
        ]
      )
    );
  }
}
