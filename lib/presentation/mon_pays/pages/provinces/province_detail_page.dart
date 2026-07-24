// ============================================================
// FICHIER 19 : pages/provinces/province_detail_page.dart
// ============================================================
// lib/presentation/mon_pays/pages/provinces/province_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/provinces_provider.dart';
import '../../providers/cities_provider.dart';
import '../../providers/achievements_provider.dart';
import '../../providers/media_provider.dart';
import '../../models/province.dart';
import '../../models/city.dart';
import '../../models/provincial_achievement.dart';
import '../../models/province_media.dart';
import '../../models/province_emergency.dart';
import '../../models/province_tourism.dart';
import '../../models/province_administrative.dart';
import '../../models/province_budget.dart';

class ProvinceDetailPage extends ConsumerStatefulWidget {
  final String provinceId;
  const ProvinceDetailPage({required this.provinceId, super.key});

  @override
  ConsumerState<ProvinceDetailPage> createState() => _ProvinceDetailPageState();
}

class _ProvinceDetailPageState extends ConsumerState<ProvinceDetailPage> {
  final ScrollController _scrollController = ScrollController();

  static const Color navyDeep = Color(0xFF0A1F44);
  static const Color navy = Color(0xFF123B7A);
  static const Color gold = Color(0xFFE3B23C);
  static const Color ivory = Color(0xFFF6F7FB);
  static const Color darkText = Color(0xFF10182B);
  static const Color mutedText = Color(0xFF6B7690);
  static const Color hairline = Color(0xFFE7EAF3);
  static const Color redThix = Color(0xFFD32F2F);

