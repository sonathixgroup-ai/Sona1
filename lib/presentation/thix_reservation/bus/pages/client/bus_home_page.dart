// lib/presentation/thix_reservation/bus/pages/client/bus_home_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/bus_search_provider.dart';
import '../../providers/agency_dashboard_provider.dart';
import '../../widgets/client/bus_search_bar.dart';
import '../../widgets/client/popular_route_card.dart';
import '../../data/services/bus_public_service.dart';

class BusHomePage extends StatefulWidget {
  const BusHomePage({super.key});
  @override
  State<BusHomePage> createState() => _BusHomePageState();
}

class _BusHomePageState extends State<BusHomePage> {
  final _publicService = BusPublicService();
  List<Map<String, dynamic>> _popularRoutes = [];
  bool _loadingPopular = true;
  String _userName = 'Voyageur';

  final PageController _heroController = PageController();
  int _heroIndex = 0;

  final List<Map<String, dynamic>> _categories = [
    {'icon': Icons.apartment_rounded, 'label': 'Hôtels', 'color': Color(0xFF0D88F2), 'route': '/thix-reservation/hotels'},
    {'icon': Icons.flight_rounded, 'label': 'Vols', 'color': Color(0xFF2ECC71), 'route': '/thix-reservation/flights'},
    {'icon': Icons.directions_bus_rounded, 'label': 'Bus', 'color': Color(0xFF7C3AED), 'route': null},
    {'icon': Icons.local_taxi_rounded, 'label': 'Transports', 'color': Color(0xFFF5A623), 'route': '/thix-reservation/taxi'},
    {'icon': Icons.confirmation_number_rounded, 'label': 'Événements', 'color': Color(0xFFE74C3C), 'route': '/thix-event'},
    {'icon': Icons.restaurant_rounded, 'label': 'Restaurants', 'color': Color(0xFFF5A623), 'route': '/thix-reservation/restaurants'},
    {'icon': Icons.home_work_rounded, 'label': 'Locations', 'color': Color(0xFF2ECC71), 'route': '/thix-reservation/locations'},
    {'icon': Icons.more_horiz_rounded, 'label': 'Plus', 'color': Color(0xFF9CA3AF), 'route': null},
  ];

  @override
  void initState() {
    super.initState();
    _initRealData();
  }

