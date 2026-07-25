// ============================================================
// FICHIER - province_detail_page.dart (ULTIMATE & RESTRUCTURED)
// Design type "Wikipédia Moderne" - Sections complètes & claires
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/provinces_provider.dart';
import '../../models/province.dart';
import '../../models/city.dart';

class ProvinceDetailPage extends ConsumerStatefulWidget {
  final String provinceId;
  const ProvinceDetailPage({required this.provinceId, super.key});

  @override
  ConsumerState<ProvinceDetailPage> createState() => _ProvinceDetailPageState();
}

class _ProvinceDetailPageState extends ConsumerState<ProvinceDetailPage> {
  static const Color navyDeep = Color(0xFF0A1F44);
  static const Color navy = Color(0xFF123B7A);
  static const Color gold = Color(0xFFE3B23C);
  static const Color ivory = Color(0xFFF6F7FB);
  static const Color hairline = Color(0xFFE7EAF3);

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
      backgroundColor: ivory,
      body: provinceAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: navy)),
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
                
                // 2. GALERIE GLOBALE (Auto-défilante & Interactive)
                if (province.galleryMedia != null && province.galleryMedia!.isNotEmpty) ...[
                  _GalleryBanner(media: province.galleryMedia!, controller: _bannerCtrl, onReady: _startBanner),
                  const SizedBox(height: 24),
                ],

                // 3. CULTURE, LANGUES & GÉNÉRALITÉS
                if (_hasCultureData(province)) ...[
                  const _SectionTitle('Culture, Langues & Généralités'),
                  const SizedBox(height: 12),
                  _CultureSection(province: province),
                  const SizedBox(height: 24),
                ],

                // 4. MONOGRAPHIE & APERÇU GLOBAL
                if (_hasInstitutionalData(province)) ...[
                  const _SectionTitle('Monographie Institutionnelle'),
                  const SizedBox(height: 12),
                  _MonographySection(province: province),
                  const SizedBox(height: 24),
                ],

                // 5. GOUVERNANCE & EXÉCUTIF
                const _SectionTitle('Gouvernance & Exécutif'),
                const SizedBox(height: 12),
                _ExecutiveSection(province: province),
                if (province.ministers != null && province.ministers!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _MinistersSection(ministers: province.ministers!),
                ],
                const SizedBox(height: 24),

                // 6. ÉCONOMIE & SECTEURS CLÉS
                if (province.economicResources.isNotEmpty) ...[
                  const _SectionTitle('Économie & Secteurs Clés'),
                  const SizedBox(height: 12),
                  _EconomySection(resources: province.economicResources),
                  const SizedBox(height: 24),
                ],

                // 7. TOURISME & SITES REMARQUABLES
                if (province.tourismSites.isNotEmpty) ...[
                  const _SectionTitle('Tourisme & Sites Remarquables'),
                  const SizedBox(height: 12),
                  _TourismSection(sites: province.tourismSites),
                  const SizedBox(height: 24),
                ],

                // 8. PEUPLES & TRIBUS AUTOCHTONES
                if (province.tribes != null && province.tribes!.isNotEmpty) ...[
                  const _SectionTitle('Peuples & Tribus Autochtones'),
                  const SizedBox(height: 12),
                  _TribesSection(tribes: province.tribes!),
                  const SizedBox(height: 24),
                ],

                // 9. DÉCOUPAGE ADMINISTRATIF
                if (province.administrativeDivisions.isNotEmpty) ...[
                  const _SectionTitle('Découpage Administratif'),
                  const SizedBox(height: 12),
                  _AdministrativeSection(divisions: province.administrativeDivisions),
                  const SizedBox(height: 24),
                ],

                // 10. VILLES PRINCIPALES
                if (province.cities.isNotEmpty) ...[
                  const _SectionTitle('Villes Principales'),
                  const SizedBox(height: 12),
                  _CitiesSection(cities: province.cities),
                  const SizedBox(height: 24),
                ],

                // 11. RÉALISATIONS & PROJETS MAJEURS
                if (province.achievements != null && province.achievements!.isNotEmpty) ...[
                  const _SectionTitle('Réalisations & Projets Majeurs'),
                  const SizedBox(height: 12),
                  _AchievementsSection(achievements: province.achievements!),
                  const SizedBox(height: 24),
                ],

                // 12. URGENCES & CONTACTS UTILES
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

