import 'package:flutter/material.dart';

class ThixMarketPage extends StatelessWidget {
  const ThixMarketPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // 1. En-tête (Header)
            _buildHeader(),

            // Zone de contenu défilante
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      // 2. Bannière Principale Premium
                      _buildHeroBanner(),
                      const SizedBox(height: 14),

                      // 3. Ligne de réassurance
                      _buildReassuranceRow(),
                      const SizedBox(height: 16),

                      // 4. Barre de Recherche
                      _buildSearchBar(),
                      const SizedBox(height: 16),

                      // 5. Liste des Catégories
                      _buildCategoriesGrid(),
                      const SizedBox(height: 18),

                      // 6. Double bannières promotionnelles
                      _buildDoubleBanners(),
                      const SizedBox(height: 20),

                      // 7. Section Offres Flash (Header + Compte à rebours)
                      _buildFlashOffersHeader(),
                      const SizedBox(height: 12),

                      // 8. Liste Horizontale des Produits Flash
                      _buildFlashProductsList(),
                      const SizedBox(height: 22),

                      // 9. Section Vendeurs Vedettes
                      _buildSectionHeader("Vendeurs vedettes"),
                      const SizedBox(height: 12),
                      _buildFeaturedSellersList(),
                      
                      const SizedBox(height: 90), // Sécurité contre le chevauchement du Dock
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

