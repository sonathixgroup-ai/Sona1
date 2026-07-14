// lib/presentation/thix_reservation/thix_reservation_home_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ThixReservationHomePage extends StatefulWidget {
  const ThixReservationHomePage({super.key});
  @override
  State<ThixReservationHomePage> createState() => _ThixReservationHomePageState();
}

class _ThixReservationHomePageState extends State<ThixReservationHomePage> {
  Map<String, int> counts = {'upcoming': 0, 'ongoing': 0, 'completed': 0, 'cancelled': 0};
  bool loadingCounts = true;

  // --- Hero banner auto-scroll (4 slides, blue dominant) ---
  final PageController _heroController = PageController();
  Timer? _heroTimer;
  int _heroIndex = 0;

  final List<Map<String, dynamic>> _heroSlides = [
    {
      'badge': 'PROMO FLASH',
      'title': 'Jusqu\'à -40%',
      'subtitle': 'sur vos réservations de bus & vols',
      'valid': 'Valable jusqu\'au 30 Juin 2025',
      'cta': 'Profiter maintenant',
      'route': '/thix-reservation/bus',
      'icon': Icons.flash_on,
      'iconColor': Colors.orange,
      'illustration': Icons.airplanemode_active_rounded,
    },
    {
      'badge': 'NOUVEAU',
      'title': 'Hôtels dès -30%',
      'subtitle': 'Séjournez plus, payez moins',
      'valid': 'Offre limitée cette semaine',
      'cta': 'Voir les hôtels',
      'route': '/thix-reservation/hotels',
      'icon': Icons.hotel_rounded,
      'iconColor': Color(0xFF0D88F2),
      'illustration': Icons.apartment_rounded,
    },
    {
      'badge': 'RAPIDE',
      'title': 'Taxi en 5 min',
      'subtitle': 'Course immédiate, prix fixe',
      'valid': 'Disponible 24h/24',
      'cta': 'Commander un taxi',
      'route': '/thix-reservation/taxi',
      'icon': Icons.bolt_rounded,
      'iconColor': Color(0xFF0D88F2),
      'illustration': Icons.local_taxi_rounded,
    },
    {
      'badge': 'EXPRESS',
      'title': 'Livraison -10%',
      'subtitle': 'Envoi express partout en ville',
      'valid': 'Valable ce mois-ci',
      'cta': 'Envoyer un colis',
      'route': '/thix-reservation/delivery',
      'icon': Icons.local_shipping_rounded,
      'iconColor': Color(0xFF0D88F2),
      'illustration': Icons.inventory_2_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadCounts();
    _startHeroAutoScroll();
  }

  void _startHeroAutoScroll() {
    _heroTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted || !_heroController.hasClients) return;
      _heroIndex = (_heroIndex + 1) % _heroSlides.length;
      _heroController.animateToPage(_heroIndex, duration: const Duration(milliseconds: 500), curve: Curves.easeInOutCubic);
    });
  }

  Future<void> _loadCounts() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      final res = await Supabase.instance.client.from('bus_bookings').select('status').eq('user_id', userId);
      final map = {'upcoming': 0, 'ongoing': 0, 'completed': 0, 'cancelled': 0};
      for (final r in res as List) {
        final s = r['status'] as String;
        if (s == 'confirmed' || s == 'pending_payment') map['upcoming'] = map['upcoming']! + 1;
        else if (s == 'in_progress') map['ongoing'] = map['ongoing']! + 1;
        else if (s == 'completed') map['completed'] = map['completed']! + 1;
        else if (s == 'cancelled') map['cancelled'] = map['cancelled']! + 1;
      }
      if (mounted) setState(() { counts = map; loadingCounts = false; });
    } catch (_) { if (mounted) setState(() => loadingCounts = false); }
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
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
        title: Row(children: [
          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]), child: const Text('R', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 26, color: Color(0xFF0D47A1)))),
          const SizedBox(width: 10),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Row(children: [Text('THIX ', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black87, fontSize: 16)), Text('RÉSERVATION', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0D88F2), fontSize: 16))]), Text('Réservez tout, partout, en toute simplicité.', style: TextStyle(fontSize: 11, color: Colors.grey))])),
        ]),
        actions: [
          Stack(children: [IconButton(onPressed: () => context.push('/notifications'), icon: const Icon(Icons.notifications_none_rounded, size: 26)), Positioned(right: 6, top: 6, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Text('3', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))))]),
          IconButton(onPressed: () => context.push('/profile'), icon: const Icon(Icons.person_outline_rounded, size: 26)),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadCounts,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // HERO BANNER - 4 slides auto-scroll, blue dominant
            _buildHeroBanner(),
            const SizedBox(height: 14),

            // CATEGORIES
            Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _Cat(icon: Icons.directions_bus_rounded, label: 'Bus', color: const Color(0xFF0D88F2), onTap: ()=> context.push('/thix-reservation/bus')),
              _Cat(icon: Icons.flight_rounded, label: 'Vol', color: const Color(0xFF0D88F2), onTap: ()=> context.push('/thix-reservation/flights')),
              _Cat(icon: Icons.apartment_rounded, label: 'Hôtel', color: const Color(0xFFF5A623), onTap: ()=> context.push('/thix-reservation/hotels')),
              _Cat(icon: Icons.local_taxi_rounded, label: 'Taxi', color: const Color(0xFFF5C518), onTap: ()=> context.push('/thix-reservation/taxi')),
              _Cat(icon: Icons.two_wheeler_rounded, label: 'Livraison', color: const Color(0xFF0D88F2), onTap: ()=> context.push('/thix-reservation/delivery')),
              _Cat(icon: Icons.grid_view_rounded, label: 'Plus', color: const Color(0xFF0D88F2), onTap: ()=> showModalBottomSheet(context: context, builder: (_)=> const _MoreSheet())),
            ])),
            const SizedBox(height: 16),

            // MES RESERVATIONS
            _SectionHeader(title: 'Mes réservations', icon: Icons.calendar_today_outlined, onSeeAll: ()=> context.push('/thix-reservation/bus/bookings')),
            const SizedBox(height: 8),
            Row(children: [
              _ReservationCard(label: 'À venir', count: loadingCounts? '-' : '${counts['upcoming']}', color: const Color(0xFF0D88F2), icon: Icons.luggage_rounded),
              const SizedBox(width: 8),
              _ReservationCard(label: 'En cours', count: loadingCounts? '-' : '${counts['ongoing']}', color: const Color(0xFFF5A623), icon: Icons.timer_outlined),
              const SizedBox(width: 8),
              _ReservationCard(label: 'Terminées', count: loadingCounts? '-' : '${counts['completed']}', color: const Color(0xFF2ECC71), icon: Icons.check_circle),
              const SizedBox(width: 8),
              _ReservationCard(label: 'Annulées', count: loadingCounts? '-' : '${counts['cancelled']}', color: const Color(0xFFE74C3C), icon: Icons.cancel),
            ]),
            const SizedBox(height: 16),

            // OFFRES SPECIALES
            _SectionHeader(title: 'Offres spéciales pour vous', onSeeAll: (){}),
            const SizedBox(height: 8),
            SizedBox(height: 110, child: FutureBuilder(future: Supabase.instance.client.from('promotions').select().eq('is_active', true).limit(4), builder: (_, snap){
              final data = (snap.data as List?)?? [];
              if(data.isEmpty) return Row(children: const [
                _OfferCard(title:'Hôtels', discount:'-30%', subtitle:'Séjournez plus,\npayez moins', color: Color(0xFFFDF0DC), accent: Color(0xFFE0A03D)),
                SizedBox(width: 8),
                _OfferCard(title:'Vols', discount:'-20%', subtitle:'Sur tous les vols', color: Color(0xFFE3EEFB), accent: Color(0xFF0D88F2)),
                SizedBox(width: 8),
                _OfferCard(title:'Bus', discount:'-15%', subtitle:'Voyagez en toute\nconfiance', color: Color(0xFFE0EAFC), accent: Color(0xFF0D47A1)),
                SizedBox(width: 8),
                _OfferCard(title:'Livraison', discount:'-10%', subtitle:'Envoi express', color: Color(0xFFE7F5E9), accent: Color(0xFF2ECC71)),
              ]);
              return ListView.separated(scrollDirection: Axis.horizontal, itemCount: data.length, separatorBuilder: (_,__)=> const SizedBox(width: 8), itemBuilder: (_,i){ final o=data[i]; return _OfferCard(title: o['category']??'', discount: o['discount']??'', subtitle: o['subtitle']??'', color: const Color(0xFFE3EEFB), accent: const Color(0xFF0D88F2)); });
            })),
            const SizedBox(height: 14),

            // PARRAINAGE
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFEAF2FE), borderRadius: BorderRadius.circular(14)), child: Row(children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)), child: const Text('🎁', style: TextStyle(fontSize: 26))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Parrainez & Gagnez !', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D47A1), fontSize: 14)),
                const SizedBox(height: 2),
                RichText(text: const TextSpan(style: TextStyle(fontSize: 11, color: Colors.black54), children: [TextSpan(text: 'Invitez vos proches et gagnez jusqu\'à '), TextSpan(text: '10.000 FC', style: TextStyle(color: Color(0xFF0D88F2), fontWeight: FontWeight.bold)), TextSpan(text: ' par parrainage.')])),
              ])),
              const SizedBox(width: 8),
              FutureBuilder(future: Supabase.instance.client.from('profiles').select('avatar_url').limit(4), builder: (_, s){ final avs = (s.data as List?)?? []; return SizedBox(width: 80, height: 32, child: Stack(children: List.generate(avs.length.clamp(0,4), (i)=> Positioned(left: i*18, child: CircleAvatar(radius: 14, backgroundColor: Colors.white, child: CircleAvatar(radius: 12, backgroundImage: avs[i]['avatar_url']!=null? NetworkImage(avs[i]['avatar_url']): null)))))); }),
              const Icon(Icons.chevron_right, color: Color(0xFF0D47A1)),
            ])),
            const SizedBox(height: 16),

            // RESTAURANTS
            _SectionHeader(title: 'Restaurants à proximité', onSeeAll: ()=> context.push('/thix-reservation/restaurants')),
            const SizedBox(height: 8),
            SizedBox(height: 170, child: FutureBuilder(future: Supabase.instance.client.from('restaurants').select().eq('is_active', true).limit(6), builder: (_, snap){
              final list = (snap.data as List?)?? [];
              if(list.isEmpty) return const Center(child: Text('Aucun restaurant partenaire pour le moment', style: TextStyle(color: Colors.grey)));
              return ListView.separated(scrollDirection: Axis.horizontal, itemCount: list.length, separatorBuilder: (_,__)=> const SizedBox(width: 10), itemBuilder: (_, i){ final r=list[i]; return _RestaurantCard(name: r['name'], category: r['category'], time: '${r['min_time']??15}-${r['max_time']??30} min', price: r['price_level']??'\$\$', image: r['image_url'], rating: (r['rating']??4.5).toDouble()); });
            })),
            const SizedBox(height: 16),

            // ANNONCES
            _SectionHeader(title: 'Annonces', onSeeAll: ()=> context.push('/market')),
            const SizedBox(height: 8),
            SizedBox(height: 170, child: FutureBuilder(future: Supabase.instance.client.from('market_products').select().eq('is_published', true).limit(6), builder: (_, snap){
              final list = (snap.data as List?)?? [];
              if(list.isEmpty) return Row(children: const [_AnnonceCard(badge:'À VENDRE', badgeColor: Color(0xFF2ECC71), title:'Toyota RAV4 2021', price:'25.000.000 FC'), SizedBox(width: 10), _AnnonceCard(badge:'À LOUER', badgeColor: Color(0xFFF5A623), title:'Appartement 3 pièces', price:'600.000 FC / mois'), SizedBox(width: 10), _AnnonceCard(badge:'SERVICE', badgeColor: Color(0xFF2ECC71), title:'Ménage à domicile', price:'À partir de 10.000 FC')]);
              return ListView.separated(scrollDirection: Axis.horizontal, itemCount: list.length, separatorBuilder: (_,__)=> const SizedBox(width: 10), itemBuilder: (_, i){ final a=list[i]; return _AnnonceCard(badge: a['type']??'À VENDRE', badgeColor: const Color(0xFF2ECC71), title: a['title']??'', price: '${a['price']??0} FC', image: a['image_url']); });
            })),
            const SizedBox(height: 16),

            // FOOTER
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: const [
              _FooterItem(icon: Icons.verified_user_outlined, title: 'Paiement sécurisé', sub: 'Transactions 100% sûres'),
              _FooterItem(icon: Icons.headset_mic_outlined, title: 'Support 24/7', sub: 'Nous sommes là'),
              _FooterItem(icon: Icons.workspace_premium_outlined, title: 'Meilleurs prix', sub: 'Garantie incluse'),
              _FooterItem(icon: Icons.cancel_outlined, title: 'Annulation facile', sub: 'Flexible et rapide'),
            ])),
            const SizedBox(height: 80),
          ]),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(currentIndex: 2, selectedItemColor: const Color(0xFF0D88F2), unselectedItemColor: Colors.grey, type: BottomNavigationBarType.fixed, items: [
        const BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Accueil'),
        const BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), label: 'Explorer'),
        BottomNavigationBarItem(icon: Container(padding: const EdgeInsets.all(10), decoration: const BoxDecoration(color: Color(0xFF0D88F2), shape: BoxShape.circle), child: const Icon(Icons.calendar_month, color: Colors.white)), label: 'Réserver'),
        const BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), label: 'Mes réservations'),
        const BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
      ], onTap: (i){ if(i==2) return; if(i==0) context.go('/'); if(i==3) context.push('/thix-reservation/bus/bookings'); }),
    );
  }

  Widget _buildHeroBanner() {
    return SizedBox(
      height: 190,
      child: Stack(children: [
        PageView.builder(
          controller: _heroController,
          itemCount: _heroSlides.length,
          onPageChanged: (i) => setState(() => _heroIndex = i),
          itemBuilder: (context, index) {
            final s = _heroSlides[index];
            return Container(
              height: 170,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFEAF2FE), Color(0xFFDCEBFC)]),
              ),
              child: Stack(children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [Icon(s['icon'] as IconData, size: 14, color: s['iconColor'] as Color), const SizedBox(width: 4), Text((s['badge'] as String).toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: (s['iconColor'] as Color)))]),
                      const SizedBox(height: 6),
                      Text(s['title'] as String, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0A3D62))),
                      Text(s['subtitle'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0A3D62))),
                      const SizedBox(height: 4),
                      Text(s['valid'] as String, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => context.push(s['route'] as String),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D88F2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
                        child: Text(s['cta'] as String, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ])),
                    Icon(s['illustration'] as IconData, size: 84, color: const Color(0xFF0D47A1).withOpacity(0.85)),
                  ]),
                ),
              ]),
            );
          },
        ),
        Positioned(
          left: 0, top: 60,
          child: IconButton(
            icon: const Icon(Icons.chevron_left, color: Color(0xFF0A3D62)),
            onPressed: () {
              final prev = (_heroIndex - 1 + _heroSlides.length) % _heroSlides.length;
              _heroController.animateToPage(prev, duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
            },
          ),
        ),
        Positioned(
          right: 0, top: 60,
          child: IconButton(
            icon: const Icon(Icons.chevron_right, color: Color(0xFF0A3D62)),
            onPressed: () {
              final next = (_heroIndex + 1) % _heroSlides.length;
              _heroController.animateToPage(next, duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
            },
          ),
        ),
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_heroSlides.length, (i) {
              final isActive = i == _heroIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(color: isActive ? const Color(0xFF0D88F2) : Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
              );
            }),
          ),
        ),
      ]),
    );
  }
}

