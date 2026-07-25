// ============================================================
// FICHIER - province_detail_page.dart (EXPERT EDITION — SYNCHRONISÉ AVEC LE FORM)
// Design "Wikipédia Moderne" — Charte THIX ID (navy #0A1F44 / gold #E3B23C)
// Chaque rubrique du formulaire admin est reflétée ici, avec fiches
// détaillées ("Voir plus") et galeries photos/vidéos plein écran.
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/provinces_provider.dart';
import '../../models/province.dart';
import '../../models/city.dart';

// ==================== PALETTE (Charte THIX ID) ====================
const Color _navyDeep = Color(0xFF0A1F44);
const Color _navy = Color(0xFF123B7A);
const Color _gold = Color(0xFFE3B23C);
const Color _ivory = Color(0xFFF6F7FB);
const Color _hairline = Color(0xFFE7EAF3);
const Color _muted = Color(0xFF6B7690);
const Color _ink = Color(0xFF10182B);

class ProvinceDetailPage extends ConsumerStatefulWidget {
  final String provinceId;
  const ProvinceDetailPage({required this.provinceId, super.key});

  @override
  ConsumerState<ProvinceDetailPage> createState() => _ProvinceDetailPageState();
}

class _ProvinceDetailPageState extends ConsumerState<ProvinceDetailPage> {
  final ScrollController _scrollCtrl = ScrollController();
  final PageController _bannerCtrl = PageController();
  Timer? _bannerTimer;
  int _bannerIndex = 0;

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _startBanner(int count) {
    if (count <= 1) return;
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_bannerCtrl.hasClients) return;
      _bannerIndex = (_bannerIndex + 1) % count;
      _bannerCtrl.animateToPage(_bannerIndex, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provinceAsync = ref.watch(provinceWithAllRelationsProvider(widget.provinceId));

    return Scaffold(
      backgroundColor: _ivory,
      body: provinceAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: _navy)),
        error: (e, _) => _ErrorView(onRetry: () => ref.invalidate(provinceWithAllRelationsProvider(widget.provinceId))),
        data: (province) => CustomScrollView(
          controller: _scrollCtrl,
          slivers: [
            _ProvinceHeader(province: province),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList.list(children: [

                // 1. IDENTITÉ & CHIFFRES CLÉS
                _ProvinceIdentityCard(province: province),
                const SizedBox(height: 16),

                // 2. CARTE GÉOGRAPHIQUE
                if (province.mapUrl != null && province.mapUrl!.trim().isNotEmpty) ...[
                  const _SectionTitle('Carte Géographique'),
                  const SizedBox(height: 12),
                  _MapCard(url: province.mapUrl!, provinceName: province.name),
                  const SizedBox(height: 24),
                ],

                // 3. GALERIE GLOBALE
                if (province.galleryMedia != null && province.galleryMedia!.isNotEmpty) ...[
                  const _SectionTitle('Galerie de la Province'),
                  const SizedBox(height: 12),
                  _GalleryBanner(media: province.galleryMedia!, controller: _bannerCtrl, onReady: _startBanner, provinceName: province.name),
                  const SizedBox(height: 24),
                ],

                // 4. CULTURE, LANGUES & GÉNÉRALITÉS
                if (_hasCultureData(province)) ...[
                  const _SectionTitle('Culture, Langues & Généralités'),
                  const SizedBox(height: 12),
                  _CultureSection(province: province),
                  const SizedBox(height: 24),
                ],

                // 5. MONOGRAPHIE INSTITUTIONNELLE
                if (_hasInstitutionalData(province)) ...[
                  const _SectionTitle('Monographie Institutionnelle'),
                  const SizedBox(height: 12),
                  _MonographySection(province: province),
                  const SizedBox(height: 24),
                ],

                // 6. GOUVERNANCE & EXÉCUTIF
                const _SectionTitle('Gouvernance & Exécutif'),
                const SizedBox(height: 12),
                _ExecutiveSection(province: province),
                if (province.ministers != null && province.ministers!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _MinistersSection(ministers: province.ministers!),
                ],
                const SizedBox(height: 24),

                // 7. ÉCONOMIE & SECTEURS CLÉS
                if (province.economicResources.isNotEmpty) ...[
                  const _SectionTitle('Économie & Secteurs Clés'),
                  const SizedBox(height: 12),
                  _EconomySection(resources: province.economicResources),
                  const SizedBox(height: 24),
                ],

                // 8. TOURISME & SITES REMARQUABLES
                if (province.tourismSites.isNotEmpty) ...[
                  const _SectionTitle('Tourisme & Sites Remarquables'),
                  const SizedBox(height: 12),
                  _TourismSection(sites: province.tourismSites),
                  const SizedBox(height: 24),
                ],

                // 9. PEUPLES & TRIBUS AUTOCHTONES
                if (province.tribes != null && province.tribes!.isNotEmpty) ...[
                  const _SectionTitle('Peuples & Tribus Autochtones'),
                  const SizedBox(height: 12),
                  _TribesSection(tribes: province.tribes!),
                  const SizedBox(height: 24),
                ],

                // 10. DÉCOUPAGE ADMINISTRATIF
                if (province.administrativeDivisions.isNotEmpty) ...[
                  const _SectionTitle('Découpage Administratif'),
                  const SizedBox(height: 12),
                  _AdministrativeSection(divisions: province.administrativeDivisions),
                  const SizedBox(height: 24),
                ],

                // 11. VILLES PRINCIPALES
                if (province.cities.isNotEmpty) ...[
                  const _SectionTitle('Villes Principales'),
                  const SizedBox(height: 12),
                  _CitiesSection(cities: province.cities),
                  const SizedBox(height: 24),
                ],

                // 12. RÉALISATIONS & PROJETS MAJEURS
                if (province.achievements != null && province.achievements!.isNotEmpty) ...[
                  const _SectionTitle('Réalisations & Projets Majeurs'),
                  const SizedBox(height: 12),
                  _AchievementsSection(achievements: province.achievements!),
                  const SizedBox(height: 24),
                ],

                // 13. URGENCES & CONTACTS UTILES
                if (province.emergencyContacts.isNotEmpty) ...[
                  const _SectionTitle('Urgences & Contacts Utiles'),
                  const SizedBox(height: 12),
                  _EmergencySection(contacts: province.emergencyContacts),
                  const SizedBox(height: 40),
                ],
              ]),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasCultureData(Province p) {
    return (p.description?.trim().isNotEmpty == true) ||
           (p.languages?.trim().isNotEmpty == true) ||
           (p.resources?.trim().isNotEmpty == true);
  }

  bool _hasInstitutionalData(Province p) {
    return (p.history?.trim().isNotEmpty == true) ||
           (p.climate?.trim().isNotEmpty == true) ||
           (p.infrastructure?.trim().isNotEmpty == true) ||
           (p.education?.trim().isNotEmpty == true);
  }
}

// ============================================================
// UTILITAIRES PARTAGÉS : lancement de liens & appels
// ============================================================
Future<void> _launchUrlSafe(String rawUrl) async {
  var u = rawUrl.trim();
  if (!u.startsWith('http://') && !u.startsWith('https://')) u = 'https://$u';
  final uri = Uri.tryParse(u);
  if (uri != null) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

String _fmtNumber(num n) => n.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');

// ============================================================
// GALERIE MÉDIA PLEIN ÉCRAN (photos + vidéos)
// ============================================================
void _openMediaGallery(BuildContext context, List<Map<String, dynamic>> media, {int initialIndex = 0, String title = 'Galerie'}) {
  if (media.isEmpty) return;
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (_, __, ___) => _MediaGalleryPage(media: media, initialIndex: initialIndex, title: title),
      transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
    ),
  );
}

void _openMediaGrid(BuildContext context, List<Map<String, dynamic>> media, {String title = 'Galerie'}) {
  if (media.isEmpty) return;
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => _MediaGridPage(media: media, title: title)));
}