  Future<void> _initRealData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('full_name')
            .eq('id', user.id)
            .maybeSingle();
        if (profile != null && mounted) {
          setState(() => _userName = (profile['full_name'] as String).split(' ').first);
        }
      } catch (_) {}
    }

    if (mounted) {
      Future.microtask(() => context.read<AgencyDashboardProvider>().init());
    }

    try {
      final routes = await _publicService.getPopularRoutes();
      if (mounted) {
        setState(() {
          _popularRoutes = routes;
          _loadingPopular = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingPopular = false);
    }
  }

  @override
  void dispose() {
    _heroController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Icon(Icons.menu_rounded, color: Colors.grey.shade800),
        ),
        leadingWidth: 44,
        titleSpacing: 0,
        title: Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF0D47A1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.directions_bus, color: Colors.white, size: 20)),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  Text('THIX ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0A3D62))),
                  Text('RESERVATION', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0D88F2))),
                ]),
                Text('Réservez simplement, voyagez sereinement.', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        ]),
        actions: [
          IconButton(
            onPressed: () => context.push('/notifications'),
            icon: const Badge(label: Text('3'), child: Icon(Icons.notifications_outlined)),
          ),
          // Bouton "Devenir partenaire" (kiosque) à la place de l'avatar profil
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Tooltip(
              message: 'Devenir partenaire',
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => context.push('/thix-reservation/bus/agency'),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFEAF2FE),
                    border: Border.all(color: const Color(0xFF0D88F2).withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.storefront_rounded, color: Color(0xFF0D47A1), size: 20),
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _initRealData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // HERO BANNER auto-scroll (bus image + promo)
            _buildHeroBanner(),
            const SizedBox(height: 16),

            // CATEGORIES
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _categories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 12, crossAxisSpacing: 4, childAspectRatio: 0.95),
                itemBuilder: (_, i) {
                  final c = _categories[i];
                  final isActive = c['label'] == 'Bus';
                  return InkWell(
                    onTap: () { if (c['route'] != null) context.push(c['route'] as String); },
                    borderRadius: BorderRadius.circular(14),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          color: isActive ? (c['color'] as Color).withOpacity(0.14) : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: isActive ? Border.all(color: (c['color'] as Color).withOpacity(0.4)) : null,
                        ),
                        child: Icon(c['icon'] as IconData, color: c['color'] as Color, size: 24),
                      ),
                      const SizedBox(height: 6),
                      Text(c['label'] as String, style: TextStyle(fontSize: 11, fontWeight: isActive ? FontWeight.w800 : FontWeight.w600, color: isActive ? const Color(0xFF7C3AED) : Colors.black87)),
                    ]),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // RESERVATION RAPIDE
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Réservation rapide de bus', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              TextButton(onPressed: () => context.push('/thix-reservation/bus/popular'), child: const Text('Voir tout')),
            ]),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
              child: BusSearchBar(onSearch: () async {
                await context.read<BusSearchProvider>().search();
                if (context.mounted) context.push('/thix-reservation/bus/search');
              }),
            ),

            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Routes populaires', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              TextButton(onPressed: () => context.push('/thix-reservation/bus/popular'), child: const Text('Voir tout'))
            ]),

            if (_loadingPopular)
              const SizedBox(height: 170, child: Center(child: CircularProgressIndicator()))
            else if (_popularRoutes.isEmpty)
              Container(height: 100, alignment: Alignment.center, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: const Text('Aucune route populaire pour le moment', style: TextStyle(color: Colors.grey)))
            else
              SizedBox(
                height: 170,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _popularRoutes.length,
                  itemBuilder: (_, i) {
                    final r = _popularRoutes[i];
                    return PopularRouteCard(
                      from: r['departure_city'] as String,
                      to: r['arrival_city'] as String,
                      dateLabel: r['next_departure_label'] as String? ?? 'Départ quotidien',
                      price: '${r['min_price'] ?? 0} FCFA',
                      imageUrl: r['arrival_city_image'] as String?,
                      onTap: () {
                        final searchP = context.read<BusSearchProvider>();
                        searchP.setDeparture(r['departure_city']);
                        searchP.setArrival(r['arrival_city']);
                        searchP.search().then((_) {
                          if (context.mounted) context.push('/thix-reservation/bus/search');
                        });
                      },
                    );
                  },
                ),
              ),

            const SizedBox(height: 20),
            const Text('Nos bus pour votre confort', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                flex: 3,
                child: FutureBuilder(
                  future: Supabase.instance.client.from('bus_amenities').select().eq('is_active', true),
                  builder: (context, snap) {
                    if (!snap.hasData) return const SizedBox(height: 80, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
                    final amenities = snap.data as List;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: amenities.take(5).map((a) {
                        return _Comfort(icon: _iconFromName(a['icon_name']), label: a['label']);
                      }).toList(),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: const Color(0xFFEAF2FE), borderRadius: BorderRadius.circular(16)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.headset_mic_rounded, color: Color(0xFF0D47A1), size: 24),
                    const SizedBox(height: 8),
                    const Text('Besoin d\'aide ?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0A3D62))),
                    const SizedBox(height: 2),
                    Text('Notre équipe est disponible 24h/24 et 7j/7', style: TextStyle(fontSize: 10.5, color: Colors.grey.shade700, height: 1.3)),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => context.push('/support'),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D88F2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 10)),
                        child: const Text('Nous contacter', style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ]),
                ),
              ),
            ]),
            const SizedBox(height: 90),
          ]),
        ),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 6))]),
        child: SafeArea(
          top: false,
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _navItem(Icons.home_rounded, 'Accueil', true, () => context.go('/')),
            _navItem(Icons.confirmation_number_outlined, 'Réservations', false, () => context.push('/thix-reservation/bus/bookings')),
            InkWell(
              onTap: () {
                context.read<BusSearchProvider>().search();
                context.push('/thix-reservation/bus/search');
              },
              child: Container(width: 58, height: 58, decoration: BoxDecoration(color: const Color(0xFF0D88F2), shape: BoxShape.circle, boxShadow: [BoxShadow(color: const Color(0xFF0D88F2).withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))]), child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_rounded, color: Colors.white, size: 20), Text('Réserver', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700))])),
            ),
            _navItem(Icons.favorite_border_rounded, 'Favoris', false, () => context.push('/thix-reservation/favorites')),
            _navItem(Icons.person_outline_rounded, 'Profil', false, () => context.push('/profile')),
          ]),
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    final slides = [
      {
        'title': 'Réservez votre bus\nen toute simplicité',
        'subtitle': 'Voyagez confortablement vers\nvotre destination.',
        'cta': 'Réserver un bus',
      },
      {
        'title': 'Nouvelles lignes\ncette semaine',
        'subtitle': 'Plus de destinations,\nplus de confort.',
        'cta': 'Découvrir',
      },
      {
        'title': 'Voyagez en\ntoute sécurité',
        'subtitle': 'Bus climatisés et\npersonnel qualifié.',
        'cta': 'En savoir plus',
      },
      {
        'title': 'Offres du\nmoment',
        'subtitle': 'Jusqu\'à -15% sur vos\nprochains trajets.',
        'cta': 'Voir les offres',
      },
    ];

    return SizedBox(
      height: 200,
      child: Stack(children: [
        PageView.builder(
          controller: _heroController,
          itemCount: slides.length,
          onPageChanged: (i) => setState(() => _heroIndex = i),
          itemBuilder: (context, index) {
            final s = slides[index];
            return Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0D47A1), Color(0xFF1E88E5)]),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(children: [
                Positioned(
                  right: -20, bottom: 0,
                  child: Icon(Icons.directions_bus_filled_rounded, size: 160, color: Colors.white.withOpacity(0.15)),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('Bonjour, $_userName 👋', style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Text(s['title']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 21, height: 1.2)),
                    const SizedBox(height: 6),
                    Text(s['subtitle']!, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.3)),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: () {
                        context.read<BusSearchProvider>().search();
                        context.push('/thix-reservation/bus/search');
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF0D47A1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.directions_bus_rounded, size: 16),
                        const SizedBox(width: 6),
                        Text(s['cta']!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_rounded, size: 14),
                      ]),
                    ),
                  ]),
                ),
              ]),
            );
          },
        ),
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(slides.length, (i) {
              final isActive = i == _heroIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(color: isActive ? Colors.white : Colors.white.withOpacity(0.4), borderRadius: BorderRadius.circular(10)),
              );
            }),
          ),
        ),
      ]),
    );
  }

  Widget _navItem(IconData icon, String label, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 22, color: isActive ? const Color(0xFF0D88F2) : Colors.grey),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize:
