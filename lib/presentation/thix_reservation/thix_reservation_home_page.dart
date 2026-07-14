// lib/presentation/thix_reservation/thix_reservation_home_page.dart
// DESIGN V2 - INSTITUTIONAL BLUE - BUILD VERT
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ThixReservationHomePage extends StatefulWidget {
  const ThixReservationHomePage({super.key});
  @override State<ThixReservationHomePage> createState() => _ThixReservationHomePageState();
}

class _ThixReservationHomePageState extends State<ThixReservationHomePage> {
  Map<String, int> counts = {'upcoming': 0, 'ongoing': 0, 'completed': 0, 'cancelled': 0};
  bool loadingCounts = true;
  final PageController _heroController = PageController();
  Timer? _heroTimer;
  int _heroIndex = 0;

  // Palette institutionnelle - PLUS DE JAUNE
  static const kPrimary = Color(0xFF0A3D91);
  static const kPrimaryLight = Color(0xFF0D5BC2);
  static const kBackground = Color(0xFFF5F7FB);
  static const kSuccess = Color(0xFF0E8A5B);

  final List<Map<String, dynamic>> _heroSlides = [
    {
      'badge': 'PROMO FLASH',
      'title': "Jusqu'à -40%",
      'subtitle': 'bus & vols nationaux',
      'valid': 'Valable jusqu’au 30 Juin 2026',
      'cta': 'Réserver maintenant',
      'route': '/thix-reservation/bus',
      'image': 'assets/images/hero_bus_plane.png', // mets ton image du screenshot
      'gradient': [Color(0xFF0A3D91), Color(0xFF1E6BFF)],
    },
    {
      'badge': 'CONFIANCE',
      'title': 'Paiement Sécurisé',
      'subtitle': 'Mobile Money & Carte',
      'valid': 'Transactions 100% garanties',
      'cta': 'En savoir plus',
      'route': '/thix-reservation/bus',
      'image': null,
      'gradient': [Color(0xFF0B2E6B), Color(0xFF134EB5)],
    },
  ];

