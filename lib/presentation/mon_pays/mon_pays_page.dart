// lib/presentation/mon_pays/mon_pays_page.dart
// Page d'accueil du module Mon Pays avec les cartes et le bouton Admin

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sections/authorities_section.dart';
import 'sections/header_section.dart';
import 'admin/admin_authorities_page.dart';
import 'pages/authorities/authorities_page.dart';
import 'utils/constants.dart';

class MonPaysPage extends ConsumerWidget {
  const MonPaysPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.flag, color: Colors.white),
            SizedBox(width: 10),
            Text('Mon Pays'),
          ],
        ),
        actions: [
          // Bouton Admin pour charger/gérer les données
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminAuthoritiesPage(),
                ),
              );
            },
            tooltip: 'Administration des autorités',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: ouvrir la recherche globale (Phase 4)
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bannière d'accueil
            const HeaderSection(),
            const SizedBox(height: 24),

            // Section Autorités
            const AuthoritiesSection(),
            const SizedBox(height: 16),

            // Ligne "Voir toutes les autorités"
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AuthoritiesPage(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Voir toutes les autorités',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A5276),
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, color: Color(0xFF1A5276)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Grille des modules (Phase 2+)
            _buildModulesGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildModulesGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tous les modules',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.1,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _moduleCard(
              icon: Icons.account_balance,
              label: 'Autorités',
              color: const Color(0xFF1A5276),
              onTap: () {
                // Déjà disponible
              },
            ),
            _moduleCard(
              icon: Icons.history_edu,
              label: 'Figures Historiques',
              color: const Color(0xFFE67E22),
              onTap: () {
                // Phase 2
              },
            ),
            _moduleCard(
              icon: Icons.newspaper,
              label: 'À la Une',
              color: const Color(0xFF27AE60),
              onTap: () {
                // Phase 2
              },
            ),
            _moduleCard(
              icon: Icons.business,
              label: 'Agences & Institutions',
              color: const Color(0xFF8E44AD),
              onTap: () {
                // Phase 2
              },
            ),
            _moduleCard(
              icon: Icons.video_library,
              label: 'Vidéos Officielles',
              color: const Color(0xFFE74C3C),
              onTap: () {
                // Phase 3
              },
            ),
            _moduleCard(
              icon: Icons.library_books,
              label: 'Documentaires',
              color: const Color(0xFF2980B9),
              onTap: () {
                // Phase 3
              },
            ),
            _moduleCard(
              icon: Icons.people_alt,
              label: 'Citoyens Exemplaires',
              color: const Color(0xFF1ABC9C),
              onTap: () {
                // Phase 3
              },
            ),
            _moduleCard(
              icon: Icons.gavel,
              label: 'Valeurs & Lois',
              color: const Color(0xFF2C3E50),
              onTap: () {
                // Phase 4
              },
            ),
            _moduleCard(
              icon: Icons.record_voice_over,
              label: 'Participer',
              color: const Color(0xFFF39C12),
              onTap: () {
                // Phase 4
              },
            ),
            _moduleCard(
              icon: Icons.warning,
              label: 'Personnes recherchées',
              color: const Color(0xFFE74C3C),
              onTap: () {
                // Phase 4
              },
            ),
            _moduleCard(
              icon: Icons.search,
              label: 'Recherche globale',
              color: const Color(0xFF7F8C8D),
              onTap: () {
                // Phase 4
              },
            ),
            _moduleCard(
              icon: Icons.star,
              label: 'Citoyens ★',
              color: const Color(0xFFF1C40F),
              onTap: () {
                // Phase 3
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _moduleCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