class _MediaGalleryPage extends StatefulWidget {
  final List<Map<String, dynamic>> media;
  final int initialIndex;
  final String title;
  const _MediaGalleryPage({required this.media, required this.title, this.initialIndex = 0});

  @override
  State<_MediaGalleryPage> createState() => _MediaGalleryPageState();
}

class _MediaGalleryPageState extends State<_MediaGalleryPage> {
  late final PageController _pageCtrl;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _pageCtrl = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageCtrl,
            itemCount: widget.media.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) {
              final item = widget.media[i];
              final url = item['url']?.toString() ?? '';
              final isVideo = item['type'] == 'video';
              if (isVideo) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 96, height: 96,
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), shape: BoxShape.circle),
                        child: const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 64),
                      ),
                      const SizedBox(height: 20),
                      const Text('Contenu vidéo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => _launchUrlSafe(url),
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: const Text('Lire la vidéo'),
                        style: ElevatedButton.styleFrom(backgroundColor: _gold, foregroundColor: _navyDeep, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                      ),
                    ],
                  ),
                );
              }
              return InteractiveViewer(
                panEnabled: true, minScale: 1.0, maxScale: 4.0,
                child: CachedNetworkImage(
                  imageUrl: url, fit: BoxFit.contain,
                  placeholder: (_, __) => const Center(child: CircularProgressIndicator(color: Colors.white)),
                  errorWidget: (_, __, ___) => const Center(child: Icon(Icons.error_outline, color: Colors.white, size: 50)),
                ),
              );
            },
          ),
          Positioned(
            top: 44, left: 16, right: 16,
            child: Row(
              children: [
                _RoundIconButton(icon: Icons.close, onTap: () => Navigator.of(context).pop()),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                  child: Text('${_index + 1} / ${widget.media.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 32, left: 0, right: 0,
            child: Text(widget.title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap, customBorder: const CircleBorder(),
      child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: 22)),
    );
  }
}

