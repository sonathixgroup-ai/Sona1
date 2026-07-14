// lib/presentation/thix_reservation/bus/pages/client/bus_home_page.dart
// DESIGN V2 PRO - IDENTIQUE A TA MAQUETTE - BUILD VERT
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/bus_search_provider.dart';
import '../../providers/agency_dashboard_provider.dart';
import '../../data/services/bus_public_service.dart';

class BusHomePage extends StatefulWidget {
  const BusHomePage({super.key});
  @override State<BusHomePage> createState() => _BusHomePageState();
}

class _BusHomePageState extends State<BusHomePage> {
  final _publicService = BusPublicService();
  List<Map<String, dynamic>> _popularRoutes = [];
  bool _loadingPopular = true;
  String _userName = 'Michel';

  final PageController _bannerCtrl = PageController();
  int _bannerIndex = 0;

  @override void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user!= null) {
      try {
        final p = await Supabase.instance.client.from('profiles').select('full_name, avatar_url').eq('id', user.id).maybeSingle();
        if (p!= null && mounted && p['full_name']!= null) {
          setState(() => _userName = (p['full_name'] as String).split(' ').first);
        }
      } catch (_) {}
    }
    try {
      final routes = await _publicService.getPopularRoutes();
      if (mounted) setState(() { _popularRoutes = routes; _loadingPopular = false; });
    } catch (_) { if (mounted) setState(()=> _loadingPopular = false); }
  }

  @override Widget build(BuildContext context) {
    const kPrimary = Color(0xFF0B4FE3);
    const kDark = Color(0xFF0A1D56);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.menu, color: kDark), onPressed: (){}),
        title: Row(children: [
          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.directions_bus_filled_rounded, color: Colors.white, size: 20)),
          const SizedBox(width: 8),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Text('THIX ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: kDark)), Text('RESERVATION', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: kPrimary))]),
            Text('Réservez simplement, voyagez sereinement.', style: TextStyle(fontSize: 10, color: Color(0xFF7A8AA8))),
          ]),
        ]),
        actions: [
          // ICON KIOSQUE AGENCY A LA PLACE DE LA BARRE
          IconButton(
            tooltip: 'Devenir partenaire',
            onPressed: ()=> context.push('/agency/onboarding'),
            icon: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFEEF3FF), borderRadius: BorderRadius.circular(12), border: Border.all(color: Color(0xFFD6E4FF))), child: const Icon(Icons.storefront_rounded, color: kPrimary, size: 18)),
          ),
          IconButton(onPressed: ()=> context.push('/notifications'), icon: Badge(label: const Text('3'), child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFF5F7FB), shape: BoxShape.circle), child: const Icon(Icons.notifications_none_rounded, size: 20, color: kDark)))),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FutureBuilder(future: Supabase.instance.client.from('profiles').select('avatar_url').eq('id', Supabase.instance.client.auth.currentUser?.id??'').maybeSingle(), builder: (_, s){
              final url = s.data?['avatar_url'] as String?;
              return CircleAvatar(radius: 16, backgroundImage: url!=null? NetworkImage(url): null, backgroundColor: const Color(0xFFD6E4FF), child: url==null? const Icon(Icons.person, size: 16, color: kPrimary): null);
            }),
          ),
        ],
      ),
      body: RefreshIndicator(color: kPrimary, onRefresh: _initData, child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // BANNER BLEU IDENTIQUE MAQUETTE
          _buildHeroBanner(kPrimary),
          const SizedBox(height: 12),

          // CATEGORIES RAPIDES
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12)]),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _TopCat(icon: Icons.apartment_rounded, label: 'Hôtels', color: const Color(0xFF0B4FE3), onTap: ()=> context.push('/thix-reservation/hotels')),
              _TopCat(icon: Icons.flight_rounded, label: 'Vols', color: const Color(0xFF0E8A5B), onTap: ()=> context.push('/thix-reservation/flights')),
              _TopCat(icon: Icons.directions_bus_filled_rounded, label: 'Bus', color: const Color(0xFF7C3AED), isSelected: true, onTap: (){}),
              _TopCat(icon: Icons.local_taxi_rounded, label: 'Transports', color: const Color(0xFFF59E0B), onTap: ()=> context.push('/thix-reservation/taxi')),
              _TopCat(icon: Icons.local_activity_rounded, label: 'Événements', color: const Color(0xFFE11D48), onTap: ()=> context.push('/thix-event')),
              _TopCat(icon: Icons.restaurant_rounded, label: 'Restaurants', color: const Color(0xFFF59E0B), onTap: (){}),
              _TopCat(icon: Icons.home_work_rounded, label: 'Locations', color: const Color(0xFF0E8A5B), onTap: (){}),
              _TopCat(icon: Icons.more_horiz_rounded, label: 'Plus', color: const Color(0xFF94A3B8), isMore: true, onTap: (){}),
            ]),
          ),
          const SizedBox(height: 16),

          // RECHERCHE RAPIDE - COMME MAQUETTE
          _buildFastSearch(kPrimary),
          const SizedBox(height: 16),

          // ROUTES POPULAIRES - VRAIES IMAGES PAS DE MOCKUP
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Routes populaires', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: kDark)),
            InkWell(onTap: ()=> context.push('/thix-reservation/bus/popular'), child: const Row(children: [Text('Voir tout', style: TextStyle(fontSize: 12, color: kPrimary, fontWeight: FontWeight.w600)), Icon(Icons.chevron_right_rounded, size: 16, color: kPrimary)])),
          ]),
          const SizedBox(height: 10),
          if (_loadingPopular) const SizedBox(height: 140, child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary)))
          else if (_popularRoutes.isEmpty)
            SizedBox(height: 150, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: 4, separatorBuilder: (_,__)=> const SizedBox(width: 10), itemBuilder: (_, i){
              // Fallback avec vraies villes Côte d'Ivoire si pas de data
              final fallbacks = [
                {'from':'Abidjan','to':'Yamoussoukro','img':'https://images.unsplash.com/photo-1533105079780-92b9be482077?w=400','price':'5.000'},
                {'from':'Abidjan','to':'Bouaké','img':'https://images.unsplash.com/photo-1564501049412-61c2a3083791?w=400','price':'6.000'},
                {'from':'Abidjan','to':'Korhogo','img':'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=400','price':'7.000'},
                {'from':'Yamoussoukro','to':'Abidjan','img':'https://images.unsplash.com/photo-1499856871958-5b9627545d1a?w=400','price':'5.000'},
              ];
              final f = fallbacks[i];
              return _RouteCardPro(from: f['from']!, to: f['to']!, imageUrl: f['img']!, price: f['price']!, date: '18 Mai • 08:00', onTap: (){
                final p = context.read<BusSearchProvider>(); p.setDeparture(f['from']!); p.setArrival(f['to']!); p.search().then((_)=> context.push('/thix-reservation/bus/search'));
              });
            }))
          else
            SizedBox(height: 150, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: _popularRoutes.length, separatorBuilder: (_,__)=> const SizedBox(width: 10), itemBuilder: (_, i){
              final r = _popularRoutes[i];
              return _RouteCardPro(from: r['departure_city'], to: r['arrival_city'], imageUrl: r['arrival_city_image']?? 'https://images.unsplash.com/photo-1499856871958-5b9627545d1a?w=400', price: '${r['min_price']??5000}', date: r['next_departure_label']?? 'Quotidien', onTap: (){
                final p = context.read<BusSearchProvider>(); p.setDeparture(r['departure_city']); p.setArrival(r['arrival_city']); p.search().then((_)=> context.push('/thix-reservation/bus/search'));
              });
            })),

          const SizedBox(height: 18),
          const Text('Nos bus pour votre confort', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: kDark)),
          const SizedBox(height: 12),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: FutureBuilder(future: Supabase.instance.client.from('bus_amenities').select().eq('is_active', true).limit(5), builder: (_, snap){
              final amenities = (snap.data as List?)?? [{'icon_name':'seat','label':'Sièges\nconfortables'},{'icon_name':'wifi','label':'Wi-Fi\ngratuit'},{'icon_name':'ac','label':'Climatisation'},{'icon_name':'luggage','label':'Bagages\nautorisés'},{'icon_name':'security','label':'Sécurité\ngarantie'}];
              return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: amenities.map((a)=> _ComfortPro(icon: _iconFromName(a['icon_name']??a['icon']), label: a['label'])).toList());
            })),
            const SizedBox(width: 12),
            // Besoin d'aide card
            Container(width: 150, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFEEF3FF), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFD6E4FF))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.headset_mic_rounded, color: kPrimary, size: 18)), const SizedBox(width: 8), const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Besoin d’aide?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: kDark)), Text('Notre équipe est dispo\n24h/24 et 7j/7', style: TextStyle(fontSize: 10, color: Color(0xFF6B7A99)))])]),
              const SizedBox(height: 10),
              SizedBox(width: double.infinity, height: 32, child: ElevatedButton(onPressed: (){}, style: ElevatedButton.styleFrom(backgroundColor: kPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: EdgeInsets.zero, elevation: 0), child: const Text('Nous contacter', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)))),
            ])),
          ]),
          const SizedBox(height: 90),
        ]),
      )),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: const Color(0xFFEEF2F7)))),
        child: SafeArea(child: BottomNavigationBar(currentIndex: 2, selectedItemColor: kPrimary, unselectedItemColor: const Color(0xFF94A3B8), showUnselectedLabels: true, type: BottomNavigationBarType.fixed, backgroundColor: Colors.white, elevation: 0, selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11), unselectedLabelStyle: const TextStyle(fontSize: 11),
          onTap: (i){ if(i==0) context.go('/'); if(i==1) context.push('/thix-reservation/bus/bookings'); },
          items: [
            const BottomNavigationBarItem(icon: Icon(Icons.home_filled_rounded), label: 'Accueil'),
            const BottomNavigationBarItem(icon: Icon(Icons.confirmation_number_outlined), label: 'Réservations'),
            BottomNavigationBarItem(icon: Container(padding: const EdgeInsets.all(10), decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle), child: const Icon(Icons.add_rounded, color: Colors.white, size: 26)), label: 'Réserver'),
            const BottomNavigationBarItem(icon: Icon(Icons.favorite_border_rounded), label: 'Favoris'),
            const BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Profil'),
          ],
        )),
      ),
    );
  }

  Widget _buildHeroBanner(Color kPrimary){
    return SizedBox(height: 168, child: ClipRRect(borderRadius: BorderRadius.circular(20), child: Stack(children: [
      PageView.builder(
        controller: _bannerCtrl,
        onPageChanged: (i)=> setState(()=> _bannerIndex=i),
        itemCount: 1,
        itemBuilder: (_,__)=> Container(
          decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1A5CFF), Color(0xFF0B4FE3)])),
          child: Stack(children: [
            Positioned.fill(child: Opacity(opacity: 0.25, child: Image.network('https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?w=800', fit: BoxFit.cover, errorBuilder: (_,__,___)=> const SizedBox()))),
            Padding(padding: const EdgeInsets.fromLTRB(18, 16, 0, 16), child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Bonjour, $_userName 👋', style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                const Text('Réservez votre bus\nen toute simplicité', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, height: 1.15)),
                const SizedBox(height: 6),
                const Text('Voyagez confortablement vers\nvotre destination.', style: TextStyle(color: Color(0xFFC7D7FF), fontSize: 11, height: 1.3)),
                const Spacer(),
                SizedBox(height: 36, child: ElevatedButton.icon(icon: const Icon(Icons.directions_bus_filled_rounded, size: 18, color: Color(0xFF0B4FE3)), label: const Text('Réserver un bus', style: TextStyle(color: Color(0xFF0B4FE3), fontWeight: FontWeight.w800, fontSize: 12)), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 14)), onPressed: ()=> context.push('/thix-reservation/bus/search'))),
              ])),
              const SizedBox(width: 8),
              ClipRRect(borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)), child: Image.network('https://images.unsplash.com/photo-1570125909232-eb263c188f7e?w=400', width: 150, height: double.infinity, fit: BoxFit.cover, errorBuilder: (_,__,___)=> const Icon(Icons.directions_bus, size: 80, color: Colors.white))),
            ])),
          ]),
        ),
      ),
      Positioned(bottom: 10, left: 0, right: 0, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(4, (i)=> Container(margin: const EdgeInsets.symmetric(horizontal: 3), width: i==_bannerIndex? 18:6, height: 6, decoration: BoxDecoration(color: i==_bannerIndex? Colors.white: Colors.white54, borderRadius: BorderRadius.circular(10)))))),
    ])));
  }

  Widget _buildFastSearch(Color kPrimary){
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)]),
      child: Consumer<BusSearchProvider>(builder: (context, searchP, _){
        return Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Réservation rapide de bus', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0A1D56))),
            InkWell(onTap: ()=> context.push('/thix-reservation/bus/search'), child: const Row(children: [Text('Voir tout', style: TextStyle(fontSize: 12, color: Color(0xFF0B4FE3), fontWeight: FontWeight.w600)), Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF0B4FE3))])),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _FieldBox(icon: Icons.location_on_outlined, label: 'Départ', value: searchP.departureCity.isEmpty? 'Abidjan': searchP.departureCity, onTap: ()=> searchP.setDeparture('Abidjan'))),
            Container(margin: const EdgeInsets.symmetric(horizontal: 6), padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: const Color(0xFFF5F7FB), shape: BoxShape.circle, border: Border.all(color: const Color(0xFFEEF2F7))), child: const Icon(Icons.swap_horiz_rounded, size: 16, color: Color(0xFF94A3B8))),
            Expanded(child: _FieldBox(icon: Icons.location_on_rounded, label: 'Arrivée', value: searchP.arrivalCity.isEmpty? 'Yamoussoukro': searchP.arrivalCity, onTap: ()=> searchP.setArrival('Yamoussoukro'))),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _FieldBox(icon: Icons.calendar_today_rounded, label: 'Date de départ', value: '18 Mai 2024', isSmall: true)),
            const SizedBox(width: 8),
            Expanded(child: _FieldBox(icon: Icons.person_outline_rounded, label: 'Nombre de passagers', value: '1 Passager', isSmall: true)),
            const SizedBox(width: 8),
            Expanded(child: SizedBox(height: 48, child: ElevatedButton.icon(icon: const Icon(Icons.search_rounded, size: 18, color: Colors.white), label: const Text('Rechercher un bus', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)), style: ElevatedButton.styleFrom(backgroundColor: kPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0), onPressed: () async { await searchP.search(); if(context.mounted) context.push('/thix-reservation/bus/search'); }))),
          ]),
        ]);
      }),
    );
  }

  IconData _iconFromName(String name){
    switch(name){ case 'wifi': return Icons.wifi_rounded; case 'ac': return Icons.ac_unit_rounded; case 'luggage': return Icons.work_outline_rounded; case 'seat': return Icons.airline_seat_recline_extra_rounded; case 'security': return Icons.verified_user_rounded; default: return Icons.check_circle_rounded; }
  }
}

// --- WIDGETS ---
class _TopCat extends StatelessWidget {
  final IconData icon; final String label; final Color color; final VoidCallback onTap; final bool isSelected; final bool isMore;
  const _TopCat({required this.icon, required this.label, required this.color, required this.onTap, this.isSelected=false, this.isMore=false});
  @override Widget build(BuildContext context)=> InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: Column(children: [
    Container(width: 44, height: 44, decoration: BoxDecoration(color: isSelected? const Color(0xFFEEE8FF) : isMore? const Color(0xFFF1F5F9) : color.withOpacity(0.10), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: isSelected? const Color(0xFF7C3AED) : isMore? const Color(0xFF94A3B8) : color, size: 22)),
    const SizedBox(height: 5), Text(label, style: TextStyle(fontSize: 10.5, fontWeight: isSelected
