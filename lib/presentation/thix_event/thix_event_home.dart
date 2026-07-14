// lib/presentation/thix_event/thix_event_home.dart
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
  static const Color primary = Color(0xFF6B3BFF);
  static const Color primaryLight = Color(0xFF7C3AED);
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

  final List<Map<String, dynamic>> _quickFilters = [
    {'value': 'all', 'label': 'Tous les\nevenements', 'icon': Icons.calendar_month_rounded, 'color': const Color(0xFF6B3BFF)},
    {'value': 'concert', 'label': 'Concerts', 'icon': Icons.music_note_rounded, 'color': const Color(0xFFEC4899)},
    {'value': 'spectacle', 'label': 'Spectacles', 'icon': Icons.theater_comedy_rounded, 'color': const Color(0xFFF59E0B)},
    {'value': 'conference', 'label': 'Conferences', 'icon': Icons.mic_rounded, 'color': const Color(0xFF3B82F6)},
    {'value': 'sport', 'label': 'Sport', 'icon': Icons.emoji_events_rounded, 'color': const Color(0xFF10B981)},
    {'value': 'more', 'label': 'Plus', 'icon': Icons.more_horiz_rounded, 'color': const Color(0xFF9CA3AF)},
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
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
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

  void _goToEventDetail(String eventId) => context.push('/thix-event/event/$eventId');

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Notifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _ThixColors.darkText)),
        content: const Text('Recevoir les alertes des nouveaux evenements?', style: TextStyle(fontSize: 13, color: _ThixColors.mutedText)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Plus tard')),
          ElevatedButton(
            onPressed: () { Navigator.pop(ctx); _requestNotificationPermission(); },
            style: ElevatedButton.styleFrom(backgroundColor: _ThixColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: const Text('Activer', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _requestNotificationPermission() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notifications activees'), duration: Duration(seconds: 1)));
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = Provider.of<EventProvider>(context);
    final featuredEvent = eventProvider.featuredEvent;
    final events = eventProvider.upcomingEvents;
    final recommendedEvents = events.take(4).toList();
    final upcomingEvents = events.skip(4).take(6).toList();
    final isLoading = eventProvider.isLoading;
    final hasError = eventProvider.error!= null;

    if (!_isInitialized && isLoading) {
      return const Scaffold(backgroundColor: _ThixColors.lightBg, body: Center(child: CircularProgressIndicator(color: _ThixColors.primary)));
    }
    if (hasError && events.isEmpty) {
      return Scaffold(
        backgroundColor: _ThixColors.lightBg,
        body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 84, height: 84, decoration: const BoxDecoration(color: Color(0xFFEEE9FF), shape: BoxShape.circle), child: Icon(Icons.error_outline_rounded, size: 38, color: Color(0x886B3BFF))),
            const SizedBox(height: 16),
            const Text('Impossible de charger les evenements', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _ThixColors.darkText)),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: () { eventProvider.clearError(); eventProvider.fetchEvents(); eventProvider.fetchFeaturedEvents(); }, style: ElevatedButton.styleFrom(backgroundColor: _ThixColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: const Text('Reessayer', style: TextStyle(color: Colors.white)))
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
              const SizedBox(height: 12),
              _buildHeroBanner(featuredEvent),
              const SizedBox(height: 16),
              _buildQuickFilters(),
              const SizedBox(height: 20),
              _buildCategorySection(),
              const SizedBox(height: 20),
              _buildSectionHeader('Evenements recommandes', '/thix-event/recommended'),
              const SizedBox(height: 12),
              if (isLoading && recommendedEvents.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: _ThixColors.primary)))
              else if (recommendedEvents.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Aucun evenement disponible', style: TextStyle(color: _ThixColors.mutedText))))
              else
                SizedBox(
                  height: 268,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: recommendedEvents.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, i) => SizedBox(width: 160, child: EventCard(event: recommendedEvents[i], onTap: () => _goToEventDetail(recommendedEvents[i].id))),
                  ),
                ),
              const SizedBox(height: 20),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _buildNotificationBanner()),
              const SizedBox(height: 20),
              _buildSectionHeader('Prochains evenements', '/thix-event/upcoming'),
              const SizedBox(height: 12),
            ]),
          ),
          if (isLoading && upcomingEvents.isEmpty)
            const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: _ThixColors.primary))))
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(padding: const EdgeInsets.only(bottom: 12), child: UpcomingEventItem(event: upcomingEvents[index], onTap: () => _goToEventDetail(upcomingEvents[index].id))),
                  childCount: upcomingEvents.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildTopBar() {
    return SliverAppBar(
      pinned: true,
      floating: true,
      elevation: 0,
      backgroundColor: _ThixColors.pureWhite,
      toolbarHeight: 72,
      automaticallyImplyLeading: false,
      title: Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _ThixColors.lightBg, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.menu_rounded, color: _ThixColors.darkText, size: 22)),
        const SizedBox(width: 10),
        Container(width: 36, height: 36, decoration: BoxDecoration(color: _ThixColors.primary, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 18)),
        const SizedBox(width: 8),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Text('THIX ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _ThixColors.darkText, letterSpacing: -0.5)), Text('EVENEMENT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _ThixColors.primary, letterSpacing: -0.5))]), Text('Decouvrez, reservez, vivez.', style: TextStyle(fontSize: 10, color: _ThixColors.mutedText, fontWeight: FontWeight.w500))])),
        InkWell(onTap: () => context.push('/moderator'), borderRadius: BorderRadius.circular(20), child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _ThixColors.cardBorder)), child: const Icon(Icons.admin_panel_settings_rounded, size: 20, color: _ThixColors.primary))),
        const SizedBox(width: 8),
        Stack(clipBehavior: Clip.none, children: [
          InkWell(onTap: _showNotificationSettings, borderRadius: BorderRadius.circular(20), child: Container(padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: _ThixColors.lightBg, shape: BoxShape.circle, border: Border.all(color: _ThixColors.cardBorder)), child: const Icon(Icons.notifications_none_rounded, size: 20, color: _ThixColors.darkText))),
          Positioned(top: -4, right: -2, child: Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2), decoration: const BoxDecoration(color: _ThixColors.primary, shape: BoxShape.circle), child: const Text('3', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)))),
        ]),
        const SizedBox(width: 8),
        InkWell(onTap: () => context.push('/profile'), child: Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Color(0x336B3BFF), width: 2)), child: const CircleAvatar(radius: 18, backgroundImage: NetworkImage('https://i.pravatar.cc/100')))),
      ]),
    );
  }

  Widget _buildHeroBanner(EventModel? featuredEvent) {
    final imageUrl = featuredEvent?.imageUrl?? 'https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?q=80&w=2070';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 180,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: _ThixColors.primary),
        clipBehavior: Clip.antiAlias,
        child: Stack(children: [
          Positioned.fill(child: Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: _ThixColors.primary))),
          Positioned.fill(child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [const Color(0xF26B3BFF), const Color(0xB36B3BFF), Colors.transparent])))),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: _ThixColors.primaryLight, borderRadius: BorderRadius.circular(6)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.star_rounded, size: 12, color: Colors.white), SizedBox(width: 4), Text('A LA UNE', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5))])),
              const SizedBox(height: 12),
              const Text('Vivez des moments\ninoubliables.', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, height: 1.1)),
              const SizedBox(height: 8),
              const Text('Concerts, festivals, conferences,\nspectacles et plus encore.', style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 11, height: 1.3)),
              const SizedBox(height: 14),
              InkWell(onTap: () => context.push('/thix-event/search'), child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: _ThixColors.primaryLight, borderRadius: BorderRadius.circular(10)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Text('Decouvrir les evenements', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)), SizedBox(width: 6), Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white)]))),
            ]),
          ),
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final bool isFirst = i == 0;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isFirst? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(color: isFirst? _ThixColors.primaryLight : const Color(0x80FFFFFF), borderRadius: BorderRadius.circular(10)),
                );
              }),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildQuickFilters() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _ThixColors.cardBorder)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(children: _quickFilters.map((f) {
          final isSelected = _selectedQuickFilter == f['value'];
          final color = f['color'] as Color;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: InkWell(
              onTap: () {
                if (f['value'] == 'more') { context.push('/thix-event/categories'); return; }
                setState(() => _selectedQuickFilter = f['value'] as String);
                context.read<EventProvider>().fetchEvents(dateFilter: 'all');
              },
              borderRadius: BorderRadius.circular(12),
              child: Column(children: [
                Container(width: 48, height: 48, decoration: BoxDecoration(color: isSelected? color.withOpacity(0.18) : color.withOpacity(0.10), borderRadius: BorderRadius.circular(12), border: isSelected? Border.all(color: color, width: 1.2) : null), child: Icon(f['icon'] as IconData, color: color, size: 22)),
                const SizedBox(height: 6),
                Text(f['label'] as String, textAlign: TextAlign.center, style: TextStyle(fontSize: 10.5, fontWeight: isSelected? FontWeight.w800 : FontWeight.w600, color: isSelected? _ThixColors.darkText : _ThixColors.mutedText, height: 1.1)),
              ]),
            ),
          );
        }).toList()),
      ),
    );
  }

  Widget _buildCategorySection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Categories populaires', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _ThixColors.darkText)), GestureDetector(onTap: () => context.push('/thix-event/categories'), child: const Row(children: [Text('Voir tout', style: TextStyle(fontSize: 12, color: _ThixColors.primary, fontWeight: FontWeight.w700)), SizedBox(width: 2), Icon(Icons.chevron_right_rounded, size: 16, color: _ThixColors.primary)]))])),
      const SizedBox(height: 10),
      const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: CategoryChipsList()),
    ]);
  }

  Widget _buildSectionHeader(String title, String route) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _ThixColors.darkText)), GestureDetector(onTap: () => context.push(route), child: const Row(children: [Text('Voir tout', style: TextStyle(fontSize: 12, color: _ThixColors.primary, fontWeight: FontWeight.w700)), Icon(Icons.chevron_right_rounded, size: 16, color: _ThixColors.primary)]))]));
  }

  Widget _buildNotificationBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF6B3BFF)]), borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Container(width: 52, height: 52, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.confirmation_number_rounded, color: _ThixColors.primary, size: 28)),
        const SizedBox(width: 12),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Ne manquez aucun evenement!', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)), SizedBox(height: 3), Text('Activez les notifications pour etre informe des nouveaux evenements pres de vous.', style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 10.5, height: 1.3))])),
        const SizedBox(width: 10),
        ElevatedButton.icon(onPressed: _requestNotificationPermission, icon: const Icon(Icons.notifications_none_rounded, size: 18, color: _ThixColors.primary), label: const Text('Activer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _ThixColors.darkText)), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: _ThixColors.primary, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10))),
      ]),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8))], border: Border.all(color: _ThixColors.cardBorder)),
      child: SafeArea(top: false, child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_navItem(Icons.home_rounded, 'Accueil', 0), _navItem(Icons.search_rounded, 'Rechercher', 1), _centerNavItem(), _navItem(Icons.favorite_border_rounded, 'Favoris', 3), _navItem(Icons.person_outline_rounded, 'Profil', 4)])),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final isSelected = _selectedNavIndex == index;
    return InkWell(onTap: () => _onNavTap(index), borderRadius: BorderRadius.circular(16), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: isSelected? _ThixColors.primary : _ThixColors.mutedText, size: 22), const SizedBox(height: 2), Text(label, style: TextStyle(fontSize: 10, color: isSelected? _ThixColors.primary : _ThixColors.mutedText, fontWeight: isSelected? FontWeight.w700 : FontWeight.w500))])));
  }

  Widget _centerNavItem() {
    return InkWell(onTap: () => _onNavTap(2), child: Container(width: 64, height: 64, decoration: BoxDecoration(color: _ThixColors.primary, shape: BoxShape.circle, boxShadow: [BoxShadow(color: _ThixColors.primary.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6))]), child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.confirmation_number_rounded, color: Colors.white, size: 22), SizedBox(height: 2), Text('Mes billets', style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w700))])));
  }
}