// ==================== VISUALISEUR D'IMAGE PLEIN ÉCRAN ====================
void _openImageFullScreen(BuildContext context, String imageUrl) {
  showDialog(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: Colors.black.withOpacity(0.95),
      insetPadding: EdgeInsets.zero,
      child: Stack(
        fit: StackFit.expand,
        children: [
          InteractiveViewer(
            panEnabled: true, minScale: 1.0, maxScale: 4.0,
            child: CachedNetworkImage(
              imageUrl: imageUrl, fit: BoxFit.contain,
              placeholder: (_, __) => const Center(child: CircularProgressIndicator(color: Colors.white)),
              errorWidget: (_, __, ___) => const Center(child: Icon(Icons.error, color: Colors.white, size: 50)),
            ),
          ),
          Positioned(
            top: 40, right: 20,
            child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => Navigator.of(context).pop()),
          ),
        ],
      ),
    ),
  );
}

// ==================== WIDGETS DE SECTIONS ====================

class _ProvinceHeader extends StatelessWidget {
  final Province province;
  const _ProvinceHeader({required this.province});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 260, pinned: true, backgroundColor: const Color(0xFF0A1F44),
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        title: Text(province.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, shadows: [Shadow(blurRadius: 8, color: Colors.black54)])),
        background: Stack(fit: StackFit.expand, children: [
          province.coverImageUrl != null && province.coverImageUrl!.isNotEmpty
              ? CachedNetworkImage(imageUrl: province.coverImageUrl!, fit: BoxFit.cover, placeholder: (_, __) => Container(color: Colors.grey.shade800), errorWidget: (_, __, ___) => Container(color: const Color(0xFF0A1F44)))
              : Container(color: const Color(0xFF0A1F44)),
          Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, const Color(0xFF0A1F44).withOpacity(0.95)], stops: const [0.3, 1]))),
        ]),
      ),
    );
  }
}

class _ProvinceIdentityCard extends StatelessWidget {
  final Province province;
  const _ProvinceIdentityCard({required this.province});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE7EAF3))),
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Row(children: [
          Container(
            width: 64, height: 64, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFE7EAF3)), color: const Color(0xFFF6F7FB)),
            child: province.coatOfArmsUrl != null ? ClipOval(child: CachedNetworkImage(imageUrl: province.coatOfArmsUrl!, fit: BoxFit.contain)) : const Icon(Icons.shield, color: Color(0xFF0A1F44)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(province.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0A1F44))),
                const SizedBox(height: 4),
                Row(children: [
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFD32F2F), borderRadius: BorderRadius.circular(6)), child: Text(province.code, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white))),
                  const SizedBox(width: 8),
                  Text('Région ${province.region}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF123B7A))),
                ]),
              ],
            ),
          ),
        ]),
        const Divider(height: 24, color: Color(0xFFE7EAF3)),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _StatItem(icon: Icons.location_city, label: 'Capitale', value: province.capital),
          _StatItem(icon: Icons.groups, label: 'Population', value: province.population != null ? '${_fmt(province.population!)} hab' : 'N/A'),
          _StatItem(icon: Icons.map, label: 'Superficie', value: province.area != null ? '${_fmt(province.area!)} km²' : 'N/A'),
        ]),
      ]),
    );
  }
  String _fmt(int n) => n.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');
}

class _StatItem extends StatelessWidget {
  final IconData icon; final String label, value;
  const _StatItem({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(children: [Icon(icon, size: 20, color: const Color(0xFF123B7A)), const SizedBox(height: 4), Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF10182B))), Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF6B7690)))]);
}

class _GalleryBanner extends StatelessWidget {
  final List<Map<String, dynamic>> media;
  final PageController controller;
  final void Function(int) onReady;
  const _GalleryBanner({required this.media, required this.controller, required this.onReady});

