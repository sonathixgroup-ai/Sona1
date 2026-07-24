// ============================================================
// FICHIER 19 : pages/provinces/province_detail_page.dart
// ============================================================
// lib/presentation/mon_pays/pages/provinces/province_detail_page.dart

import 'dart:async';
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
import '../../models/province_minister.dart';

class ProvinceDetailPage extends ConsumerStatefulWidget {
  final String provinceId;
  const ProvinceDetailPage({required this.provinceId, super.key});

  @override
  ConsumerState<ProvinceDetailPage> createState() => _ProvinceDetailPageState();
}

class _ProvinceDetailPageState extends ConsumerState<ProvinceDetailPage> {
  final ScrollController _scrollController = ScrollController();
  final PageController _autoScrollController = PageController();
  Timer? _autoScrollTimer;
  int _currentPage = 0;

  static const Color navyDeep = Color(0xFF0A1F44);
  static const Color navy = Color(0xFF123B7A);
  static const Color gold = Color(0xFFE3B23C);
  static const Color ivory = Color(0xFFF6F7FB);
  static const Color darkText = Color(0xFF10182B);
  static const Color mutedText = Color(0xFF6B7690);
  static const Color hairline = Color(0xFFE7EAF3);
  static const Color redThix = Color(0xFFD32F2F);

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _autoScrollController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startAutoScroll(int itemCount) {
    if (itemCount <= 1) return;
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      if (_autoScrollController.hasClients) {
        _currentPage = (_currentPage + 1) % itemCount;
        _autoScrollController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

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
                
                // 1. Photos en auto-scrolling en haut
                _buildAutoScrollMediaBanner(province.id),
                const SizedBox(height: 16),

                // 2. Villes principales affichées directement
                _buildCitiesCardSection(province),
                const SizedBox(height: 16),

                // 3. Carte des Gouverneurs (Tête de l'Exécutif)
                _buildExecutiveCardSection(province),
                const SizedBox(height: 16),

                // 4. Carte des Ministres
                _buildMinistersCardSection(province),
                const SizedBox(height: 16),
                
                if (province.description != null && province.description!.isNotEmpty) ...[
                  _buildSectionTitle(Icons.info_outline, 'À propos de la province'),
                  _buildTextCard(province.description!),
                  const SizedBox(height: 24),
                ],
                
                // Autres sections cliquables
                _buildCardSection(
                  title: 'Culture & Géographie',
                  icon: Icons.public,
                  subtitle: province.languages != null ? 'Langues : ${province.languages}' : 'Voir les détails culturels',
                  onTap: () => _showCultureModal(context, province),
                ),
                _buildCardSection(
                  title: 'Économie & Ressources',
                  icon: Icons.monetization_on,
                  subtitle: province.resources != null ? 'Ressources : ${province.resources}' : '${province.economicResources.length} secteur(s) clé(s)',
                  onTap: () => _showEconomyModal(context, province),
                ),
                _buildCardSection(
                  title: 'Tourisme & Sites',
                  icon: Icons.landscape,
                  subtitle: '${province.tourismSites.length} site(s) touristique(s)',
                  onTap: () => _showTourismModal(context, province.tourismSites),
                ),
                _buildCardSection(
                  title: 'Urgences & Contacts',
                  icon: Icons.emergency,
                  subtitle: '${province.emergencyContacts.length} numéro(s) d\'urgence',
                  onTap: () => _showEmergencyModal(context, province.emergencyContacts),
                ),
                _buildCardSection(
                  title: 'Découpage Administratif',
                  icon: Icons.dashboard_customize,
                  subtitle: '${province.administrativeDivisions.length} division(s)',
                  onTap: () => _showAdministrativeModal(context, province.administrativeDivisions),
                ),
                _buildCardSection(
                  title: 'Réalisations Majeures',
                  icon: Icons.emoji_events,
                  subtitle: 'Projets et accomplissements',
                  onTap: () => _showAchievementsModal(context),
                ),
                _buildCardSection(
                  title: 'Média & Galerie',
                  icon: Icons.perm_media,
                  subtitle: 'Photos et vidéos de la province',
                  onTap: () => _showMediaModal(context),
                ),

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
                    errorWidget: (_, __, ___) => _buildCoverPlaceholder(),
                  )
                : _buildCoverPlaceholder(),
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

  Widget _buildCoverPlaceholder() {
    return Container(
      color: navy,
      child: Center(
        child: Icon(Icons.map, size: 80, color: Colors.white.withOpacity(0.2)),
      ),
    );
  }

  // BANNIÈRE AUTO-SCROLLING (PHOTOS EN HAUT)
  Widget _buildAutoScrollMediaBanner(String provinceId) {
    return Consumer(
      builder: (context, ref, child) {
        final mediaAsync = ref.watch(mediaByProvinceProvider(provinceId));
        return mediaAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (media) {
            final photos = media.where((m) => m.type == 'photo').toList();
            if (photos.isEmpty) return const SizedBox.shrink();

            _startAutoScroll(photos.length);

            return Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: PageView.builder(
                  controller: _autoScrollController,
                  itemCount: photos.length,
                  itemBuilder: (context, index) {
                    final photo = photos[index];
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(imageUrl: photo.url, fit: BoxFit.cover),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                            ),
                          ),
                        ),
                        if (photo.title != null && photo.title!.isNotEmpty)
                          Positioned(
                            bottom: 12, left: 16, right: 16,
                            child: Text(
                              photo.title!,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, shadows: [Shadow(color: Colors.black, blurRadius: 4)]),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  // CARTE : TÊTE DE L'EXÉCUTIF (GOUVERNEURS)
  Widget _buildExecutiveCardSection(Province province) {
    final hasGovernor = province.governor != null && province.governor!.isNotEmpty;
    final hasViceGovernor = province.viceGovernor != null && province.viceGovernor!.isNotEmpty;

    if (!hasGovernor && !hasViceGovernor) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: hairline),
        boxShadow: [BoxShadow(color: navyDeep.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: navyDeep.withOpacity(0.08), shape: BoxShape.circle),
                  child: const Icon(Icons.account_balance, color: navyDeep, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text("Tête de l'Exécutif", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: navyDeep)),
                ),
              ],
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1, color: hairline)),
            
            if (hasGovernor)
              _buildPersonRow(Icons.person, "Gouverneur", province.governor!),
            
            if (hasGovernor && hasViceGovernor)
              const SizedBox(height: 12),
              
            if (hasViceGovernor)
              _buildPersonRow(Icons.person_outline, "Vice-Gouverneur", province.viceGovernor!),
          ],
        ),
      ),
    );
  }

  // CARTE : MINISTRES PROVINCIAUX
  Widget _buildMinistersCardSection(Province province) {
    final ministers = province.government?.ministers ?? [];

    if (ministers.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: hairline),
        boxShadow: [BoxShadow(color: navyDeep.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: gold.withOpacity(0.15), shape: BoxShape.circle),
                  child: const Icon(Icons.groups, color: gold, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text("Ministres Provinciaux (${ministers.length})", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: navyDeep)),
                ),
              ],
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1, color: hairline)),
            
            ...ministers.map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    child: const Icon(Icons.work, size: 16, color: mutedText),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.portfolio, style: const TextStyle(fontSize: 12, color: mutedText, fontWeight: FontWeight.w600)),
                        Text(m.name ?? 'Nom non renseigné', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: darkText)),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonRow(IconData icon, String role, String name) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          backgroundColor: ivory,
          radius: 18,
          child: Icon(icon, size: 20, color: navy),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(role, style: const TextStyle(fontSize: 12, color: mutedText, fontWeight: FontWeight.w600)),
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: darkText)),
            ],
          ),
        ),
      ],
    );
  }

  // CARTE SPÉCIFIQUE VILLES PRINCIPALES (EN BAS DE L'EN-TÊTE)
  Widget _buildCitiesCardSection(Province province) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: hairline),
        boxShadow: [BoxShadow(color: navyDeep.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _showCitiesModal(context, province.cities),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: navyDeep.withOpacity(0.08), shape: BoxShape.circle),
                      child: const Icon(Icons.location_city, color: navyDeep, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('Villes Principales', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: navyDeep)),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: mutedText),
                  ],
                ),
                const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1, color: hairline)),
                province.cities.isEmpty
                    ? const Text('Aucune ville enregistrée', style: TextStyle(color: mutedText, fontStyle: FontStyle.italic, fontSize: 13))
                    : Column(
                        children: province.cities.take(3).map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Icon(c.isCapital ? Icons.star : Icons.location_on, size: 16, color: c.isCapital ? gold : navy),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: darkText)),
                              ),
                              if (c.population != null)
                                Text('${_formatNumber(int.tryParse(c.population.toString()) ?? 0)} hab.', style: const TextStyle(fontSize: 12, color: mutedText)),
                              if (c.isCapital) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: gold.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                                  child: const Text('Chef-lieu', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: navyDeep)),
                                ),
                              ],
                            ],
                          ),
                        )).toList(),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // CARTE STANDARD DES SECTIONS CLIQUABLES
  Widget _buildCardSection({required String title, required IconData icon, required String subtitle, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: hairline),
        boxShadow: [BoxShadow(color: navyDeep.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: navyDeep.withOpacity(0.08), shape: BoxShape.circle),
          child: Icon(icon, color: navyDeep, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: navyDeep)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: mutedText)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: mutedText),
      ),
    );
  }

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
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: hairline),
                    image: DecorationImage(image: CachedNetworkImageProvider(province.coatOfArmsUrl!), fit: BoxFit.contain),
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

  void _showModal(BuildContext context, String title, Widget content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: navyDeep)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const Divider(height: 20),
            Expanded(child: SingleChildScrollView(child: content)),
          ],
        ),
      ),
    );
  }

  void _showCitiesModal(BuildContext context, List<City> cities) {
    _showModal(context, 'Villes Principales', cities.isEmpty 
      ? const Text('Aucune ville enregistrée.')
      : Column(
          children: cities.map((c) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: ivory, borderRadius: BorderRadius.circular(12), border: Border.all(color: hairline)),
            child: Row(
              children: [
                Icon(c.isCapital ? Icons.star : Icons.location_city, color: c.isCapital ? gold : navy),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (c.population != null) Text('${c.population} hab.', style: const TextStyle(fontSize: 12, color: mutedText)),
                    ],
                  ),
                ),
                if (c.isCapital) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: gold.withOpacity(0.2), borderRadius: BorderRadius.circular(4)), child: const Text('Capitale', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: navyDeep))),
              ],
            ),
          )).toList(),
        ),
    );
  }

  void _showCultureModal(BuildContext context, Province province) {
    _showModal(context, 'Culture & Géographie', Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _modalRow(Icons.chat_bubble_outline, 'Langues parlées', province.languages ?? 'Non spécifié'),
        const Divider(),
        _modalRow(Icons.explore, 'Région', province.region),
      ],
    ));
  }

  void _showEconomyModal(BuildContext context, Province province) {
    _showModal(context, 'Économie & Ressources', Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _modalRow(Icons.diamond, 'Ressources principales', province.resources ?? 'Non spécifié'),
      ],
    ));
  }

  void _showTourismModal(BuildContext context, List<ProvinceTourism> sites) {
    _showModal(context, 'Tourisme & Sites', sites.isEmpty 
      ? const Text('Aucun site touristique enregistré.')
      : Column(
          children: sites.map((t) => ListTile(
            leading: t.imageUrl != null ? CachedNetworkImage(imageUrl: t.imageUrl!, width: 50, height: 50, fit: BoxFit.cover) : const Icon(Icons.landscape),
            title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(t.type),
          )).toList(),
        ),
    );
  }

  void _showEmergencyModal(BuildContext context, List<ProvinceEmergencyContact> contacts) {
    _showModal(context, 'Numéros d\'urgence', contacts.isEmpty 
      ? const Text('Aucun contact d\'urgence enregistré.')
      : Column(
          children: contacts.map((e) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(color: ivory, borderRadius: BorderRadius.circular(12), border: Border.all(color: redThix.withOpacity(0.3))),
            child: ListTile(
              leading: const Icon(Icons.phone, color: redThix),
              title: Text(e.service, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(e.phone, style: const TextStyle(color: navy, fontWeight: FontWeight.bold)),
              trailing: IconButton(icon: const Icon(Icons.call, color: Colors.green), onPressed: () => _launchUrl('tel:${e.phone}')),
            ),
          )).toList(),
        ),
    );
  }

  void _showAdministrativeModal(BuildContext context, List<ProvinceAdministrativeDivision> divisions) {
    _showModal(context, 'Découpage Administratif', divisions.isEmpty 
      ? const Text('Aucune division administrative enregistrée.')
      : Wrap(
          spacing: 8, runSpacing: 8,
          children: divisions.map((d) => Chip(label: Text('${d.type} : ${d.name}'))).toList(),
        ),
    );
  }

  void _showAchievementsModal(BuildContext context) {
    _showModal(context, 'Réalisations Majeures', Consumer(
      builder: (context, ref, child) {
        final achievementsAsync = ref.watch(achievementsByProvinceProvider(widget.provinceId));
        return achievementsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Text('Erreur de chargement.'),
          data: (achievements) => achievements.isEmpty 
            ? const Text('Aucune réalisation enregistrée.')
            : Column(
                children: achievements.map((a) => ListTile(
                  title: Text(a.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(a.description ?? ''),
                )).toList(),
              ),
        );
      },
    ));
  }

  void _showMediaModal(BuildContext context) {
    _showModal(context, 'Média & Galerie', Consumer(
      builder: (context, ref, child) {
        final mediaAsync = ref.watch(mediaByProvinceProvider(widget.provinceId));
        return mediaAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Text('Erreur de chargement.'),
          data: (media) => media.isEmpty 
            ? const Text('Aucun média disponible.')
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8),
                itemCount: media.length,
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(imageUrl: media[i].url, fit: BoxFit.cover),
                ),
              ),
        );
      },
    ));
  }

  Widget _modalRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: navy),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: mutedText)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: darkText)),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
