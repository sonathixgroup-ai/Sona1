// lib/presentation/thix_reservation/thix_reservation_home_page.dart
// V3 PHOTO REFERENCE - BLEU INSTITUTIONNEL - 6 HERO BANNERS - BUILD VERT
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
  final PageController _heroController = PageController();
  Timer? _heroTimer;
  int _heroIndex = 0;

  static const kPrimary = Color(0xFF0A3D91);
  static const kBg = Color(0xFFF5F7FB);

  // 6 HERO BANNERS HAUTE QUALITE - AUTO SCROLL
  final List<Map<String, String>> _heroSlides = [
    {
      'badge': 'PROMO FLASH',
      'title': "Jusqu'a -40%",
      'subtitle': 'sur vos reservations de bus & vols',
      'valid': 'Valable jusqu au 30 Juin 2026',
      'cta': 'Profiter maintenant',
      'route': '/thix-reservation/bus',
      'image': 'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?w=800&q=80',
    },
    {
      'badge': 'HOTELS',
      'title': 'Hotels -30%',
      'subtitle': 'Sejournez plus, payez moins',
      'valid': 'Offre limitee cette semaine',
      'cta': 'Voir les hotels',
      'route': '/thix-reservation/hotels',
      'image': 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',
    },
    {
      'badge': 'RAPIDE',
      'title': 'Taxi en 5 min',
      'subtitle': 'Course immediate, prix fixe',
      'valid': 'Disponible 24h/24',
      'cta': 'Commander un taxi',
      'route': '/thix-reservation/taxi',
      'image': 'https://images.unsplash.com/photo-1449965408869-eaa3f722e40d?w=800&q=80',
    },
    {
      'badge': 'CONFORT',
      'title': 'Bus VIP',
      'subtitle': 'Clim, Wi-Fi, Siege large',
      'valid': 'Voyagez en toute confiance',
      'cta': 'Reserver un bus',
      'route': '/thix-reservation/bus',
      'image': 'https://images.unsplash.com/photo-1570125909232-eb263c188f7e?w=800&q=80',
    },
    {
      'badge': 'EXPRESS',
      'title': 'Livraison -10%',
      'subtitle': 'Envoi express partout en ville',
      'valid': 'Valable ce mois-ci',
      'cta': 'Envoyer un colis',
      'route': '/thix-reservation/delivery',
      'image': 'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?w=800&q=80',
    },
    {
      'badge': 'VOL',
      'title': 'Vols Nationaux',
      'subtitle': 'Abidjan - Interieur a partir de 25.000 FC',
      'valid': 'Meilleurs prix garantis',
      'cta': 'Chercher un vol',
      'route': '/thix-reservation/flights',
      'image': 'https://images.unsplash.com/photo-1436491865332-7a61a109cc05?w=800&q=80',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadCounts();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _heroTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted ||!_heroController.hasClients) return;
      _heroIndex = (_heroIndex + 1) % _heroSlides.length;
      _heroController.animateToPage(_heroIndex, duration: const Duration(milliseconds: 550), curve: Curves.easeInOutCubic);
    });
  }

  Future<void> _loadCounts() async {
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) { setState(() => loadingCounts = false); return; }
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

  @override
  void dispose() { _heroTimer?.cancel(); _heroController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(10)), child: const Center(child: Text('R', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)))),
          const SizedBox(width: 10),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Text('THIX ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.black)), Text('RESERVATION', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: kPrimary))]),
            Text('Reservez tout, partout, en toute simplicite.', style: TextStyle(fontSize: 11, color: Color(0xFF6B7A99))),
          ]),
        ]),
        actions: [
          IconButton(onPressed: () => context.push('/notifications'), icon: Badge(label: const Text('3'), child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFF1F4F9), shape: BoxShape.circle), child: const Icon(Icons.notifications_none_rounded, color: Color(0xFF1A2B4D), size: 20)))),
          IconButton(onPressed: () => context.push('/profile'), icon: const CircleAvatar(radius: 16, backgroundColor: Color(0xFFD6E4FF), child: Icon(Icons.person_outline_rounded, size: 18, color: kPrimary))), const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(color: kPrimary, onRefresh: _loadCounts, child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildHero(),
          const SizedBox(height: 14),

          // CATEGORIES COMME PHOTO - 6 ICONES 3D STYLE MAIS BLEU
          Container(padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _CatEmoji(icon: Icons.directions_bus_filled_rounded, label: 'Bus', bg: const Color(0xFFEAF1FF), color: kPrimary, onTap: () => context.push('/thix-reservation/bus')),
            _CatEmoji(icon: Icons.flight_takeoff_rounded, label: 'Vol', bg: const Color(0xFFEAF1FF), color: kPrimary, onTap: () => context.push('/thix-reservation/flights')),
            _CatEmoji(icon: Icons.apartment_rounded, label: 'Hotel', bg: const Color(0xFFEAF1FF), color: kPrimary, onTap: () => context.push('/thix-reservation/hotels')),
            _CatEmoji(icon: Icons.local_taxi_rounded, label: 'Taxi', bg: const Color(0xFFFFF4E0), color: const Color(0xFFB7791F), onTap: () => context.push('/thix-reservation/taxi')),
            _CatEmoji(icon: Icons.delivery_dining_rounded, label: 'Livraison', bg: const Color(0xFFE6F4EA), color: const Color(0xFF0E8A5B), onTap: () => context.push('/thix-reservation/delivery')),
            _CatEmoji(icon: Icons.apps_rounded, label: 'Plus', bg: const Color(0xFFF1F4F9), color: const Color(0xFF64748B), onTap: () => showModalBottomSheet(context: context, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (_) => const _MoreSheet())),
          ])),
          const SizedBox(height: 16),

          // MES RESERVATIONS - SANS MOCKUP - DESIGN PHOTO
          _HeaderRow(title: 'Mes reservations', onTap: () => context.push('/thix-reservation/bus/bookings')),
          const SizedBox(height: 10),
          Row(children: [
            _ResCardClean(label: 'A venir', count: loadingCounts? '-' : '${counts['upcoming']}', icon: Icons.work_outline_rounded, color: kPrimary, bg: const Color(0xFFEAF1FF)),
            const SizedBox(width: 8),
            _ResCardClean(label: 'En cours', count: loadingCounts? '-' : '${counts['ongoing']}', icon: Icons.access_time_rounded, color: const Color(0xFFE67E22), bg: const Color(0xFFFFF4E0)),
            const SizedBox(width: 8),
            _ResCardClean(label: 'Terminees', count: loadingCounts? '-' : '${counts['completed']}', icon: Icons.check_circle_rounded, color: const Color(0xFF0E8A5B), bg: const Color(0xFFE6F4EA)),
            const SizedBox(width: 8),
            _ResCardClean(label: 'Annulees', count: loadingCounts? '-' : '${counts['cancelled']}', icon: Icons.cancel_rounded, color: const Color(0xFF64748B), bg: const Color(0xFFF1F5F9)),
          ]),
          const SizedBox(height: 18),

          // OFFRES SPECIALES - AVEC MOCKUP IMAGE
          _HeaderRow(title: 'Offres speciales pour vous', onTap: () {}),
          const SizedBox(height: 10),
          SizedBox(height: 118, child: ListView(separated: true, scrollDirection: Axis.horizontal, itemCount: 4, separatorBuilder: (_, __) => const SizedBox(width: 10), itemBuilder: (_, i) {
            final offers = [
              {'title':'Hotels','disc':'-30%','sub':'Sejournez plus,\npayez moins','img':'https://images.unsplash.com/photo-1611892440504-42a792e24d32?w=300&q=80','c1': const Color(0xFF0A3D91),'c2': const Color(0xFF2A7FFF)},
              {'title':'Vols','disc':'-20%','sub':'Sur tous les vols','img':'https://images.unsplash.com/photo-1436491865332-7a61a109cc05?w=300&q=80','c1': const Color(0xFF0B2E6B),'c2': const Color(0xFF3A8DFF)},
              {'title':'Bus','disc':'-15%','sub':'Voyagez en toute\nconfiance','img':'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?w=300&q=80','c1': const Color(0xFF0E4DA4),'c2': const Color(0xFF4A90E2)},
              {'title':'Livraison','disc':'-10%','sub':'Envoi express','img':'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?w=300&q=80','c1': const Color(0xFF0A2F6B),'c2': const Color(0xFF2D6CDF)},
            ];
            final o = offers[i];
            return _OfferWithImage(title: o['title'] as String, discount: o['disc'] as String, subtitle: o['sub'] as String, image: o['img'] as String, c1: o['c1'] as Color, c2: o['c2'] as Color);
          })),
          const SizedBox(height: 16),

          // PARRAINAGE BLEU
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFEAF1FF), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFD6E4FF))), child: Row(children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 20)),
            const SizedBox(width: 12),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Parrainez & Gagnez!', style: TextStyle(fontWeight: FontWeight.w800, color: kPrimary, fontSize: 13)), SizedBox(height: 2), Text('Invitez vos proches et gagnez jusqu a 10.000 FC par parrainage.', style: TextStyle(fontSize: 11, color: Color(0xFF5A6D8E)))])),
            FutureBuilder(future: Supabase.instance.client.from('profiles').select('avatar_url').limit(4), builder: (_, s){ final avs = (s.data as List?)?? []; return SizedBox(width: 80, height: 28, child: Stack(children: List.generate(avs.length.clamp(0,4), (i) => Positioned(left: i*18, child: CircleAvatar(radius: 13, backgroundColor: Colors.white, child: CircleAvatar(radius: 11, backgroundColor: const Color(0xFFD6E4FF))))))); }),
            const Icon(Icons.chevron_right_rounded, color: kPrimary, size: 18),
          ])),
          const SizedBox(height: 18),

          // RESTAURANTS
          _HeaderRow(title: 'Restaurants a proximite', onTap: () {}),
          const SizedBox(height: 10),
          SizedBox(height: 172, child: FutureBuilder(future: Supabase.instance.client.from('restaurants').select().eq('is_active', true).limit(6), builder: (_, snap){
            final list = (snap.data as List?)?? [];
            if(list.isEmpty) return ListView.separated(scrollDirection: Axis.horizontal, itemCount: 4, separatorBuilder: (_, __)=> const SizedBox(width: 10), itemBuilder: (_, i)=> const _RestoPlaceHolder());
            return ListView.separated(scrollDirection: Axis.horizontal, itemCount: list.length, separatorBuilder: (_, __)=> const SizedBox(width: 10), itemBuilder: (_, i){ final r=list[i]; return _RestoCard(name: r['name']?? 'Le Gout d ici', cat: r['category']?? 'Africaine', time: '20-30 min', price: '\$\$', rating: 4.6, image: r['image_url']); });
          })),
          const SizedBox(height: 18),

          // ANNONCES
          _HeaderRow(title: 'Annonces', onTap: () {}),
          const SizedBox(height: 10),
          SizedBox(height: 172, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: 3, separatorBuilder: (_, __)=> const SizedBox(width: 10), itemBuilder: (_, i){
            final ann = [
              {'badge':'A VENDRE','title':'Toyota RAV4 2021','price':'25.000.000 FC','img':'https://images.unsplash.com/photo-1552519507-da3b142c6e3d?w=400&q=80'},
              {'badge':'A LOUER','title':'Appartement 3 pieces','price':'600.000 FC / mois','img':'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=400&q=80'},
              {'badge':'SERVICE','title':'Menage a domicile','price':'A partir de 10.000 FC','img':'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=400&q=80'},
            ][i];
            return _AnnonceCard(badge: ann['badge']!, title: ann['title']!, price: ann['price']!, image: ann['img']!);
          })),
          const SizedBox(height: 18),

          // TRUST FOOTER BLEU
          Container(padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFEEF2F7))), child: const Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _Trust(icon: Icons.verified_user_outlined, t1: 'Paiement securise', t2: 'Transactions 100% sures'),
            _Trust(icon: Icons.headset_mic_outlined, t1: 'Support 24/7', t2: 'Nous sommes la'),
            _Trust(icon: Icons.workspace_premium_outlined, t1: 'Meilleurs prix', t2: 'Garantie incluse'),
            _Trust(icon: Icons.bolt_outlined, t1: 'Annulation facile', t2: 'Flexible et rapide'),
          ])),
          const SizedBox(height: 90),
        ]),
      )),
      bottomNavigationBar: Container(decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16)]), child: SafeArea(child: BottomNavigationBar(
        currentIndex: 2, selectedItemColor: kPrimary, unselectedItemColor: const Color(0xFF94A3B8), type: BottomNavigationBarType.fixed, backgroundColor: Colors.white, elevation: 0,
        onTap: (i){ if(i==0) context.go('/'); if(i==3) context.push('/thix-reservation/bus/bookings'); },
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Accueil'),
          const BottomNavigationBarItem(icon: Icon(Icons.search_rounded), label: 'Explorer'),
          BottomNavigationBarItem(icon: Container(padding: const EdgeInsets.all(11), decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle), child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 20)), label: 'Reserver'),
          const BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'Mes reservations'),
          const BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Profil'),
        ],
      ))),
    );
  }

  Widget _buildHero() {
    return SizedBox(height: 182, child: Stack(children: [
      PageView.builder(
        controller: _heroController,
        itemCount: _heroSlides.length,
        onPageChanged: (i) => setState(() => _heroIndex = i),
        itemBuilder: (_, index){
          final s = _heroSlides[index];
          return Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: const Color(0xFFEAF1FF)),
            child: Stack(children: [
              ClipRRect(borderRadius: BorderRadius.circular(18), child: Stack(children: [
                Positioned.fill(child: Image.network(s['image']!, fit: BoxFit.cover, errorBuilder: (_,__,___)=> Container(color: const Color(0xFFD6E4FF)))),
                Positioned.fill(child: Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [Color(0xFFF8FBFF), Color(0xCCEAF1FF), Color(0x330A3D91)])))),
              ])),
              Padding(padding: const EdgeInsets.fromLTRB(16, 14, 140, 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [const Icon(Icons.bolt_rounded, size: 12, color: kPrimary), const SizedBox(width: 4), Text(s['badge']!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: kPrimary, letterSpacing: 0.6))]),
                const SizedBox(height: 8),
                Text.rich(TextSpan(children: [TextSpan(text: s['title']!.split(' ').first + ' ', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F2040))), TextSpan(text: s['title']!.split(' ').skip(1).join(' '), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kPrimary))])),
                Text(s['subtitle']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A2B4D))),
                const SizedBox(height: 4),
                Text(s['valid']!, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7A99))),
                const Spacer(),
                SizedBox(height: 34, child: ElevatedButton(onPressed: ()=> context.push(s['route']!), style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)), padding: const EdgeInsets.symmetric(horizontal: 14)), child: Text(s['cta']!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)))),
              ])),
              Positioned(right: 12, top: 18, bottom: 18, child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(s['image']!, width: 110, fit: BoxFit.cover, errorBuilder: (_,__,___)=> const Icon(Icons.directions_bus_filled_rounded, size: 60, color: kPrimary)))),
            ]),
          );
        },
      ),
      Positioned(left: 8, top: 0, bottom: 0, child: Center(child: InkWell(onTap: (){ final p = (_heroIndex-1+_heroSlides.length)%_heroSlides.length; _heroController.animateToPage(p, duration: const Duration(milliseconds: 350), curve: Curves.easeOut); }, child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6)]), child: const Icon(Icons.chevron_left_rounded, size: 18, color: Color(0xFF1A2B4D)))))),
      Positioned(right: 8, top: 0, bottom: 0, child: Center(child: InkWell(onTap: (){ final n = (_heroIndex+1)%_heroSlides.length; _heroController.animateToPage(n, duration: const Duration(milliseconds: 350), curve: Curves.easeOut); }, child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6)]), child: const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF1A2B4D)))))),
      Positioned(bottom: 10, left: 0, right: 0, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(_heroSlides.length, (i){ final active = i==_heroIndex; return AnimatedContainer(duration: const Duration(milliseconds: 250), margin: const EdgeInsets.symmetric(horizontal: 3), width: active? 18:6, height: 6, decoration: BoxDecoration(color: active? kPrimary: Colors.white, border: active? null: Border.all(color: const Color(0xFFD6E4FF)), borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 3)])); }))),
    ]));
  }
}

