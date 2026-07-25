// ============================================================
// FICHIER - province_detail_page.dart (ULTIMATE & SELF-CONTAINED)
// Basé exclusivement sur le modèle Province unifié et enrichi
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/provinces_provider.dart';
import '../../models/province.dart';
import '../../models/city.dart';
import '../../models/province_tourism.dart';
import '../../models/province_emergency.dart';
import '../../models/province_administrative.dart';

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
  static const Color redThix = Color(0xFFD32F2F);

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
                _ProvinceIdentityCard(province: province),
                const SizedBox(height: 16),
                
                // 1. Galerie Multimédia Globale (Auto-défilante)
                if (province.galleryMedia != null && province.galleryMedia!.isNotEmpty) ...[
                  _GalleryBanner(media: province.galleryMedia!, controller: _bannerCtrl, onReady: _startBanner),
                  const SizedBox(height: 20),
                ],

                // 2. Description Générale
                if (province.description != null && province.description!.trim().isNotEmpty) ...[
                  const _SectionTitle('À propos de la province'),
                  const SizedBox(height: 8),
                  _ContentCard(content: province.description!),
                  const SizedBox(height: 20),
                ],

                // 3. Monographie & Aperçu Global (Histoire, Climat, Infrastructures, Éducation)
                if (_hasInstitutionalData(province)) ...[
                  const _SectionTitle('Monographie Institutionnelle'),
                  const SizedBox(height: 12),
                  _MonographySection(province: province),
                  const SizedBox(height: 20),
                ],

                // 4. Exécutif Provincial (Gouverneur & Vice-Gouverneur)
                const _SectionTitle('Exécutif Provincial'),
                const SizedBox(height: 12),
                _ExecutiveSection(province: province),
                const SizedBox(height: 20),

                // 5. Gouvernement (Ministres)
                if (province.ministers != null && province.ministers!.isNotEmpty) ...[
                  const _SectionTitle('Gouvernement Provincial (Ministres)'),
                  const SizedBox(height: 12),
                  _MinistersSection(ministers: province.ministers!),
                  const SizedBox(height: 20),
                ],

                // 6. Peuples & Tribus Autochtones
                if (province.tribes != null && province.tribes!.isNotEmpty) ...[
                  const _SectionTitle('Peuples & Tribus Autochtones'),
                  const SizedBox(height: 12),
                  _TribesSection(tribes: province.tribes!),
                  const SizedBox(height: 20),
                ],

                // 7. Réalisations & Projets Majeurs
                if (province.achievements != null && province.achievements!.isNotEmpty) ...[
                  const _SectionTitle('Réalisations & Projets Majeurs'),
                  const SizedBox(height: 12),
                  _AchievementsSection(achievements: province.achievements!),
                  const SizedBox(height: 20),
                ],

                // 8. Villes Principales
                if (province.cities.isNotEmpty) ...[
                  const _SectionTitle('Villes Principales'),
                  const SizedBox(height: 12),
                  _CitiesSection(cities: province.cities),
                  const SizedBox(height: 20),
                ],

                // 9. Grille d'Exploration Interactive (Culture, Économie, Tourisme, Urgences, Admin)
                const _SectionTitle('Explorer la province'),
                const SizedBox(height: 12),
                _ExploreGridSection(province: province),
                const SizedBox(height: 40),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasInstitutionalData(Province p) {
    return (p.history?.trim().isNotEmpty == true) ||
           (p.climate?.trim().isNotEmpty == true) ||
           (p.infrastructure?.trim().isNotEmpty == true) ||
           (p.education?.trim().isNotEmpty == true);
  }
}

// ==================== 1. HEADER & IDENTITY ====================
class _ProvinceHeader extends StatelessWidget {
  final Province province;
  const _ProvinceHeader({required this.province});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: const Color(0xFF0A1F44),
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        title: Text(
          province.name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, shadows: [Shadow(blurRadius: 8, color: Colors.black54)]),
        ),
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
            width: 64, height: 64,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFE7EAF3)), color: const Color(0xFFF6F7FB)),
            child: province.coatOfArmsUrl != null
                ? ClipOval(child: CachedNetworkImage(imageUrl: province.coatOfArmsUrl!, fit: BoxFit.contain))
                : const Icon(Icons.shield, color: Color(0xFF0A1F44)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(province.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0A1F44))),
                const SizedBox(height: 4),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFD32F2F), borderRadius: BorderRadius.circular(6)),
                    child: Text(province.code, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
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
  final IconData icon;
  final String label, value;
  const _StatItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(children: [
    Icon(icon, size: 20, color: const Color(0xFF123B7A)),
    const SizedBox(height: 4),
    Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF10182B))),
    Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF6B7690))),
  ]);
}