  @override
  Widget build(BuildContext context) {
    final photos = media.where((m) => m['type'] == 'photo').toList();
    if (photos.isEmpty) return const SizedBox.shrink();
    WidgetsBinding.instance.addPostFrameCallback((_) => onReady(photos.length));

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 180,
        child: PageView.builder(
          controller: controller, itemCount: photos.length,
          itemBuilder: (_, i) {
            final url = photos[i]['url']?.toString() ?? '';
            return GestureDetector(
              onTap: () => _openImageFullScreen(context, url),
              child: Stack(fit: StackFit.expand, children: [
                CachedNetworkImage(imageUrl: url, fit: BoxFit.cover, placeholder: (_, __) => Container(color: Colors.grey.shade200)),
                Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withOpacity(0.5), Colors.transparent]))),
              ]),
            );
          },
        ),
      ),
    );
  }
}

class _CultureSection extends StatelessWidget {
  final Province province;
  const _CultureSection({required this.province});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE7EAF3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (province.description?.trim().isNotEmpty == true) ...[
          Text(province.description!, style: const TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF10182B))),
          const SizedBox(height: 16),
        ],
        if (province.languages?.trim().isNotEmpty == true) ...[
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.forum, size: 18, color: Color(0xFF123B7A)), const SizedBox(width: 8),
            Expanded(child: Text.rich(TextSpan(children: [const TextSpan(text: 'Langues : ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0A1F44))), TextSpan(text: province.languages!, style: const TextStyle(color: Color(0xFF6B7690)))], style: const TextStyle(fontSize: 13)))),
          ]),
          const SizedBox(height: 8),
        ],
        if (province.resources?.trim().isNotEmpty == true) ...[
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.diamond, size: 18, color: Color(0xFFE3B23C)), const SizedBox(width: 8),
            Expanded(child: Text.rich(TextSpan(children: [const TextSpan(text: 'Ressources : ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0A1F44))), TextSpan(text: province.resources!, style: const TextStyle(color: Color(0xFF6B7690)))], style: const TextStyle(fontSize: 13)))),
          ]),
        ],
      ]),
    );
  }
}

class _MonographySection extends StatelessWidget {
  final Province province;
  const _MonographySection({required this.province});

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    if (province.history?.trim().isNotEmpty == true) items.add(_buildCard('Historique & Origines', province.history!, Icons.history_edu, const Color(0xFF123B7A)));
    if (province.climate?.trim().isNotEmpty == true) items.add(_buildCard('Climat & Environnement', province.climate!, Icons.wb_sunny, const Color(0xFFE3B23C)));
    if (province.infrastructure?.trim().isNotEmpty == true) items.add(_buildCard('Infrastructures & Énergie', province.infrastructure!, Icons.bolt, const Color(0xFF2E7D32)));
    if (province.education?.trim().isNotEmpty == true) items.add(_buildCard('Éducation & Santé', province.education!, Icons.school, const Color(0xFF6A1B9A)));

