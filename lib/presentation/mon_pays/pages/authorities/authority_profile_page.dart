// lib/presentation/mon_pays/pages/authorities/authority_profile_page.dart
// Détail complet d'une autorité avec toutes les sections

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/authorities_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../models/authority.dart';
import '../../utils/helpers.dart';
import '../../utils/constants.dart';

class AuthorityProfilePage extends ConsumerStatefulWidget {
  final String authorityId;

  const AuthorityProfilePage({
    required this.authorityId,
    super.key,
  });

  @override
  ConsumerState<AuthorityProfilePage> createState() => _AuthorityProfilePageState();
}

class _AuthorityProfilePageState extends ConsumerState<AuthorityProfilePage> {
  final ScrollController _scrollController = ScrollController();

  // ============================================================
  // CHARTE THIX ID — Design Institutionnel Premium (Navy / Bleu / Or)
  // ============================================================
  static const Color navyDeep = Color(0xFF0A1F44);
  static const Color navy = Color(0xFF123B7A);
  static const Color primaryBlue = Color(0xFF2D6CDF);
  static const Color gold = Color(0xFFE3B23C);
  static const Color ivory = Color(0xFFF6F7FB);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color darkText = Color(0xFF10182B);
  static const Color mutedText = Color(0xFF6B7690);
  static const Color success = Color(0xFF1FA971);
  static const Color danger = Color(0xFFD64545);
  static const Color hairline = Color(0xFFE7EAF3);

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authorityAsync = ref.watch(authorityDetailProvider(widget.authorityId));
    final isFavorite = ref.watch(favoritesProvider).contains(widget.authorityId);

