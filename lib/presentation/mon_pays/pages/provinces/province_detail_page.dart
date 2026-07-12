// ============================================================
// FICHIER 19 : pages/provinces/province_detail_page.dart
// ============================================================
// lib/presentation/mon_pays/pages/provinces/province_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

  @override
  Widget build(BuildContext context) {
    final provinceAsync = ref.watch(provinceWithAllRelationsProvider(widget.provinceId));

    return Scaffold(
      body: provinceAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur : $err')),
        data: (province) => _buildContent(province),
      ),
    );
  }

  Widget _buildContent(Province province) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Bannière
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: province.coverImageUrl != null
                ? CachedNetworkImage(
                    imageUrl: province.coverImageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: Colors.grey.shade300),
                    errorWidget: (_, __, ___) => _buildCoverPlaceholder(province),
                  )
                : _buildCoverPlaceholder(province),
            title: Text(province.name),
            centerTitle: true,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                // TODO: partager
              },
            ),
          ],
        ),
        // Contenu
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Blason + infos
                Row(
                  children: [
                    if (province.coatOfArmsUrl != null)
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: CachedNetworkImageProvider(province.coatOfArmsUrl!),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            province.name,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          Text('Code : ${province.code}'),
                          Text('Capitale : ${province.capital}'),
                          Text('Région : ${province.region}'),
                          if (province.area != null)
                            Text('Superficie : ${province.area!} km²'),
                          if (province.population != null)
                            Text('Population : ${province.population!} hab.'),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),
                // Description
                if (province.description != null) ...[
                  const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(province.description!),
                  const SizedBox(height: 16),
                ],
                // Gouvernement
                _buildGovernmentSection(province),
                const SizedBox(height: 16),
                // Économie
                _buildEconomySection(province),
                const SizedBox(height: 16),
                // Budget
                _buildBudgetSection(province),
                const SizedBox(height: 16),
                // Tourisme
                _buildTourismSection(province),
                const SizedBox(height: 16),
                // Urgences
                _buildEmergencySection(province),
                const SizedBox(height: 16),
                // Découpage administratif
                _buildAdministrativeSection(province),
                const SizedBox(height: 16),
                // Villes
                _buildCitiesSection(province),
                const SizedBox(height: 16),
                // Réalisations
                _buildAchievementsSection(province),
                const SizedBox(height: 16),
                // Galerie média
                _buildMediaSection(province),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCoverPlaceholder(Province province) {
    return Container(
      color: Colors.grey.shade400,
      child: Center(
        child: Text(
          province.code,
          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white70),
        ),
      ),
    );
  }

  // ============================================================
  // SECTIONS
  // ============================================================

  Widget _buildGovernmentSection(Province province) {
    if (province.government == null) return const SizedBox.shrink();
    final gov = province.government!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Gouvernement provincial', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (gov.governorId != null)
          _infoRow(Icons.person, 'Gouverneur', 'ID : ${gov.governorId}'),
        if (gov.viceGovernorId != null)
          _infoRow(Icons.person_outline, 'Vice-gouverneur', 'ID : ${gov.viceGovernorId}'),
        if (gov.ministers.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text('Ministres provinciaux', style: TextStyle(fontWeight: FontWeight.w600)),
          ...gov.ministers.map((m) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: _infoRow(Icons.work, m.portfolio, 'Ministre ${m.authorityId ?? ''}'),
          )),
        ],
      ],
    );
  }

  Widget _buildEconomySection(Province province) {
    if (province.economicResources.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ressources économiques', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: province.economicResources.map((r) {
            return Chip(
              label: Text(r.name),
              backgroundColor: r.isKeySector ? Colors.green.shade100 : Colors.grey.shade200,
              avatar: r.iconUrl != null
                  ? Image.network(r.iconUrl!, width: 20, height: 20)
                  : null,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBudgetSection(Province province) {
    if (province.budgetPriorities.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Priorités budgétaires', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...province.budgetPriorities.map((b) => ListTile(
          leading: const Icon(Icons.monetization_on),
          title: Text(b.title),
          subtitle: Text('${b.year} - ${b.allocatedAmount != null ? '${b.allocatedAmount!} USD' : 'Montant non spécifié'}'),
          trailing: b.pdfUrl != null
              ? IconButton(
                  icon: const Icon(Icons.picture_as_pdf),
                  onPressed: () {
                    // TODO: ouvrir PDF
                  },
                )
              : null,
        )),
      ],
    );
  }

  Widget _buildTourismSection(Province province) {
    if (province.tourismSites.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tourisme & Culture', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...province.tourismSites.map((t) => ListTile(
          leading: t.imageUrl != null
              ? SizedBox(
                  width: 50,
                  height: 50,
                  child: Image.network(t.imageUrl!, fit: BoxFit.cover),
                )
              : const Icon(Icons.place),
          title: Text(t.name),
          subtitle: Text('${t.type} - ${t.location ?? ''}'),
        )),
      ],
    );
  }

  Widget _buildEmergencySection(Province province) {
    if (province.emergencyContacts.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Numéros d\'urgence', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...province.emergencyContacts.map((e) => ListTile(
          leading: const Icon(Icons.phone, color: Colors.red),
          title: Text(e.service),
          subtitle: Text(e.phone),
        )),
      ],
    );
  }

  Widget _buildAdministrativeSection(Province province) {
    if (province.administrativeDivisions.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Découpage administratif', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: province.administrativeDivisions.map((d) {
            return Chip(
              label: Text('${d.type} : ${d.name}'),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCitiesSection(Province province) {
    if (province.cities.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Villes principales', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...province.cities.map((c) => ListTile(
          leading: c.isCapital ? const Icon(Icons.star, color: Colors.amber) : const Icon(Icons.location_city),
          title: Text(c.name),
          subtitle: Text('${c.population ?? ''} hab.'),
        )),
      ],
    );
  }

  Widget _buildAchievementsSection(Province province) {
    // On récupère séparément les réalisations via le provider
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
                const Text('Réalisations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...achievements.map((a) => ListTile(
                  leading: a.coverImageUrl != null
                      ? SizedBox(
                          width: 50,
                          height: 50,
                          child: Image.network(a.coverImageUrl!, fit: BoxFit.cover),
                        )
                      : const Icon(Icons.emoji_events),
                  title: Text(a.title),
                  subtitle: Text('${a.category} - ${a.date != null ? a.date!.toLocal().toString().split(' ')[0] : ''}'),
                )),
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
            // Séparer photos et vidéos
            final photos = media.where((m) => m.type == 'photo').toList();
            final videos = media.where((m) => m.type == 'video').toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (photos.isNotEmpty) ...[
                  const Text('Photos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: photos.length,
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(photos[i].url, width: 120, fit: BoxFit.cover),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (videos.isNotEmpty) ...[
                  const Text('Vidéos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...videos.map((v) => ListTile(
                    leading: const Icon(Icons.play_circle, color: Colors.red),
                    title: Text(v.title ?? 'Vidéo'),
                  )),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade700),
        const SizedBox(width: 8),
        Text('$label : ', style: const TextStyle(fontWeight: FontWeight.w600)),
        Expanded(child: Text(value)),
      ],
    );
  }
}
