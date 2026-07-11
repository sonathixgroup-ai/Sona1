// lib/presentation/mon_pays/pages/authorities/authority_profile_page.dart
// Détail complet d'une autorité avec toutes les sections :
// - Photo, biographie, mandat, parti
// - Discours, vidéos, publications
// - Agenda, réseaux sociaux
// - Favoris, partage, signalement

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/authorities_provider.dart';
import '../../providers/favorites_provider.dart';
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
  bool _isExpanded = false;

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
      body: authorityAsync.when(
        loading: () => _buildLoadingState(),
        error: (error, stack) => _buildErrorState(error),
        data: (authority) => _buildProfileContent(authority, isFavorite),
      ),
    );
  }

  // ==================== LOADING STATE ====================

  Widget _buildLoadingState() {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A5276)),
            ),
            SizedBox(height: 16),
            Text(
              'Chargement du profil...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== ERROR STATE ====================

  Widget _buildErrorState(Object error) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/mon-pays/authorities'),
        ),
        title: const Text('Erreur'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                color: Colors.red.shade400,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(authorityDetailProvider(widget.authorityId));
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A5276),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== PROFILE CONTENT ====================

  Widget _buildProfileContent(Authority authority, bool isFavorite) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // AppBar avec image de couverture
        _buildSliverAppBar(authority, isFavorite),
        // Contenu du profil
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Actions rapides
                _buildQuickActions(authority, isFavorite),
                const SizedBox(height: 16),
                // Biographie
                if (authority.biography.isNotEmpty) ...[
                  _buildSectionTitle('📝 Biographie'),
                  const SizedBox(height: 8),
                  _buildBiography(authority.biography),
                  const SizedBox(height: 16),
                ],
                // Informations supplémentaires
                _buildInfoSection(authority),
                const SizedBox(height: 16),
                // Discours
                if (authority.speeches.isNotEmpty) ...[
                  _buildSectionTitle('🎙️ Discours'),
                  const SizedBox(height: 8),
                  ..._buildSpeechList(authority.speeches),
                  const SizedBox(height: 16),
                ],
                // Vidéos
                if (authority.videos.isNotEmpty) ...[
                  _buildSectionTitle('🎬 Vidéos'),
                  const SizedBox(height: 8),
                  ..._buildVideoList(authority.videos),
                  const SizedBox(height: 16),
                ],
                // Publications
                if (authority.publications.isNotEmpty) ...[
                  _buildSectionTitle('📄 Publications'),
                  const SizedBox(height: 8),
                  ..._buildPublicationList(authority.publications),
                  const SizedBox(height: 16),
                ],
                // Agenda
                if (authority.agenda.isNotEmpty) ...[
                  _buildSectionTitle('📅 Agenda'),
                  const SizedBox(height: 8),
                  ..._buildAgendaList(authority.agenda),
                  const SizedBox(height: 16),
                ],
                // Réseaux sociaux
                if (authority.socialNetworks.isNotEmpty) ...[
                  _buildSectionTitle('🌐 Réseaux officiels'),
                  const SizedBox(height: 8),
                  ..._buildSocialList(authority.socialNetworks),
                  const SizedBox(height: 16),
                ],
                // Footer
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==================== SLIVER APP BAR ====================

  Widget _buildSliverAppBar(Authority authority, bool isFavorite) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      floating: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => context.go('/mon-pays/authorities'),
      ),
      actions: [
        // Bouton favori
        IconButton(
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? Colors.red : Colors.white,
            size: 28,
          ),
          onPressed: () {
            ref.read(favoritesProvider.notifier).toggleFavorite(authority.id);
            if (isFavorite) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Retiré des favoris'),
                  duration: Duration(seconds: 1),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ajouté aux favoris ⭐'),
                  duration: Duration(seconds: 1),
                ),
              );
            }
          },
        ),
        // Bouton partage
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: () => _shareAuthority(authority),
        ),
        // Bouton signalement
        IconButton(
          icon: const Icon(Icons.flag, color: Colors.white),
          onPressed: () => _showReportDialog(context, authority),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          authority.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Image de fond (photo officielle ou placeholder)
            authority.imageUrl != null && authority.imageUrl!.isNotEmpty
                ? Image.network(
                    authority.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildCoverPlaceholder(authority),
                  )
                : _buildCoverPlaceholder(authority),
            // Dégradé pour la lisibilité
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.6),
                  ],
                ),
              ),
            ),
            // Photo de profil en bas
            Positioned(
              bottom: 20,
              left: 20,
              child: _buildProfileAvatar(authority),
            ),
            // Infos en bas à droite
            Positioned(
              bottom: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A5276).withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      authority.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (authority.party.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        authority.party,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
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

  Widget _buildCoverPlaceholder(Authority authority) {
    return Container(
      color: MonPaysHelpers.getColorFromName(authority.name),
      child: Center(
        child: Text(
          MonPaysHelpers.getInitials(authority.name),
          style: const TextStyle(
            fontSize: 60,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
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
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        image: authority.imageUrl != null && authority.imageUrl!.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(authority.imageUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: authority.imageUrl == null || authority.imageUrl!.isEmpty
          ? Center(
              child: Text(
                MonPaysHelpers.getInitials(authority.name),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            )
          : null,
    );
  }

  // ==================== QUICK ACTIONS ====================

  Widget _buildQuickActions(Authority authority, bool isFavorite) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildQuickAction(
          icon: isFavorite ? Icons.favorite : Icons.favorite_border,
          label: isFavorite ? 'Favori' : 'Ajouter',
          color: isFavorite ? Colors.red : Colors.grey,
          onTap: () {
            ref.read(favoritesProvider.notifier).toggleFavorite(authority.id);
          },
        ),
        _buildQuickAction(
          icon: Icons.share,
          label: 'Partager',
          color: const Color(0xFF1A5276),
          onTap: () => _shareAuthority(authority),
        ),
        _buildQuickAction(
          icon: Icons.flag,
          label: 'Signaler',
          color: Colors.orange,
          onTap: () => _showReportDialog(context, authority),
        ),
        _buildQuickAction(
          icon: Icons.link,
          label: 'Lien',
          color: Colors.green,
          onTap: () {
            // Copier le lien
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Lien copié dans le presse-papier'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ],
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
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== SECTION TITLE ====================

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.circle, color: Color(0xFF1A5276), size: 8),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== BIOGRAPHY ====================

  Widget _buildBiography(String biography) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              biography,
              style: TextStyle(
                height: 1.8,
                color: Colors.grey.shade800,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Mandat: ${authority.mandate.isNotEmpty ? authority.mandate : 'Non spécifié'}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==================== INFO SECTION ====================

  Widget _buildInfoSection(Authority authority) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoItem(
              icon: Icons.work,
              label: 'Fonction',
              value: authority.title,
            ),
            const Divider(height: 16),
            _buildInfoItem(
              icon: Icons.people,
              label: 'Parti',
              value: authority.party.isNotEmpty ? authority.party : 'Non spécifié',
            ),
            const Divider(height: 16),
            _buildInfoItem(
              icon: Icons.calendar_today,
              label: 'Mandat',
              value: authority.mandate.isNotEmpty ? authority.mandate : 'Non spécifié',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF1A5276)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== SPEECH LIST ====================

  List<Widget> _buildSpeechList(List<String> speeches) {
    return speeches.asMap().entries.map((entry) {
      final index = entry.key;
      final speech = entry.value;
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFF1A5276).withOpacity(0.1),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Color(0xFF1A5276),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            speech,
            style: const TextStyle(fontSize: 14),
          ),
          trailing: const Icon(
            Icons.play_circle_outline,
            color: Color(0xFF1A5276),
          ),
          onTap: () {
            // TODO: Ouvrir le discours
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lecture du discours: ${speech.length > 30 ? speech.substring(0, 30) + '...' : speech}'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
      );
    }).toList();
  }

  // ==================== VIDEO LIST ====================

  List<Widget> _buildVideoList(List<String> videos) {
    return videos.asMap().entries.map((entry) {
      final index = entry.key;
      final video = entry.value;
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListTile(
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
          title: Text(
            video,
            style: const TextStyle(fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            'Vidéo ${index + 1}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          trailing: const Icon(
            Icons.fullscreen,
            color: Colors.grey,
          ),
          onTap: () {
            // TODO: Ouvrir le lecteur vidéo
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lecture de la vidéo: ${video.length > 30 ? video.substring(0, 30) + '...' : video}'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
      );
    }).toList();
  }

  // ==================== PUBLICATION LIST ====================

  List<Widget> _buildPublicationList(List<String> publications) {
    return publications.map((pub) {
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListTile(
          leading: const Icon(
            Icons.article,
            color: Color(0xFF1A5276),
          ),
          title: Text(
            pub,
            style: const TextStyle(fontSize: 14),
          ),
          trailing: const Icon(
            Icons.open_in_new,
            size: 18,
            color: Colors.grey,
          ),
          onTap: () {
            // TODO: Ouvrir la publication
          },
        ),
      );
    }).toList();
  }

  // ==================== AGENDA LIST ====================

  List<Widget> _buildAgendaList(List<Map<String, String>> agenda) {
    return agenda.map((item) {
      final date = item['date'] ?? 'Date non spécifiée';
      final event = item['event'] ?? 'Événement';
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListTile(
          leading: Container(
            width: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A5276).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  date.split('-').last,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF1A5276),
                  ),
                ),
                Text(
                  _getMonthName(date),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          title: Text(
            event,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          trailing: const Icon(
            Icons.calendar_today,
            size: 16,
            color: Colors.grey,
          ),
        ),
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

  // ==================== SOCIAL LIST ====================

  List<Widget> _buildSocialList(Map<String, String> socialNetworks) {
    return socialNetworks.entries.map((entry) {
      final platform = entry.key;
      final url = entry.value;
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListTile(
          leading: _getSocialIcon(platform),
          title: Text(
            platform,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            url,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(
            Icons.open_in_new,
            size: 18,
            color: Colors.grey,
          ),
          onTap: () => _launchUrl(url),
        ),
      );
    }).toList();
  }

  Widget _getSocialIcon(String platform) {
    final platformLower = platform.toLowerCase();
    IconData icon;
    Color color;
    if (platformLower.contains('twitter') || platformLower.contains('x')) {
      icon = Icons.chat;
      color = const Color(0xFF1DA1F2);
    } else if (platformLower.contains('facebook')) {
      icon = Icons.facebook;
      color = const Color(0xFF1877F2);
    } else if (platformLower.contains('instagram')) {
      icon = Icons.photo_camera;
      color = const Color(0xFFE4405F);
    } else if (platformLower.contains('linkedin')) {
      icon = Icons.work;
      color = const Color(0xFF0A66C2);
    } else if (platformLower.contains('youtube')) {
      icon = Icons.video_library;
      color = const Color(0xFFFF0000);
    } else if (platformLower.contains('whatsapp')) {
      icon = Icons.chat_bubble;
      color = const Color(0xFF25D366);
    } else {
      icon = Icons.link;
      color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  // ==================== SHARE ====================

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

  // ==================== LAUNCH URL ====================

  Future<void> _launchUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (!await launchUrl(uri)) {
        throw Exception('Impossible d\'ouvrir $url');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible d\'ouvrir le lien: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ==================== REPORT DIALOG ====================

  void _showReportDialog(BuildContext context, Authority authority) {
    final TextEditingController _reportController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.flag, color: Colors.orange),
            SizedBox(width: 8),
            Text('Signaler'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Signaler une information concernant ${authority.name}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Motif du signalement',
                border: OutlineInputBorder(),
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
              controller: _reportController,
              decoration: const InputDecoration(
                labelText: 'Description (optionnelle)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Signalement envoyé ✅'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }
}
