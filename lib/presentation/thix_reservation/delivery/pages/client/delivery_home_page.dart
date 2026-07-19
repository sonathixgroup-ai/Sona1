// lib/presentation/thix_reservation/delivery/pages/client/delivery_home_page.dart
// ROLE: PAGE PRINCIPALE - 100% MAQUETTE SCREENSHOT - ALL ONTAP FONCTIONNEL
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:thix_id/nav.dart';
import '../../providers/delivery_client_provider.dart';

class DeliveryHomePage extends StatefulWidget {
  const DeliveryHomePage({super.key});
  @override
  State<DeliveryHomePage> createState() => _DeliveryHomePageState();
}

class _DeliveryHomePageState extends State<DeliveryHomePage> {
  String _selectedCat = "Livraison colis";
  String _typeColis = "Sélectionner";
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
                _buildOffres(prov),
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

  // ================= APPBAR AVEC BOUTON ADMIN =================
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leadingWidth: 46,
      leading: Padding(
        padding: const EdgeInsets.only(left: 10),
        child: InkWell(
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Menu"))),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(color: const Color(0xFFF6F5FF), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.menu_rounded, size: 18, color: Colors.black),
          ),
        ),
      ),
      title: Row(
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(color: const Color(0xFF5B2BD6), borderRadius: BorderRadius.circular(7)),
            child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 6),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text("THIX ", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Colors.black, letterSpacing: -0.3)),
                Text("RESERVATION", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Color(0xFF5B2BD6), letterSpacing: -0.3)),
              ]),
              Text("Livrez vos colis en toute simplicité.", style: TextStyle(fontSize: 8.5, color: Color(0xFF8B8BA3), fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
      actions: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            InkWell(
              onTap: () => context.push(AppRoutes.deliveryTracking),
              child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(color: const Color(0xFFF6F5FF), shape: BoxShape.circle),
                child: const Icon(Icons.notifications_none_rounded, size: 18, color: Colors.black87),
              ),
            ),
            Positioned(
              right: -2, top: -2,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(color: Color(0xFF5B2BD6), shape: BoxShape.circle),
                child: const Text("3", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        const SizedBox(width: 10),
        // BOUTON ADMIN A LA PLACE AVATAR - ACCES LIBRE
        InkWell(
          onTap: () => context.push(AppRoutes.deliveryAdminDashboard),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFF5B2BD6), borderRadius: BorderRadius.circular(20)),
            child: const Row(children: [
              Icon(Icons.admin_panel_settings_rounded, size: 14, color: Colors.white),
              SizedBox(width: 4),
              Text("ADMIN", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
            ]),
          ),
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  // ================= HERO VIOLET =================
  Widget _buildHero(DeliveryClientProvider prov) {
    return Container(
      height: 148,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(colors: [Color(0xFF5B2BD6), Color(0xFF7C4DFF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0, bottom: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(bottomRight: Radius.circular(16)),
              child: Image.asset('assets/images/van.png', width: 150, height: 90, fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.local_shipping_rounded, size: 80, color: Colors.white24),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Bonjour, ${prov.userName.isEmpty? 'Michel' : prov.userName} 👋", style: const TextStyle(color: Color(0xFFD9CCFF), fontSize: 9.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                const SizedBox(
                  width: 165,
                  child: Text("Envoyez ou recevez vos colis en toute simplicité", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800, height: 1.15)),
                ),
                const SizedBox(height: 4),
                const Text("Rapide, sécurisé et au meilleur prix.", style: TextStyle(color: Color(0xFFC9B8FF), fontSize: 9)),
                const Spacer(),
                InkWell(
                  onTap: () => _scrollToForm(),
                  child: Container(
                    height: 30,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.inventory_2_rounded, size: 14, color: Color(0xFF5B2BD6)),
                      SizedBox(width: 6),
                      Text("Envoyer un colis", style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF1A1A2E)),
                    ]),
                  ),
                ),
                const SizedBox(height: 6),
                Row(children: List.generate(4, (i) => Container(
                  margin: const EdgeInsets.only(right: 5), width: i==0?14:5, height: 5,
                  decoration: BoxDecoration(color: i==0?Colors.white:Colors.white38, borderRadius: BorderRadius.circular(10)),
                ))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= CATEGORIES =================
  Widget _buildCategories() {
    final cats = [
      {'icon': Icons.apartment_rounded, 'label': 'Hôtels', 'color': Color(0xFF0A7AFF), 'route': '/thix-reservation/hotels'},
      {'icon': Icons.flight_rounded, 'label': 'Vols', 'color': Color(0xFF00B26A), 'route': '/thix-reservation/flights'},
      {'icon': Icons.directions_bus_filled_rounded, 'label': 'Bus', 'color': Color(0xFFFF8A00), 'route': '/thix-reservation/bus'},
      {'icon': Icons.directions_car_filled_rounded, 'label': 'Transports', 'color': Color(0xFF5B5BD6), 'route': '/thix-reservation/taxi'},
      {'icon': Icons.inventory_2_rounded, 'label': 'Livraison colis', 'color': Color(0xFF5B2BD6), 'route': AppRoutes.deliveryHome},
      {'icon': Icons.local_activity_rounded, 'label': 'Évènements', 'color': Color(0xFFE93A5E), 'route': '/thix-event'},
      {'icon': Icons.more_horiz_rounded, 'label': 'Plus', 'color': Color(0xFF8B8BA3), 'route': 'more'},
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: cats.map((c) {
          final isSel = c['label'] == _selectedCat;
          return InkWell(
            onTap: () {
              setState(() => _selectedCat = c['label'] as String);
              if (c['route'] == 'more') {
                showModalBottomSheet(context: context, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))), builder: (_) => _buildMoreSheet());
              } else if ((c['route'] as String)!= AppRoutes.deliveryHome) {
                context.push(c['route'] as String);
              } else {
                _scrollToForm();
              }
            },
            child: Column(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: isSel? const Color(0xFFF0EBFF) : (c['color'] as Color).withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: isSel? const Color(0xFF5B2BD6).withOpacity(0.3) : Colors.transparent)),
                child: Icon(c['icon'] as IconData, size: 18, color: c['color'] as Color),
              ),
              const SizedBox(height: 4),
              Text(c['label'] as String, style: TextStyle(fontSize: 8.5, fontWeight: isSel? FontWeight.w700:FontWeight.w600, color: isSel? const Color(0xFF5B2BD6): const Color(0xFF1A1A2E))),
            ]),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMoreSheet() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Wrap(spacing: 16, runSpacing: 16, children: [
        _catMore(Icons.admin_panel_settings, "Admin", () { Navigator.pop(context); context.push(AppRoutes.deliveryAdminDashboard); }),
        _catMore(Icons.route_rounded, "Routes Prix", () { Navigator.pop(context); context.push(AppRoutes.deliveryAdminRoutes); }),
        _catMore(Icons.local_shipping, "Envois", () { Navigator.pop(context); context.push(AppRoutes.deliveryAdminShipments); }),
      ]),
    );
  }
  Widget _catMore(IconData i, String l, VoidCallback t) => InkWell(onTap: t, child: Column(children: [Icon(i, color: Color(0xFF5B2BD6)), Text(l, style: TextStyle(fontSize: 10))]));

  // ================= FORM =================
  Widget _buildFormCard(DeliveryClientProvider prov) {
    return Container(
      key: _formKey,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text("Envoyer un colis", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
          InkWell(onTap: () => context.push(AppRoutes.deliveryTracking), child: const Row(children: [Icon(Icons.headset_mic_rounded, size: 12, color: Color(0xFF5B2BD6)), SizedBox(width: 3), Text("Besoin d'aide?", style: TextStyle(fontSize: 9, color: Color(0xFF5B2BD6), fontWeight: FontWeight.w600)), Icon(Icons.chevron_right_rounded, size: 12, color: Color(0xFF5B2BD6))])),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _toggleBtn("National", prov.isNational, () => prov.setNational(true)),
          const SizedBox(width: 8),
          _toggleBtn("International",!prov.isNational, () => prov.setNational(false)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _fieldBox("Expéditeur", prov.fromCity.isEmpty? "Abidjan, Côte d'Ivoire" : prov.fromCity, "Adresse complète", Icons.person_pin_circle_outlined, () => _pickCity(true, prov))),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: InkWell(onTap: () => prov.swapCities(), child: Container(width: 28, height: 28, decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Color(0xFFE8E8F0)), shape: BoxShape.circle), child: const Icon(Icons.swap_horiz_rounded, size: 14, color: Color(0xFF5B2BD6))))),
          Expanded(child: _fieldBox("Destinataire", prov.toCity.isEmpty? "Yamoussoukro, Côte d'Ivoire" : prov.toCity, "Adresse complète", Icons.location_on_outlined, () => _pickCity(false, prov))),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _smallDropdown("Type de colis", _typeColis, Icons.inventory_2_outlined, () => _pickType())),
          const SizedBox(width: 6),
          Expanded(child: _smallDropdown("Poids estimé", prov.weightKg==0? "0 - 5 kg" : "${prov.weightKg} kg", Icons.scale_outlined, () => _pickWeight(prov))),
          const SizedBox(width: 6),
          Expanded(child: _smallDropdown("Mode de livraison", prov.deliveryMode.isEmpty? "Standard (2-3 jours)" : prov.deliveryMode, Icons.local_shipping_outlined, () => _pickMode(prov))),
        ]),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity, height: 38,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5B2BD6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0),
            onPressed: prov.isCalculating? null : () {
              if (prov.calculatedPrice == 0 && prov.fromCity.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Choisissez villes, admin doit créer le prix si 0"), style: TextStyle(fontSize: 11)));
                return;
              }
              context.push(AppRoutes.deliveryCheckout);
            },
            icon: prov.isCalculating? const SizedBox(width:12,height:12,child: CircularProgressIndicator(strokeWidth:2,color: Colors.white)) : const Icon(Icons.search_rounded, size: 14, color: Colors.white),
            label: Text(prov.isCalculating? "Calcul..." : prov.calculatedPrice>0? "${prov.calculatedPrice.toInt()} FCFA - Calculer le prix et continuer" : "Calculer le prix et continuer", style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }

  Widget _toggleBtn(String label, bool sel, VoidCallback tap) {
    return InkWell(
      onTap: tap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(color: sel? const Color(0xFFF0EBFF) : Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: sel? const Color(0xFF5B2BD6) : const Color(0xFFE8E8F0))),
        child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: sel? const Color(0xFF5B2BD6) : const Color(0xFF8B8BA3))),
      ),
    );
  }

  Widget _fieldBox(String head, String city, String sub, IconData icon, VoidCallback tap) {
    return InkWell(
      onTap: tap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: const Color(0xFFFBFAFF), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFF0EBFF))),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: const Color(0xFFF0EBFF), borderRadius: BorderRadius.circular(6)), child: Icon(icon, size: 12, color: Color(0xFF5B2BD6))),
          const SizedBox(width: 6),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(head, style: const TextStyle(fontSize: 7.5, color: Color(0xFF8B8BA3))),
            Text(city, maxLines:1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
            Text(sub, style: const TextStyle(fontSize: 7.5, color: Color(0xFF8B8BA3))),
          ])),
        ]),
      ),
    );
  }

  Widget _smallDropdown(String head, String value, IconData icon, VoidCallback tap) {
    return InkWell(
      onTap: tap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(color: const Color(0xFFFBFAFF), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFF0EBFF))),
        child: Row(children: [
          Icon(icon, size: 12, color: Color(0xFF5B2BD6)),
          const SizedBox(width: 4),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(head, style: const TextStyle(fontSize: 7, color: Color(0xFF8B8BA3))),
            Row(children: [
              Expanded(child: Text(value, maxLines:1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700))),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 12, color: Color(0xFF8B8BA3)),
            ]),
          ])),
        ]),
      ),
    );
  }

  // ================= ACTIONS RAPIDES =================
  Widget _buildActionsRapides() {
    final actions = [
      {'icon': Icons.inventory_2_outlined, 'title': 'Suivre un colis', 'sub': 'Suivez l\'acheminement de votre colis', 'route': AppRoutes.deliveryTracking},
      {'icon': Icons.download_rounded, 'title': 'Recevoir un colis', 'sub': 'Recevez un colis en attente', 'route': AppRoutes.deliveryHistory},
      {'icon': Icons.assignment_outlined, 'title': 'Mes envois', 'sub': 'Consultez l\'historique de vos envois', 'route': AppRoutes.deliveryHistory},
      {'icon': Icons.location_on_rounded, 'title': 'Points relais', 'sub': 'Trouvez un point relais proche', 'route': AppRoutes.deliveryTracking},
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text("Actions rapides", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      Row(children: actions.map((a) => Expanded(child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
        child: InkWell(
          onTap: () => context.push(a['route'] as String),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: const Color(0xFFF0EBFF), borderRadius: BorderRadius.circular(7)), child: Icon(a['icon'] as IconData, size: 14, color: const Color(0xFF5B2BD6))),
            const SizedBox(width: 6),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a['title'] as String, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700)),
              Text(a['sub'] as String, maxLines:2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 7, color: Color(0xFF8B8BA3))),
            ])),
          ]),
        ),
      ))).toList()),
    ]);
  }

  Widget _buildOffres(DeliveryClientProvider prov) {
    final offers = prov.offers.isEmpty? [
      {'title':'Livraison Express','sub':'Livraison en 24-48h','old':'5.000 FCFA','new':'4.000 FCFA','off':'-20%'},
      {'title':'Livraison Standard','sub':'Livraison en 2-3 jours','old':'3.000 FCFA','new':'2.550 FCFA','off':'-15%'},
      {'title':'International','sub':'Vers plusieurs pays','old':'15.000 FCFA','new':'13.500 FCFA','off':'-10%'},
      {'title':'Point Relais','sub':'Économisez sur la livraison','old':'2.000 FCFA','new':'1.800 FCFA','off':'-10%'},
    ] : prov.offers.map((e) => {'title': e['title']?? '', 'sub': e['subtitle']?? '', 'old':'', 'new':'${e['price']??0} FCFA', 'off': e['badge']?? ''}).toList();

    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text("Offres du moment", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
        InkWell(onTap: (){}, child: const Row(children: [Text("Voir tout", style: TextStyle(fontSize: 9, color: Color(0xFF5B2BD6), fontWeight: FontWeight.w600)), Icon(Icons.chevron_right_rounded, size: 12, color: Color(0xFF5B2BD6))])),
      ]),
      const SizedBox(height: 8),
      SizedBox(height: 112, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: offers.length, separatorBuilder: (_,__)=> const SizedBox(width: 8), itemBuilder: (_, i){
        final o = offers[i];
        return InkWell(
          onTap: () => context.push(AppRoutes.deliveryCheckout),
          child: Container(
            width: 110,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Stack(children: [
                Container(height: 42, decoration: BoxDecoration(color: const Color(0xFFF6F5FF), borderRadius: BorderRadius.circular(8)), child: const Center(child: Icon(Icons.card_giftcard_rounded, size: 22, color: Color(0xFF5B2BD6)))),
                Positioned(left:0, top:0, child: Container(padding: const EdgeInsets.symmetric(horizontal:5, vertical:2), decoration: BoxDecoration(color: const Color(0xFF00B26A), borderRadius: BorderRadius.circular(10)), child: Text(o['off'] as String, style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.w700)))),
              ]),
              const SizedBox(height: 4),
              Text(o['title'] as String, maxLines:1, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700)),
              Text(o['sub'] as String, maxLines:1, style: const TextStyle(fontSize: 7, color: Color(0xFF8B8BA3))),
              const Spacer(),
              Text(o['old'] as String, style: const TextStyle(fontSize: 7, color: Color(0xFF8B8BA3), decoration: TextDecoration.lineThrough)),
              Text(o['new'] as String, style: const TextStyle(fontSize: 9, color: Color(0xFF00B26A), fontWeight: FontWeight.w800)),
            ]),
          ),
        );
      })),
    ]);
  }

  Widget _buildHowItWorks() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("Comment ça marche?", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Row(children: [
          _step(1, "Renseignez les détails de votre colis", Icons.inventory_2_outlined),
          _arrow(),
          _step(2, "Choisissez le mode de livraison", Icons.credit_card_rounded),
          _arrow(),
          _step(3, "Payez en toute sécurité", Icons.credit_card_rounded),
          _arrow(),
          _step(4, "Nous livrons à destination", Icons.local_shipping_rounded),
        ]),
      ]),
    );
  }

  Widget _step(int n, String t, IconData icon) {
    return Expanded(child: Column(children: [
      Container(width:18,height:18, decoration: BoxDecoration(color: Color(0xFF5B2BD6), shape: BoxShape.circle), child: Center(child: Text("$n", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)))),
      const SizedBox(height: 4),
      Icon(icon, size: 20, color: Color(0xFF1A1A2E)),
      const SizedBox(height: 4),
      Text(t, textAlign: TextAlign.center, style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w600, height: 1.2)),
    ]));
  }
  Widget _arrow() => const Padding(padding: EdgeInsets.only(bottom: 18), child: Icon(Icons.arrow_forward_rounded, size: 12, color: Color(0xFFC9B8FF)));

  Widget _buildHelp() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: const Color(0xFFF0EBFF), borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Color(0xFFE6DEFF), shape: BoxShape.circle), child: const Icon(Icons.headset_mic_rounded, size: 18, color: Color(0xFF5B2BD6))),
        const SizedBox(width: 8),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Besoin d'aide?", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
          Text("Notre équipe est disponible 24h/24 et 7j/7", style: TextStyle(fontSize: 7.5, color: Color(0xFF8B8BA3))),
        ])),
        SizedBox(height: 28, child: ElevatedButton(onPressed: (){}, style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF5B2BD6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)), padding: EdgeInsets.symmetric(horizontal: 12)), child: const Text("Nous contacter", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)))),
      ]),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 64,
      decoration: BoxDecoration(color: Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(14)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)]),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _navItem(Icons.home_rounded, "Accueil", true, () => context.go(AppRoutes.home)),
        _navItem(Icons.confirmation_number_outlined, "Réservations", false, () => context.push(AppRoutes.deliveryHistory)),
        InkWell(onTap: () => _scrollToForm(), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width:44,height:44, decoration: const BoxDecoration(color: Color(0xFF5B2BD6), shape: BoxShape.circle), child: const Icon(Icons.add_rounded, color: Colors.white, size: 22)),
          const Text("Envoyer", style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: Color(0xFF5B2BD6))),
        ])),
        _navItem(Icons.favorite_border_rounded, "Favoris", false, () => context.push(AppRoutes.deliveryHistory)),
        _navItem(Icons.person_outline_rounded, "Profil", false, () => context.go('/user/dashboard')),
      ]),
    );
  }

  Widget _navItem(IconData icon, String label, bool sel, VoidCallback tap) {
    return InkWell(onTap: tap, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 18, color: sel? const Color(0xFF5B2BD6): const Color(0xFF8B8BA3)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(fontSize: 8, fontWeight: sel? FontWeight.w700:FontWeight.w500, color: sel? const Color(0xFF5B2BD6): const Color(0xFF8B8BA3))),
    ]));
  }

  void _scrollToForm() {
    if (_formKey.currentContext!= null) {
      Scrollable.ensureVisible(_formKey.currentContext!, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  void _pickCity(bool isFrom, DeliveryClientProvider prov) {
    final cities = prov.popularRoutes.isEmpty? ["Abidjan", "Yamoussoukro", "Bouaké", "San Pedro", "Korhogo"] : prov.popularRoutes.map((e) => e.fromCity).toSet().toList();
    showModalBottomSheet(context: context, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(14))), builder: (_) => ListView.builder(itemCount: cities.length, itemBuilder: (_, i) => ListTile(dense:true, title: Text(cities[i], style: const TextStyle(fontSize: 12)), onTap: () {
      if (isFrom) prov.setFromCity(cities[i]); else prov.setToCity(cities[i]); Navigator.pop(context);
    })));
  }

  void _pickType() {
    final types = ["Document", "Colis", "Fragile", "Alimentaire"];
    showModalBottomSheet(context: context, builder: (_) => ListView(children: types.map((t) => ListTile(dense:true, title: Text(t, style: const TextStyle(fontSize: 12)), onTap: () { setState(() => _typeColis = t); Navigator.pop(context); })).toList()));
  }

  void _pickWeight(DeliveryClientProvider prov) {
    final weights = [1, 3, 5, 10, 20];
    showModalBottomSheet(context: context, builder: (_) => ListView(children: weights.map((w) => ListTile(dense:true, title: Text("$w kg", style: const TextStyle(fontSize: 12)), onTap: () { prov.setWeight(w.toDouble()); Navigator.pop(context); })).toList()));
  }

  void _pickMode(DeliveryClientProvider prov) {
    final modes = ["Standard (2-3 jours)", "Express (24h)", "Eco (4-5 jours)"];
    showModalBottomSheet(context: context, builder: (_) => ListView(children: modes.map((m) => ListTile(dense:true, title: Text(m, style: const TextStyle(fontSize: 12)), onTap: () { prov.setMode(m); Navigator.pop(context); })).toList()));
  }
}