class _MediaGridPage extends StatelessWidget {
  final List<Map<String, dynamic>> media;
  final String title;
  const _MediaGridPage({required this.media, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ivory,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        backgroundColor: _navyDeep, foregroundColor: Colors.white, elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
          itemCount: media.length,
          itemBuilder: (_, i) {
            final item = media[i];
            final isVideo = item['type'] == 'video';
            return GestureDetector(
              onTap: () => _openMediaGallery(context, media, initialIndex: i, title: title),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: isVideo
                    ? Container(color: _navyDeep, child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30))
                    : CachedNetworkImage(imageUrl: item['url']?.toString() ?? '', fit: BoxFit.cover, placeholder: (_, __) => Container(color: Colors.grey.shade200), errorWidget: (_, __, ___) => Container(color: Colors.grey.shade200, child: const Icon(Icons.broken_image, color: Colors.grey))),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Bande de miniatures utilisée dans les cartes de rubriques
class _MediaStrip extends StatelessWidget {
  final List<Map<String, dynamic>> media;
  final void Function(int index) onTapItem;
  const _MediaStrip({required this.media, required this.onTapItem});

  @override
  Widget build(BuildContext context) {
    final shown = media.take(4).toList();
    final remaining = media.length - shown.length;
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          for (int i = 0; i < shown.length; i++) ...[
            GestureDetector(
              onTap: () => onTapItem(i),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: shown[i]['type'] == 'video'
                        ? Container(width: 56, height: 56, color: _navyDeep, child: const Icon(Icons.play_arrow_rounded, color: Colors.white))
                        : CachedNetworkImage(
                            imageUrl: shown[i]['url']?.toString() ?? '', width: 56, height: 56, fit: BoxFit.cover,
                            placeholder: (_, __) => Container(width: 56, height: 56, color: Colors.grey.shade200),
                            errorWidget: (_, __, ___) => Container(width: 56, height: 56, color: Colors.grey.shade200, child: const Icon(Icons.broken_image, size: 16, color: Colors.grey)),
                          ),
                  ),
                  if (i == shown.length - 1 && remaining > 0)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.55), borderRadius: BorderRadius.circular(10)),
                        alignment: Alignment.center,
                        child: Text('+$remaining', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// FICHE DÉTAILLÉE GÉNÉRIQUE ("Voir plus")
// ============================================================
class _DetailSection {
  final String label;
  final String content;
  final IconData icon;
  const _DetailSection({required this.label, required this.content, this.icon = Icons.notes});
}

void _showDetailSheet(
  BuildContext context, {
  required IconData icon,
  required Color color,
  required String title,
  String? badge,
  String? headerPhotoUrl,
  List<Widget> chips = const [],
  List<_DetailSection> sections = const [],
  List<Map<String, dynamic>> media = const [],
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.72, minChildSize: 0.4, maxChildSize: 0.95, expand: false,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(width: 42, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  Row(
                    children: [
                      if (headerPhotoUrl != null && headerPhotoUrl.trim().isNotEmpty)
                        Container(
                          width: 60, height: 60,
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 2)),
                          child: ClipOval(child: CachedNetworkImage(imageUrl: headerPhotoUrl, fit: BoxFit.cover)),
                        )
                      else
                        Container(width: 52, height: 52, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color, size: 26)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: _navyDeep)),
                            if (badge != null && badge.trim().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(badge, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (chips.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(spacing: 8, runSpacing: 8, children: chips),
                  ],
                  for (final s in sections) ...[
                    const SizedBox(height: 20),
                    Row(children: [
                      Icon(s.icon, size: 16, color: color),
                      const SizedBox(width: 6),
                      Text(s.label, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: color)),
                    ]),
                    const SizedBox(height: 6),
                    Text(s.content, style: const TextStyle(fontSize: 13.5, height: 1.55, color: _ink)),
                  ],
                  if (media.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('Photos & Vidéos (${media.length})', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: _navyDeep)),
                      TextButton(
                        onPressed: () => _openMediaGrid(context, media, title: title),
                        child: const Text('Voir tout', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
                      itemCount: media.length,
                      itemBuilder: (_, i) {
                        final m = media[i];
                        final isVideo = m['type'] == 'video';
                        return GestureDetector(
                          onTap: () => _openMediaGallery(context, media, initialIndex: i, title: title),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: isVideo
                                ? Container(color: _navyDeep, child: const Icon(Icons.play_arrow_rounded, color: Colors.white))
                                : CachedNetworkImage(imageUrl: m['url']?.toString() ?? '', fit: BoxFit.cover, placeholder: (_, __) => Container(color: Colors.grey.shade200), errorWidget: (_, __, ___) => Container(color: Colors.grey.shade200)),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void _showTextSheet(BuildContext context, {required String title, required String text, required IconData icon, required Color color}) {
  _showDetailSheet(context, icon: icon, color: color, title: title, sections: [_DetailSection(label: title, content: text, icon: icon)]);
}

Widget _metaChip(IconData icon, String text, {Color color = _navy}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 5),
      Text(text, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: color)),
    ]),
  );
}

// ============================================================
// CARTE GÉNÉRIQUE D'ENTITÉ (cliquable — "Voir plus")
// ============================================================
class _EntityCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? badge;
  final List<Widget> metaLines;
  final String? preview;
  final List<Map<String, dynamic>> media;
  final VoidCallback onTap;

  const _EntityCard({
    required this.icon, required this.color, required this.title, this.badge,
    this.metaLines = const [], this.preview, this.media = const [], required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _hairline)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: _navyDeep))),
                      if (badge != null && badge!.isNotEmpty)
                        Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)), child: Text(badge!, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: _muted))),
                    ]),
                    if (metaLines.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(spacing: 6, runSpacing: 6, children: metaLines),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: _muted),
            ]),
            if (preview != null && preview!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(preview!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: _muted, height: 1.4)),
            ],
            if (media.isNotEmpty) ...[
              const SizedBox(height: 10),
              _MediaStrip(media: media, onTapItem: (i) => _openMediaGallery(context, media, initialIndex: i, title: title)),
            ],
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text('Voir plus', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== HEADER ====================
class _ProvinceHeader extends StatelessWidget {
  final Province province;
  const _ProvinceHeader({required this.province});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 260, pinned: true, backgroundColor: _navyDeep,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        title: Text(province.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, shadows: [Shadow(blurRadius: 8, color: Colors.black54)])),
        background: Stack(fit: StackFit.expand, children: [
          GestureDetector(
            onTap: (province.coverImageUrl != null && province.coverImageUrl!.isNotEmpty)
                ? () => _openMediaGallery(context, [{'url': province.coverImageUrl, 'type': 'photo'}], title: province.name)
                : null,
            child: province.coverImageUrl != null && province.coverImageUrl!.isNotEmpty
                ? CachedNetworkImage(imageUrl: province.coverImageUrl!, fit: BoxFit.cover, placeholder: (_, __) => Container(color: Colors.grey.shade800), errorWidget: (_, __, ___) => Container(color: _navyDeep))
                : Container(color: _navyDeep),
          ),
          Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, _navyDeep.withOpacity(0.95)], stops: const [0.3, 1]))),
        ]),
      ),
    );
  }
}