  // --- PIÈCES DU PUZZLE UI ---

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(Icons.shopping_bag, color: Color(0xFFEAB308), size: 22),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Text("THIX ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                      Text("MARKET", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFEAB308))),
                    ],
                  ),
                  const Text("Achetez. Vendez. Évoluez.", style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              )
            ],
          ),
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: IconButton(
                      onPressed: () {}, 
                      icon: const Icon(Icons.notifications_none, color: Colors.black87, size: 22)
                    ),
                  ),
                  Positioned(
                    right: 14,
                    top: 10,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(color: Color(0xFFEAB308), shape: BoxShape.circle),
                    ),
                  )
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const CircleAvatar(
                  radius: 19,
                  backgroundColor: Color(0xFF0F172A),
                  child: Icon(Icons.person_outline, color: Colors.white, size: 20),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF030712), Color(0xFF0B1528), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Text("Bonjour, Michel ", style: TextStyle(color: Colors.white, fontSize: 12)),
                  Text("👋", style: TextStyle(fontSize: 12)),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                "Votre marketplace\npremium et sécurisée",
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, height: 1.2, letterSpacing: -0.5),
              ),
              const SizedBox(height: 6),
              Text(
                "Des milliers de produits, des vendeurs\nvérifiés, une expérience unique.",
                style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 10, height: 1.3),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAB308),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.search, color: Colors.black, size: 15),
                      const SizedBox(width: 6),
                      const Text("Explorer le marché", style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(color: Colors.black12, shape: BoxShape.circle),
                        child: const Icon(Icons.chevron_right, color: Colors.black, size: 12),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
          Positioned(
            right: -10,
            bottom: -5,
            child: Opacity(
              opacity: 0.85,
              child: Icon(Icons.shopping_cart_checkout_outlined, size: 105, color: const Color(0xFFEAB308).withOpacity(0.25)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildReassuranceRow() {
    final items = [
      {'icon': Icons.lock_outline, 'text': 'Paiement sécurisé'},
      {'icon': Icons.check_circle_outline, 'text': 'Vendeurs vérifiés'},
      {'icon': Icons.local_shipping_outlined, 'text': 'Livraison fiable'},
      {'icon': Icons.headset_mic_outlined, 'text': 'Support 24/7'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: items.map((item) {
          return Row(
            children: [
              Icon(item['icon'] as IconData, size: 12, color: const Color(0xFF334155)),
              const SizedBox(width: 4),
              Text(item['text'] as String, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.grey, size: 20),
                const SizedBox(width: 10),
                Text("Rechercher un produit, une marque...", style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text("Rechercher", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        )
      ],
    );
  }

  Widget _buildCategoriesGrid() {
    final categories = [
      {'icon': Icons.important_devices, 'label': 'Électronique'},
      {'icon': Icons.checkroom, 'label': 'Mode & Fashion'},
      {'icon': Icons.gite_outlined, 'label': 'Maison & Déco'},
      {'icon': Icons.clean_hands_outlined, 'label': 'Beauté & Santé'},
      {'icon': Icons.sports_basketball_outlined, 'label': 'Sports & Loisirs'},
      {'icon': Icons.grid_view_rounded, 'label': 'Plus'},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: categories.map((cat) {
        return Column(
          children: [
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2))
                ],
              ),
              child: Icon(cat['icon'] as IconData, color: const Color(0xFF1E293B), size: 22),
            ),
            const SizedBox(height: 6),
            Text(cat['label'] as String, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildDoubleBanners() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 100,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFF0B132B), Color(0xFF1C2541)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("OFFRES EXCLUSIVES", style: TextStyle(color: Color(0xFFF59E0B), fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                const SizedBox(height: 2),
                const Text("Jusqu'à -50%", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const Text("sur une sélection premium", style: TextStyle(color: Colors.white60, fontSize: 8)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: const Color(0xFFEAB308), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text("Découvrir", style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.black)),
                      SizedBox(width: 2),
                      Icon(Icons.chevron_right, size: 10, color: Colors.black),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 100,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("VENDEZ AVEC THIX", style: TextStyle(color: Color(0xFFB45309), fontSize: 8, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text("Développez votre\nbusiness aujourd'hui", style: TextStyle(color: Color(0xFF1E293B), fontSize: 12, fontWeight: FontWeight.bold, height: 1.2)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text("Commencer", style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.white)),
                      SizedBox(width: 2),
                      Icon(Icons.chevron_right, size: 10, color: Colors.white),
                    ],
                  ),
                )
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildFlashOffersHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.flash_on, color: Color(0xFFEAB308), size: 18),
            const SizedBox(width: 4),
            const Text("Offres flash", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(width: 10),
            Text("Se termine dans", style: TextStyle(fontSize: 9.5, color: Colors.grey.shade500)),
            const SizedBox(width: 6),
            _buildTimeBox("02"),
            const Text(" : ", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFEAB308))),
            _buildTimeBox("45"),
            const Text(" : ", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFEAB308))),
            _buildTimeBox("18"),
          ],
        ),
        Row(
          children: const [
            Text("Voir tout", style: TextStyle(fontSize: 10.5, color: Colors.grey, fontWeight: FontWeight.w500)),
            Icon(Icons.chevron_right, size: 14, color: Colors.grey),
          ],
        )
      ],
    );
  }

  Widget _buildTimeBox(String digits) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(4)),
      child: Text(digits, style: const TextStyle(color: Color(0xFFD97706), fontSize: 9.5, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildFlashProductsList() {
    final products = [
      {'tag': '-30%', 'name': 'Écouteurs sans fil\nPremium Pro', 'price': '32.900 FCFA', 'oldPrice': '47.000 FCFA', 'rating': '4.8 (124)'},
      {'tag': '-25%', 'name': 'Montre Connectée\nTHIX Watch 5', 'price': '75.000 FCFA', 'oldPrice': '100.000 FCFA', 'rating': '4.9 (89)'},
      {'tag': '-20%', 'name': 'Sneakers Air Max\nÉdition Limitée', 'price': '56.000 FCFA', 'oldPrice': '70.000 FCFA', 'rating': '4.7 (63)'},
      {'tag': '-15%', 'name': 'Parfum Élégance\nPremium 100ml', 'price': '28.000 FCFA', 'oldPrice': '33.000 FCFA', 'rating': '4.6 (42)'},
    ];

    return SizedBox(
      height: 195,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final p = products[index];
          return Container(
            width: 130,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 80,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.devices_other_outlined, color: Colors.grey.shade300, size: 28),
                      ),
                      const SizedBox(height: 8),
                      Text(p['name']!, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF1E293B), height: 1.2), maxLines: 2),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Color(0xFFF59E0B), size: 9),
                          const SizedBox(width: 2),
                          Text(p['rating']!, style: const TextStyle(fontSize: 8.5, color: Colors.grey, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(p['price'] ?? '', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                      Text(p['oldPrice']!, style: const TextStyle(fontSize: 8.5, color: Colors.grey, decoration: TextDecoration.lineThrough)),
                    ],
                  ),
                ),
                Positioned(
                  top: 8, left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFF59E0B), borderRadius: BorderRadius.circular(6)),
                    child: Text(p['tag']!, style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold)),
                  ),
                ),
                const Positioned(
                  top: 6, right: 6,
                  child: Icon(Icons.favorite_border, size: 16, color: Colors.black45),
                ),
                Positioned(
                  bottom: 8, right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(color: Color(0xFFF59E0B), shape: BoxShape.circle),
                    child: const Icon(Icons.add_shopping_cart_rounded, size: 11, color: Colors.white),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        Row(
          children: const [
            Text("Voir tout", style: TextStyle(fontSize: 10.5, color: Colors.grey)),
            Icon(Icons.chevron_right, size: 14, color: Colors.grey),
          ],
        )
      ],
    );
  }

  Widget _buildFeaturedSellersList() {
    final sellers = [
      {'name': 'TechStore Pro', 'rating': '4.9 (236)'},
      {'name': 'Fashion House', 'rating': '4.8 (189)'},
      {'name': 'Maison Chic', 'rating': '4.9 (157)'},
    ];

    return SizedBox(
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: sellers.length,
        itemBuilder: (context, index) {
          final s = sellers[index];
          return Container(
            width: 145,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 15,
                  backgroundColor: Color(0xFF0F172A),
                  child: Icon(Icons.storefront, size: 14, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(s['name']!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Color(0xFFEAB308), size: 9),
                          Text(" ${s['rating']}", style: const TextStyle(fontSize: 8.5, color: Colors.grey, fontWeight: FontWeight.w500)),
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

  Widget _buildBottomNavigationBar() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 6.0,
      elevation: 12,
      child: SizedBox(
        height: 54,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBottomNavItem(Icons.home, "Accueil", true),
            _buildBottomNavItem(Icons.grid_view, "Catégories", false),
            const SizedBox(width: 45), 
            _buildBottomNavItem(Icons.receipt_long_outlined, "Commandes", false),
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
          Icon(icon, color: isActive ? const Color(0xFFEAB308) : Colors.grey, size: 22),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: isActive ? Colors.black87 : Colors.grey, fontSize: 9.5, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _buildMiddleButton() {
    return Container(
      height: 58,
      width: 58,
      margin: const EdgeInsets.only(top: 6),
      child: FloatingActionButton(
        backgroundColor: const Color(0xFFEAB308),
        elevation: 4,
        shape: const CircleBorder(),
        onPressed: () {},
        child: const Icon(Icons.shopping_bag, color: Colors.white, size: 26),
      ),
    );
  }
}