// ==================== 2. GALLERY BANNER ====================
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
          controller: controller,
          itemCount: photos.length,
          itemBuilder: (_, i) {
            final url = photos[i]['url']?.toString() ?? '';
            return Stack(fit: StackFit.expand, children: [
              CachedNetworkImage(imageUrl: url, fit: BoxFit.cover, placeholder: (_, __) => Container(color: Colors.grey.shade200), errorWidget: (_, __, ___) => Container(color: Colors.grey.shade300)),
              Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withOpacity(0.7), Colors.transparent]))),
            ]);
          },
        ),
      ),
    );
  }
}

// ==================== 3. MONOGRAPHY SECTION ====================
class _MonographySection extends StatelessWidget {
  final Province province;
  const _MonographySection({required this.province});

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    if (province.history?.trim().isNotEmpty == true) {
      items.add(_buildCard('Historique & Origines', province.history!, Icons.history_edu, const Color(0xFF123B7A)));
    }
    if (province.climate?.trim().isNotEmpty == true) {
      items.add(_buildCard('Climat & Environnement', province.climate!, Icons.wb_sunny, const Color(0xFFE3B23C)));
    }
    if (province.infrastructure?.trim().isNotEmpty == true) {
      items.add(_buildCard('Infrastructures & Énergie', province.infrastructure!, Icons.bolt, const Color(0xFF2E7D32)));
    }
    if (province.education?.trim().isNotEmpty == true) {
      items.add(_buildCard('Éducation & Santé', province.education!, Icons.school, const Color(0xFF6A1B9A)));
    }

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

// ==================== 4. EXECUTIVE SECTION ====================
class _ExecutiveSection extends StatelessWidget {
  final Province province;
  const _ExecutiveSection({required this.province});

  @override
  Widget build(BuildContext context) {
    final items = <Map<String, String?>>[];
    if (province.governor != null && province.governor!.isNotEmpty) {
      items.add({'role': 'Gouverneur', 'name': province.governor, 'photo': province.governorPhotoUrl});
    }
    if (province.viceGovernor != null && province.viceGovernor!.isNotEmpty) {
      items.add({'role': 'Vice-Gouverneur', 'name': province.viceGovernor, 'photo': province.viceGovernorPhotoUrl});
    }
    if (items.isEmpty) return const _EmptyCard(text: 'Aucun exécutif renseigné');

    return GridView.builder(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.85),
      itemCount: items.length,
      itemBuilder: (_, i) => _ExecutiveCard(role: items[i]['role']!, name: items[i]['name']!, photoUrl: items[i]['photo']),
    );
  }
}

class _ExecutiveCard extends StatelessWidget {
  final String role, name;
  final String? photoUrl;
  const _ExecutiveCard({required this.role, required this.name, this.photoUrl});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.trim().isNotEmpty;
    final isGov = role.toLowerCase().contains('gouverneur') && !role.toLowerCase().contains('vice');
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE7EAF3)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
      padding: const EdgeInsets.all(14),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isGov ? const Color(0xFFE3B23C) : const Color(0xFF123B7A), width: 2.5)),
          child: CircleAvatar(
            radius: 38, backgroundColor: const Color(0xFFF6F7FB),
            backgroundImage: hasPhoto ? CachedNetworkImageProvider(photoUrl!) : null,
            child: !hasPhoto ? const Icon(Icons.person, size: 36, color: Color(0xFF6B7690)) : null,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: (isGov ? const Color(0xFFE3B23C) : const Color(0xFF123B7A)).withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
          child: Text(role.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: isGov ? const Color(0xFF8A6B00) : const Color(0xFF123B7A))),
        ),
        const SizedBox(height: 6),
        Text(name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF10182B))),
      ]),
    );
  }
}

// ==================== 5. MINISTERS SECTION ====================
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
            CircleAvatar(
              radius: 28, backgroundColor: const Color(0xFFF6F7FB),
              backgroundImage: hasPhoto ? CachedNetworkImageProvider(photo) : null,
              child: !hasPhoto ? const Icon(Icons.person, size: 22, color: Color(0xFF6B7690)) : null,
            ),
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