// ==================== IDENTITÉ ====================
class _ProvinceIdentityCard extends StatelessWidget {
  final Province province;
  const _ProvinceIdentityCard({required this.province});

  @override
  Widget build(BuildContext context) {
    final hasWebsite = province.website != null && province.website!.trim().isNotEmpty;
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: _hairline)),
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Row(children: [
          GestureDetector(
            onTap: (province.coatOfArmsUrl != null && province.coatOfArmsUrl!.isNotEmpty)
                ? () => _openMediaGallery(context, [{'url': province.coatOfArmsUrl, 'type': 'photo'}], title: 'Blason — ${province.name}')
                : null,
            child: Container(
              width: 64, height: 64, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _hairline), color: _ivory),
              child: province.coatOfArmsUrl != null && province.coatOfArmsUrl!.isNotEmpty
                  ? ClipOval(child: CachedNetworkImage(imageUrl: province.coatOfArmsUrl!, fit: BoxFit.contain))
                  : const Icon(Icons.shield, color: _navyDeep),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(province.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: _navyDeep)),
                const SizedBox(height: 4),
                Row(children: [
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFD32F2F), borderRadius: BorderRadius.circular(6)), child: Text(province.code, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white))),
                  const SizedBox(width: 8),
                  Text('Région ${province.region}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _navy)),
                ]),
              ],
            ),
          ),
        ]),
        const Divider(height: 24, color: _hairline),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _StatItem(icon: Icons.location_city, label: 'Capitale', value: province.capital),
          _StatItem(icon: Icons.groups, label: 'Population', value: province.population != null ? '${_fmtNumber(province.population!)} hab' : 'N/A'),
          _StatItem(icon: Icons.map, label: 'Superficie', value: province.area != null ? '${_fmtNumber(province.area!)} km²' : 'N/A'),
          if (province.territoriesCount != null)
            _StatItem(icon: Icons.format_list_numbered, label: 'Territoires', value: '${province.territoriesCount}'),
        ]),
        if (hasWebsite) ...[
          const SizedBox(height: 14),
          InkWell(
            onTap: () => _launchUrlSafe(province.website!),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(color: _navy.withOpacity(0.06), borderRadius: BorderRadius.circular(10)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.language, size: 16, color: _navy),
                const SizedBox(width: 8),
                Text(province.website!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _navy)),
              ]),
            ),
          ),
        ],
      ]),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon; final String label, value;
  const _StatItem({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(children: [
        Icon(icon, size: 20, color: _navy), const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: _ink)),
        Text(label, style: const TextStyle(fontSize: 10, color: _muted)),
      ]);
}