  @override void initState() { super.initState(); _loadCounts(); _startHeroAutoScroll(); }
  void _startHeroAutoScroll() {
    _heroTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted ||!_heroController.hasClients) return;
      _heroIndex = (_heroIndex + 1) % _heroSlides.length;
      _heroController.animateToPage(_heroIndex, duration: const Duration(milliseconds: 600), curve: Curves.easeInOut);
    });
  }
  Future<void> _loadCounts() async {
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) return;
      final res = await Supabase.instance.client.from('bus_bookings').select('status').eq('user_id', uid);
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
  @override void dispose() { _heroTimer?.cancel(); _heroController.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(10)),
            child: const Center(child: Text('R', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20))),
          ),
          const SizedBox(width: 10),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Text('THIX ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.black)), Text('RÉSERVATION', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: kPrimary))]),
            Text('La plateforme nationale de réservation', style: TextStyle(fontSize: 11, color: Color(0xFF6B7A99), fontWeight: FontWeight.w500)),
          ]),
        ]),
        actions: [
          IconButton(onPressed: (){}, icon: Badge(label: const Text('3'), child: const Icon(Icons.notifications_none_rounded, color: Color(0xFF1A2B4D)))),
          IconButton(onPressed: (){}, icon: const Icon(Icons.account_circle_outlined, color: Color(0xFF1A2B4D))), const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        color: kPrimary,
        onRefresh: _loadCounts,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildPremiumHero(),
            const SizedBox(height: 16),

            // CATEGORIES INSTITUTIONNELLES
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0,4))]),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _CatPro(icon: Icons.directions_bus_filled_rounded, label: 'Bus', onTap: ()=> context.push('/thix-reservation/bus')),
                _CatPro(icon: Icons.flight_takeoff_rounded, label: 'Vol', onTap: ()=> context.push('/thix-reservation/flights')),
                _CatPro(icon: Icons.king_bed_rounded, label: 'Hôtel', onTap: ()=> context.push('/thix-reservation/hotels')),
                _CatPro(icon: Icons.local_taxi_rounded, label: 'Taxi', onTap: ()=> context.push('/thix-reservation/taxi')),
                _CatPro(icon: Icons.delivery_dining_rounded, label: 'Livraison', onTap: ()=> context.push('/thix-reservation/delivery')),
                _CatPro(icon: Icons.apps_rounded, label: 'Plus', isMore: true, onTap: ()=> showModalBottomSheet(context: context, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), builder: (_)=> const _MoreSheetPro())),
              ]),
            ),
            const SizedBox(height: 20),

            _SectionPro(title: 'Mes réservations', onSeeAll: ()=> context.push('/thix-reservation/bus/bookings')),
            const SizedBox(height: 10),
            Row(children: [
              _ResPro(label: 'À venir', count: loadingCounts? '—' : '${counts['upcoming']}', color: kPrimary, icon: Icons.luggage_rounded),
              const SizedBox(width: 10),
              _ResPro(label: 'En cours', count: loadingCounts? '—' : '${counts['ongoing']}', color: const Color(0xFFE67E22), icon: Icons.access_time_filled_rounded),
              const SizedBox(width: 10),
              _ResPro(label: 'Terminées', count: loadingCounts? '—' : '${counts['completed']}', color: kSuccess, icon: Icons.check_circle_rounded),
              const SizedBox(width: 10),
              _ResPro(label: 'Annulées', count: loadingCounts? '—' : '${counts['cancelled']}', color: const Color(0xFF95A1B5), icon: Icons.cancel_rounded),
            ]),
            const SizedBox(height: 20),

            _SectionPro(title: 'Offres spéciales pour vous', onSeeAll: (){}),
            const SizedBox(height: 10),
            SizedBox(height: 116, child: ListView(scrollDirection: Axis.horizontal, children: const [
              _OfferPro(title: 'Hôtels', discount: '-30%', subtitle: 'Séjournez plus,\npayez moins', colors: [Color(0xFF0A3D91), Color(0xFF2A7FFF)]),
              SizedBox(width: 10),
              _OfferPro(title: 'Vols', discount: '-20%', subtitle: 'Sur tous les vols\nnationaux', colors: [Color(0xFF123B7A), Color(0xFF3A8DFF)]),
              SizedBox(width: 10),
              _OfferPro(title: 'Bus', discount: '-15%', subtitle: 'Voyagez en toute\nconfiance', colors: [Color(0xFF0E4DA4), Color(0xFF4A90E2)]),
              SizedBox(width: 10),
              _OfferPro(title: 'Livraison', discount: '-10%', subtitle: 'Envoi express\n24h/24', colors: [Color(0xFF0A2F6B), Color(0xFF2D6CDF)]),
            ])),
            const SizedBox(height: 18),

            // PARRAINAGE BLEU
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFEAF1FF), Colors.white]), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFD6E4FF))),
              child: Row(children: [
                Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 22)),
                const SizedBox(width: 12),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Parrainez & Gagnez!', style: TextStyle(fontWeight: FontWeight.w800, color: kPrimary, fontSize: 13)),
                  SizedBox(height: 2),
                  Text.rich(TextSpan(style: TextStyle(fontSize: 11, color: Color(0xFF5A6D8E)), children: [TextSpan(text: 'Gagnez jusqu’à '), TextSpan(text: '10.000 FC', style: TextStyle(color: kPrimary, fontWeight: FontWeight.w800)), TextSpan(text: ' par ami parrainé.')])),
                ])),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: kPrimary),
              ]),
            ),
            const SizedBox(height: 20),

            _SectionPro(title: 'Restaurants à proximité', onSeeAll: (){}),
            const SizedBox(height: 10),
            SizedBox(height: 176, child: FutureBuilder(
              future: Supabase.instance.client.from('restaurants').select().eq('is_active', true).limit(6),
              builder: (_, snap){
                final list = (snap.data as List?)?? [];
                if(list.isEmpty) return ListView.separated(scrollDirection: Axis.horizontal, itemCount: 4, separatorBuilder: (_,__)=> const SizedBox(width: 12), itemBuilder: (_, i)=> const _RestaurantProPlaceholder());
                return ListView.separated(scrollDirection: Axis.horizontal, itemCount: list.length, separatorBuilder: (_,__)=> const SizedBox(width: 12), itemBuilder: (_, i){ final r=list[i]; return _RestaurantCardPro(name: r['name'], cat: r['category']??'Africain', time: '20-30 min', rating: 4.6, image: r['image_url']); });
              },
            )),
            const SizedBox(height: 20),

            _SectionPro(title: 'Annonces vérifiées', onSeeAll: (){}),
            const SizedBox(height: 10),
            SizedBox(height: 178, child: ListView(scrollDirection: Axis.horizontal, children: const [
              _AnnoncePro(badge: 'À VENDRE', title: 'Toyota RAV4 2021', price: '25.000.000 FC', color: kPrimary),
              SizedBox(width: 12),
              _AnnoncePro(badge: 'À LOUER', title: 'Appart 3 pièces', price: '600.000 FC / mois', color: Color(0xFF0E8A5B)),
              SizedBox(width: 12),
              _AnnoncePro(badge: 'SERVICE', title: 'Ménage pro', price: 'Dès 10.000 FC', color: kPrimary),
            ])),
            const SizedBox(height: 20),

            // TRUST FOOTER BLEU
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFEEF2F7))),
              child: const Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _TrustItem(icon: Icons.verified_user_rounded, title: 'Paiement sécurisé'),
                _TrustItem(icon: Icons.support_agent_rounded, title: 'Support 24/7'),
                _TrustItem(icon: Icons.workspace_premium_rounded, title: 'Prix garantis'),
                _TrustItem(icon: Icons.bolt_rounded, title: 'Rapide & fiable'),
              ]),
            ),
            const SizedBox(height: 90),
          ]),
        ),
      ),
      bottomNavigationBar: _buildProBottomBar(context),
    );
  }

  Widget _buildPremiumHero() {
    return SizedBox(
      height: 196,
      child: Stack(children: [
        PageView.builder(
          controller: _heroController,
          itemCount: _heroSlides.length,
          onPageChanged: (i)=> setState(()=> _heroIndex=i),
          itemBuilder: (_, index){
            final s = _heroSlides[index];
            return Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: s['gradient'] as List<Color>)),
              child: Stack(children: [
                Positioned(right: -10, bottom: 0, child: Opacity(opacity: 0.18, child: Icon(index==0? Icons.directions_bus_filled_rounded : Icons.verified_user_rounded, size: 160, color: Colors.white))),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white30)), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.bolt_rounded, size: 12, color: Colors.white), const SizedBox(width: 4), Text(s['badge'] as String, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.6))])),
                      const SizedBox(height: 12),
                      Text(s['title'] as String, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, height: 1.0)),
                      Text(s['subtitle'] as String, style: const TextStyle(color: Color(0xFFD6E8FF), fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text(s['valid'] as String, style: const TextStyle(color: Color(0xFFA9C6FF), fontSize: 11)),
                      const Spacer(),
                      SizedBox(height: 36, child: ElevatedButton(onPressed: ()=> context.push(s['route'] as String), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: kPrimary, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(horizontal: 16)), child: Text(s['cta'] as String, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)))),
                    ])),
                    const SizedBox(width: 12),
                    // Illustration - utilise ton image jaune du screenshot ici
                    if(index==0) Image.asset('assets/bus_plane.png', width: 132, errorBuilder: (_,__,___)=> const Icon(Icons.airport_shuttle_rounded, size: 90, color: Colors.white))
                    else const Icon(Icons.shield_rounded, size: 90, color: Colors.white),
                  ]),
                ),
              ]),
            );
          },
        ),
        Positioned(bottom: 10, left: 0, right: 0, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(_heroSlides.length, (i)=> AnimatedContainer(duration: const Duration(milliseconds: 300), margin: const EdgeInsets.symmetric(horizontal: 3), width: i==_heroIndex? 20:6, height: 6, decoration: BoxDecoration(color: i==_heroIndex? Colors.white : Colors.white54, borderRadius: BorderRadius.circular(10)))))),
      ]),
    );
  }

  Widget _buildProBottomBar(BuildContext context){
    return Container(
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20)]),
      child: SafeArea(child: BottomNavigationBar(
        currentIndex: 2, selectedItemColor: kPrimary, unselectedItemColor: const Color(0xFF9AA8C3), type: BottomNavigationBarType.fixed, backgroundColor: Colors.white, elevation: 0,
        onTap: (i){ if(i==0) context.go('/'); if(i==3) context.push('/thix-reservation/bus/bookings'); },
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Accueil'),
          const BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), label: 'Explorer'),
          BottomNavigationBarItem(icon: Container(padding: const EdgeInsets.all(12), decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Color(0x400A3D91), blurRadius: 12)]), child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 22)), label: 'Réserver'),
          const BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'Réservations'),
          const BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Profil'),
        ],
      )),
    );
  }
}