// ==================== 6. TRIBES SECTION ====================
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
        final mediaList = t['media'] as List? ?? [];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE7EAF3))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF123B7A).withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.groups_rounded, color: Color(0xFF123B7A), size: 20)),
              const SizedBox(width: 10),
              Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0A1F44)))),
              if (zone.isNotEmpty) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)), child: Text(zone, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF6B7690)))),
            ]),
            if (history.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(history, style: const TextStyle(fontSize: 12, color: Color(0xFF10182B), height: 1.4)),
            ],
            if (mediaList.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: mediaList.length,
                  itemBuilder: (_, idx) {
                    final m = mediaList[idx];
                    final url = m['url']?.toString() ?? '';
                    final isVideo = m['type'] == 'video';
                    if (url.isEmpty) return const SizedBox.shrink();
                    return Container(
                      width: 60, height: 60, margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: isVideo ? const Center(child: Icon(Icons.videocam, color: Colors.grey)) : CachedNetworkImage(imageUrl: url, fit: BoxFit.cover),
                      ),
                    );
                  },
                ),
              ),
            ]
          ]),
        );
      }).toList(),
    );
  }
}

// ==================== 7. ACHIEVEMENTS SECTION ====================
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
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE7EAF3))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF123B7A).withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.verified_rounded, color: Color(0xFF123B7A), size: 20)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF0A1F44)))),
                if (date.isNotEmpty) Text(date, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF6B7690))),
              ]),
              if (desc.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7690), height: 1.4)),
              ]
            ])),
          ]),
        );
      }).toList(),
    );
  }
}

// ==================== 8. CITIES SECTION ====================
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
              if (c.isCapital) Container(margin: const EdgeInsets.only(top: 2), padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1), decoration: BoxDecoration(color: const Color(0xFFE3B23C).withOpacity(0.2), borderRadius: BorderRadius.circular(4)), child: const Text('Chef-lieu', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold))),
            ])),
          ]),
        );
      },
    );
  }
}

// ==================== 9. EXPLORE GRID SECTION ====================
class _ExploreGridSection extends StatelessWidget {
  final Province province;
  const _ExploreGridSection({required this.province});

  @override
  Widget build(BuildContext context) {
    final fallbackImage = province.coverImageUrl ?? '';
    
    final items = [
      _ExploreItem(
        title: 'Culture', 
        subtitle: province.languages?.trim().isNotEmpty == true ? province.languages! : 'Langues & Traditions', 
        bgImage: fallbackImage,
        color: const Color(0xFF123B7A),
        onTap: (ctx) => _showModal(ctx, 'Culture & Langues', province.languages ?? 'Informations culturelles non renseignées.'),
      ),
      _ExploreItem(
        title: 'Économie', 
        subtitle: province.resources?.trim().isNotEmpty == true ? province.resources! : 'Ressources clés', 
        bgImage: fallbackImage,
        color: const Color(0xFF2E7D32),
        onTap: (ctx) => _showModal(ctx, 'Ressources Économiques', province.resources ?? 'Aucune ressource économique détaillée.'),
      ),
      _ExploreItem(
        title: 'Tourisme', 
        subtitle: '${province.tourismSites.length} site(s) enregistré(s)', 
        bgImage: province.tourismSites.isNotEmpty ? (province.tourismSites.first.imageUrl ?? fallbackImage) : fallbackImage,
        color: const Color(0xFF1565C0),
        onTap: (ctx) => _showTourismModal(ctx, province.tourismSites),
      ),
      _ExploreItem(
        title: 'Urgences', 
        subtitle: '${province.emergencyContacts.length} numéro(s) utiles', 
        bgImage: fallbackImage,
        color: const Color(0xFFD32F2F),
        onTap: (ctx) => _showEmergencyModal(ctx, province.emergencyContacts),
      ),
      _ExploreItem(
        title: 'Admin', 
        subtitle: '${province.territoriesCount ?? province.administrativeDivisions.length} Territoires', 
        bgImage: fallbackImage,
        color: const Color(0xFF6A1B9A),
        onTap: (ctx) => _showAdminModal(ctx, province.administrativeDivisions),
      ),
      _ExploreItem(
        title: 'Galerie', 
        subtitle: 'Photos et médias', 
        bgImage: province.galleryMedia?.where((m) => m['type'] == 'photo').map((m) => m['url']?.toString()).firstOrNull ?? fallbackImage,
        color: const Color(0xFF00695C),
        onTap: (ctx) => _showGalleryModal(ctx, province.galleryMedia ?? []),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.1),
      itemCount: items.length,
      itemBuilder: (_, i) => _SquareExploreCard(item: items[i]),
    );
  }

