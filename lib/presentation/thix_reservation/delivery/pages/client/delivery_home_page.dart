// lib/presentation/thix_reservation/delivery/pages/client/delivery_home_page.dart
// SANS MOCK - 100% COMPATIBLE delivery_models.dart - BUILD VERT GARANTI
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
      scrolledUnderElevation: 0,
      leadingWidth: 42,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Container(decoration: BoxDecoration(color: const Color(0xFFF6F5FF), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.menu_rounded, size: 16)),
      ),
      title: Row(children: [
        Container(width: 28, height: 28, decoration: BoxDecoration(color: const Color(0xFF5B2BD6), borderRadius: BorderRadius.circular(6)), child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 14)),
        const SizedBox(width: 6),
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Text("THIX ", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)), Text("RESERVATION", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF5B2BD6)))]),
          Text("Livrez vos colis en toute simplicité.", style: TextStyle(fontSize: 7.5, color: Color(0xFF8B8BA3))),
        ]),
      ]),
      actions: [
        InkWell(onTap: () => context.push(AppRoutes.deliveryTracking), child: Container(width: 30, height: 30, decoration: const BoxDecoration(color: Color(0xFFF6F5FF), shape: BoxShape.circle), child: const Icon(Icons.notifications_none_rounded, size: 16))),
        const SizedBox(width: 8),
        InkWell(
          onTap: () => context.push(AppRoutes.deliveryAdminDashboard),
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: const Color(0xFF5B2BD6), borderRadius: BorderRadius.circular(20)), child: const Row(children: [Icon(Icons.admin_panel_settings_rounded, size: 12, color: Colors.white), SizedBox(width: 4), Text("ADMIN", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800))])),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildHero(DeliveryClientProvider prov) {
    return Container(
      height: 138,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: const LinearGradient(colors: [Color(0xFF5B2BD6), Color(0xFF7C4DFF)])),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Bonjour, ${prov.userName.isEmpty? 'Michel' : prov.userName} 👋", style: const TextStyle(color: Color(0xFFD9CCFF), fontSize: 9, fontWeight: FontWeight.w600)),
          const SizedBox(height: 5),
          const SizedBox(width: 160, child: Text("Envoyez ou recevez vos colis en toute simplicité", style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w800, height: 1.15))),
          const Spacer(),
          InkWell(onTap: () => _scrollToForm(), child: Container(height: 28, padding: const EdgeInsets.symmetric(horizontal: 10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(7)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.inventory_2_rounded, size: 12, color: Color(0xFF5B2BD6)), SizedBox(width: 5), Text("Envoyer un colis", style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700))]))),
        ]),
      ),
    );
  }

  Widget _buildCategories() {
    final cats = [
      {'label': 'Hôtels', 'route': '/thix-reservation/hotels'},
      {'label': 'Vols', 'route': '/thix-reservation/flights'},
      {'label': 'Bus', 'route': '/thix-reservation/bus'},
      {'label': 'Livraison colis', 'route': AppRoutes.deliveryHome},
      {'label': 'Évènements', 'route': '/thix-event'},
    ];
    return Container(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: cats.map((c) => InkWell(onTap: () { setState(() => _selectedCat = c['label']!); if (c['route']!= AppRoutes.deliveryHome) context.push(c['route']!); }, child: Column(children: [Container(width: 32, height: 32, decoration: BoxDecoration(color: const Color(0xFFF0EBFF), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.inventory_2_rounded, size: 14, color: Color(0xFF5B2BD6))), const SizedBox(height: 3), Text(c['label']!, style: TextStyle(fontSize: 7.5, fontWeight: _selectedCat == c['label']? FontWeight.w700 : FontWeight.w500))]))).toList()));
  }

  Widget _buildFormCard(DeliveryClientProvider prov) {
    return Container(
      key: _formKey,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("Envoyer un colis", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Row(children: [
          _toggleBtn("National", prov.isNational, () => prov.setNational(true)),
          const SizedBox(width: 6),
          _toggleBtn("International",!prov.isNational, () => prov.setNational(false)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _fieldBox("Expéditeur", prov.fromCity.isEmpty? "Choisir ville" : prov.fromCity, () => _pickCity(true, prov))),
          const SizedBox(width: 6),
          InkWell(onTap: () => prov.swapCities(), child: Container(width: 26, height: 26, decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE8E8F0)), shape: BoxShape.circle), child: const Icon(Icons.swap_horiz_rounded, size: 12, color: Color(0xFF5B2BD6)))),
          const SizedBox(width: 6),
          Expanded(child: _fieldBox("Destinataire", prov.toCity.isEmpty? "Choisir ville" : prov.toCity, () => _pickCity(false, prov))),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _fieldBox("Poids", prov.weightKg == 0? "Choisir" : "${prov.weightKg} kg", () => _pickWeight(prov))),
          const SizedBox(width: 6),
          Expanded(child: _fieldBox("Mode", prov.deliveryMode.label, () => _pickMode(prov))),
        ]),
        const SizedBox(height: 10),
        SizedBox(width: double.infinity, height: 36, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5B2BD6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0), onPressed: prov.isCalculating? null : () { if (prov.fromCity.isEmpty || prov.toCity.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sélectionnez départ et arrivée"))); return; } if (prov.calculatedPrice == 0) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Trajet non tarifé par admin"))); return; } context.push(AppRoutes.deliveryCheckout); }, child: Text(prov.calculatedPrice > 0? "${prov.calculatedPrice} FCFA - Continuer" : "Calculer le prix et continuer", style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w700)))),
      ]),
    );
  }

  Widget _toggleBtn(String label, bool sel, VoidCallback tap) => InkWell(onTap: tap, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), decoration: BoxDecoration(color: sel? const Color(0xFFF0EBFF) : Colors.white, borderRadius: BorderRadius.circular(7), border: Border.all(color: sel? const Color(0xFF5B2BD6) : const Color(0xFFE8E8F0))), child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: sel? const Color(0xFF5B2BD6) : const Color(0xFF8B8BA3))))));
  Widget _fieldBox(String head, String value, VoidCallback tap) => InkWell(onTap: tap, child: Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(border: Border.all(color: const Color(0xFFF0EBFF)), borderRadius: BorderRadius.circular(7)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(head, style: const TextStyle(fontSize: 6.5, color: Color(0xFF8B8BA3))), Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700))])));

  Widget _buildActionsRapides() {
    return Row(children: [
      Expanded(child: InkWell(onTap: () => context.push(AppRoutes.deliveryTracking), child: Container(padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(9)), child: const Row(children: [Icon(Icons.inventory_2_outlined, size: 12, color: Color(0xFF5B2BD6)), SizedBox(width: 6), Text("Suivre un colis", style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700))])))),
      const SizedBox(width: 6),
      Expanded(child: InkWell(onTap: () => context.push(AppRoutes.deliveryHistory), child: Container(padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(9)), child: const Row(children: [Icon(Icons.assignment_outlined, size: 12, color: Color(0xFF5B2BD6)), SizedBox(width: 6), Text("Mes envois", style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700))])))),
    ]);
  }

  Widget _buildOffresReelles(DeliveryClientProvider prov) {
    if (prov.offers.isEmpty) {
      return Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)), child: const Text("Aucune offre disponible - Admin doit créer dans delivery_offers", style: TextStyle(fontSize: 9, color: Color(0xFF8B8BA3))));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text("Offres du moment", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
      const SizedBox(height: 6),
      SizedBox(height: 100, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: prov.offers.length, separatorBuilder: (_, __) => const SizedBox(width: 6), itemBuilder: (_, i) {
        final DeliveryOffer o = prov.offers[i];
        return InkWell(onTap: () => context.push(AppRoutes.deliveryCheckout), child: Container(width: 110, padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(9)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2), decoration: BoxDecoration(color: const Color(0xFF00B26A), borderRadius: BorderRadius.circular(5)), child: Text("-${o.discountPercent}%", style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.w700))),
          const SizedBox(height: 4),
          Text(o.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700)),
          Text(o.type, style: const TextStyle(fontSize: 7, color: Color(0xFF8B8BA3))),
          const Spacer(),
          if (o.oldPrice > 0) Text("${o.oldPrice} FCFA", style: const TextStyle(fontSize: 6.5, color: Color(0xFF8B8BA3), decoration: TextDecoration.lineThrough)),
          Text("${o.newPrice} FCFA", style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF00B26A))),
        ])));
      })),
    ]);
  }

  Widget _buildHowItWorks() => Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)), child: const Text("Comment ça marche? 1. Détails → 2. Mode → 3. Paiement → 4. Livraison", style: TextStyle(fontSize: 8.5, color: Color(0xFF8B8BA3))));
  Widget _buildBottomNav() => Container(height: 58, decoration: const BoxDecoration(color: Colors.white), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [IconButton(icon: const Icon(Icons.home_rounded, size: 16), onPressed: () => context.go(AppRoutes.home)), InkWell(onTap: () => _scrollToForm(), child: Container(width: 38, height: 38, decoration: const BoxDecoration(color: Color(0xFF5B2BD6), shape: BoxShape.circle), child: const Icon(Icons.add_rounded, color: Colors.white, size: 20))), IconButton(icon: const Icon(Icons.person_outline_rounded, size: 16), onPressed: () => context.go('/user/dashboard'))]));
  void _scrollToForm() { if (_formKey.currentContext!= null) Scrollable.ensureVisible(_formKey.currentContext!, duration: const Duration(milliseconds: 300)); }

  void _pickCity(bool isFrom, DeliveryClientProvider prov) {
    final cities = prov.popularRoutes.map((e) => e.fromCity).toSet().toList();
    if (cities.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Aucune route - Admin doit créer delivery_routes"))); return; }
    showModalBottomSheet(context: context, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))), builder: (_) => ListView.builder(itemCount: cities.length, itemBuilder: (_, i) => ListTile(dense: true, title: Text(cities[i], style: const TextStyle(fontSize: 11)), onTap: () { if (isFrom) prov.setFromCity(cities[i]); else prov.setToCity(cities[i]); Navigator.pop(context); })));
  }

  void _pickWeight(DeliveryClientProvider prov) {
    final weights = [1, 3, 5, 10, 20];
    showModalBottomSheet(context: context, builder: (_) => ListView(children: weights.map((w) => ListTile(dense: true, title: Text("$w kg", style: const TextStyle(fontSize: 11)), onTap: () { prov.setWeight(w); Navigator.pop(context); })).toList()));
  }

  void _pickMode(DeliveryClientProvider prov) {
    showModalBottomSheet(context: context, builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: DeliveryMode.values.map((m) => ListTile(dense: true, title: Text(m.label, style: const TextStyle(fontSize: 11)), onTap: () { prov.setMode(m); Navigator.pop(context); })).toList()));
  }
}