// ==================== CARTE GÉOGRAPHIQUE ====================
class _MapCard extends StatelessWidget {
  final String url;
  final String provinceName;
  const _MapCard({required this.url, required this.provinceName});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openMediaGallery(context, [{'url': url, 'type': 'photo'}], title: 'Carte — $provinceName'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(children: [
          CachedNetworkImage(imageUrl: url, height: 190, width: double.infinity, fit: BoxFit.cover, placeholder: (_, __) => Container(height: 190, color: Colors.grey.shade200), errorWidget: (_, __, ___) => Container(height: 190, color: Colors.grey.shade200, child: const Icon(Icons.map_outlined, color: Colors.grey))),
          Positioned(right: 10, bottom: 10, child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.zoom_in, color: Colors.white, size: 18))),
        ]),
      ),
    );
  }
}

// ==================== GALERIE GLOBALE ====================
class _GalleryBanner extends StatelessWidget {
  final List<Map<String, dynamic>> media;
  final PageController controller;
  final void Function(int) onReady;
  final String provinceName;
  const _GalleryBanner({required this.media, required this.controller, required this.onReady, required this.provinceName});

  @override
  Widget build(BuildContext context) {
    final photos = media.where((m) => m['type'] != 'video').toList();
    final display = photos.isNotEmpty ? photos : media;
    if (display.isEmpty) return const SizedBox.shrink();
    WidgetsBinding.instance.addPostFrameCallback((_) => onReady(display.length));

    return Column(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 190,
          child: PageView.builder(
            controller: controller, itemCount: display.length,
            itemBuilder: (_, i) {
              final item = display[i];
              final url = item['url']?.toString() ?? '';
              final isVideo = item['type'] == 'video';
              return GestureDetector(
                onTap: () => _openMediaGallery(context, display, initialIndex: i, title: provinceName),
                child: Stack(fit: StackFit.expand, children: [
                  isVideo
                      ? Container(color: _navyDeep, child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 44))
                      : CachedNetworkImage(imageUrl: url, fit: BoxFit.cover, placeholder: (_, __) => Container(color: Colors.grey.shade200)),
                  Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withOpacity(0.5), Colors.transparent]))),
                ]),
              );
            },
          ),
        ),
      ),
      const SizedBox(height: 10),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          onPressed: () => _openMediaGrid(context, media, title: provinceName),
          icon: const Icon(Icons.grid_view_rounded, size: 16),
          label: Text('Voir toute la galerie (${media.length})', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          style: TextButton.styleFrom(foregroundColor: _navy),
        ),
      ),
    ]);
  }
}

// ==================== CULTURE ====================
class _CultureSection extends StatelessWidget {
  final Province province;
  const _CultureSection({required this.province});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _hairline)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (province.description?.trim().isNotEmpty == true) ...[
          Text(province.description!, style: const TextStyle(fontSize: 13, height: 1.5, color: _ink)),
          const SizedBox(height: 16),
        ],
        if (province.languages?.trim().isNotEmpty == true) ...[
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.forum, size: 18, color: _navy), const SizedBox(width: 8),
            Expanded(child: Text.rich(TextSpan(children: [const TextSpan(text: 'Langues : ', style: TextStyle(fontWeight: FontWeight.bold, color: _navyDeep)), TextSpan(text: province.languages!, style: const TextStyle(color: _muted))], style: const TextStyle(fontSize: 13)))),
          ]),
          const SizedBox(height: 8),
        ],
        if (province.resources?.trim().isNotEmpty == true) ...[
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.diamond, size: 18, color: _gold), const SizedBox(width: 8),
            Expanded(child: Text.rich(TextSpan(children: [const TextSpan(text: 'Ressources : ', style: TextStyle(fontWeight: FontWeight.bold, color: _navyDeep)), TextSpan(text: province.resources!, style: const TextStyle(color: _muted))], style: const TextStyle(fontSize: 13)))),
          ]),
        ],
      ]),
    );
  }
}

// ==================== MONOGRAPHIE ====================
class _MonographySection extends StatelessWidget {
  final Province province;
  const _MonographySection({required this.province});

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    if (province.history?.trim().isNotEmpty == true) items.add(_buildCard(context, 'Historique & Origines', province.history!, Icons.history_edu, _navy));
    if (province.climate?.trim().isNotEmpty == true) items.add(_buildCard(context, 'Climat & Environnement', province.climate!, Icons.wb_sunny, _gold));
    if (province.infrastructure?.trim().isNotEmpty == true) items.add(_buildCard(context, 'Infrastructures & Énergie', province.infrastructure!, Icons.bolt, const Color(0xFF2E7D32)));
    if (province.education?.trim().isNotEmpty == true) items.add(_buildCard(context, 'Éducation & Santé', province.education!, Icons.school, const Color(0xFF6A1B9A)));

