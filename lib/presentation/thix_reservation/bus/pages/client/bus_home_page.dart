// lib/presentation/thix_reservation/bus/pages/client/bus_home_page.dart
// V2.1 FIX SYNTAX - BUILD OK
import 'dart:async';
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
  final PageController _heroCtrl = PageController();
  Timer? _timer;
  int _heroIndex = 0;
  List<Map<String, dynamic>> _popularRoutes = [];
  bool _loadingPopular = true;
  String _userName = "Michel";
  bool _hasAgency = false;

  final List<Map<String, String>> _heroSlides = [
    {
      "title": "Reservez votre bus\nen toute simplicite",
      "sub": "Voyagez confortablement vers\nvotre destination.",
      "cta": "Reserver un bus",
      "img": "https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?w=1200&q=80",
    },
    {
      "title": "Bus VIP Climatise\nWi-Fi a bord",
      "sub": "Confort premium, prix mini\nKinshasa - Lubumbashi",
      "cta": "Voir les offres",
      "img": "https://images.unsplash.com/photo-1570125909232-eb263c188f7e?w=1200&q=80",
    },
    {
      "title": "Voyagez en toute\nsecurite 24h/24",
      "sub": "Chauffeurs verifies, bus suivis GPS",
      "cta": "Reserver maintenant",
      "img": "https://images.unsplash.com/photo-1499856871958-5b9627545d1a?w=1200&q=80",
    },
  ];

  @override void initState() {
    super.initState();
    _init();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted ||!_heroCtrl.hasClients) return;
      _heroIndex = (_heroIndex + 1) % _heroSlides.length;
      _heroCtrl.animateToPage(_heroIndex, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    });
  }

  Future<void> _init() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user!= null) {
      try {
        final p = await Supabase.instance.client.from("profiles").select("full_name").eq("id", user.id).maybeSingle();
        if (p!= null && mounted) setState(() => _userName = (p["full_name"] as String).split(" ").first);
        final agency = await Supabase.instance.client.from("bus_agencies").select("id").eq("owner_id", user.id).maybeSingle();
        if (agency!= null && mounted) setState(() => _hasAgency = true);
      } catch (_) {}
    }
    if (mounted) Future.microtask(() => context.read<AgencyDashboardProvider>().init());
    try {
      final routes = await _publicService.getPopularRoutes();
      if (mounted) setState(() { _popularRoutes = routes; _loadingPopular = false; });
    } catch (_) { if (mounted) setState(() => _loadingPopular = false); }
  }

  @override void dispose() { _timer?.cancel(); _heroCtrl.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    const kPrimary = Color(0xFF0B4FE3);
    final searchP = context.watch<BusSearchProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.menu_rounded, color: Color(0xFF0F172A)), onPressed: (){}),
        title: Row(children: [
          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.directions_bus_rounded, color: Colors.white, size: 22)),
          const SizedBox(width: 8),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Text("THIX ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A))), Text("RESERVATION", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: kPrimary))]),
            Text("Reservez simplement, voyagez sereinement.", style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
          ]),
        ]),
        actions: [
          IconButton(
            tooltip: _hasAgency? "Mon agence" : "Devenir agence",
            onPressed: () => _hasAgency? context.push("/agency/dashboard") : context.push("/agency/onboarding"),
            icon: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _hasAgency? const Color(0xFFEAF1FF) : const Color(0xFFFFF7E6), borderRadius: BorderRadius.circular(10)), child: Icon(_hasAgency? Icons.storefront_rounded : Icons.add_business_rounded, size: 18, color: _hasAgency? kPrimary : const Color(0xFFB7791F))),
          ),
          IconButton(onPressed: ()=> context.push("/notifications"), icon: Badge(label: const Text("3"), child: Container(padding: const EdgeInsets.all(7), decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle), child: const Icon(Icons.notifications_none_rounded, size: 20)))),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(onRefresh: _init, child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(12,8,12,90), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(height: 182, child: Stack(children: [
          PageView.builder(
            controller: _heroCtrl,
            itemCount: _heroSlides.length,
            onPageChanged: (i)=> setState(()=> _heroIndex=i),
            itemBuilder: (_, i){
              final s = _heroSlides[i];
              return ClipRRect(borderRadius: BorderRadius.circular(18), child: Stack(children: [
                Positioned.fill(child: Image.network(s["img"]!, fit: BoxFit.cover)),
                Positioned.fill(child: Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [Color(0xFF0B4FE3), Color(0xCC0B4FE3), Colors.transparent])))),
                Padding(padding: const EdgeInsets.fromLTRB(18,16,120,16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("Bonjour, $_userName", style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(s["title"]!, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, height: 1.15)),
                  const SizedBox(height: 6),
                  Text(s["sub"]!, style: const TextStyle(color: Color(0xFFD6E8FF), fontSize: 12, height: 1.3)),
                  const Spacer(),
                  SizedBox(height: 36, child: ElevatedButton.icon(onPressed: ()=> searchP.search(), icon: const Icon(Icons.directions_bus_filled_rounded, size: 18), label: Text(s["cta"]!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: kPrimary, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))))),
                ])),
              ]));
            },
          ),
          Positioned(bottom: 12, left: 0, right: 0, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(_heroSlides.length, (i)=> AnimatedContainer(duration: const Duration(milliseconds: 250), margin: const EdgeInsets.symmetric(horizontal: 3), width: i==_heroIndex? 18:6, height: 6, decoration: BoxDecoration(color: i==_heroIndex? Colors.white : Colors.white54, borderRadius: BorderRadius.circular(10)))))),
        ])),
        const SizedBox(height: 12),
        Container(padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _Cat(icon: Icons.apartment_rounded, label: "Hotels", color: const Color(0xFF0B4FE3), onTap: (){}),
          _Cat(icon: Icons.flight_rounded, label: "Vols", color: const Color(0xFF0E8A5B), onTap: (){}),
          _Cat(icon: Icons.directions_bus_filled_rounded, label: "Bus", color: kPrimary, active: true, onTap: (){}),
          _Cat(icon: Icons.local_taxi_rounded, label: "Transports", color: const Color(0xFFE67E22), onTap: (){}),
          _Cat(icon: Icons.local_activity_rounded, label: "Evenements", color: const Color(0xFFDB2777), onTap: (){}),
          _Cat(icon: Icons.restaurant_rounded, label: "Restaurants", color: const Color(0xFFEA580C), onTap: (){}),
          _Cat(icon: Icons.home_work_rounded, label: "Locations", color: const Color(0xFF0E8A5B), onTap: (){}),
          _Cat(icon: Icons.more_horiz_rounded, label: "Plus", color: const Color(0xFF64748B), onTap: (){}),
        ])),
        const SizedBox(height: 14),
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: Column(children: [
          Row(children: [const Text("Reservation rapide de bus", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)), const Spacer(), InkWell(onTap: (){}, child: const Row(children: [Text("Voir tout", style: TextStyle(fontSize: 11, color: kPrimary, fontWeight: FontWeight.w700)), Icon(Icons.chevron_right_rounded, size: 14, color: kPrimary)]))]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _FieldBox(icon: Icons.my_location_rounded, label: "Depart", value: searchP.departure?? "Choisir", onTap: ()=> _showCityPicker(context, true))),
            Container(margin: const EdgeInsets.symmetric(horizontal: 6), padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFF1F5F9), shape: BoxShape.circle, border: Border.all(color: const Color(0xFFE2E8F0))), child: const Icon(Icons.swap_horiz_rounded, size: 16)),
            Expanded(child: _FieldBox(icon: Icons.location_on_rounded, label: "Arrivee", value: searchP.arrival?? "Choisir", onTap: ()=> _showCityPicker(context, false))),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _FieldBox(icon: Icons.calendar_today_rounded, label: "Date de depart", value: searchP.departureDate!= null? "${searchP.departureDate!.day} ${_month(searchP.departureDate!.month)} ${searchP.departureDate!.year}" : "18 Mai 2024", onTap: ()=> _pickDate(context))),
            const SizedBox(width: 10),
            Expanded(child: _FieldBox(icon: Icons.person_outline_rounded, label: "Nombre de passagers", value: "${searchP.passengers?? 1} Passager", onTap: ()=> _pickPassengers(context))),
            const SizedBox(width: 10),
            SizedBox(height: 48, child: ElevatedButton.icon(onPressed: () async { await searchP.search(); if(context.mounted) context.push("/thix-reservation/bus/search"); }, icon: const Icon(Icons.search_rounded, size: 18), label: const Text("Rechercher", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)), style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
          ]),
        ])),
        const SizedBox(height: 16),
        Row(children: [const Text("Routes populaires", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)), const Spacer(), InkWell(onTap: ()=> context.push("/thix-reservation/bus/popular"), child: const Row(children: [Text("Voir tout", style: TextStyle(fontSize: 11, color: kPrimary, fontWeight: FontWeight.w700)), Icon(Icons.chevron_right_rounded, size: 14, color: kPrimary)]))]),
        const SizedBox(height: 10),
        if (_loadingPopular) const SizedBox(height: 170, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
        else if (_popularRoutes.isEmpty) Container(height: 80, alignment: Alignment.center, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: const Text("Aucune route", style: TextStyle(color: Colors.grey, fontSize: 12)))
        else SizedBox(height: 186, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: _popularRoutes.length, separatorBuilder: (_, __)=> const SizedBox(width: 10), itemBuilder: (_, i){
          final r = _popularRoutes[i];
          return _RouteCard(from: r["departure_city"]?? "Kinshasa", to: r["arrival_city"]?? "Matadi", date: r["next_departure_label"]?? "18 Mai - 08:00", price: "${r["min_price"]?? 5000} FCFA", img: r["arrival_city_image"]?? "https://images.unsplash.com/photo-1480714378408-67cf0d13bc1b?w=400", onTap: (){ final sp = context.read<BusSearchProvider>(); sp.setDeparture(r["departure_city"]); sp.setArrival(r["arrival_city"]); sp.search().then((_)=> context.push("/thix-reservation/bus/search")); });
        })),
        const SizedBox(height: 18),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("Nos bus pour votre confort", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            const SizedBox(height: 12),
            FutureBuilder(
              future: Supabase.instance.client.from("bus_amenities").select().eq("is_active", true).limit(5),
              builder: (_, snap){
                final list = (snap.data as List?)?? [{"label":"Sieges\nconfortables","icon_name":"seat"},{"label":"Wi-Fi\ngratuit","icon_name":"wifi"},{"label":"Climatisation","icon_name":"ac"},{"label":"Bagages\nautorises","icon_name":"luggage"},{"label":"Securite\ngarantie","icon_name":"security"}];
                return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: list.map((a){ return _ComfortItem(icon: _iconFrom(a["icon_name"]), label: a["label"]); }).toList());
              },
            ),
          ])),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFEEF4FF), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFD6E4FF))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.headset_mic_rounded, color: kPrimary, size: 20)), const SizedBox(width: 8), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Besoin daide?", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)), Text("Equipe dispo 24h/24 et 7j/7", style: TextStyle(fontSize: 10, color: Color(0xFF64748B)))]))]),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, height: 34, child: ElevatedButton(onPressed: (){}, style: ElevatedButton.styleFrom(backgroundColor: kPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)), elevation: 0), child: const Text("Nous contacter", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)))),
          ]))),
        ]),
      ]))),
    );
  }

  void _showCityPicker(BuildContext context, bool isDep){ showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))), builder: (_)=> _CityPicker(isDep: isDep)); }
  Future<void> _pickDate(BuildContext context) async { final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365))); if(d!=null && mounted) context.read<BusSearchProvider>().setDepartureDate(d); }
  void _pickPassengers(BuildContext context){ showModalBottomSheet(context: context, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))), builder: (_){ int p = context.read<BusSearchProvider>().passengers?? 1; return StatefulBuilder(builder: (c,setS)=> Container(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Passagers", style: TextStyle(fontWeight: FontWeight.w800)), Row(children: [IconButton(onPressed: ()=> setS(()=> p = (p>1? p-1:1)), icon: const Icon(Icons.remove_circle_outline)), Text("$p", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)), IconButton(onPressed: ()=> setS(()=> p++), icon: const Icon(Icons.add_circle_outline))])]), const SizedBox(height: 12), SizedBox(width: double.infinity, child: ElevatedButton(onPressed: (){ context.read<BusSearchProvider>().setPassengers(p); Navigator.pop(c); }, child: const Text("Confirmer")))]))); }); }
  String _month(int m){ const ms=["","Jan","Fev","Mar","Avr","Mai","Juin","Juil","Aout","Sep","Oct","Nov","Dec"]; return ms[m]; }
  IconData _iconFrom(String? n){ switch(n){ case "wifi": return Icons.wifi_rounded; case "ac": return Icons.ac_unit_rounded; case "luggage": return Icons.work_rounded; case "seat": return Icons.airline_seat_recline_extra_rounded; case "security": return Icons.verified_user_rounded; default: return Icons.check_circle_outline_rounded; } }
}

class _Cat extends StatelessWidget { final IconData icon; final String label; final Color color; final bool active; final VoidCallback onTap; const _Cat({required this.icon, required this.label, required this.color, this.active=false, required this.onTap}); @override Widget build(BuildContext context)=> InkWell(onTap: onTap, borderRadius: BorderRadius.circular(10), child: Column(children: [Container(width: 42, height: 42, decoration: BoxDecoration(color: active? const Color(0xFFEAF1FF) : color.withOpacity(0.1), borderRadius: BorderRadius.circular(11)), child: Icon(icon, size: 20, color: color)), const SizedBox(height: 4), Text(label, style: TextStyle(fontSize: 10, fontWeight: active? FontWeight.w800 : FontWeight.w600, color: active? const Color(0xFF0B4FE3) : const Color(0xFF334155)))])); }
class _FieldBox extends StatelessWidget { final IconData icon; final String label, value; final VoidCallback onTap; const _FieldBox({required this.icon, required this.label, required this.value, required this.onTap}); @override Widget build(BuildContext context)=> InkWell(onTap: onTap, borderRadius: BorderRadius.circular(10), child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10), decoration: BoxDecoration(color: const Color(0xFFF8FAFF), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFEEF2F7))), child: Row(children: [Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 14, color: const Color(0xFF0B4FE3))), const SizedBox(width: 8), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)), Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))) ])), const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF94A3B8))]))); }
class _RouteCard extends StatelessWidget { final String from, to, date, price, img; final VoidCallback onTap; const _RouteCard({required this.from, required this.to, required this.date, required this.price, required this.img, required this.onTap}); @override Widget build(BuildContext context)=> InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: Container(width: 148, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFEEF2F7))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(12)), child: Image.network(img, height: 88, width: 148, fit: BoxFit.cover, errorBuilder: (_,__,___)=> Container(height: 88, color: const Color(0xFFEEF2F7)))), Padding(padding: const EdgeInsets.all(9), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("$from -> $to", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5)), const SizedBox(height: 4), Row(children: [const Icon(Icons.calendar_today_rounded, size: 10, color: Color(0xFF94A3B8)), const SizedBox(width: 3), Text(date, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)))]), const SizedBox(height: 4), Text.rich(TextSpan(children: [const TextSpan(text: "A partir de ", style: TextStyle(fontSize: 10, color: Color(0xFF64748B))), TextSpan(text: price, style: const TextStyle(fontSize: 11, color: Color(0xFF0E8A5B), fontWeight: FontWeight.w800))]))]))]))); }
class _ComfortItem extends StatelessWidget { final IconData icon; final String label; const _ComfortItem({required this.icon, required this.label}); @override Widget build(BuildContext context)=> Column(children: [Container(width: 40, height: 40, decoration: const BoxDecoration(color: Color(0xFFEEF4FF), shape: BoxShape.circle), child: Icon(icon, size: 18, color: const Color(0xFF0B4FE3))), const SizedBox(height: 5), Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF475569), height: 1.2))]); }
class _CityPicker extends StatefulWidget { final bool isDep; const _CityPicker({required this.isDep}); @override State<_CityPicker> createState()=> _CityPickerState(); }
class _CityPickerState extends State<_CityPicker>{
  List<String> all=[], filtered=[]; bool loading=true; final ctrl=TextEditingController();
  @override void initState(){ super.initState(); _load(); ctrl.addListener(()=> setState(()=> filtered = all.where((c)=> c.toLowerCase().contains(ctrl.text.toLowerCase())).toList())); }
  Future<void> _load() async { try{ final r= await Supabase.instance.client.from("cities").select("name").order("name").limit(80); all=(r as List).map((e)=> e["name"] as String).toList(); if(all.isEmpty) throw "empty"; }catch(_){ all=["Kinshasa","Lubumbashi","Goma","Bukavu","Kisangani","Mbuji-Mayi","Kananga","Kolwezi","Matadi","Mbandaka","Beni","Butembo","Bunia","Kindu","Kalemie","Kikwit","Boma"]; } setState((){ filtered=all; loading=false; }); }
  @override Widget build(BuildContext context){ return DraggableScrollableSheet(initialChildSize: 0.7, maxChildSize: 0.9, minChildSize: 0.5, expand: false, builder: (_, c)=> Column(children: [const SizedBox(height: 10), Container(width: 40,height: 4,decoration: BoxDecoration(color: const Color(0xFFE2E8F0),borderRadius: BorderRadius.circular(10))), const SizedBox(height: 14), Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: TextField(controller: ctrl, decoration: InputDecoration(hintText: widget.isDep?"Depart":"Arrivee", prefixIcon: const Icon(Icons.search_rounded), filled: true, fillColor: const Color(0xFFF1F5F9), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)))), const SizedBox(height: 10), if(loading) const Expanded(child: Center(child: CircularProgressIndicator())) else Expanded(child: ListView.separated(controller: c, itemCount: filtered.length, separatorBuilder: (_, __)=> const Divider(height: 1), itemBuilder: (_, i)=> ListTile(leading: Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: const Color(0xFFEAF1FF), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF0B4FE3))), title: Text(filtered[i], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)), subtitle: const Text("RDC", style: TextStyle(fontSize: 10)), onTap: (){ final p=context.read<BusSearchProvider>(); if(widget.isDep) p.setDeparture(filtered[i]); else p.setArrival(filtered[i]); Navigator.pop(context); })))) ]); }
}