class _Cat extends StatelessWidget {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  const _Cat({required this.icon, required this.label, required this.color, required this.onTap});
  @override Widget build(BuildContext context)=> InkWell(onTap: onTap, borderRadius: BorderRadius.circular(14), child: Column(children: [
    Container(width: 52, height: 52, decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color, size: 24)),
    const SizedBox(height: 6),
    Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
  ]));
}
class _SectionHeader extends StatelessWidget { final String title; final IconData? icon; final VoidCallback? onSeeAll; const _SectionHeader({required this.title, this.icon, this.onSeeAll}); @override Widget build(BuildContext context)=> Row(children: [if(icon!=null) Icon(icon, size: 18, color: const Color(0xFF0D88F2)), if(icon!=null) const SizedBox(width: 6), Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)), const Spacer(), InkWell(onTap: onSeeAll, child: Row(children: const [Text('Voir tout', style: TextStyle(fontSize: 12, color: Colors.grey)), Icon(Icons.chevron_right, size: 16, color: Colors.grey)]))]); }
class _ReservationCard extends StatelessWidget { final String label, count; final Color color; final IconData icon; const _ReservationCard({required this.label, required this.count, required this.color, required this.icon}); @override Widget build(BuildContext context)=> Expanded(child: Container(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: Column(children: [
  Container(width: 34, height: 34, decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle), child: Icon(icon, size: 17, color: color)),
  const SizedBox(height: 6),
  Text(count, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
  Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center),
]))); }
class _OfferCard extends StatelessWidget { final String title, discount, subtitle; final Color color, accent; const _OfferCard({required this.title, required this.discount, required this.subtitle, required this.color, required this.accent}); @override Widget build(BuildContext context)=> Container(width: 150, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), const SizedBox(height: 4), Text(discount, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: accent)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.black54))])) ;}
class _RestaurantCard extends StatelessWidget { final String name, category, time, price; final String? image; final double rating; const _RestaurantCard({required this.name, required this.category, required this.time, required this.price, this.image, required this.rating}); @override Widget build(BuildContext context)=> Container(width: 150, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Stack(children: [ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(12)), child: image!=null? Image.network(image!, height: 90, width: 150, fit: BoxFit.cover): Container(height: 90, color: Colors.grey.shade200, child: const Icon(Icons.restaurant))), Positioned(top: 6, right: 6, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(8)), child: Row(children: [const Icon(Icons.star, size: 10, color: Colors.amber), const SizedBox(width: 2), Text('$rating', style: const TextStyle(color: Colors.white, fontSize: 10))])))]), Padding(padding: const EdgeInsets.all(8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)), const Icon(Icons.favorite_border, size: 14)]), Text(category, style: const TextStyle(fontSize: 10, color: Colors.grey)), const SizedBox(height: 4), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(time, style: const TextStyle(fontSize: 10)), Text(price, style: const TextStyle(fontSize: 10))])]))])); }
class _AnnonceCard extends StatelessWidget { final String badge, title, price; final Color badgeColor; final String? image; const _AnnonceCard({required this.badge, required this.title, required this.price, required this.badgeColor, this.image}); @override Widget build(BuildContext context)=> Container(width: 160, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Stack(children: [ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(12)), child: image!=null? Image.network(image!, height: 90, width: 160, fit: BoxFit.cover): Container(height: 90, color: Colors.grey.shade200)), Positioned(top: 6, left: 6, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(6)), child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)))), Positioned(top: 6, right: 6, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.favorite_border, size: 14))) ]), Padding(padding: const EdgeInsets.all(8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis), const SizedBox(height: 2), Text(price, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))]))])); }
class _FooterItem extends StatelessWidget { final IconData icon; final String title, sub; const _FooterItem({required this.icon, required this.title, required this.sub}); @override Widget build(BuildContext context)=> Column(children: [Icon(icon, size: 20, color: const Color(0xFF0D88F2)), Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)), Text(sub, style: const TextStyle(fontSize: 9, color: Colors.grey))]); }
class _MoreSheet extends StatelessWidget { const _MoreSheet(); @override Widget build(BuildContext context)=> Container(padding: const EdgeInsets.all(20), child: Wrap(spacing: 20, runSpacing: 20, children: [ _Cat(icon: Icons.restaurant_rounded, label: 'Restaurant', color: const Color(0xFFF5A623), onTap: (){}), _Cat(icon: Icons.storefront_rounded, label: 'Annonces', color: const Color(0xFF0D88F2), onTap: (){}), _Cat(icon: Icons.event_rounded, label: 'Événement', color: const Color(0xFF6B3BFF), onTap: (){}), ])); }
