// lib/presentation/thix_reservation/delivery/pages/client/delivery_home_page.dart
// SANS MOCK-UP - 100% SUPABASE - BUILD WEB FIX
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:thix_id/nav.dart';
import '../../providers/delivery_client_provider.dart';
import '../../data/delivery_models.dart';

class DeliveryHomePage extends StatefulWidget {
  const DeliveryHomePage({super.key});
  @override
  State<DeliveryHomePage> createState() => _DeliveryHomePageState();
}

class _DeliveryHomePageState extends State<DeliveryHomePage> {
  String _selectedCat = "Livraison colis";
  final ScrollController _scrollCtrl = ScrollController();
  final GlobalKey _formKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeliveryClientProvider>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: _buildAppBar(),
      body: Consumer<DeliveryClientProvider>(
        builder: (context, prov, _) {
          if (prov.isLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF5B2BD6)));
          }
          return SingleChildScrollView(
            controller: _scrollCtrl,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHero(prov),
                const SizedBox(height: 12),
                _buildCategories(),
                const SizedBox(height: 12),
                _buildFormCard(prov),
                const SizedBox(height: 12),
                _buildActionsRapides(),
                const SizedBox(height: 12),
                _buildOffresReelles(prov),
                const SizedBox(height: 12),
                _buildHowItWorks(),
                const SizedBox(height: 10),
                _buildHelp(),
                const SizedBox(height: 90),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leadingWidth: 46,
      leading: Padding(padding: const EdgeInsets.only(left: 10), child: Container(decoration: BoxDecoration(color: const Color(0xFFF6F5FF), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.menu_rounded, size: 18))),
      title: Row(children: [
        Container(width: 30, height: 30, decoration: BoxDecoration(color: const Color(0xFF5B2BD6), borderRadius: BorderRadius.circular(7)), child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 16)),
        const SizedBox(width: 6),
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Text("THIX ", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Colors.black)), Text("RESERVATION", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Color(0xFF5B2BD6)))]), Text("Livrez vos colis en toute simplicité.", style: TextStyle(fontSize: 8.5, color: Color(0xFF8B8BA3)))]),
      ]),
      actions: [
        InkWell(onTap: () => context.push(AppRoutes.deliveryTracking), child: Container(width: 32, height: 32, decoration: const BoxDecoration(color: Color(0xFFF6F5FF), shape: BoxShape.circle), child: const Icon(Icons.notifications_none_rounded, size: 18))),
        const SizedBox(width: 10),
        InkWell(onTap: () => context.push(AppRoutes.deliveryAdminDashboard), child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: const Color(0xFF5B2BD6), borderRadius: BorderRadius.circular(20)), child: const Row(children: [Icon(Icons.admin_panel_settings_rounded, size: 14, color: Colors.white), SizedBox(width: 4), Text("ADMIN", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800))]))),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget _buildHero(DeliveryClientProvider prov) {
    return Container(height: 148, decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: const LinearGradient(colors: [Color(0xFF5B2BD6), Color(0xFF7C4DFF)])), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("Bonjour, ${prov.userName.isEmpty? 'Michel' : prov.userName} 👋", style: const TextStyle(color: Color(0xFFD9CCFF), fontSize: 9.5, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      const SizedBox(width: 165, child: Text("Envoyez ou recevez vos colis en toute simplicité", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800, height: 1.15))),
      const Spacer(),
      InkWell(onTap: () => _scrollToForm(), child: Container(height: 30, padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.inventory_2_rounded, size: 14, color: Color(0xFF5B2BD6)), SizedBox(width: 6), Text("Envoyer un colis", style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700))]))) ])));
  }

  Widget _buildCategories() {
    final cats = [
      {'icon': Icons.apartment_rounded, 'label': 'Hôtels', 'color': const Color(0xFF0A7AFF), 'route': '/thix-reservation/hotels'},
      {'icon': Icons.flight_rounded, 'label': 'Vols', 'color': const Color(0xFF00B26A), 'route': '/thix-reservation/flights'},
      {'icon': Icons.directions_bus_filled_rounded, 'label': 'Bus', 'color': const Color(0xFFFF8A00), 'route': '/thix-reservation/bus'},
      {'icon': Icons.directions_car_filled_rounded, 'label': 'Transports', 'color': const Color(0xFF5B5BD6), 'route': '/thix-reservation/taxi'},
      {'icon': Icons.inventory_2_rounded, 'label': 'Livraison colis', 'color': const Color(0xFF5B2BD6), 'route': AppRoutes.deliveryHome},
      {'icon': Icons.local_activity_rounded, 'label': 'Évènements', 'color': const Color(0xFFE93A5E), 'route': '/thix-event'},
    ];
    return Container(padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: cats.map((c) => InkWell(onTap: () { setState(() => _selectedCat = c['label'] as String); if ((c['route'] as String)!= AppRoutes.deliveryHome) context.push(c['route'] as String); }, child: Column(children: [Container(width: 36, height: 36, decoration: BoxDecoration(color: (c['color'] as Color).withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(c['icon'] as IconData, size: 18, color: c['color'] as Color)), const SizedBox(height: 4), Text(c['label'] as String, style: TextStyle(fontSize: 8.5, fontWeight: _selectedCat==c['label']? FontWeight.w700:FontWeight.w600))]))).toList()));
  }

  Widget _buildFormCard(DeliveryClientProvider prov) {
    return Container(key: _formKey, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text("Envoyer un colis", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
      const SizedBox(height: 10),
      Row(children: [_toggleBtn("National", prov.isNational, () => prov.setNational(true)), const SizedBox(width: 8), _toggleBtn("International",!prov.isNational, () => prov.setNational(false))]),
      const SizedBox(height: 10),
      Row(children: [Expanded(child: _fieldBox("Expéditeur", prov.fromCity.isEmpty? "Choisir ville" : prov.fromCity, prov.fromCity.isEmpty? "Admin doit créer routes" : "Départ", Icons.person_pin_circle_outlined, () => _pickCity(true, prov))), Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: InkWell(onTap: () => prov.swapCities(), child: Container(width: 28, height: 28, decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE8E8F0)), shape: BoxShape.circle), child: const Icon(Icons.swap_horiz_rounded, size: 14, color: Color(0xFF5B2BD6))))), Expanded(child: _fieldBox("Destinataire", prov.toCity.isEmpty? "Choisir ville" : prov.toCity, prov.toCity.isEmpty? "Admin doit créer routes" : "Arrivée", Icons.location_on_outlined, () => _pickCity(false, prov)))]),
      const SizedBox(height: 8),
      Row(children: [Expanded(child: _smallDropdown("Poids", prov.weightKg==0? "Choisir" : "${prov.weightKg} kg", Icons.scale_outlined, () => _pickWeight(prov))), const SizedBox(width: 6), Expanded(child: _smallDropdown("Mode", prov.deliveryModeLabel.isEmpty? "Choisir" : prov.deliveryModeLabel, Icons.local_shipping_outlined, () => _pickMode(prov)))]),
      const SizedBox(height: 10),
      SizedBox(width: double.infinity, height: 38, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5B2BD6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0), onPressed: prov.isCalculating? null : () { if (prov.fromCity.isEmpty || prov.toCity.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sélectionnez départ et arrivée - Admin doit créer le prix du trajet"))); return; } if (prov.calculatedPrice==0) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Trajet non tarifé par admin"))); return; } context.push(AppRoutes.deliveryCheckout); }, child: Text(prov.calculatedPrice>0? "${prov.calculatedPrice.toInt()} FCFA - Continuer" : "Calculer le prix et continuer", style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700)))),
    ]));
  }

  Widget _toggleBtn(String label, bool sel, VoidCallback tap) => InkWell(onTap: tap, child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), decoration: BoxDecoration(color: sel? const Color(0xFFF0EBFF) : Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: sel? const Color(0xFF5B2BD6) : const Color(0xFFE8E8F0))), child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: sel? const Color(0xFF5B2BD6) : const Color(0xFF8B8BA3)))));
  Widget _fieldBox(String head, String city, String sub, IconData icon, VoidCallback tap) => InkWell(onTap: tap, child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFFBFAFF), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFF0EBFF))), child: Row(children: [Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: const Color(0xFFF0EBFF), borderRadius: BorderRadius.circular(6)), child: Icon(icon, size: 12, color: const Color(0xFF5B2BD6))), const SizedBox(width: 6), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(head, style: const TextStyle(fontSize: 7.5, color: Color(0xFF8B8BA3))), Text(city, maxLines:1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700)), Text(sub, style: const TextStyle(fontSize: 7, color: Color(0xFF8B8BA3)))]))])));

  Widget _smallDropdown(String head, String value, IconData icon, VoidCallback tap) => InkWell(onTap: tap, child: Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: const Color(0xFFFBFAFF), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFF0EBFF))), child: Row(children: [Icon(icon, size: 12, color: const Color(0xFF5B2BD6)), const SizedBox(width: 4), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(head, style: const TextStyle(fontSize: 7, color: Color(0xFF8B8BA3))), Row(children: [Expanded(child: Text(value, maxLines:1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700))), const Icon(Icons.keyboard_arrow_down_rounded, size: 12)])]))])));

  Widget _buildActionsRapides() {
    final actions = [
      {'icon': Icons.inventory_2_outlined, 'title': 'Suivre un colis', 'route': AppRoutes.deliveryTracking},
      {'icon': Icons.assignment_outlined, 'title': 'Mes envois', 'route': AppRoutes.deliveryHistory},
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Actions rapides", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)), const SizedBox(height: 8), Row(children: actions.map((a) => Expanded(child: Container(margin: const EdgeInsets.only(right: 6), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)), child: InkWell(onTap: () => context.push(a['route'] as String), child: Row(children: [Icon(a['icon'] as IconData, size: 16, color: const Color(0xFF5B2BD6)), const SizedBox(width: 8), Text(a['title'] as String, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700))]))))).toList())]);
  }

  // SANS MOCK - QUE DU REEL SUPABASE
  Widget _buildOffresReelles(DeliveryClientProvider prov) {
    if (prov.offers.isEmpty) {
      return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)), child: const Row(children: [Icon(Icons.local_offer_outlined, size: 14, color: Color(0xFF8B8BA3)), SizedBox(width: 8), Text("Aucune offre disponible - Admin doit créer offres", style: TextStyle(fontSize: 10, color: Color(0xFF8B8BA3)))]));
    }
    return Column(children: [
      const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("Offres du moment", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800))]),
      const SizedBox(height: 8),
      SizedBox(height: 110, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: prov.offers.length, separatorBuilder: (_,__)=> const SizedBox(width: 8), itemBuilder: (_, i){
        final o = prov.offers[i];
        return InkWell(onTap: () => context.push(AppRoutes.deliveryCheckout), child: Container(width: 120, padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: const Color(0xFF00B26A), borderRadius: BorderRadius.circular(6)), child: Text(o.badge, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700))),
          const SizedBox(height: 6),
          Text(o.title, maxLines:1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700)),
          Text(o.subtitle, maxLines:1, style: const TextStyle(fontSize: 8, color: Color(0xFF8B8BA3))),
          const Spacer(),
          Text("${o.price} FCFA", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF00B26A))),
        ])));
      })),
    ]);
  }

  Widget _buildHowItWorks() => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Comment ça marche?", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)), SizedBox(height: 8), Text("1. Renseignez colis → 2. Choisissez mode → 3. Payez → 4. Livraison", style: TextStyle(fontSize: 9, color: Color(0xFF8B8BA3)))]));
  Widget _buildHelp() => Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFF0EBFF), borderRadius: BorderRadius.circular(10)), child: Row(children: [const Icon(Icons.headset_mic_rounded, size: 18, color: Color(0xFF5B2BD6)), const SizedBox(width: 8), const Expanded(child: Text("Besoin d'aide? Disponible 24h/24", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))), SizedBox(height: 28, child: ElevatedButton(onPressed: (){}, style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF5B2BD6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))), child: const Text("Nous contacter", style: TextStyle(color: Colors.white, fontSize: 9))))]));
  Widget _buildBottomNav() => Container(height: 64, decoration: BoxDecoration(color: Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(14)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)]), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
    _navItem(Icons.home_rounded, "Accueil", true, () => context.go(AppRoutes.home)),
    _navItem(Icons.confirmation_number_outlined, "Réservations", false, () => context.push(AppRoutes.deliveryHistory)),
    InkWell(onTap: () => _scrollToForm(), child: Container(width:44,height:44, decoration: const BoxDecoration(color: Color(0xFF5B2BD6), shape: BoxShape.circle), child: const Icon(Icons.add_rounded, color: Colors.white, size: 22))),
    _navItem(Icons.favorite_border_rounded, "Favoris", false, () => context.push(AppRoutes.deliveryHistory)),
    _navItem(Icons.person_outline_rounded, "Profil", false, () => context.go('/user/dashboard')),
  ]));
  Widget _navItem(IconData icon, String label, bool sel, VoidCallback tap) => InkWell(onTap: tap, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 18, color: sel? const Color(0xFF5B2BD6): const Color(0xFF8B8BA3)), Text(label, style: TextStyle(fontSize: 8, fontWeight: sel? FontWeight.w700:FontWeight.w500, color: sel? const Color(0xFF5B2BD6): const Color(0xFF8B8BA3)))]));
  void _scrollToForm() { if (_formKey.currentContext!= null) Scrollable.ensureVisible(_formKey.currentContext!, duration: const Duration(milliseconds: 400)); }

  // VILLES UNIQUEMENT DEPUIS SUPABASE - PAS DE MOCK
  void _pickCity(bool isFrom, DeliveryClientProvider prov) {
    final cities = prov.popularRoutes.map((e) => e.fromCity).toSet().toList();
    if (cities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Aucune route créée par admin")));
      return;
    }
    showModalBottomSheet(context: context, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(14))), builder: (_) => ListView.builder(itemCount: cities.length, itemBuilder: (_, i) => ListTile(dense:true, title: Text(cities[i], style: const TextStyle(fontSize: 12)), onTap: () { if (isFrom) prov.setFromCity(cities[i]); else prov.setToCity(cities[i]); Navigator.pop(context); })));
  }

  void _pickWeight(DeliveryClientProvider prov) {
    final weights = [1, 3, 5, 10, 20]; // int pas double
    showModalBottomSheet(context: context, builder: (_) => ListView(children: weights.map((w) => ListTile(dense:true, title: Text("$w kg", style: const TextStyle(fontSize: 12)), onTap: () { prov.setWeight(w); Navigator.pop(context); })).toList()));
  }

  void _pickMode(DeliveryClientProvider prov) {
    showModalBottomSheet(context: context, builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: DeliveryMode.values.map((m) => ListTile(dense:true, title: Text(m.label, style: const TextStyle(fontSize: 12)), onTap: () { prov.setMode(m); Navigator.pop(context); })).toList()));
  }
}
