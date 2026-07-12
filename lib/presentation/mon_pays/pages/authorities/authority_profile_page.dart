// lib/presentation/mon_pays/pages/authorities/authority_profile_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/authorities_provider.dart';
import '../../models/authority.dart';

class AuthorityProfilePage extends ConsumerStatefulWidget {
  final String authorityId;

  const AuthorityProfilePage({required this.authorityId, super.key});

  @override
  ConsumerState<AuthorityProfilePage> createState() => _AuthorityProfilePageState();
}

class _AuthorityProfilePageState extends ConsumerState<AuthorityProfilePage> {
  // Charte THIX ID
  static const Color navyDeep = Color(0xFF0A1F44);
  static const Color navy = Color(0xFF123B7A);
  static const Color gold = Color(0xFFE3B23C);
  static const Color ivory = Color(0xFFF6F7FB);
  static const Color darkText = Color(0xFF10182B);
  static const Color mutedText = Color(0xFF6B7690);

  @override
  Widget build(BuildContext context) {
    final authorityAsync = ref.watch(authorityDetailProvider(widget.authorityId));

    return Scaffold(
      backgroundColor: ivory,
      body: authorityAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: navy)),
        error: (error, stack) => _buildErrorState(error),
        data: (authority) => _buildProfileContent(authority),
      ),
    );
  }

  // ==================== ÉTAT D'ERREUR ====================
  Widget _buildErrorState(Object error) {
    return Scaffold(
      appBar: AppBar(backgroundColor: navyDeep, foregroundColor: Colors.white),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('Impossible de charger le profil', style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(authorityDetailProvider(widget.authorityId)),
              style: ElevatedButton.styleFrom(backgroundColor: navy),
              child: const Text('Réessayer', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== CONTENU DU PROFIL ====================
  Widget _buildProfileContent(Authority authority) {
    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(authority),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBadges(authority),
                const SizedBox(height: 24),
                
                if (authority.biography.isNotEmpty) ...[
                  _buildSectionTitle(Icons.history_edu, 'Biographie'),
                  _buildTextCard(authority.biography),
                  const SizedBox(height: 24),
                ],

                if (authority.explanation != null && authority.explanation!.isNotEmpty) ...[
                  _buildSectionTitle(Icons.lightbulb_outline, 'Rôle & Missions'),
                  _buildTextCard(authority.explanation!),
                  const SizedBox(height: 24),
                ],

                if (authority.speeches.isNotEmpty) ...[
                  _buildSectionTitle(Icons.mic, 'Discours Officiels'),
                  ...authority.speeches.map((url) => _buildLinkCard(url, Icons.mic, 'Discours')),
                  const SizedBox(height: 24),
                ],

                if (authority.videos.isNotEmpty) ...[
                  _buildSectionTitle(Icons.video_library, 'Vidéos'),
                  ...authority.videos.map((url) => _buildLinkCard(url, Icons.play_circle_fill, 'Voir la vidéo')),
                  const SizedBox(height: 24),
                ],

                if (authority.publications.isNotEmpty) ...[
                  _buildSectionTitle(Icons.article, 'Publications'),
                  ...authority.publications.map((url) => _buildLinkCard(url, Icons.article, 'Lire la publication')),
                  const SizedBox(height: 24),
                ],

                if (authority.socialNetworks.isNotEmpty) ...[
                  _buildSectionTitle(Icons.public, 'Réseaux Sociaux'),
                  _buildSocialNetworks(authority.socialNetworks),
                  const SizedBox(height: 40),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==================== EN-TÊTE IMAGE (APP BAR) ====================
  Widget _buildSliverAppBar(Authority authority) {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      backgroundColor: navyDeep,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16, right: 16),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              authority.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white, shadows: [Shadow(color: Colors.black, blurRadius: 4)]),
            ),
            Text(
              authority.title,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: gold, shadows: [Shadow(color: Colors.black, blurRadius: 4)]),
            ),
          ],
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            authority.imageUrl != null && authority.imageUrl!.isNotEmpty
                ? Image.network(authority.imageUrl!, fit: BoxFit.cover)
                : Container(color: navy, child: const Icon(Icons.person, size: 100, color: Colors.white24)),
            // Dégradé noir pour rendre le texte lisible
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, navyDeep.withOpacity(0.9)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== BADGES (Catégorie, Parti, Mandat) ====================
  Widget _buildBadges(Authority authority) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildBadgeItem(Icons.category, authority.category, navy),
        if (authority.party.isNotEmpty) _buildBadgeItem(Icons.people, authority.party, const Color(0xFF1A5276)),
        if (authority.mandate.isNotEmpty) _buildBadgeItem(Icons.calendar_today, authority.mandate, Colors.orange.shade700),
      ],
    );
  }

  Widget _buildBadgeItem(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.3))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  // ==================== ÉLÉMENTS DE DESIGN ====================
  Widget _buildSectionTitle(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: gold, size: 22),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: navyDeep)),
        ],
      ),
    );
  }

  Widget _buildTextCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: hairline), boxShadow: [BoxShadow(color: navyDeep.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Text(text, style: const TextStyle(fontSize: 14, color: darkText, height: 1.6)),
    );
  }

  Widget _buildLinkCard(String url, IconData icon, String label) {
    return InkWell(
      onTap: () => _launchUrl(url),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: hairline)),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: navy.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: navy, size: 20)),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: darkText))),
            const Icon(Icons.open_in_new, color: mutedText, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialNetworks(Map<String, String> socials) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: socials.entries.map((entry) {
        return InkWell(
          onTap: () => _launchUrl(entry.value),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: hairline)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.link, color: navy, size: 18),
                const SizedBox(width: 8),
                Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w700, color: navy)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible d\'ouvrir ce lien.'), backgroundColor: Colors.red));
      }
    }
  }
}