    return Column(children: items.map((w) => Padding(padding: const EdgeInsets.only(bottom: 12), child: w)).toList());
  }

  Widget _buildCard(BuildContext context, String title, String content, IconData icon, Color color) {
    final isLong = content.length > 220;
    return InkWell(
      onTap: isLong ? () => _showTextSheet(context, title: title, text: content, icon: icon, color: color) : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _hairline)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 20)),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: _navyDeep))),
          ]),
          const SizedBox(height: 10),
          Text(content, maxLines: isLong ? 4 : null, overflow: isLong ? TextOverflow.ellipsis : TextOverflow.visible, style: const TextStyle(fontSize: 13, height: 1.5, color: _ink)),
          if (isLong) ...[
            const SizedBox(height: 8),
            Text('Lire la suite', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: color)),
          ],
        ]),
      ),
    );
  }
}

// ==================== EXÉCUTIF ====================
class _ExecutiveSection extends StatelessWidget {
  final Province province;
  const _ExecutiveSection({required this.province});

  @override
  Widget build(BuildContext context) {
    final items = <Map<String, String?>>[];
    if (province.governor != null && province.governor!.isNotEmpty) items.add({'role': 'Gouverneur', 'name': province.governor, 'photo': province.governorPhotoUrl});
    if (province.viceGovernor != null && province.viceGovernor!.isNotEmpty) items.add({'role': 'Vice-Gouverneur', 'name': province.viceGovernor, 'photo': province.viceGovernorPhotoUrl});

    if (items.isEmpty) return const SizedBox.shrink();

    return GridView.builder(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.85),
      itemCount: items.length,
      itemBuilder: (_, i) => _ExecutiveCard(role: items[i]['role']!, name: items[i]['name']!, photoUrl: items[i]['photo']),
    );
  }
}

class _ExecutiveCard extends StatelessWidget {
  final String role, name; final String? photoUrl;
  const _ExecutiveCard({required this.role, required this.name, this.photoUrl});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.trim().isNotEmpty;
    final isGov = role.toLowerCase().contains('gouverneur') && !role.toLowerCase().contains('vice');
    final color = isGov ? _gold : _navy;
    return InkWell(
      onTap: () => _showDetailSheet(context, icon: Icons.person, color: color, title: name, badge: role, headerPhotoUrl: photoUrl, media: hasPhoto ? [{'url': photoUrl, 'type': 'photo'}] : []),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: _hairline), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))]),
        padding: const EdgeInsets.all(14),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(3), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 2.5)),
            child: CircleAvatar(radius: 38, backgroundColor: _ivory, backgroundImage: hasPhoto ? CachedNetworkImageProvider(photoUrl!) : null, child: !hasPhoto ? const Icon(Icons.person, size: 36, color: _muted) : null),
          ),
          const SizedBox(height: 12),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)), child: Text(role.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: isGov ? const Color(0xFF8A6B00) : _navy))),
          const SizedBox(height: 6),
          Text(name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: _ink)),
        ]),
      ),
    );
  }
}

// ==================== MINISTRES ====================
class _MinistersSection extends StatelessWidget {
  final List<dynamic> ministers;
  const _MinistersSection({required this.ministers});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.78),
      itemCount: ministers.length,
      itemBuilder: (_, i) {
        final m = ministers[i] as Map;
        final name = m['name']?.toString() ?? '—';
        final role = m['role']?.toString() ?? 'Ministre';
        final photo = m['photoUrl']?.toString() ?? m['photo_url']?.toString();
        final hasPhoto = photo != null && photo.trim().isNotEmpty;
        return InkWell(
          onTap: () => _showDetailSheet(context, icon: Icons.person, color: _navy, title: name, badge: role, headerPhotoUrl: photo, media: hasPhoto ? [{'url': photo, 'type': 'photo'}] : []),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _hairline)),
            padding: const EdgeInsets.all(10),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              CircleAvatar(radius: 28, backgroundColor: _ivory, backgroundImage: hasPhoto ? CachedNetworkImageProvider(photo) : null, child: !hasPhoto ? const Icon(Icons.person, size: 22, color: _muted) : null),
              const SizedBox(height: 8),
              Text(role, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9, color: _muted, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: _ink)),
            ]),
          ),
        );
      },
    );
  }
}

