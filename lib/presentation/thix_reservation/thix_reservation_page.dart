import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF1A73E8),
        fontFamily: 'Roboto',
      ),
      home: const ThixReservationPage(),
    );
  }
}

class ThixReservationPage extends StatelessWidget {
  const ThixReservationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header App Bar
            _buildHeader(),

            // Zone de contenu principale (Ajustée pour éviter le scroll vertical)
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      
                      // 2. Banner Promo Flash + Page Indicators
                      _buildPromoBanner(isSmallScreen),
                      const SizedBox(height: 12),

                      // 3. Grid Services (Bus, Vol, Hôtel...)
                      _buildServicesGrid(),
                      const SizedBox(height: 14),

                      // 4. Mes Réservations
                      _buildSectionHeader("Mes réservations"),
                      const SizedBox(height: 6),
                      _buildReservationsStatus(),
                      const SizedBox(height: 14),

                      // 5. Offres spéciales
                      _buildSectionHeader("Offres spéciales pour vous"),
                      const SizedBox(height: 6),
                      _buildSpecialOffers(isSmallScreen),
                      const SizedBox(height: 14),

                      // 6. Parrainez & Gagnez
                      _buildReferralBanner(),
                      const SizedBox(height: 14),

                      // 7. Restaurants à proximité
                      _buildSectionHeader("Restaurants à proximité"),
                      const SizedBox(height: 6),
                      _buildRestaurantsList(isSmallScreen),
                      const SizedBox(height: 14),

                      // 8. Annonces
                      _buildSectionHeader("Annonces"),
                      const SizedBox(height: 6),
                      _buildAnnoncesList(isSmallScreen),
                      const SizedBox(height: 20),