// WIDGETS CLEAN
class _CatEmoji extends StatelessWidget {
  final IconData icon; final String label; final Color bg; final Color color; final VoidCallback onTap;
  const _CatEmoji({required this.icon, required this.label, required this.bg, required this.color, required this.onTap});
  @override Widget build(BuildContext context)=> InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: Column(children: [Container(width: 48, height: 48, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 22)), const SizedBox(height: 6), Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)))]));
}
class _HeaderRow extends StatelessWidget { final String title; final VoidCallback? onTap; const _HeaderRow({required this.title, this.onTap}); @override Widget build(BuildContext context)=> Row(children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: Color(0xFF0F172A))), const Spacer(), InkWell(onTap: onTap, child: const Row(children: [Text('Voir tout', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600)), Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF64748B))]))]); }
class _ResCardClean extends StatelessWidget { final String label, count; final IconData icon; final Color color, bg; const _ResCardClean({required this.label, required this.count, required this.icon, required this.color, required this.bg}); @override Widget build(BuildContext context)=> Expanded(child: Container(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFEEF2F7))), child: Column(children: [Container(width: 32, height: 32, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9)), child: Icon(icon, size: 16, color: color)), const SizedBox(height: 6), Text(count, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))), Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600), textAlign: TextAlign.center)]))); }
class _OfferWithImage extends StatelessWidget { final String title, discount, subtitle, image; final Color c1,c2; const _OfferWithImage({required this.title, required this.discount, required this.subtitle, required this.image, required this.c1, required this.c2}); @override Widget build(BuildContext context)=> Container(width: 162, decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [c1,c2])), child: Stack(children: [Positioned(right: -10, bottom: -6, top: 10, child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Opacity(opacity: 0.28, child: Image.network(image, width: 88, fit: BoxFit.cover, errorBuilder: (_,__,___)=> const SizedBox())))), Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)), const SizedBox(height: 4), Text(discount, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)), const SizedBox(height: 2), Text(subtitle, style: const TextStyle(color: Color(0xFFD6E8FF), fontSize: 10.5, height: 1.2))]))])); }
class _RestoPlaceHolder extends StatelessWidget { const _RestoPlaceHolder(); @override Widget build(BuildContext context)=> Container(width: 150, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: Column(children: [Container(height: 92, decoration: BoxDecoration(color: const Color(0xFFEEF2F7), borderRadius: const BorderRadius.vertical(top: Radius.circular(12))))])); }
class _RestoCard extends StatelessWidget { final String name, cat, time, price; final double rating; final String? image; const _RestoCard({required this.name, required this.cat, required this.time, required this.price, required this.rating, this.image}); @override Widget build(BuildContext context)=> Container(width: 150, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Stack(children: [ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(12)), child: image!=null? Image.network(image!, height: 92, width: 150, fit: BoxFit.cover): Container(height: 92, color: const Color(0xFFEEF2F7))), Positioned(top: 6, right: 6, child: Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2), decoration: BoxDecoration(color: Colors.black.withOpacity(0.75), borderRadius: BorderRadius.circular(7)), child: Row(children: [const Icon(Icons.star_rounded, size: 10, color: Colors.amber), const SizedBox(width: 2), Text('$rating', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700))])))]), Padding(padding: const EdgeInsets.all(8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12))), const Icon(Icons.favorite_border_rounded, size: 14, color: Color(0xFF94A3B8))]), Text(cat, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))), const SizedBox(height: 4), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(time, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))), Text(price, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)))])]))])); }
class _AnnonceCard extends StatelessWidget { final String badge, title, price, image; const _AnnonceCard({required this.badge, required this.title, required this.price, required this.image}); @override Widget build(BuildContext context){ Color bc = badge.contains('VENDRE')? const Color(0xFF0E8A5B): badge.contains('LOUER')? const Color(0xFFE67E22): const Color(0xFF0A3D91); return Container(width: 160, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFEEF2F7))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Stack(children: [ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(12)), child: Image.network(image, height: 92, width: 160, fit: BoxFit.cover, errorBuilder: (_,__,___)=> Container(height: 92, color: const Color(0xFFEEF2F7)))), Positioned(top: 6, left: 6, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: bc, borderRadius: BorderRadius.circular(6)), child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800))))]), Padding(padding: const EdgeInsets.all(8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)), const SizedBox(height: 2), Text(price, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)))]))])) ;}}
class _Trust extends StatelessWidget { final IconData icon; final String t1,t2; const _Trust({required this.icon, required this.t1, required this.t2}); @override Widget build(BuildContext context)=> Column(children: [Icon(icon, size: 18, color: const Color(0xFF0A3D91)), const SizedBox(height: 4), Text(t1, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))), Text(t2, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B)))]); }
class _MoreSheet extends StatelessWidget { const _MoreSheet(); @override Widget build(BuildContext context)=> Container(padding: const EdgeInsets.all(18), decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))), child: Wrap(spacing: 18, runSpacing: 16, children: [ _CatEmoji(icon: Icons.restaurant_rounded, label: 'Restaurant', bg: const Color(0xFFFFF4E0), color: const Color(0xFFB7791F), onTap: (){}), _CatEmoji(icon: Icons.storefront_rounded, label: 'Annonces', bg: const Color(0xFFEAF1FF), color: const Color(0xFF0A3D91), onTap: (){}), _CatEmoji(icon: Icons.event_rounded, label: 'Evenement', bg: const Color(0xFFF3E8FF), color: const Color(0xFF7C3AED), onTap: (){}), ])); }
