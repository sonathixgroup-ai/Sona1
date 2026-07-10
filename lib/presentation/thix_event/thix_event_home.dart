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
import '../../providers/auth_provider.dart';        // ← AJOUTÉ pour le rôle
import '../../models/event_model.dart';
import 'widgets/event_card.dart';
import 'widgets/category_chip.dart';
import 'widgets/featured_event.dart';
import 'widgets/upcoming_event_item.dart';
import 'event_search_page.dart';
import 'event_detail_page.dart';

// ============================================================
// CHARTE THIX ÉVÉNEMENT — Élite Institutionnel Bleu / Blanc
// ============================================================
class _EventColors {
  static const Color navyDeep = Color(0xFF0A1F44);
  static const Color navy = Color(0xFF123B7A);
  static const Color primaryBlue = Color(0xFF2D6CDF);
  static const Color softBlue = Color(0xFFEFF5FF);
  static const Color background = Color(0xFFF7FAFF);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color darkText = Color(0xFF10192E);
  static const Color mutedText = Color(0xFF7386A8);
  static const Color border = Color(0xFFE7EEFC);
  static const Color gold = Color(0xFFE3B23C);
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
    context.push('/thix-event/event/${eventId}');
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
            onPressed: _requestNotificationPermission,
            style: ElevatedButton.styleFrom(
              backgroundColor: _EventColors.gold,
              foregroundColor: _EventColors.navyDeep,
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
        backgroundColor: _EventColors.background,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_EventColors.primaryBlue),
          ),
        ),
      );
    }

    if (hasError && events.isEmpty) {
      return Scaffold(
        backgroundColor: _EventColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(color: _EventColors.softBlue, shape: BoxShape.circle),
                child: Icon(Icons.error_outline_rounded, size: 38, color: _EventColors.navy.withOpacity(0.5)),
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
                  backgroundColor: _EventColors.navyDeep,
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
      backgroundColor: _EventColors.background,
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
          
          if (isLoading && recommendedEvents.isEmpty)
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
          else if (recommendedEvents.isEmpty && !isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    'Aucun événement disponible',
                    style: TextStyle(color: _EventColors.mutedText),
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
  // HEADER — dégradé incurvé bleu institutionnel
  // ============================================================
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_EventColors.navyDeep, _EventColors.navy, _EventColors.primaryBlue],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(26),
          bottomRight: Radius.circular(26),
        ),
        boxShadow: [
          BoxShadow(color: Color(0x332D6CDF), blurRadius: 22, offset: Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), borderRadius: BorderRadius.circular(9)),
                        child: const Icon(Icons.event_rounded, size: 15, color: _EventColors.gold),
                      ),
                      const SizedBox(width: 7),
                      const Text('THIX ÉVÉNEMENT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15.5, letterSpacing: 0.4)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('Découvrez, réservez, vivez l\'exceptionnel.', style: TextStyle(color: Colors.white70, fontSize: 10)),
                ],
              ),
              Row(
                children: [
                  _headerIconButton(Icons.search_rounded, () => context.push('/thix-event/search')),
                  _headerIconButton(Icons.notifications_none_rounded, _showNotificationSettings),

                  // 👇 BOUTON MODÉRATEUR TOUJOURS VISIBLE (test)
                  _headerIconButton(
                    Icons.admin_panel_settings_rounded,
                    () => context.push('/moderator'),
                  ),

                  GestureDetector(
                    onTap: () => context.push('/profile'),
                    child: Container(
                      width: 30,
                      height: 30,
                      margin: const EdgeInsets.only(left: 2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.14),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: const Icon(Icons.person_rounded, size: 15, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerIconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(11),
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 17),
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
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: _EventColors.pureWhite,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _EventColors.border),
            boxShadow: [BoxShadow(color: _EventColors.navyDeep.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: const Row(
            children: [
              Icon(Icons.search_rounded, size: 17, color: _EventColors.mutedText),
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
      padding: const EdgeInsets.symmetric(horizontal: 12),
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected ? const LinearGradient(colors: [_EventColors.navyDeep, _EventColors.primaryBlue]) : null,
                  color: isSelected ? null : _EventColors.pureWhite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? Colors.transparent : _EventColors.border),
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
              const Text('Catégories populaires', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: _EventColors.darkText)),
              GestureDetector(
                onTap: () => context.push('/thix-event/categories'),
                child: const Row(
                  children: [
                    Text('Voir tout', style: TextStyle(fontSize: 11.5, color: _EventColors.primaryBlue, fontWeight: FontWeight.w700)),
                    SizedBox(width: 2),
                    Icon(Icons.arrow_forward_ios_rounded, size: 10, color: _EventColors.primaryBlue),
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
          Text(title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: _EventColors.darkText)),
          GestureDetector(
            onTap: () => context.push(route),
            child: const Row(
              children: [
                Text('Voir tout', style: TextStyle(fontSize: 11.5, color: _EventColors.primaryBlue, fontWeight: FontWeight.w700)),
                SizedBox(width: 2),
                Icon(Icons.arrow_forward_ios_rounded, size: 10, color: _EventColors.primaryBlue),
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
          colors: [_EventColors.navyDeep, _EventColors.navy, _EventColors.primaryBlue],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: _EventColors.navyDeep.withOpacity(0.18), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.notifications_active_rounded, color: _EventColors.gold, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ne manquez aucun événement !', style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text('Activez les notifications pour être informé des nouveaux événements près de vous.', style: TextStyle(color: Colors.white.withOpacity(0.72), fontSize: 9.5, height: 1.3)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _requestNotificationPermission,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              decoration: BoxDecoration(color: _EventColors.gold, borderRadius: BorderRadius.circular(20)),
              child: const Text('Activer', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _EventColors.navyDeep)),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BARRE DE NAVIGATION BOTTOM — flottante, incurvée
  // ============================================================
  Widget _buildBottomNavBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      decoration: BoxDecoration(
        color: _EventColors.pureWhite,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(color: _EventColors.navyDeep.withOpacity(0.12), blurRadius: 22, offset: const Offset(0, 9)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home_rounded, 'Accueil', 0),
              _navItem(Icons.search_rounded, 'Rechercher', 1),
              _navItem(Icons.confirmation_number_rounded, 'Mes billets', 2),
              _navItem(Icons.favorite_border_rounded, 'Favoris', 3),
              _navItem(Icons.person_outline_rounded, 'Profil', 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final isSelected = _selectedNavIndex == index;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _onNavTap(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: isSelected ? _EventColors.softBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: isSelected ? _EventColors.primaryBlue : _EventColors.mutedText, size: 20),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                color: isSelected ? _EventColors.primaryBlue : _EventColors.mutedText,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