    return Column(children: items.map((w) => Padding(padding: const EdgeInsets.only(bottom: 12), child: w)).toList());
  }

  Widget _buildCard(String title, String content, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE7EAF3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0A1F44))),
        ]),
        const SizedBox(height: 10),
        Text(content, style: const TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF10182B))),
      ]),
    );
  }
}

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
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE7EAF3)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))]),
      padding: const EdgeInsets.all(14),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(3), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isGov ? const Color(0xFFE3B23C) : const Color(0xFF123B7A), width: 2.5)),
          child: CircleAvatar(radius: 38, backgroundColor: const Color(0xFFF6F7FB), backgroundImage: hasPhoto ? CachedNetworkImageProvider(photoUrl!) : null, child: !hasPhoto ? const Icon(Icons.person, size: 36, color: Color(0xFF6B7690)) : null),
        ),
        const SizedBox(height: 12),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: (isGov ? const Color(0xFFE3B23C) : const Color(0xFF123B7A)).withOpacity(0.12), borderRadius: BorderRadius.circular(6)), child: Text(role.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: isGov ? const Color(0xFF8A6B00) : const Color(0xFF123B7A)))),
        const SizedBox(height: 6),
        Text(name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF10182B))),
      ]),
    );
  }
}

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
        return Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE7EAF3))),
          padding: const EdgeInsets.all(10),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            CircleAvatar(radius: 28, backgroundColor: const Color(0xFFF6F7FB), backgroundImage: hasPhoto ? CachedNetworkImageProvider(photo) : null, child: !hasPhoto ? const Icon(Icons.person, size: 22, color: Color(0xFF6B7690)) : null),
            const SizedBox(height: 8),
            Text(role, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9, color: Color(0xFF6B7690), fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF10182B))),
          ]),
        );
      },
    );
  }
}

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
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE7EAF3))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF2E7D32).withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.monetization_on, color: Color(0xFF2E7D32), size: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0A1F44))),
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(desc, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7690), height: 1.4)),
                ]
              ]),
            ),
          ]),
        );
      }).toList(),
    );
  }
}

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
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE7EAF3))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF1565C0).withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.landscape, color: Color(0xFF1565C0), size: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0A1F44)))),
                  if (type.isNotEmpty) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)), child: Text(type, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF6B7690)))),
                ]),
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(desc, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7690), height: 1.4)),
                ]
              ]),
            ),
          ]),
        );
      }).toList(),
    );
  }
}

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
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE7EAF3))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF123B7A).withOpacity(0.08), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.groups, color: Color(0xFF123B7A), size: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0A1F44))),
                  if (zone.isNotEmpty) Text(zone, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7690), fontWeight: FontWeight.w600)),
                ])
              ),
            ]),
            if (history.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(history, style: const TextStyle(fontSize: 13, color: Color(0xFF10182B), height: 1.4)),
            ],
          ]),
        );
      }).toList(),
    );
  }
}

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

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE7EAF3))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF6A1B9A).withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.dashboard_customize, color: Color(0xFF6A1B9A), size: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0A1F44)))),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)), child: Text(type, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF6B7690)))),
                  ]),
                  if (capital.isNotEmpty) Text('Chef-lieu : $capital', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7690))),
                ])
              ),
            ]),
            if (pop.isNotEmpty || area.isNotEmpty) ...[
              const Divider(height: 20),
              Row(children: [
                if (pop.isNotEmpty) Expanded(child: Row(children: [const Icon(Icons.groups, size: 14, color: Colors.grey), const SizedBox(width: 4), Text('$pop hab', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))])),
                if (area.isNotEmpty) Expanded(child: Row(children: [const Icon(Icons.map, size: 14, color: Colors.grey), const SizedBox(width: 4), Text('$area km²', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))])),
              ]),
            ],
          ]),
        );
      }).toList(),
    );
  }
}

class _CitiesSection extends StatelessWidget {
  final List<City> cities;
  const _CitiesSection({required this.cities});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.6),
      itemCount: cities.length,
      itemBuilder: (_, i) {
        final c = cities[i];
        return Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE7EAF3))),
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: c.isCapital ? const Color(0xFFE3B23C).withOpacity(0.15) : const Color(0xFF123B7A).withOpacity(0.08), borderRadius: BorderRadius.circular(10)), child: Icon(c.isCapital ? Icons.star_rounded : Icons.location_city_rounded, color: c.isCapital ? const Color(0xFF8A6B00) : const Color(0xFF123B7A))),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
              if (c.population != null) Text('${c.population} hab', style: const TextStyle(fontSize: 10, color: Color(0xFF6B7690))),
              if (c.isCapital) Container(margin: const EdgeInsets.only(top: 4), padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFE3B23C).withOpacity(0.2), borderRadius: BorderRadius.circular(4)), child: const Text('Chef-lieu', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold))),
            ])),
          ]),
        );
      },
    );
  }
}

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
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE7EAF3))),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xFF123B7A).withOpacity(0.08), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.verified, color: Color(0xFF123B7A), size: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0A1F44))),
                    if (desc.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7690))),
                    ]
                  ],
                ),
              ),
              if (date.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(date, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7690), fontWeight: FontWeight.w600)),
              ]
            ],
          ),
        );
      }).toList(),
    );
  }
}

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
            subtitle: Text(phone, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF10182B))),
            trailing: phone.isNotEmpty ? IconButton(icon: const Icon(Icons.call, color: Colors.green), onPressed: () => launchUrl(Uri.parse('tel:$phone'))) : null,
          ),
        );
      }).toList(),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0A1F44)));
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red), const SizedBox(height: 12), const Text('Impossible de charger'), const SizedBox(height: 12), ElevatedButton(onPressed: onRetry, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF123B7A)), child: const Text('Réessayer', style: TextStyle(color: Colors.white)))]));
}
