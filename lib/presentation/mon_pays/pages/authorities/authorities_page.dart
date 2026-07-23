// ============================================================
// FICHIER 5 : lib/presentation/mon_pays/pages/authorities/authority_profile_page.dart
// PROFIL COMPLET AVEC TOUTES LES NOUVELLES SECTIONS
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/authorities_provider.dart';
import '../../models/authority.dart';

class AuthorityProfilePage extends ConsumerStatefulWidget {
  final String authorityId;

  const AuthorityProfilePage({required this.authorityId, super.key});

  @override
  ConsumerState<AuthorityProfilePage> createState() => _AuthorityProfilePageState();
}

class _AuthorityProfilePageState extends ConsumerState<AuthorityProfilePage> {
  static const Color navyDeep = Color(0xFF0A1F44);
  static const Color navy = Color(0xFF123B7A);
  static const Color gold = Color(0xFFE3B23C);
  static const Color ivory = Color(0xFFF6F7FB);
  static const Color darkText = Color(0xFF10182B);
  static const Color mutedText = Color(0xFF6B7690);
  static const Color hairline = Color(0xFFE7EAF3);
  static const Color success = Color(0xFF1FA971);
  static const Color danger = Color(0xFFD64545);

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

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: danger, size: 48),
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
    );
  }

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

                // Biographie
                if (authority.biography.isNotEmpty) ...[
                  _buildSectionTitle(Icons.history_edu, 'Biographie'),
                  _buildTextCard(authority.biography),
                  const SizedBox(height: 24),
                ],

                // Études
                if (authority.education.isNotEmpty) ...[
                  _buildSectionTitle(Icons.school, 'Études'),
                  ...authority.education.map((e) => _buildEducationCard(e)),
                  const SizedBox(height: 24),
                ],

                // Parcours
                if (authority.career.isNotEmpty) ...[
                  _buildSectionTitle(Icons.timeline, 'Parcours professionnel'),
                  ...authority.career.map((c) => _buildCareerCard(c)),
                  const SizedBox(height: 24),
                ],

                // Réalisations
                if (authority.achievements.isNotEmpty) ...[
                  _buildSectionTitle(Icons.emoji_events, 'Réalisations'),
                  ...authority.achievements.map((a) => _buildAchievementCard(a)),
                  const SizedBox(height: 24),
                ],

                // Galerie photos
                if (authority.photos.isNotEmpty) ...[
                  _buildSectionTitle(Icons.photo_library, 'Galerie photos'),
                  _buildPhotoGallery(authority.photos),
                  const SizedBox(height: 24),
                ],

                // Vidéos
                if (authority.videos.isNotEmpty) ...[
                  _buildSectionTitle(Icons.video_library, 'Vidéos'),
                  ...authority.videos.map((v) => _buildVideoCard(v)),
                  const SizedBox(height: 24),
                ],

                // Agenda
                if (authority.agenda.isNotEmpty) ...[
                  _buildSectionTitle(Icons.calendar_today, 'Agenda'),
                  ...authority.agenda.map((item) => _buildAgendaItem(item)),
                  const SizedBox(height: 24),
                ],

                // Réseaux sociaux
                if (authority.socialNetworks.isNotEmpty) ...[
                  _buildSectionTitle(Icons.public, 'Réseaux sociaux'),
                  _buildSocialNetworks(authority.socialNetworks),
                  const SizedBox(height: 24),
                ],

                // Statut (actif / historique)
                _buildStatusBanner(authority),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==================== APP BAR ====================
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
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                shadows: [Shadow(color: Colors.black, blurRadius: 4)],
              ),
            ),
            Text(
              authority.title,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: gold,
                shadows: [Shadow(color: Colors.black, blurRadius: 4)],
              ),
            ),
          ],
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            authority.coverImageUrl != null && authority.coverImageUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: authority.coverImageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: Colors.grey.shade300),
                    errorWidget: (_, __, ___) => Container(
                      color: navy,
                      child: Icon(Icons.person, size: 100, color: Colors.white24),
                    ),
                  )
                : Container(
                    color: navy,
                    child: const Icon(Icons.person, size: 100, color: Colors.white24),
                  ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, navyDeep.withOpacity(0.9)],
                ),
              ),
            ),
            // Photo de profil en superposition
            Positioned(
              bottom: 20,
              left: 20,
              child: CircleAvatar(
                radius: 45,
                backgroundImage: authority.imageUrl != null && authority.imageUrl!.isNotEmpty
                    ? CachedNetworkImageProvider(authority.imageUrl!)
                    : null,
                backgroundColor: Colors.grey.shade300,
                child: authority.imageUrl == null || authority.imageUrl!.isEmpty
                    ? Text(
                        authority.name[0].toUpperCase(),
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: navy),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: () {
            // Partager le profil
          },
        ),
      ],
    );
  }

  // ==================== BADGES ====================
  Widget _buildBadges(Authority authority) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildBadgeItem(Icons.category, authority.category ?? 'Autorité', navy),
        if (authority.party.isNotEmpty) _buildBadgeItem(Icons.people, authority.party, const Color(0xFF1A5276)),
        if (authority.mandate.isNotEmpty) _buildBadgeItem(Icons.calendar_today, authority.mandate, Colors.orange.shade700),
        if (!authority.isCurrentlyActive)
          _buildBadgeItem(Icons.history, 'Mandat terminé', danger),
      ],
    );
  }

  Widget _buildBadgeItem(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
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

  // ==================== SECTIONS ====================
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: hairline),
        boxShadow: [BoxShadow(color: navyDeep.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Text(text, style: const TextStyle(fontSize: 14, color: darkText, height: 1.6)),
    );
  }

  // ==================== ÉTUDES ====================
  Widget _buildEducationCard(Education e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: hairline),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: navy.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.school, color: navy, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.degree, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(e.institution, style: const TextStyle(color: mutedText)),
                if (e.field != null) Text('Domaine : ${e.field}', style: const TextStyle(fontSize: 12, color: mutedText)),
                if (e.startYear != null || e.endYear != null)
                  Text('${e.startYear ?? ''} - ${e.endYear ?? 'Présent'}', style: const TextStyle(fontSize: 12, color: mutedText)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== PARCOURS ====================
  Widget _buildCareerCard(Career c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: hairline),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: gold.withOpacity(0.2), shape: BoxShape.circle),
            child: const Icon(Icons.timeline, color: gold, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(c.organization, style: const TextStyle(color: mutedText)),
                Text('${c.startDate} - ${c.endDate ?? 'Présent'}', style: const TextStyle(fontSize: 12, color: mutedText)),
                if (c.description != null) Text(c.description!, style: const TextStyle(fontSize: 12, color: mutedText)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== RÉALISATIONS ====================
  Widget _buildAchievementCard(Achievement a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: hairline),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: success.withOpacity(0.2), shape: BoxShape.circle),
            child: const Icon(Icons.emoji_events, color: success, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                if (a.description != null) Text(a.description!, style: const TextStyle(color: mutedText)),
                if (a.date != null) Text('Date : ${a.date}', style: const TextStyle(fontSize: 12, color: mutedText)),
                if (a.category != null) Text('Catégorie : ${a.category}', style: const TextStyle(fontSize: 12, color: mutedText)),
              ],
            ),
          ),
          if (a.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(a.imageUrl!, width: 50, height: 50, fit: BoxFit.cover),
            ),
        ],
      ),
    );
  }

  // ==================== GALERIE PHOTOS ====================
  Widget _buildPhotoGallery(List<AuthorityPhoto> photos) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        itemBuilder: (_, i) {
          final photo = photos[i];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: photo.url,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(width: 100, height: 100, color: Colors.grey.shade200),
                errorWidget: (_, __, ___) => Container(
                  width: 100,
                  height: 100,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.broken_image),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ==================== VIDÉOS ====================
  Widget _buildVideoCard(AuthorityVideo v) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: hairline),
      ),
      child: InkWell(
        onTap: () {
          // Ouvrir le lecteur vidéo
        },
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: v.thumbnailUrl != null
                    ? DecorationImage(image: CachedNetworkImageProvider(v.thumbnailUrl!), fit: BoxFit.cover)
                    : null,
                color: Colors.black12,
              ),
              child: const Icon(Icons.play_circle, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(v.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  if (v.description != null) Text(v.description!, style: const TextStyle(color: mutedText, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== AGENDA ====================
  Widget _buildAgendaItem(Map<String, String> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: hairline),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: navy.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.event, color: navy, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item['event'] != null) Text(item['event']!, style: const TextStyle(fontWeight: FontWeight.w700)),
                if (item['date'] != null) Text('Date : ${item['date']}', style: const TextStyle(color: mutedText)),
                if (item['location'] != null) Text('Lieu : ${item['location']}', style: const TextStyle(color: mutedText)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== RÉSEAUX SOCIAUX ====================
  Widget _buildSocialNetworks(Map<String, String> socials) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: socials.entries.map((entry) {
        return InkWell(
          onTap: () => _launchUrl(entry.value),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: hairline),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_getSocialIcon(entry.key), color: _getSocialColor(entry.key), size: 18),
                const SizedBox(width: 8),
                Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w700, color: navy)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _getSocialIcon(String platform) {
    final lc = platform.toLowerCase();
    if (lc.contains('twitter') || lc.contains('x')) return Icons.chat;
    if (lc.contains('facebook')) return Icons.facebook;
    if (lc.contains('instagram')) return Icons.photo_camera;
    if (lc.contains('youtube')) return Icons.video_library;
    if (lc.contains('linkedin')) return Icons.work;
    if (lc.contains('whatsapp')) return Icons.chat_bubble;
    return Icons.link;
  }

  Color _getSocialColor(String platform) {
    final lc = platform.toLowerCase();
    if (lc.contains('twitter') || lc.contains('x')) return const Color(0xFF1DA1F2);
    if (lc.contains('facebook')) return const Color(0xFF1877F2);
    if (lc.contains('instagram')) return const Color(0xFFE4405F);
    if (lc.contains('youtube')) return const Color(0xFFFF0000);
    if (lc.contains('linkedin')) return const Color(0xFF0A66C2);
    if (lc.contains('whatsapp')) return const Color(0xFF25D366);
    return navy;
  }

  // ==================== STATUT ====================
  Widget _buildStatusBanner(Authority authority) {
    final isActive = authority.isCurrentlyActive;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? success.withOpacity(0.1) : danger.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isActive ? success : danger),
      ),
      child: Row(
        children: [
          Icon(isActive ? Icons.check_circle : Icons.history, color: isActive ? success : danger),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isActive ? 'Autorité en fonction' : 'Ancienne autorité (mandat terminé)',
              style: TextStyle(fontWeight: FontWeight.w600, color: isActive ? success : danger),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== UTILITAIRES ====================
  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'ouvrir ce lien.'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