// ==================== ÉCONOMIE ====================
class _EconomySection extends StatelessWidget {
  final List<dynamic> resources;
  const _EconomySection({required this.resources});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: resources.map((e) {
        final dyn = e as dynamic;
        final name = dyn.name?.toString() ?? 'Secteur';
        final desc = dyn.description?.toString() ?? '';
        List<Map<String, dynamic>> media = [];
        try {
          if (dyn.media != null) media = List<Map<String, dynamic>>.from(dyn.media);
        } catch (_) {}
        if (media.isEmpty) {
          try {
            if (dyn.imageUrl != null && dyn.imageUrl.toString().isNotEmpty) media = [{'url': dyn.imageUrl, 'type': 'photo'}];
          } catch (_) {}
        }
        return _EntityCard(
          icon: Icons.monetization_on, color: const Color(0xFF2E7D32), title: name, preview: desc, media: media,
          onTap: () => _showDetailSheet(context, icon: Icons.monetization_on, color: const Color(0xFF2E7D32), title: name,
              sections: desc.isNotEmpty ? [_DetailSection(label: 'Description', content: desc, icon: Icons.notes)] : [], media: media),
        );
      }).toList(),
    );
  }
}

// ==================== TOURISME ====================
class _TourismSection extends StatelessWidget {
  final List<dynamic> sites;
  const _TourismSection({required this.sites});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: sites.map((s) {
        final dyn = s as dynamic;
        final name = dyn.name?.toString() ?? 'Site';
        final type = dyn.type?.toString() ?? 'Lieu';
        final desc = dyn.description?.toString() ?? '';
        List<Map<String, dynamic>> media = [];
        try {
          if (dyn.media != null) media = List<Map<String, dynamic>>.from(dyn.media);
        } catch (_) {}
        if (media.isEmpty) {
          try {
            if (dyn.imageUrl != null && dyn.imageUrl.toString().isNotEmpty) media = [{'url': dyn.imageUrl, 'type': 'photo'}];
          } catch (_) {}
        }
        return _EntityCard(
          icon: Icons.landscape, color: const Color(0xFF1565C0), title: name, badge: type.isNotEmpty ? type : null, preview: desc, media: media,
          onTap: () => _showDetailSheet(context, icon: Icons.landscape, color: const Color(0xFF1565C0), title: name, badge: type,
              sections: desc.isNotEmpty ? [_DetailSection(label: 'Description', content: desc, icon: Icons.notes)] : [], media: media),
        );
      }).toList(),
    );
  }
}

// ==================== TRIBUS ====================
class _TribesSection extends StatelessWidget {
  final List<Map<String, dynamic>> tribes;
  const _TribesSection({required this.tribes});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: tribes.map((t) {
        final name = t['name']?.toString() ?? 'Tribu';
        final zone = t['zone']?.toString() ?? '';
        final history = t['history']?.toString() ?? '';
        final media = t['media'] != null ? List<Map<String, dynamic>>.from(t['media']) : <Map<String, dynamic>>[];
        return _EntityCard(
          icon: Icons.groups, color: _navy, title: name,
          metaLines: zone.isNotEmpty ? [_metaChip(Icons.place, zone)] : [],
          preview: history, media: media,
          onTap: () => _showDetailSheet(context, icon: Icons.groups, color: _navy, title: name,
              chips: zone.isNotEmpty ? [_metaChip(Icons.place, zone)] : [],
              sections: history.isNotEmpty ? [_DetailSection(label: 'Histoire, origines & coutumes', content: history, icon: Icons.menu_book)] : [],
              media: media),
        );
      }).toList(),
    );
  }
}

// ==================== DÉCOUPAGE ADMINISTRATIF ====================
class _AdministrativeSection extends StatelessWidget {
  final List<dynamic> divisions;
  const _AdministrativeSection({required this.divisions});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: divisions.map((d) {
        final dyn = d as dynamic;
        final name = dyn.name?.toString() ?? 'Division';
        final type = dyn.type?.toString() ?? 'Territoire';
        final capital = dyn.capital?.toString() ?? '';
        final pop = dyn.population?.toString() ?? '';
        final area = dyn.area?.toString() ?? '';
        String administrator = '';
        try { administrator = dyn.administrator?.toString() ?? ''; } catch (_) {}
        List<Map<String, dynamic>> media = [];
        try {
          if (dyn.media != null) media = List<Map<String, dynamic>>.from(dyn.media);
        } catch (_) {}

        final meta = <Widget>[];
        if (capital.isNotEmpty) meta.add(_metaChip(Icons.star, 'Chef-lieu : $capital'));
        if (pop.isNotEmpty) meta.add(_metaChip(Icons.groups, '$pop hab'));
        if (area.isNotEmpty) meta.add(_metaChip(Icons.map, '$area km²'));
        if (administrator.isNotEmpty) meta.add(_metaChip(Icons.person, administrator));

        return _EntityCard(
          icon: Icons.dashboard_customize, color: const Color(0xFF6A1B9A), title: name, badge: type, metaLines: meta, media: media,
          onTap: () => _showDetailSheet(
            context, icon: Icons.dashboard_customize, color: const Color(0xFF6A1B9A), title: name, badge: type,
            chips: meta,
            sections: administrator.isNotEmpty ? [_DetailSection(label: 'Administrateur', content: administrator, icon: Icons.person)] : [],
            media: media,
          ),
        );
      }).toList(),
    );
  }
}