    return Scaffold(
      backgroundColor: ivory,
      body: authorityAsync.when(
        loading: () => _buildLoadingState(),
        error: (error, stack) => _buildErrorState(error),
        data: (authority) => _buildProfileContent(authority, isFavorite),
      ),
    );
  }

  // ============================================================
  // ÉTAT CHARGEMENT
  // ============================================================
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: primaryBlue),
          SizedBox(height: 16),
          Text(
            'Chargement du profil…',
            style: TextStyle(color: mutedText, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ÉTAT ERREUR
  // ============================================================
  Widget _buildErrorState(Object error) {
    return Scaffold(
      backgroundColor: ivory,
      appBar: AppBar(
        backgroundColor: navyDeep,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.go('/mon-pays/authorities'),
        ),
        title: const Text('Erreur', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: danger.withOpacity(0.08), shape: BoxShape.circle),
              child: const Icon(Icons.error_outline_rounded, color: danger, size: 42),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: mutedText, fontSize: 12.5, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 18),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                ref.invalidate(authorityDetailProvider(widget.authorityId));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [navyDeep, navy]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, size: 16, color: gold),
                    SizedBox(width: 8),
                    Text('Réessayer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CONTENU DU PROFIL
  // ============================================================
  Widget _buildProfileContent(Authority authority, bool isFavorite) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        _buildSliverAppBar(authority, isFavorite),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildQuickActions(authority, isFavorite),
                const SizedBox(height: 18),

                if (authority.biography.isNotEmpty) ...[
                  _buildSectionTitle(Icons.description_rounded, 'Biographie'),
                  const SizedBox(height: 10),
                  _buildBiography(authority),
                  const SizedBox(height: 16),
                ],

                if (authority.explanation != null && authority.explanation!.isNotEmpty) ...[
                  _buildSectionTitle(Icons.lightbulb_rounded, 'Rôle & Explication'),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: gold.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: gold.withOpacity(0.35)),
                    ),
                    child: Text(
                      authority.explanation!,
                      style: const TextStyle(height: 1.6, color: darkText, fontSize: 13.5, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                _buildInfoSection(authority),
                const SizedBox(height: 16),

                if (authority.speeches.isNotEmpty) ...[
                  _buildSectionTitle(Icons.mic_rounded, 'Discours'),
                  const SizedBox(height: 10),
                  ..._buildSpeechList(authority.speeches),
                  const SizedBox(height: 16),
                ],

                if (authority.videos.isNotEmpty) ...[
                  _buildSectionTitle(Icons.smart_display_rounded, 'Vidéos'),
                  const SizedBox(height: 10),
                  ..._buildVideoList(authority.videos),
                  const SizedBox(height: 16),
                ],

                if (authority.publications.isNotEmpty) ...[
                  _buildSectionTitle(Icons.article_rounded, 'Publications'),
                  const SizedBox(height: 10),
                  ..._buildPublicationList(authority.publications),
                  const SizedBox(height: 16),
                ],

                if (authority.agenda.isNotEmpty) ...[
                  _buildSectionTitle(Icons.event_rounded, 'Agenda'),
                  const SizedBox(height: 10),
                  ..._buildAgendaList(authority.agenda),
                  const SizedBox(height: 16),
                ],

                if (authority.socialNetworks.isNotEmpty) ...[
                  _buildSectionTitle(Icons.public_rounded, 'Réseaux officiels'),
                  const SizedBox(height: 10),
                  ..._buildSocialList(authority.socialNetworks),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SLIVER APP BAR — cover navy, avatar cerclé or
  // ============================================================
  Widget _buildSliverAppBar(Authority authority, bool isFavorite) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      floating: true,
      backgroundColor: navyDeep,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: _glassIconButton(
          icon: Icons.arrow_back_rounded,
          onTap: () => context.go('/mon-pays/authorities'),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: _glassIconButton(
            icon: isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            iconColor: isFavorite ? danger : Colors.white,
            onTap: () {
              ref.read(favoritesProvider.notifier).toggleFavorite(authority.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isFavorite ? 'Retiré des favoris' : 'Ajouté aux favoris'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: _glassIconButton(icon: Icons.share_rounded, onTap: () => _shareAuthority(authority)),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
          child: _glassIconButton(icon: Icons.flag_rounded, iconColor: gold, onTap: () => _showReportDialog(context, authority)),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          authority.name,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
          overflow: TextOverflow.ellipsis,
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            authority.imageUrl != null && authority.imageUrl!.isNotEmpty
                ? Image.network(
                    authority.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildCoverPlaceholder(authority),
                  )
                : _buildCoverPlaceholder(authority),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xE60A1F44)],
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              child: _buildProfileAvatar(authority),
            ),
            Positioned(
              bottom: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: navyDeep.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: gold.withOpacity(0.5)),
                    ),
                    child: Text(
                      authority.title,
                      style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (authority.party.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        authority.party,
                        style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glassIconButton({required IconData icon, VoidCallback? onTap, Color iconColor = Colors.white}) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.22)),
        ),
        child: Icon(icon, color: iconColor, size: 17),
      ),
    );
  }

  Widget _buildCoverPlaceholder(Authority authority) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [navyDeep, navy],
        ),
      ),
      child: Center(
        child: Text(
          MonPaysHelpers.getInitials(authority.name),
          style: TextStyle(fontSize: 58, fontWeight: FontWeight.w900, color: Colors.white.withOpacity(0.15)),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(Authority authority) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: gold, width: 3),
        boxShadow: [BoxShadow(color: navyDeep.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 5))],
        color: navyDeep,
        image: authority.imageUrl != null && authority.imageUrl!.isNotEmpty
            ? DecorationImage(image: NetworkImage(authority.imageUrl!), fit: BoxFit.cover)
            : null,
      ),
      child: authority.imageUrl == null || authority.imageUrl!.isEmpty
          ? Center(
              child: Text(
                MonPaysHelpers.getInitials(authority.name),
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            )
          : null,
    );
  }

  // ============================================================
  // ACTIONS RAPIDES — icônes cerclées navy/or
  // ============================================================
  Widget _buildQuickActions(Authority authority, bool isFavorite) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: pureWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: hairline),
        boxShadow: [BoxShadow(color: navyDeep.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildQuickAction(
            icon: isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            label: isFavorite ? 'Favori' : 'Ajouter',
            color: isFavorite ? danger : navy,
            onTap: () {
              ref.read(favoritesProvider.notifier).toggleFavorite(authority.id);
            },
          ),
          _buildQuickAction(
            icon: Icons.share_rounded,
            label: 'Partager',
            color: primaryBlue,
            onTap: () => _shareAuthority(authority),
          ),
          _buildQuickAction(
            icon: Icons.flag_rounded,
            label: 'Signaler',
            color: const Color(0xFFB8860B),
            onTap: () => _showReportDialog(context, authority),
          ),
          _buildQuickAction(
            icon: Icons.link_rounded,
            label: 'Lien',
            color: success,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Lien copié dans le presse-papier'), duration: Duration(seconds: 2)),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(fontSize: 10, color: darkText, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  // ============================================================
  // TITRE DE SECTION — liseré or
  // ============================================================
  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: navyDeep, borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, size: 14, color: gold),
        ),
        const SizedBox(width: 9),
        Text(title, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: darkText)),
      ],
    );
  }

  // ============================================================
  // BIOGRAPHIE
  // ============================================================
  Widget _buildBiography(Authority authority) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: pureWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: hairline),
        boxShadow: [BoxShadow(color: navyDeep.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            authority.biography,
            style: const TextStyle(height: 1.7, color: darkText, fontSize: 13.5, fontWeight: FontWeight.w400),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: hairline),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 15, color: navy),
              const SizedBox(width: 8),
              Text(
                'Mandat : ${authority.mandate.isNotEmpty ? authority.mandate : 'Non spécifié'}',
                style: const TextStyle(fontSize: 12, color: mutedText, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION INFOS
  // ============================================================
  Widget _buildInfoSection(Authority authority) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: pureWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: hairline),
        boxShadow: [BoxShadow(color: navyDeep.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          _buildInfoItem(icon: Icons.work_rounded, label: 'Fonction', value: authority.title),
          Container(height: 1, color: hairline, margin: const EdgeInsets.symmetric(vertical: 12)),
          _buildInfoItem(icon: Icons.people_rounded, label: 'Parti', value: authority.party.isNotEmpty ? authority.party : 'Non spécifié'),
          Container(height: 1, color: hairline, margin: const EdgeInsets.symmetric(vertical: 12)),
          _buildInfoItem(icon: Icons.calendar_today_rounded, label: 'Mandat', value: authority.mandate.isNotEmpty ? authority.mandate : 'Non spécifié'),
        ],
      ),
    );
  }

  Widget _buildInfoItem({required IconData icon, required String label, required String value}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(color: ivory, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 16, color: navy),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10.5, color: mutedText, fontWeight: FontWeight.w600)),
              const SizedBox(height: 1),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: darkText)),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LISTE DISCOURS
  // ============================================================
  List<Widget> _buildSpeechList(List<String> speeches) {
    return speeches.asMap().entries.map((entry) {
      final index = entry.key;
      final speech = entry.value;
      return _listCard(
        leading: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: navyDeep, shape: BoxShape.circle),
          child: Text('${index + 1}', style: const TextStyle(color: gold, fontWeight: FontWeight.w800, fontSize: 13)),
        ),
        title: speech,
        trailing: const Icon(Icons.play_circle_fill_rounded, color: navy, size: 22),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lecture du discours: ${speech.length > 30 ? speech.substring(0, 30) + '...' : speech}'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
      );
    }).toList();
  }

  // ============================================================
  // LISTE VIDÉOS
  // ============================================================
  List<Widget> _buildVideoList(List<String> videos) {
    return videos.asMap().entries.map((entry) {
      final index = entry.key;
      final video = entry.value;
      return _listCard(
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(color: navyDeep, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.play_arrow_rounded, color: gold, size: 26),
        ),
        title: video,
        subtitle: 'Vidéo ${index + 1}',
        trailing: const Icon(Icons.fullscreen_rounded, color: mutedText, size: 18),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lecture de la vidéo: ${video.length > 30 ? video.substring(0, 30) + '...' : video}'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
      );
    }).toList();
  }

  // ============================================================
  // LISTE PUBLICATIONS
  // ============================================================
  List<Widget> _buildPublicationList(List<String> publications) {
    return publications.map((pub) {
      return _listCard(
        leading: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(color: ivory, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.article_rounded, color: navy, size: 18),
        ),
        title: pub,
        trailing: const Icon(Icons.open_in_new_rounded, size: 16, color: mutedText),
        onTap: () {},
      );
    }).toList();
  }

  // ============================================================
  // LISTE AGENDA
  // ============================================================
  List<Widget> _buildAgendaList(List<Map<String, String>> agenda) {
    return agenda.map((item) {
      final date = item['date'] ?? 'Date non spécifiée';
      final event = item['event'] ?? 'Événement';
      return _listCard(
        leading: Container(
          width: 48,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(color: navyDeep, borderRadius: BorderRadius.circular(10)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(date.split('-').last, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: gold)),
              Text(_getMonthName(date), style: const TextStyle(fontSize: 9, color: Colors.white70, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        title: event,
        trailing: const Icon(Icons.calendar_today_rounded, size: 15, color: mutedText),
        onTap: () {},
      );
    }).toList();
  }

  String _getMonthName(String date) {
    try {
      final parts = date.split('-');
      if (parts.length >= 2) {
        final month = int.parse(parts[1]);
        const months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
        return months[month - 1];
      }
    } catch (e) {
      return 'Date';
    }
    return 'Date';
  }

  // ============================================================
  // LISTE RÉSEAUX SOCIAUX
  // ============================================================
  List<Widget> _buildSocialList(Map<String, String> socialNetworks) {
    return socialNetworks.entries.map((entry) {
      final platform = entry.key;
      final url = entry.value;
      return _listCard(
        leading: _getSocialIcon(platform),
        title: platform,
        subtitle: url,
        trailing: const Icon(Icons.open_in_new_rounded, size: 16, color: mutedText),
        onTap: () => _launchUrl(url),
      );
    }).toList();
  }

  Widget _getSocialIcon(String platform) {
    final platformLower = platform.toLowerCase();
    IconData icon;
    Color color;
    if (platformLower.contains('twitter') || platformLower.contains('x')) {
      icon = Icons.chat_rounded;
      color = const Color(0xFF1DA1F2);
    } else if (platformLower.contains('facebook')) {
      icon = Icons.facebook_rounded;
      color = const Color(0xFF1877F2);
    } else if (platformLower.contains('instagram')) {
      icon = Icons.camera_alt_rounded;
      color = const Color(0xFFE4405F);
    } else if (platformLower.contains('linkedin')) {
      icon = Icons.work_rounded;
      color = const Color(0xFF0A66C2);
    } else if (platformLower.contains('youtube')) {
      icon = Icons.smart_display_rounded;
      color = const Color(0xFFFF0000);
    } else if (platformLower.contains('whatsapp')) {
      icon = Icons.chat_bubble_rounded;
      color = const Color(0xFF25D366);
    } else {
      icon = Icons.link_rounded;
      color = navy;
    }
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(color: color.withOpacity(0.10), shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 19),
    );
  }

  // ============================================================
  // CARTE LISTE GÉNÉRIQUE — institutionnelle
  // ============================================================
  Widget _listCard({
    required Widget leading,
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: pureWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: hairline),
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: darkText),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: mutedText, fontWeight: FontWeight.w500),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 6), trailing],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PARTAGE
  // ============================================================
  Future<void> _shareAuthority(Authority authority) async {
    try {
      final String shareText = '''
📋 ${authority.name}
🏛️ ${authority.title}
📅 Mandat: ${authority.mandate}
🏛️ Parti: ${authority.party}
📖 Biographie: ${authority.biography.length > 150 ? authority.biography.substring(0, 150) + '...' : authority.biography}

🔗 Voir le profil complet sur Sona1
''';
      await Share.share(shareText);
    } catch (e) {
      // Gérer l'erreur
    }
  }

  // ============================================================
  // OUVERTURE URL
  // ============================================================
  Future<void> _launchUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (!await launchUrl(uri)) {
        throw Exception("Impossible d'ouvrir $url");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible d\'ouvrir le lien: ${e.toString()}'),
          backgroundColor: danger,
        ),
      );
    }
  }

  // ============================================================
  // DIALOGUE SIGNALEMENT — institutionnel
  // ============================================================
  void _showReportDialog(BuildContext context, Authority authority) {
    final TextEditingController reportController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: navyDeep, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.flag_rounded, size: 16, color: gold),
                  ),
                  const SizedBox(width: 10),
                  const Text('Signaler', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: darkText)),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Signaler une information concernant ${authority.name}',
                style: const TextStyle(fontSize: 13, color: mutedText, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Motif du signalement',
                  labelStyle: const TextStyle(color: mutedText, fontSize: 12.5),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: hairline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: navy, width: 1.6),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'information_incorrecte', child: Text('Information incorrecte')),
                  DropdownMenuItem(value: 'contenu_inapproprié', child: Text('Contenu inapproprié')),
                  DropdownMenuItem(value: 'problème_technique', child: Text('Problème technique')),
                  DropdownMenuItem(value: 'autre', child: Text('Autre')),
                ],
                onChanged: (value) {},
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reportController,
                decoration: InputDecoration(
                  labelText: 'Description (optionnelle)',
                  labelStyle: const TextStyle(color: mutedText, fontSize: 12.5),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: hairline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: navy, width: 1.6),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Annuler', style: TextStyle(color: mutedText, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [navyDeep, navy]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Signalement envoyé ✅'), backgroundColor: success),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Envoyer', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