  void _showModal(BuildContext context, String title, String content) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0A1F44))),
          const Divider(height: 20),
          Text(content, style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF10182B))),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  void _showTourismModal(BuildContext context, List<ProvinceTourism> sites) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.white, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6, minChildSize: 0.4, maxChildSize: 0.9, expand: false,
        builder: (_, scrollCtrl) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Sites Touristiques & Culturels', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0A1F44))),
            const Divider(height: 20),
            Expanded(
              child: sites.isEmpty ? const Center(child: Text('Aucun site répertorié.')) : ListView.builder(
                controller: scrollCtrl, itemCount: sites.length,
                itemBuilder: (_, i) {
                  final s = sites[i];
                  return ListTile(
                    leading: s.imageUrl != null ? CircleAvatar(backgroundImage: CachedNetworkImageProvider(s.imageUrl!)) : const Icon(Icons.place),
                    title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(s.description ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _showEmergencyModal(BuildContext context, List<ProvinceEmergencyContact> contacts) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Numéros d\'Urgence', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFFD32F2F))),
          const Divider(height: 20),
          contacts.isEmpty ? const Text('Aucun contact d\'urgence.') : Column(
            children: contacts.map((e) => ListTile(
              leading: const Icon(Icons.phone_in_talk, color: Color(0xFFD32F2F)),
              title: Text(e.service, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(e.phone),
              trailing: e.phone.isNotEmpty ? IconButton(
                icon: const Icon(Icons.call, color: Colors.green),
                onPressed: () => launchUrl(Uri.parse('tel:${e.phone}')),
              ) : null,
            )).toList(),
          ),
        ]),
      ),
    );
  }

  void _showAdminModal(BuildContext context, List<ProvinceAdministrativeDivision> divs) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Découpage Administratif', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0A1F44))),
          const Divider(height: 20),
          divs.isEmpty ? const Text('Aucun découpage enregistré.') : Column(
            children: divs.map((d) => ListTile(
              leading: const Icon(Icons.account_balance, color: Color(0xFF123B7A)),
              title: Text(d.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Type: ${d.type}'),
            )).toList(),
          ),
        ]),
      ),
    );
  }

  void _showGalleryModal(BuildContext context, List<Map<String, dynamic>> media) {
    final photos = media.where((m) => m['type'] == 'photo').toList();
    showModalBottomSheet(
      context: context, backgroundColor: Colors.white, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7, minChildSize: 0.5, maxChildSize: 0.95, expand: false,
        builder: (_, scrollCtrl) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Galerie Multimédia', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0A1F44))),
            const Divider(height: 20),
            Expanded(
              child: photos.isEmpty ? const Center(child: Text('Aucune photo.')) : GridView.builder(
                controller: scrollCtrl,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10),
                itemCount: photos.length,
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(imageUrl: photos[i]['url']?.toString() ?? '', fit: BoxFit.cover),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _ExploreItem {
  final String title, subtitle, bgImage;
  final Color color;
  final void Function(BuildContext) onTap;
  _ExploreItem({required this.title, required this.subtitle, required this.bgImage, required this.color, required this.onTap});
}

class _SquareExploreCard extends StatelessWidget {
  final _ExploreItem item;
  const _SquareExploreCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final hasImg = item.bgImage.trim().isNotEmpty;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Material(
        color: Colors.white,
        child: InkWell(
          onTap: () => item.onTap(context),
          child: Stack(fit: StackFit.expand, children: [
            if (hasImg) CachedNetworkImage(imageUrl: item.bgImage, fit: BoxFit.cover, placeholder: (_, __) => Container(color: Colors.grey.shade200), errorWidget: (_, __, ___) => Container(color: item.color.withOpacity(0.1))),
            Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(hasImg ? 0.3 : 0.0), Colors.black.withOpacity(hasImg ? 0.8 : 0.05)]), color: hasImg ? null : Colors.white, border: Border.all(color: const Color(0xFFE7EAF3)), borderRadius: BorderRadius.circular(20))),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: item.color.withOpacity(0.9), borderRadius: BorderRadius.circular(8)), child: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.white))),
                const Spacer(),
                Text(item.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: hasImg ? Colors.white70 : const Color(0xFF6B7690), height: 1.3)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0A1F44)));
}

class _ContentCard extends StatelessWidget {
  final String content;
  const _ContentCard({required this.content});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE7EAF3))),
    child: Text(content, style: const TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF10182B))),
  );
}

class _EmptyCard extends StatelessWidget {
  final String text;
  const _EmptyCard({required this.text});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE7EAF3))), child: Center(child: Text(text, style: const TextStyle(color: Color(0xFF6B7690), fontStyle: FontStyle.italic))));
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red), const SizedBox(height: 12), const Text('Impossible de charger'), const SizedBox(height: 12), ElevatedButton(onPressed: onRetry, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF123B7A)), child: const Text('Réessayer', style: TextStyle(color: Colors.white)))]));
}