                      // 9. Reassurance Badges
                      _buildReassuranceBadges(),
                      const SizedBox(height: 75), 
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _buildMiddleButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  // --- COMPOSANTS DE L'INTERFACE ---

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text("R", style: TextStyle(color: Color(0xFF1A73E8), fontSize: 22, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Text("THIX ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text("RÉSERVATION", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A73E8))),
                    ],
                  ),
                  const Text("Réservez tout, partout, en toute simplicité.", style: TextStyle(fontSize: 9, color: Colors.grey)),
                ],
              )
            ],
          ),
          Row(
            children: [
              Stack(
                children: [
                  IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none, color: Colors.black54, size: 24)),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: const Text("3", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
              const CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFFF1F3F4),
                child: Icon(Icons.person_outline, color: Colors.black54, size: 20),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildPromoBanner(bool isSmallScreen) {
    return Column(
      children: [
        Container(
          height: isSmallScreen ? 110 : 125,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade50, const Color(0xFFE8F0FE)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.flash_on, color: Colors.orange, size: 12),
                        Text(" PROMO FLASH", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 9)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text("Jusqu'à -40%", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                    Text("sur vos réservations de bus & vols", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.black.withOpacity(0.8))),
                    const Text("Valable jusqu'au 30 Juin 2025", style: TextStyle(fontSize: 8, color: Colors.grey)),
                    const SizedBox(height: 6),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A73E8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                        minimumSize: const Size(75, 24),
                      ),
                      child: const Text("Profiter maintenant", style: TextStyle(fontSize: 9, color: Colors.white)),
                    )
                  ],
                ),
              ),
              Positioned(
                right: -10,
                bottom: 10,
                child: Icon(Icons.directions_bus_filled, size: isSmallScreen ? 80 : 100, color: const Color(0xFF1A73E8).withOpacity(0.9)),
              )
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 12, height: 5, decoration: BoxDecoration(color: const Color(0xFF1A73E8), borderRadius: BorderRadius.circular(4))),
            const SizedBox(width: 4),
            ...List.generate(3, (index) => Container(margin: const EdgeInsets.symmetric(horizontal: 2), width: 5, height: 5, decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle))),
          ],
        )
      ],
    );
  }

  Widget _buildServicesGrid() {
    final services = [
      {'icon': Icons.directions_bus, 'label': 'Bus', 'color': const Color(0xFF1A73E8)},
      {'icon': Icons.flight, 'label': 'Vol', 'color': Colors.indigo},
      {'icon': Icons.hotel, 'label': 'Hôtel', 'color': Colors.orange},
      {'icon': Icons.local_taxi, 'label': 'Taxi', 'color': Colors.amber},
      {'icon': Icons.delivery_dining, 'label': 'Livraison', 'color': Colors.green},
      {'icon': Icons.apps, 'label': 'Plus', 'color': Colors.grey},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: services.map((service) {
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Icon(service['icon'] as IconData, color: service['color'] as Color, size: 22),
            ),
            const SizedBox(height: 4),
            Text(service['label'] as String, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black.withOpacity(0.8))),
        Row(
          children: const [
            Text("Voir tout", style: TextStyle(fontSize: 10, color: Colors.grey)),
            Icon(Icons.chevron_right, size: 12, color: Colors.grey),
          ],
        )
      ],
    );
  }

  Widget _buildReservationsStatus() {
    final status = [
      {'label': 'À venir', 'count': '3', 'color': Colors.blue, 'icon': Icons.business_center},
      {'label': 'En cours', 'count': '1', 'color': Colors.green, 'icon': Icons.timelapse},
      {'label': 'Terminées', 'count': '8', 'color': Colors.purple, 'icon': Icons.check_circle_outline},
      {'label': 'Annulées', 'count': '0', 'color': Colors.red, 'icon': Icons.cancel_outlined},
    ];

    return Row(
      children: status.map((item) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(item['icon'] as IconData, color: item['color'] as Color, size: 14),
                    Text(item['count'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(item['label'] as String, style: const TextStyle(fontSize: 9, color: Colors.grey), maxLines: 1),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSpecialOffers(bool isSmallScreen) {
    final offers = [
      {'title': 'Hôtels', 'promo': '-30%', 'desc': 'Séjournez plus,\npayez moins', 'color': Colors.red.shade50},
      {'title': 'Vols', 'promo': '-20%', 'desc': 'Sur tous les vols', 'color': Colors.blue.shade50},
      {'title': 'Bus', 'promo': '-15%', 'desc': 'Voyagez en toute\nconfiance', 'color': Colors.indigo.shade50},
      {'title': 'Livraison', 'promo': '-10%', 'desc': 'Envoi express', 'color': Colors.green.shade50},
    ];

    return SizedBox(
      height: isSmallScreen ? 70 : 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: offers.length,
        itemBuilder: (context, index) {
          final offer = offers[index];
          return Container(
            width: 105,
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: offer['color'] as Color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(offer['title'] as String, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black54)),
                Text(offer['promo'] as String, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A73E8))),
                const SizedBox(height: 1),
                Text(offer['desc'] as String, style: const TextStyle(fontSize: 8, color: Colors.black54, height: 1.1)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReferralBanner() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.card_giftcard, color: Colors.purple, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("Parrainez & Gagnez !", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.purple)),
                Text("Invitez vos proches et gagnez jusqu'à 10.000 FC par parrainage.", style: TextStyle(fontSize: 8.5, color: Colors.black54)),
              ],
            ),
          ),
          Row(
            children: List.generate(3, (index) => const Align(
              widthFactor: 0.6,
              child: CircleAvatar(radius: 9, backgroundColor: Colors.grey, child: Icon(Icons.person, size: 10, color: Colors.white)),
            )),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 14)
        ],
      ),
    );
  }

  Widget _buildRestaurantsList(bool isSmallScreen) {
    final restaurants = [
      {'name': "Le Goût d'Ici", 'type': 'Africaine', 'time': '20-30 min', 'price': '\$\$', 'rating': '4.6'},
      {'name': 'Fast & Good', 'type': 'Fast Food', 'time': '15-25 min', 'price': '\$\$', 'rating': '4.8'},
      {'name': 'Pizza Time', 'type': 'Italienne', 'time': '20-30 min', 'price': '\$\$', 'rating': '4.5'},
      {'name': 'Sushi House', 'type': 'Japonaise', 'time': '25-35 min', 'price': '\$\$', 'rating': '4.7'},
    ];

    return SizedBox(
      height: isSmallScreen ? 115 : 125,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: restaurants.length,
        itemBuilder: (context, index) {
          final restau = restaurants[index];
          return Container(
            width: 115,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 4, right: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(4)),
                            child: Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 8),
                                Text(" ${restau['rating']}", style: const TextStyle(color: Colors.white, fontSize: 8)),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(restau['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 9), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(restau['type']!, style: const TextStyle(fontSize: 7.5, color: Colors.grey)),
                      const SizedBox(height: 1),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(restau['time']!, style: const TextStyle(fontSize: 7.5, color: Colors.black54)),
                          const Icon(Icons.favorite_border, size: 10, color: Colors.black54),
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnnoncesList(bool isSmallScreen) {
    final annonces = [
      {'tag': 'À VENDRE', 'tagColor': Colors.green, 'title': 'Toyota RAV4 2021', 'price': '25.000.000 FC'},
      {'tag': 'À LOUER', 'tagColor': Colors.red, 'title': 'Appartement 3 pièces', 'price': '600.000 FC / mois'},
      {'tag': 'SERVICE', 'tagColor': Colors.teal, 'title': 'Ménage à domicile', 'price': 'À partir de 10.000 FC'},
    ];

    return SizedBox(
      height: isSmallScreen ? 110 : 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: annonces.length,
        itemBuilder: (context, index) {
          final item = annonces[index];
          return Container(
            width: 140,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 4, left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(color: item['tagColor'] as Color, borderRadius: BorderRadius.circular(4)),
                            child: Text(item['tag'] as String, style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold)),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 9), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 1),
                      Text(item['price'] as String, style: const TextStyle(fontSize: 8.5, color: Color(0xFF1A73E8), fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReassuranceBadges() {
    final badges = [
      {'icon': Icons.verified_user_outlined, 'text': 'Paiement sécurisé'},
      {'icon': Icons.support_agent, 'text': 'Support 24/7'},
      {'icon': Icons.workspace_premium_outlined, 'text': 'Meilleurs prix'},
      {'icon': Icons.cancel_schedule_send_outlined, 'text': 'Annulation facile'},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: badges.map((badge) {
        return Column(
          children: [
            Icon(badge['icon'] as IconData, size: 14, color: const Color(0xFF1A73E8)),
            const SizedBox(height: 2),
            Text(badge['text'] as String, style: const TextStyle(fontSize: 7.5, color: Colors.black54)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 5.0,
      elevation: 8,
      child: SizedBox(
        height: 50,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBottomNavItem(Icons.home, "Accueil", true),
            _buildBottomNavItem(Icons.explore_outlined, "Explorer", false),
            const SizedBox(width: 35), 
            _buildBottomNavItem(Icons.event_note, "Mes rés.", false),
            _buildBottomNavItem(Icons.person_outline, "Profil", false),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, bool isActive) {
    return InkWell(
      onTap: () {},
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? const Color(0xFF1A73E8) : Colors.grey, size: 18),
          Text(label, style: TextStyle(color: isActive ? const Color(0xFF1A73E8) : Colors.grey, fontSize: 8.5)),
        ],
      ),
    );
  }

  Widget _buildMiddleButton() {
    return Container(
      height: 54,
      width: 54,
      margin: const EdgeInsets.only(top: 10),
      child: FloatingActionButton(
        backgroundColor: const Color(0xFF1A73E8),
        elevation: 3,
        shape: const CircleBorder(),
        onPressed: () {},
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.calendar_month, color: Colors.white, size: 18),
            SizedBox(height: 1),
            Text("Réserver", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
