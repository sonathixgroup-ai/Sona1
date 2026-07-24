// lib/presentation/mon_pays/pages/authorities/authority_profile_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text('Impossible de charger le profil', style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: () => ref.invalidate(authorityDetailProvider(widget.authorityId)), style: ElevatedButton.styleFrom(backgroundColor: navy), child: const Text('Réessayer', style: TextStyle(color: Colors.white))),
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
                
                if (authority.biography.isNotEmpty) ...[
                  _buildSectionTitle(Icons.history_edu, 'Biographie'),
                  _buildTextCard(authority.biography),
                  const SizedBox(height: 24),
                ],
                if (authority.education.isNotEmpty) ...[
                  _buildSectionTitle(Icons.school, 'Études & Formations'),
                  ...authority.education.map((edu) => _buildTimelineCard(title: edu.degree, subtitle: edu.institution, dateRange: '${edu.startYear ?? ''} - ${edu.endYear ?? 'Présent'}'.trim(), icon: Icons.school_outlined)),
                  const SizedBox(height: 24),
                ],
                if (authority.career.isNotEmpty) ...[
                  _buildSectionTitle(Icons.work, 'Parcours Professionnel'),
                  ...authority.career.map((career) => _buildTimelineCard(title: career.title, subtitle: career.organization, dateRange: '${career.startDate} - ${career.endDate ?? 'Présent'}'.trim(), icon: Icons.business_center_outlined)),
                  const SizedBox(height: 24),
                ],
                if (authority.achievements.isNotEmpty) ...[
                  _buildSectionTitle(Icons.emoji_events, 'Réalisations'),
                  ...authority.achievements.map((ach) => _buildAchievementCard(ach)),
                  const SizedBox(height: 24),
                ],
                if (authority.photos.isNotEmpty) ...[
                  _buildSectionTitle(Icons.photo_library, 'Galerie Photos'),
                  _buildPhotoGallery(authority.photos),
                  const SizedBox(height: 24),
                ],
                if (authority.videos.isNotEmpty) ...[
                  _buildSectionTitle(Icons.video_library, 'Vidéos'),
                  ...authority.videos.map((video) => _buildVideoCard(video)),
                  const SizedBox(height: 24),
                ],
                if (authority.documents.isNotEmpty) ...[
                  _buildSectionTitle(Icons.folder, 'Documents'),
                  ...authority.documents.map((doc) => _buildDocumentCard(doc)),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar(Authority authority) {
    final bgImage = authority.coverImageUrl ?? authority.imageUrl;
    return SliverAppBar(
      expandedHeight: 320, pinned: true, backgroundColor: navyDeep, iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16, right: 16),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (authority.imageUrl != null) ...[
              Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: gold, width: 2)), child: CircleAvatar(radius: 24, backgroundImage: CachedNetworkImageProvider(authority.imageUrl!), backgroundColor: navy)),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(authority.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white, shadows: [Shadow(color: Colors.black, blurRadius: 4)])),
                  Text(authority.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: gold, shadows: [Shadow(color: Colors.black, blurRadius: 4)])),
                ],
              ),
            ),
          ],
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (bgImage != null && bgImage.isNotEmpty)
              CachedNetworkImage(imageUrl: bgImage, fit: BoxFit.cover, placeholder: (_, __) => Container(color: Colors.grey.shade300), errorWidget: (_, __, ___) => Container(color: navy, child: const Icon(Icons.account_balance, size: 80, color: Colors.white24)))
            else
              Container(color: navy, child: const Icon(Icons.account_balance, size: 80, color: Colors.white24)),
            Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, navyDeep.withOpacity(0.95)], stops: const [0.4, 1.0]))),
          ],
        ),
      ),
    );
  }

  Widget _buildBadges(Authority authority) {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: [
        _buildBadgeItem(Icons.category, authority.category ?? 'Non défini', navy),
        if (authority.party.isNotEmpty) _buildBadgeItem(Icons.people, authority.party, const Color(0xFF1A5276)),
        if (authority.mandate.isNotEmpty) _buildBadgeItem(Icons.calendar_today, authority.mandate, Colors.orange.shade700),
        if (!authority.isCurrentlyActive) _buildBadgeItem(Icons.history, 'Mandat terminé', Colors.red),
      ],
    );
  }

  Widget _buildBadgeItem(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.3))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14, color: color), const SizedBox(width: 6), Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color))]),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [Icon(icon, color: gold, size: 22), const SizedBox(width: 8), Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: navyDeep)))]),
    );
  }

  Widget _buildTextCard(String text) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: hairline), boxShadow: [BoxShadow(color: navyDeep.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Text(text, style: const TextStyle(fontSize: 14, color: darkText, height: 1.6)),
    );
  }

  Widget _buildTimelineCard({required String title, required String subtitle, required String dateRange, required IconData icon}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: hairline)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: navy.withOpacity(0.08), shape: BoxShape.circle), child: Icon(icon, color: navy, size: 22)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: darkText)), const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: navy)),
                if (dateRange.isNotEmpty && dateRange != '-') ...[
                  const SizedBox(height: 4),
                  Row(children: [const Icon(Icons.calendar_month, size: 12, color: mutedText), const SizedBox(width: 4), Text(dateRange, style: const TextStyle(fontSize: 12, color: mutedText))]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: hairline), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (achievement.imageUrl != null && achievement.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: CachedNetworkImage(imageUrl: achievement.imageUrl!, height: 160, width: double.infinity, fit: BoxFit.cover, placeholder: (c, u) => Container(height: 160, color: Colors.grey.shade200)),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (achievement.category != null && achievement.category!.isNotEmpty)
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: gold.withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: Text(achievement.category!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: navyDeep))),
                    const Spacer(),
                    if (achievement.date != null && achievement.date!.isNotEmpty) Text(achievement.date!, style: const TextStyle(fontSize: 12, color: mutedText, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(achievement.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: navyDeep)),
                if (achievement.description != null && achievement.description!.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text(achievement.description!, style: const TextStyle(fontSize: 13, color: darkText, height: 1.4))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 👉 GALERIE PHOTO CLIQUABLE EN PLEIN ÉCRAN
  Widget _buildPhotoGallery(List<AuthorityPhoto> photos) {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal, itemCount: photos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final photo = photos[index];
          return GestureDetector(
            onTap: () => _showFullScreenPhoto(context, photo.url, photo.title),
            child: Container(
              width: 140, decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: hairline)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(imageUrl: photo.url, fit: BoxFit.cover, placeholder: (_, __) => Container(color: Colors.grey.shade200)),
                    if (photo.title != null && photo.title!.isNotEmpty)
                      Positioned(bottom: 0, left: 0, right: 0, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withOpacity(0.8), Colors.transparent])), child: Text(photo.title!, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis))),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showFullScreenPhoto(BuildContext context, String url, String? title) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent, insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain, height: double.infinity, width: double.infinity)),
            Positioned(top: 40, right: 20, child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => Navigator.pop(ctx))),
            if (title != null && title.isNotEmpty)
              Positioned(bottom: 40, left: 20, right: 20, child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black, blurRadius: 4)]), textAlign: TextAlign.center)),
          ],
        ),
      ),
    );
  }

  // 👉 VIDÉO EN FORME DE CARTE (THUMBNAIL + BOUTON PLAY)
  Widget _buildVideoCard(AuthorityVideo video) {
    return GestureDetector(
      onTap: () => _launchUrl(video.url),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 180, width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))],
          image: video.thumbnailUrl != null ? DecorationImage(image: CachedNetworkImageProvider(video.thumbnailUrl!), fit: BoxFit.cover, colorFilter: const ColorFilter.mode(Colors.black54, BlendMode.darken)) : null,
        ),
        child: Stack(
          children: [
            const Center(child: Icon(Icons.play_circle_fill, size: 64, color: Colors.red)),
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)), gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withOpacity(0.9), Colors.transparent])),
                child: Text(video.title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black, blurRadius: 4)])),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentCard(AuthorityDocument doc) {
    return InkWell(
      onTap: () => _launchUrl(doc.url),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: hairline)),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 24)),
            const SizedBox(width: 14),
            Expanded(child: Text(doc.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: darkText))),
            const Icon(Icons.download_rounded, color: navy, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible d\'ouvrir ce lien.'), backgroundColor: Colors.red));
    }
  }
}
