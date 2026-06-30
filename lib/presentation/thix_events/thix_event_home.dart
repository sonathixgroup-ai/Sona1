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
import '../../models/event_model.dart';
import 'widgets/event_card.dart';
import 'widgets/category_chip.dart';
import 'widgets/featured_event.dart';
import 'widgets/upcoming_event_item.dart';
import 'event_search_page.dart';
import 'event_detail_page.dart';

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
    // Attendre que le contexte soit disponible
    await Future.delayed(Duration.zero);
    
    if (mounted) {
      final eventProvider = Provider.of<EventProvider>(context, listen: false);
      
      // Charger les données avec gestion d'erreur
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
    context.push('/thix-event/event/${eventId}');
  }

  // ============================================================
  // NOTIFICATIONS
  // ============================================================
  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications', style: TextStyle(fontSize: 16)),
        content: const Text('Recevoir les alertes des nouveaux événements ?', style: TextStyle(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Plus tard', style: TextStyle(fontSize: 12))),
          ElevatedButton(
            onPressed: _requestNotificationPermission,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
            child: const Text('Activer', style: TextStyle(fontSize: 12)),
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

    // Afficher un loader pendant l'initialisation
    if (!_isInitialized && isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F9FA),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
          ),
        ),
      );
    }

    // Afficher une erreur si nécessaire
    if (hasError && events.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Impossible de charger les événements',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                eventProvider.error ?? 'Erreur inconnue',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
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
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: const Color(0xFF0B1B3D),
                ),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildSearchBar()),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          
          if (featuredEvent != null)
            SliverToBoxAdapter(child: FeaturedEventWidget(event: featuredEvent)),
          
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(child: _buildDateFilters()),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverToBoxAdapter(child: _buildCategorySection()),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(child: _buildSectionHeader('Événements recommandés', '/thix-event/recommended')),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          
          // Section événements recommandés
          if (isLoading && recommendedEvents.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
                  ),
                ),
              ),
            )
          else if (recommendedEvents.isEmpty && !isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    'Aucun événement disponible',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            )
          else
            SliverToBoxAdapter(
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 12),
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
            ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(child: _buildNotificationBanner()),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(child: _buildSectionHeader('Prochains événements', '/thix-event/upcoming')),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          
          // Section prochains événements
          if (isLoading && upcomingEvents.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
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
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => UpcomingEventItem(
                  event: upcomingEvents[index],
                  onTap: () => _goToEventDetail(upcomingEvents[index].id),
                ),
                childCount: upcomingEvents.length,
              ),
            ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B1B3D), Color(0xFF1A2B4D)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('THIX ÉVÉNEMENT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  SizedBox(height: 2),
                  Text('Découvrez, réservez, vivez l\'exceptionnel.', style: TextStyle(color: Colors.white70, fontSize: 10)),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.white, size: 20),
                    onPressed: () => context.push('/thix-event/search'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_none, color: Colors.white, size: 20),
                    onPressed: _showNotificationSettings,
                  ),
                  GestureDetector(
                    onTap: () => context.push('/profile'),
                    child: const CircleAvatar(radius: 14, backgroundColor: Colors.white24, child: Icon(Icons.person, size: 14, color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BARRE DE RECHERCHE
  // ============================================================
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: GestureDetector(
        onTap: () => context.push('/thix-event/search'),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 1))],
          ),
          child: const Row(
            children: [
              Icon(Icons.search, size: 16, color: Colors.grey),
              SizedBox(width: 8),
              Text('Rechercher un événement, lieu...', style: TextStyle(fontSize: 12, color: Colors.grey)),
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
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: _dateFilters.map((filter) {
          final isSelected = _selectedDateFilter == filter['value'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text(filter['label']!, style: const TextStyle(fontSize: 12)),
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedDateFilter = filter['value']!);
                  context.read<EventProvider>().fetchEvents(dateFilter: filter['value']);
                }
              },
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFFD4AF37).withOpacity(0.15),
              side: BorderSide(color: isSelected ? const Color(0xFFD4AF37) : Colors.grey[300]!),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
              const Text('Catégories populaires', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: () => context.push('/thix-event/categories'),
                child: Row(
                  children: [
                    Text('Voir tout', style: TextStyle(fontSize: 11, color: const Color(0xFFD4AF37))),
                    const SizedBox(width: 2),
                    Icon(Icons.arrow_forward_ios, size: 10, color: const Color(0xFFD4AF37)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
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
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          GestureDetector(
            onTap: () => context.push(route),
            child: Row(
              children: [
                Text('Voir tout', style: TextStyle(fontSize: 11, color: const Color(0xFFD4AF37))),
                const SizedBox(width: 2),
                Icon(Icons.arrow_forward_ios, size: 10, color: const Color(0xFFD4AF37)),
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
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B1B3D), Color(0xFF1A2B4D)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.notifications_active, color: Color(0xFFD4AF37), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ne manquez aucun événement !', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('Activez les notifications pour être informé des nouveaux événements près de vous.', style: TextStyle(color: Colors.white70, fontSize: 10)),
              ],
            ),
          ),
          GestureDetector(
            onTap: _requestNotificationPermission,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFFD4AF37), borderRadius: BorderRadius.circular(20)),
              child: const Text('Activer', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0B1B3D))),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BARRE DE NAVIGATION BOTTOM
  // ============================================================
  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFD4AF37),
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontSize: 9),
        unselectedLabelStyle: const TextStyle(fontSize: 9),
        currentIndex: _selectedNavIndex,
        onTap: _onNavTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home, size: 20), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.search, size: 20), label: 'Rechercher'),
          BottomNavigationBarItem(icon: Icon(Icons.confirmation_number, size: 20), label: 'Mes billets'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border, size: 20), label: 'Favoris'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline, size: 20), label: 'Profil'),
        ],
      ),
    );
  }
}
