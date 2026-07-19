// ================================================================
// CHEMIN: lib/presentation/thix_reservation/delivery/pages/client/delivery_home_page.dart
// ROLE: PAGE PRINCIPALE - C'est la capture que tu as envoyée
// Reproduit 100% ta maquette Figma/Prod
// Hero violet + Categories + Form + Actions + Offres + Stepper
// SCALABLE: SingleChildScrollView + Provider + pas de setState lourd
// ================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/delivery_client_provider.dart';
import '../../widgets/delivery_widgets.dart';

class DeliveryHomePage extends StatefulWidget {
  const DeliveryHomePage({super.key});

  @override
  State<DeliveryHomePage> createState() => _DeliveryHomePageState();
}

class _DeliveryHomePageState extends State<DeliveryHomePage> {
  // --- Category sélectionnée, comme sur ta maquette "Livraison colis" actif ---
  String _selectedCat = "Livraison colis";

  @override
  void initState() {
    super.initState();
    // Init provider au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeliveryClientProvider>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FA),
      // --- AppBar THIX RESERVATION ---
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.menu, color: Colors.black), onPressed: () {}),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: const Color(0xFF6D28D9), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.inventory_2, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("THIX RESERVATION", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black)),
                Text("Livrez vos colis en toute simplicité.", style: TextStyle(fontSize: 9, color: Colors.grey)),
              ],
            ),
          ],
        ),
        actions: [
          // Bouton notif avec badge 3
          Stack(
            children: [
              IconButton(icon: const Icon(Icons.notifications_none, color: Colors.black), onPressed: () {}),
              Positioned(right: 6, top: 6, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.purple, shape: BoxShape.circle), child: const Text("3", style: TextStyle(color: Colors.white, fontSize: 8)))),
            ],
          ),
          // Avatar + bouton Admin si admin
          Consumer<DeliveryClientProvider>(
            builder: (context, prov, _) {
              return Row(
                children: [
                  if (prov.isAdmin)
                    IconButton(
                      onPressed: () => Navigator.pushNamed(context, '/delivery-admin-dashboard'),
                      icon: const Icon(Icons.admin_panel_settings, color: Color(0xFF6D28D9)),
                    ),
                  const CircleAvatar(backgroundImage: NetworkImage("https://i.pravatar.cc/100"), radius: 18),
                  const SizedBox(width: 10),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<DeliveryClientProvider>(
        builder: (context, prov, _) {
          if (prov.isLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF6D28D9)));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- 1. HERO VIOLET ---
                DeliveryHeroSlider(
                  userName: prov.userName,
                  onSendTap: () {
                    // Scroll vers formulaire
                  },
                ),
                const SizedBox(height: 16),

                // --- 2. CATEGORIES ---
                DeliveryCategoryRow(
                  selected: _selectedCat,
                  onSelect: (cat) => setState(() => _selectedCat = cat),
                ),
                const SizedBox(height: 16),

                // --- 3. FORMULAIRE ENVOI COLIS (National/International) ---
                DeliveryFormCard(
                  isNational: prov.isNational,
                  fromCity: prov.fromCity,
                  toCity: prov.toCity,
                  weight: prov.weightKg,
                  mode: prov.deliveryMode,
                  isCalculating: prov.isCalculating,
                  price: prov.calculatedPrice,
                  onSwap: () => prov.swapCities(),
                  onFromTap: () => _pickCity(context, true, prov),
                  onToTap: () => _pickCity(context, false, prov),
                  onWeightChanged: (kg) => prov.setWeight(kg),
                  onModeChanged: (m) => prov.setMode(m),
                  onNationalChanged: (v) => prov.setNational(v),
                  onCalculate: () {
                    if (prov.calculatedPrice == 0) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Trajet non disponible, admin doit créer le prix")));
                      return;
                    }
                    Navigator.pushNamed(context, '/delivery-checkout');
                  },
                ),
                const SizedBox(height: 16),

                // --- 4. ACTIONS RAPIDES ---
                const DeliveryQuickActions(),
                const SizedBox(height: 16),

                // --- 5. OFFRES DU MOMENT ---
                DeliveryOffersList(offers: prov.offers),
                const SizedBox(height: 16),

                // --- 6. COMMENT ÇA MARCHE ---
                const DeliveryHowItWorks(),
                const SizedBox(height: 16),

                // --- 7. BESOIN D'AIDE? ---
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: const Color(0xFFF5F3FF), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.headset_mic, size: 32, color: Color(0xFF6D28D9)),
                          SizedBox(width: 10),
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text("Besoin d'aide?", style: TextStyle(fontWeight: FontWeight.bold)),
                            Text("Notre équipe est dispo 24h/24 et 7j/7", style: TextStyle(fontSize: 10, color: Colors.grey)),
                          ]),
                        ],
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6D28D9)),
                        onPressed: () {},
                        child: const Text("Nous contacter", style: TextStyle(color: Colors.white, fontSize: 11)),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 80), // Pour bottom nav
              ],
            ),
          );
        },
      ),
      // --- Bottom Nav comme maquette ---
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF6D28D9),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Accueil"),
          BottomNavigationBarItem(icon: Icon(Icons.confirmation_number_outlined), label: "Réservations"),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle, size: 50, color: Color(0xFF6D28D9)), label: "Envoyer"),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: "Favoris"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profil"),
        ],
      ),
    );
  }

  // --- Picker ville depuis delivery_routes existantes ---
  void _pickCity(BuildContext context, bool isFrom, DeliveryClientProvider prov) {
    final cities = prov.popularRoutes.map((e) => e.fromCity).toSet().toList();
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView.builder(
        itemCount: cities.length,
        itemBuilder: (context, i) => ListTile(
          title: Text(cities[i]),
          onTap: () {
            if (isFrom) prov.setFromCity(cities[i]);
            else prov.setToCity(cities[i]);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