  @override
  Widget build(BuildContext context) {
    final provinceAsync = ref.watch(provinceWithAllRelationsProvider(widget.provinceId));

    return Scaffold(
      backgroundColor: ivory,
      body: provinceAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: navy)),
        error: (err, stack) => _buildErrorState(err),
        data: (province) => _buildContent(province),
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
          Text('Impossible de charger la province', style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.invalidate(provinceWithAllRelationsProvider(widget.provinceId)),
            style: ElevatedButton.styleFrom(backgroundColor: navy),
            child: const Text('Réessayer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(Province province) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        _buildSliverAppBar(province),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIdentitySection(province),
                const SizedBox(height: 24),
                
                if (province.description != null && province.description!.isNotEmpty) ...[
                  _buildSectionTitle(Icons.info_outline, 'À propos de la province'),
                  _buildTextCard(province.description!),
                  const SizedBox(height: 24),
                ],
                
                _buildGovernmentSection(province),
                _buildCitiesSection(province),
                _buildAdministrativeSection(province),
                _buildEconomySection(province),
                _buildBudgetSection(province),
                _buildTourismSection(province),
                _buildEmergencySection(province),
                _buildAchievementsSection(province),
                _buildMediaSection(province),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar(Province province) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: navyDeep,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: () {},
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16, right: 16),
        title: Text(
          province.name,
          style: const TextStyle(
            fontSize: 20, 
            fontWeight: FontWeight.w800, 
            color: Colors.white, 
            shadows: [Shadow(color: Colors.black54, blurRadius: 8)]
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            province.coverImageUrl != null && province.coverImageUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: province.coverImageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: Colors.grey.shade300),
                    errorWidget: (_, __, ___) => _buildCoverPlaceholder(province),
                  )
                : _buildCoverPlaceholder(province),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, navyDeep.withOpacity(0.9)],
                  stops: const [0.4, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverPlaceholder(Province province) {
    return Container(
      color: navy,
      child: Center(
        child: Icon(Icons.map, size: 80, color: Colors.white.withOpacity(0.2)),
      ),
    );
  }

  // ============================================================
  // SECTIONS
  // ============================================================

  Widget _buildIdentitySection(Province province) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: hairline),
        boxShadow: [BoxShadow(color: navyDeep.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              if (province.coatOfArmsUrl != null && province.coatOfArmsUrl!.isNotEmpty)
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: hairline),
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(province.coatOfArmsUrl!),
                      fit: BoxFit.contain,
                    ),
                  ),
                )
              else
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(color: navyDeep.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Center(child: Icon(Icons.shield, color: navyDeep, size: 30)),
                ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(province.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: navyDeep)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: redThix, borderRadius: BorderRadius.circular(6)),
                          child: Text(province.code, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                        const SizedBox(width: 8),
                        Text('Région ${province.region}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: navy)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: hairline)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(Icons.location_city, 'Capitale', province.capital),
              _buildStatItem(Icons.groups, 'Population', province.population != null ? '${_formatNumber(province.population!)} hab.' : 'N/A'),
              _buildStatItem(Icons.square_foot, 'Superficie', province.area != null ? '${_formatNumber(province.area!)} km²' : 'N/A'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGovernmentSection(Province province) {
    if (province.government == null) return const SizedBox.shrink();
    final gov = province.government!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(Icons.account_balance, 'Gouvernement Provincial'),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: hairline)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (gov.governorId != null && gov.governorId!.isNotEmpty)
                _buildGovRoleRow(Icons.person, 'Gouverneur', 'ID: ${gov.governorId}'),
              if (gov.viceGovernorId != null && gov.viceGovernorId!.isNotEmpty) ...[
                const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, color: hairline)),
                _buildGovRoleRow(Icons.person_outline, 'Vice-Gouverneur', 'ID: ${gov.viceGovernorId}'),
              ],
              if (gov.ministers.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Ministres', style: TextStyle(fontWeight: FontWeight.w800, color: navyDeep, fontSize: 14)),
                const SizedBox(height: 8),
                ...gov.ministers.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.work, size: 16, color: mutedText),
                      const SizedBox(width: 8),
                      Expanded(child: Text(m.portfolio, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: darkText))),
                    ],
                  ),
                )),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildEconomySection(Province province) {
    if (province.economicResources.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(Icons.monetization_on, 'Économie & Ressources'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: province.economicResources.map((r) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: r.isKeySector ? gold.withOpacity(0.15) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: r.isKeySector ? gold : hairline),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (r.iconUrl != null && r.iconUrl!.isNotEmpty) ...[
                    CachedNetworkImage(imageUrl: r.iconUrl!, width: 16, height: 16),
                    const SizedBox(width: 6),
                  ] else
                    Icon(r.isKeySector ? Icons.star : Icons.circle, size: 12, color: r.isKeySector ? gold : mutedText),
                  const SizedBox(width: 4),
                  Text(r.name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: r.isKeySector ? navyDeep : darkText)),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildBudgetSection(Province province) {
    if (province.budgetPriorities.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(Icons.account_balance_wallet, 'Priorités Budgétaires'),
        ...province.budgetPriorities.map((b) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: hairline)),
          child: Row(
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.show_chart, color: Colors.green, size: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.title, style: const TextStyle(fontWeight: FontWeight.w700, color: darkText)),
                    Text('${b.year} ${b.allocatedAmount != null ? '• ${_formatNumber(b.allocatedAmount!.toInt())} USD' : ''}', style: const TextStyle(fontSize: 12, color: mutedText)),
                  ],
                ),
              ),
              if (b.pdfUrl != null && b.pdfUrl!.isNotEmpty)
                IconButton(icon: const Icon(Icons.picture_as_pdf, color: redThix), onPressed: () => _launchUrl(b.pdfUrl!)),
            ],
          ),
        )),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTourismSection(Province province) {
    if (province.tourismSites.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(Icons.landscape, 'Tourisme & Culture'),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: province.tourismSites.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final t = province.tourismSites[i];
              return Container(
                width: 140,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: hairline)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: t.imageUrl != null && t.imageUrl!.isNotEmpty
                          ? CachedNetworkImage(imageUrl: t.imageUrl!, height: 100, width: 140, fit: BoxFit.cover)
                          : Container(height: 100, width: 140, color: navyDeep.withOpacity(0.1), child: const Icon(Icons.landscape, color: navy)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(t.type, style: const TextStyle(fontSize: 10, color: mutedText)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildEmergencySection(Province province) {
    if (province.emergencyContacts.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(Icons.emergency, 'Urgences & Contacts'),
        ...province.emergencyContacts.map((e) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: redThix.withOpacity(0.3))),
          child: ListTile(
            leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: redThix.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.phone, color: redThix, size: 20)),
            title: Text(e.service, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(e.phone, style: const TextStyle(color: navy, fontWeight: FontWeight.w600)),
            trailing: IconButton(icon: const Icon(Icons.call, color: Colors.green), onPressed: () => _launchUrl('tel:${e.phone}')),
          ),
        )),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildAdministrativeSection(Province province) {
    if (province.administrativeDivisions.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(Icons.dashboard_customize, 'Découpage Administratif'),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: province.administrativeDivisions.map((d) {
            return Chip(
              label: Text(d.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
              avatar: const Icon(Icons.map, size: 14, color: navy),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: hairline)),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildCitiesSection(Province province) {
    if (province.cities.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(Icons.location_city, 'Villes Principales'),
        ...province.cities.map((c) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: hairline)),
          child: Row(
            children: [
              Icon(c.isCapital ? Icons.star : Icons.location_on, color: c.isCapital ? gold : navy, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.name, style: TextStyle(fontWeight: FontWeight.w700, color: c.isCapital ? navyDeep : darkText)),
                    // FIX: Conversion sécurisée en entier
                    if (c.population != null) Text('${_formatNumber(int.tryParse(c.population.toString()) ?? 0)} habitants', style: const TextStyle(fontSize: 12, color: mutedText)),
                  ],
                ),
              ),
              if (c.isCapital) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: gold.withOpacity(0.2), borderRadius: BorderRadius.circular(4)), child: const Text('Chef-lieu', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: navyDeep))),
            ],
          ),
        )),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildAchievementsSection(Province province) {
    return Consumer(
      builder: (context, ref, child) {
        final achievementsAsync = ref.watch(achievementsByProvinceProvider(widget.provinceId));
        return achievementsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (achievements) {
            if (achievements.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(Icons.emoji_events, 'Réalisations Majeures'),
                ...achievements.map((a) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: hairline), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (a.coverImageUrl != null && a.coverImageUrl!.isNotEmpty)
                        ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), child: CachedNetworkImage(imageUrl: a.coverImageUrl!, height: 140, width: double.infinity, fit: BoxFit.cover)),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: gold.withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: Text(a.category, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: navyDeep))),
                                const Spacer(),
                                if (a.date != null) Text(a.date!.toLocal().toString().split(' ')[0], style: const TextStyle(fontSize: 12, color: mutedText, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(a.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: navyDeep)),
                            // FIX: Vérification stricte de nullité avant isNotEmpty
                            if (a.description != null && a.description!.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text(a.description!, style: const TextStyle(fontSize: 13, color: darkText, height: 1.4))),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 24),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMediaSection(Province province) {
    return Consumer(
      builder: (context, ref, child) {
        final mediaAsync = ref.watch(mediaByProvinceProvider(widget.provinceId));
        return mediaAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (media) {
            if (media.isEmpty) return const SizedBox.shrink();
            final photos = media.where((m) => m.type == 'photo').toList();
            final videos = media.where((m) => m.type == 'video').toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (photos.isNotEmpty) ...[
                  _buildSectionTitle(Icons.photo_library, 'Galerie Photos'),
                  SizedBox(
                    height: 140,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: photos.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, i) {
                        final photo = photos[i];
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
                  ),
                  const SizedBox(height: 24),
                ],
                if (videos.isNotEmpty) ...[
                  _buildSectionTitle(Icons.video_library, 'Vidéos de la province'),
                  ...videos.map((v) => GestureDetector(
                    onTap: () => _launchUrl(v.url),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      height: 180, width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))],
                        // FIX: Retrait de thumbnailUrl pour éviter l'erreur de compilation
                      ),
                      child: Stack(
                        children: [
                          const Center(child: Icon(Icons.play_circle_fill, size: 64, color: Colors.white70)),
                          Positioned(
                            bottom: 0, left: 0, right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)), gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withOpacity(0.9), Colors.transparent])),
                              child: Text(v.title ?? 'Vidéo de présentation', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black, blurRadius: 4)])),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
                ],
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // UTILITAIRES & WIDGETS
  // ============================================================

  Widget _buildSectionTitle(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: gold, size: 22),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: navyDeep))),
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

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: navy, size: 24),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: darkText)),
        Text(label, style: const TextStyle(fontSize: 11, color: mutedText)),
      ],
    );
  }

  Widget _buildGovRoleRow(IconData icon, String role, String name) {
    return Row(
      children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: navyDeep.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: navyDeep, size: 18)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(role, style: const TextStyle(fontSize: 12, color: mutedText)),
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: navyDeep)),
          ],
        ),
      ],
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

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible d\'ouvrir ce lien.'), backgroundColor: Colors.red));
    }
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ');
  }
}