// ==================== VILLES ====================
class _CitiesSection extends StatelessWidget {
  final List<City> cities;
  const _CitiesSection({required this.cities});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: cities.map((c) {
        List<Map<String, dynamic>> media = [];
        try {
          final dynC = c as dynamic;
          if (dynC.media != null) media = List<Map<String, dynamic>>.from(dynC.media);
          if (media.isEmpty && dynC.imageUrl != null && dynC.imageUrl.toString().isNotEmpty) {
            media = [{'url': dynC.imageUrl, 'type': 'photo'}];
          }
        } catch (_) {}
        final mayor = c.mayor ?? '';
        final mayorPhoto = c.mayorPhotoUrl;

        final meta = <Widget>[
          if (c.population != null) _metaChip(Icons.groups, '${c.population} hab'),
          if (c.isCapital) _metaChip(Icons.star, 'Chef-lieu', color: _gold == _gold ? const Color(0xFF8A6B00) : _gold),
          if (mayor.isNotEmpty) _metaChip(Icons.person, mayor),
        ];

        return _EntityCard(
          icon: c.isCapital ? Icons.star_rounded : Icons.location_city_rounded,
          color: c.isCapital ? const Color(0xFF8A6B00) : _navy,
          title: c.name, metaLines: meta, media: media,
          onTap: () => _showDetailSheet(
            context,
            icon: c.isCapital ? Icons.star_rounded : Icons.location_city_rounded,
            color: c.isCapital ? const Color(0xFF8A6B00) : _navy,
            title: c.name, badge: c.isCapital ? 'Chef-lieu de province' : null,
            headerPhotoUrl: mayorPhoto,
            chips: meta,
            sections: mayor.isNotEmpty ? [_DetailSection(label: 'Autorité (Maire / Bourgmestre)', content: mayor, icon: Icons.person)] : [],
            media: media,
          ),
        );
      }).toList(),
    );
  }
}

// ==================== RÉALISATIONS ====================
class _AchievementsSection extends StatelessWidget {
  final List<Map<String, dynamic>> achievements;
  const _AchievementsSection({required this.achievements});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: achievements.map((a) {
        final title = a['title']?.toString() ?? 'Réalisation';
        final desc = a['description']?.toString() ?? '';
        final date = a['date']?.toString() ?? '';
        final location = a['location']?.toString() ?? '';
        final media = a['media'] != null ? List<Map<String, dynamic>>.from(a['media']) : <Map<String, dynamic>>[];

        final meta = <Widget>[
          if (date.isNotEmpty) _metaChip(Icons.calendar_today, date),
          if (location.isNotEmpty) _metaChip(Icons.location_on, location),
        ];

        return _EntityCard(
          icon: Icons.verified, color: _navy, title: title, metaLines: meta, preview: desc, media: media,
          onTap: () => _showDetailSheet(
            context, icon: Icons.verified, color: _navy, title: title,
            chips: meta,
            sections: desc.isNotEmpty ? [_DetailSection(label: 'Description', content: desc, icon: Icons.notes)] : [],
            media: media,
          ),
        );
      }).toList(),
    );
  }
}

// ==================== URGENCES ====================
class _EmergencySection extends StatelessWidget {
  final List<dynamic> contacts;
  const _EmergencySection({required this.contacts});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: contacts.map((c) {
        final dyn = c as dynamic;
        final service = dyn.service?.toString() ?? dyn.serviceName?.toString() ?? 'Service';
        final phone = dyn.phone?.toString() ?? dyn.phoneNumber?.toString() ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFD32F2F).withOpacity(0.3))),
          child: ListTile(
            leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFD32F2F).withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.phone_in_talk, color: Color(0xFFD32F2F))),
            title: Text(service, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(phone, style: const TextStyle(fontWeight: FontWeight.w600, color: _ink)),
            trailing: phone.isNotEmpty ? IconButton(icon: const Icon(Icons.call, color: Colors.green), onPressed: () => launchUrl(Uri.parse('tel:$phone'))) : null,
          ),
        );
      }).toList(),
    );
  }
}

// ==================== DIVERS ====================
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: _navyDeep));
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red), const SizedBox(height: 12),
        const Text('Impossible de charger'), const SizedBox(height: 12),
        ElevatedButton(onPressed: onRetry, style: ElevatedButton.styleFrom(backgroundColor: _navy), child: const Text('Réessayer', style: TextStyle(color: Colors.white))),
      ]));
}
