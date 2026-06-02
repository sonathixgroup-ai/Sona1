import 'package:flutter/material.dart';

class NetworkPage extends StatelessWidget {
  const NetworkPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), // Fond gris clair UI uniforme
      body: SafeArea(
        child: Column(
          children: [
            // 1. Barre de navigation supérieure (Header THIX RÉSEAU PRO)
            _buildTopNavBar(),
            
            // 2. Contenu principal séparé en colonnes (Style Dashboard Web/Tablette de l'image)
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- COLONNE GAUCHE : FLUX ET SUGGESTIONS (Flex 7) ---
                      Expanded(
                        flex: 7,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeroBanner(),
                            const SizedBox(height: 20),
                            _buildQuickActionsGrid(),
                            const SizedBox(height: 24),
                            _buildSuggestionsSection(),
                            const SizedBox(height: 24),
                            _buildFeedSectionHeader(),
                            const SizedBox(height: 12),
                            _buildNewsFeedCard(),
                            const SizedBox(height: 16),
                            _buildJobShareCard(),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // --- COLONNE DROITE : PROFIL ET WIDGETS COMPACTS (Flex 3) ---
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildProfileMiniCard(),
                            const SizedBox(height: 16),
                            _buildRecentConnectionsWidget(),
                            const SizedBox(height: 16),
                            _buildUpcomingEventsWidget(),
                            const SizedBox(height: 16),
                            _buildPopularGroupsWidget(),
                            const SizedBox(height: 16),
                            _buildRecommendedJobsWidget(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavbar(),
    );
  }

  // --- COMPOSANTS DE L'INTERFACE ---

  Widget _buildTopNavBar() {
    return Container(
      height: 65,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo & Slogan de l'application
          Row(
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text("R", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Text("THIX ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black)),
                      Text("RÉSEAU PRO", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2563EB))),
                    ],
                  ),
                  const Text("Connecter. Collaborer. Réussir ensemble.", style: TextStyle(fontSize: 9, color: Colors.grey)),
                ],
              )
            ],
          ),
          
          // Zone de recherche centrale
          Container(
            width: 300,
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: const [
                Icon(Icons.search, color: Colors.grey, size: 18),
                SizedBox(width: 8),
                Text("Rechercher des personnes, entreprises...", style: TextStyle(color: Colors.grey, fontSize: 11.5)),
              ],
            ),
          ),

          // Icônes de Notifications et Profil à droite
          Row(
            children: [
              _buildHeaderIconWithBadge(Icons.notifications_none_outlined, "3", Colors.red),
              const SizedBox(width: 12),
              _buildHeaderIconWithBadge(Icons.chat_bubble_outline_rounded, "5", Colors.red),
              const SizedBox(width: 14),
              const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFF2563EB),
                child: Icon(Icons.person, color: Colors.white, size: 18),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildHeaderIconWithBadge(IconData icon, String count, Color badgeColor) {
    return Stack(
      children: [
        Icon(icon, color: const Color(0xFF1F2937), size: 24),
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
            constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
            child: Text(count, style: const TextStyle(color: Colors.white, fontSize: 7.5, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ),
        )
      ],
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(colors: [Color(0xFF030712), Color(0xFF1D4ED8)]),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2),
                    children: [
                      TextSpan(text: "Développez votre réseau,\nélevez vos "),
                      TextSpan(text: "opportunités.", style: TextStyle(color: Color(0xFF3B82F6))),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text("Rejoignez des professionnels, partagez vos compétences et créez des partenariats à forte valeur.", style: TextStyle(color: Colors.white70, fontSize: 11)),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  icon: const Icon(Icons.person_add_alt_1, size: 14, color: Colors.white),
                  label: const Text("Élargir mon réseau", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    final actions = [
      {'icon': Icons.person_search_outlined, 'title': 'Trouver des\npersonnes', 'color': Colors.blue},
      {'icon': Icons.business_outlined, 'title': 'Entreprises', 'color': Colors.teal},
      {'icon': Icons.business_center_outlined, 'title': 'Offres d\'emploi', 'color': Colors.orange},
      {'icon': Icons.calendar_month_outlined, 'title': 'Événements', 'color': Colors.purple},
      {'icon': Icons.groups_outlined, 'title': 'Groupes', 'color': Colors.pink},
      {'icon': Icons.campaign_outlined, 'title': 'Publier', 'color': Colors.lightBlue},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: actions.map((act) {
        return Container(
          width: 92,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Column(
            children: [
              Icon(act['icon'] as IconData, color: act['color'] as Color, size: 22),
              const SizedBox(height: 6),
              Text(act['title'] as String, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSuggestionsSection() {
    final members = [
      {'name': 'Ismaël Koné', 'title': 'CEO, AgroVision', 'mutual': '12'},
      {'name': 'Fatou N\'Guessan', 'title': 'Consultante RH', 'mutual': '7'},
      {'name': 'Herve Yao', 'title': 'Investisseur', 'mutual': '5'},
      {'name': 'Adama Bakayoko', 'title': 'Développeur Fullstack', 'mutual': '9'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text("Suggestions pour vous", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
            Text("Voir tout", style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: members.map((m) {
            return Container(
              width: 140,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  const CircleAvatar(radius: 22, backgroundColor: Color(0xFFF3F4F6), child: Icon(Icons.person, color: Colors.grey)),
                  const SizedBox(height: 6),
                  Text(m['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(m['title']!, style: const TextStyle(fontSize: 9.5, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.public, size: 10, color: Colors.grey),
                      const SizedBox(width: 2),
                      Text("En commun : ${m['mutual']}", style: const TextStyle(fontSize: 8.5, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 26,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                      child: const Text("Se connecter", style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            );
          }).toList(),
        )
      ],
    );
  }

  Widget _buildFeedSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("Fil d'actualité", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
        Row(
          children: const [
            Text("Trier par : ", style: TextStyle(fontSize: 11, color: Colors.grey)),
            Text("Récent", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            Icon(Icons.arrow_drop_down, size: 14),
          ],
        )
      ],
    );
  }

  Widget _buildNewsFeedCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 16, backgroundColor: Color(0xFFF3F4F6)),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Text("Aïcha Diallo ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      Icon(Icons.verified, color: Color(0xFF2563EB), size: 12),
                    ],
                  ),
                  const Text("CEO, TechNova • 2h • ", style: TextStyle(fontSize: 9.5, color: Colors.grey)),
                ],
              )
            ],
          ),
          const SizedBox(height: 10),
          const Text("Heureuse d'annoncer le lancement de notre nouvelle plateforme d'intelligence artificielle dédiée aux PME. Hâte d'avoir vos retours !", style: TextStyle(fontSize: 11, color: Color(0xFF374151))),
          const SizedBox(height: 10),
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xFF0F172A),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text("TechNova AI", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text("L'intelligence au service de votre croissance.", style: TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _buildPostStatsAndActions("128", "24", "15"),
        ],
      ),
    );
  }

  Widget _buildJobShareCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              CircleAvatar(radius: 16, backgroundColor: Color(0xFFE5E7EB)),
              const SizedBox(width: 8),
              Text("Jean-Baptiste Koffi a partagé une offre d'emploi • 4h", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE5E7EB))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("Business Developer", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                    Text("THIX Group", style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Text("Abidjan, Côte d'Ivoire (Hybride)", style: TextStyle(fontSize: 10, color: Colors.grey)),
                    SizedBox(height: 4),
                    Text("Temps plein  •  Expérience : 2-5 ans", style: TextStyle(fontSize: 9, color: Colors.blue, fontWeight: FontWeight.w500)),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF2563EB)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    elevation: 0,
                  ),
                  child: const Text("Postuler", style: TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
          const SizedBox(height: 10),
          _buildPostStatsAndActions("56", "12", "8"),
        ],
      ),
    );
  }

  Widget _buildPostStatsAndActions(String likes, String comments, String shares) {
  // Fonction locale pour les icônes d'action
  Widget _buildActionLabel(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, size: 26, color: Colors.grey.shade700),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  return Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("👍 ❤️ $likes", style: const TextStyle(fontSize: 10, color: Colors.grey)),
          Text("$comments commentaires  •  $shares partages", style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
      const Divider(height: 14, color: Color(0xFFF3F4F6)),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionLabel(Icons.thumb_up_outlined, "J'aime"),
          _buildActionLabel(Icons.chat_bubble_outline_rounded, "Commenter"),
          _buildActionLabel(Icons.share_outlined, "Partager"),
          _buildActionLabel(Icons.send_outlined, "Envoyer"),
        ],
      ),
    ],
  );
  }

  // --- PANNEAU DROIT (WIDGETS BIEN ALIGNÉS) ---

  Widget _buildProfileMiniCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          const CircleAvatar(radius: 26, backgroundColor: Color(0xFF2563EB)),
          const SizedBox(height: 6),
          const Text("Hi, Koffi Amani 👋", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const Text("Entrepreneur | Innovateur", style: TextStyle(fontSize: 10, color: Colors.grey)),
          const Text("📍 Abidjan, Côte d'Ivoire", style: TextStyle(fontSize: 9, color: Colors.grey)),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF2563EB)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
            child: const Text("Voir mon profil", style: TextStyle(fontSize: 10.5, color: Color(0xFF2563EB))),
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildProfileStat("128", "Connexions"),
              _buildProfileStat("24", "Demandes"),
              _buildProfileStat("18", "Visites"),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildProfileStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
      ],
    );
  }

  Widget _buildRecentConnectionsWidget() => _buildCompactList("Mes connexions récentes", ["Aïcha Diallo", "Jean-Baptiste K.", "Mariam Coulibaly", "Samuel Traoré"]);
  Widget _buildUpcomingEventsWidget() => _buildCompactList("Événements à venir", ["Networking Night", "Forum des Entrepreneurs", "Atelier Personal Branding"]);
  Widget _buildPopularGroupsWidget() => _buildCompactList("Groupes populaires", ["Entrepreneurs d'Afrique", "Tech & Innovation", "Marketing Digital CI"]);
  Widget _buildRecommendedJobsWidget() => _buildCompactList("Offres d'emploi recommandées", ["Chef de Projet Digital", "Product Manager", "UI/UX Designer"]);

  Widget _buildCompactList(String title, List<String> items) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
              const Text("Voir tout", style: TextStyle(fontSize: 9, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 6),
          Column(
            children: items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  const Icon(Icons.circle, size: 5, color: Color(0xFF2563EB)),
                  const SizedBox(width: 6),
                  Expanded(child: Text(item, style: const TextStyle(fontSize: 10.5, color: Color(0xFF374151)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                ],
              ),
            )).toList(),
          )
        ],
      ),
    );
  }

  // --- COMPOSANT BARRE INFÉRIEURE ---

  Widget _buildBottomNavbar() {
    return BottomAppBar(
      color: Colors.white,
      child: SizedBox(
        height: 52,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBottomItem(Icons.home, "Accueil", true),
            _buildBottomItem(Icons.people_outline, "Réseau", false),
            _buildBottomItem(Icons.add_box_outlined, "Créer", false),
            _buildBottomItem(Icons.business_center_outlined, "Messages", false),
            _buildBottomItem(Icons.person_outline, "Profil", false),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomItem(IconData icon, String text, bool selected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: selected ? const Color(0xFF2563EB) : Colors.grey, size: 20),
        Text(text, style: TextStyle(fontSize: 9, color: selected ? const Color(0xFF2563EB) : Colors.grey)),
      ],
    );
  }
}