// --- WIDGETS PRO ---
class _CatPro extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap; final bool isMore;
  const _CatPro({required this.icon, required this.label, required this.onTap, this.isMore=false});
  @override Widget build(BuildContext context)=> InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Column(children: [
    Container(width: 54, height: 54, decoration: BoxDecoration(color: isMore? const Color(0xFFF1F4F9) : const Color(0xFF0A3D91).withOpacity(0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: isMore? Colors.transparent : const Color(0xFFD6E4FF))), child: Icon(icon, color: isMore? const Color(0xFF6B7A99) : const Color(0xFF0A3D91), size: 26)),
    const SizedBox(height: 7), Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF1A2B4D))),
  ]));
}
class _SectionPro extends StatelessWidget { final String title; final VoidCallback? onSeeAll; const _SectionPro({required this.title, this.onSeeAll}); @override Widget build(BuildContext context)=> Row(children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5, color: Color(0xFF0F2040))), const Spacer(), InkWell(onTap: onSeeAll, child: const Row(children: [Text('Voir tout', style: TextStyle(fontSize: 12, color: Color(0xFF6B7A99), fontWeight: FontWeight.w600)), Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF6B7A99))]))]); }
class _ResPro extends StatelessWidget { final String label, count; final Color color; final IconData icon; const _ResPro({required this.label, required this.count, required this.color, required this.icon}); @override Widget build(BuildContext context)=> Expanded(child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFEEF2F7)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 28, height: 28, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 16, color: color)), const SizedBox(height: 8), Text(count, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F2040))), Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF7A8AA8), fontWeight: FontWeight.w600))]))); }
class _OfferPro extends StatelessWidget { final String title, discount, subtitle; final List<Color> colors; const _OfferPro({required this.title, required this.discount, required this.subtitle, required this.colors}); @override Widget build(BuildContext context)=> Container(width: 158, padding: const EdgeInsets.all(14), decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, fontSize: 12)), const SizedBox(height: 6), Text(discount, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(color: Color(0xFFD6E8FF), fontSize: 11, height: 1.2))])) ;}
class _RestaurantProPlaceholder extends StatelessWidget { const _RestaurantProPlaceholder(); @override Widget build(BuildContext context)=> Container(width: 156, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: Column(children: [Container(height: 96, decoration: BoxDecoration(color: const Color(0xFFEEF2F7), borderRadius: const BorderRadius.vertical(top: Radius.circular(16))))])); }
class _RestaurantCardPro extends StatelessWidget { final String name, cat, time; final double rating; final String? image; const _RestaurantCardPro({required this.name, required this.cat, required this.time, required this.rating, this.image}); @override Widget build(BuildContext context)=> Container(width: 156, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Stack(children: [ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), child: image!=null? Image.network(image!, height: 96, width: 156, fit: BoxFit.cover) : Container(height: 96, color: const Color(0xFFEEF2F7), child: const Icon(Icons.restaurant_rounded, color: Color(0xFF9AA8C3)))), Positioned(top: 8, right: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), decoration: BoxDecoration(color: Colors.black.withOpacity(0.75), borderRadius: BorderRadius.circular(8)), child: Row(children: [const Icon(Icons.star_rounded, size: 12, color: Color(0xFFFFC83D)), const SizedBox(width: 2), Text('$rating', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))])))]), Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: Color(0xFF0F2040))), Text(cat, style: const TextStyle(fontSize: 11, color: Color(0xFF7A8AA8))), const SizedBox(height: 6), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(time, style: const TextStyle(fontSize: 11, color: Color(0xFF7A8AA8))), const Text('\$\$', style: TextStyle(fontSize: 11, color: Color(0xFF7A8AA8)))])]))])); }
class _AnnoncePro extends StatelessWidget { final String badge, title, price; final Color color; const _AnnoncePro({required this.badge, required this.title, required this.price, required this.color}); @override Widget build(BuildContext context)=> Container(width: 168, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFEEF2F7))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Stack(children: [Container(height: 96, decoration: BoxDecoration(color: const Color(0xFFF1F4F9), borderRadius: const BorderRadius.vertical(top: Radius.circular(16)))), Positioned(top: 8, left: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)), child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800))))]), Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)), const SizedBox(height: 4), Text(price, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF0A3D91)))]))])) ;}
class _TrustItem extends StatelessWidget { final IconData icon; final String title; const _TrustItem({required this.icon, required this.title}); @override Widget build(BuildContext context)=> Column(children: [Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: const Color(0xFF0A3D91).withOpacity(0.08), borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 18, color: const Color(0xFF0A3D91))), const SizedBox(height: 6), Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF1A2B4D)))]); }
class _MoreSheetPro extends StatelessWidget { const _MoreSheetPro(); @override Widget build(BuildContext context)=> Container(padding: const EdgeInsets.all(22), decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))), child: Wrap(spacing: 18, runSpacing: 18, children: [ _CatPro(icon: Icons.restaurant_rounded, label: 'Restaurant', onTap: (){}), _CatPro(icon: Icons.storefront_rounded, label: 'Annonces', onTap: (){}), _CatPro(icon: Icons.event_rounded, label: 'Événement', onTap: ()=> context.push('/thix-event')), ])); }
