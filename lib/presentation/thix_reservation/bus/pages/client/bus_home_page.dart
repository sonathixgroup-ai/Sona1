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
import '../agency/agency_entry_button.dart';

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

  @override
  void initState() {
    super.initState();
    _initRealData();
  }

  Future<void> _initRealData() async {
    // 1. Récupère le vrai nom depuis THIX ID (Supabase Auth + profiles)
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

    // 2. Charge agence pour bouton SaaS
    if (mounted) {
      Future.microtask(() => context.read<AgencyDashboardProvider>().init());
    }

    // 3. Charge les vraies routes populaires depuis Supabase View
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF0D47A1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.directions_bus, color: Colors.white, size: 20)),
          const SizedBox(width: 10),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('THIX RESERVATION', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0A3D62))), Text('Réservez simplement, voyagez sereinement.', style: TextStyle(fontSize: 11, color: Colors.grey))]),
        ]),
        actions: [
          IconButton(
            onPressed: () => context.push('/notifications'),
            icon: const Badge(label: Text('3'), child: Icon(Icons.notifications_outlined)),
          ),
          const SizedBox(width: 8)
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _initRealData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Banner DYNAMIQUE - image de la prochaine promo réelle si existe, sinon gradient
            FutureBuilder(
              future: Supabase.instance.client.from('promotions').select().eq('is_active', true).eq('type', 'bus').maybeSingle(),
              builder: (context, snapshot) {
                final promo = snapshot.data;
                return Container(
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(colors: [Color(0xFF0D47A1), Color(0xFF1976D2)]),
                    image: promo?['image_url'] != null
                        ? DecorationImage(image: NetworkImage(promo!['image_url']), fit: BoxFit.cover, opacity: 0.4)
                        : null,
                  ),
                  child: Stack(children: [
                    Positioned(
                      left: 20, top: 20, right: 20,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Bonjour, $_userName 👋', style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 6),
                        Text(promo?['title'] ?? 'Réservez votre bus\nen toute simplicité', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20, height: 1.2)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => context.read<BusSearchProvider>().search(),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF0D47A1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                          child: const Text('Réserver un bus'),
                        )
                      ]),
                    )
                  ]),
                );
              },
            ),

            const SizedBox(height: 16),
            const AgencyEntryButton(),
            const SizedBox(height: 8),

            BusSearchBar(onSearch: () async {
              await context.read<BusSearchProvider>().search();
              if (context.mounted) context.push('/thix-reservation/bus/search');
            }),

            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Routes populaires', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              TextButton(onPressed: () => context.push('/thix-reservation/bus/popular'), child: const Text('Voir tout'))
            ]),

            // LISTE REELLE DEPUIS SUPABASE
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
                      imageUrl: r['arrival_city_image'] as String?, // Image réelle de la ville depuis table cities
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
            // Conforts réels depuis table bus_amenities
            FutureBuilder(
              future: Supabase.instance.client.from('bus_amenities').select().eq('is_active', true),
              builder: (context, snap) {
                if (!snap.hasData) return const SizedBox(height: 60, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
                final amenities = snap.data as List;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: amenities.take(5).map((a) {
                    return _Comfort(icon: _iconFromName(a['icon_name']), label: a['label']);
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 80),
          ]),
        ),
      ),
    );
  }

  IconData _iconFromName(String? name) {
    switch (name) {
      case 'wifi': return Icons.wifi;
      case 'ac': return Icons.ac_unit;
      case 'luggage': return Icons.luggage;
      case 'seat': return Icons.airline_seat_recline_extra;
      case 'security': return Icons.verified_user;
      default: return Icons.check_circle_outline;
    }
  }
}

class _Comfort extends StatelessWidget {
  final IconData icon; final String label;
  const _Comfort({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Column(children: [Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle), child: Icon(icon, color: const Color(0xFF0D47A1), size: 20)), const SizedBox(height: 6), Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.grey.shade700))]);
  }
}
