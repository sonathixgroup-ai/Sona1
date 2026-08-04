// lib/presentation/thix_weeding/pages/guest/guest_home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/failure.dart';
import '../../providers/wedding_provider.dart';
import '../../providers/countdown_provider.dart';

part 'guest_home_page.g.dart';

// ============================================================
// PALETTE — Charte THIX
// ============================================================
class _P {
  static const bg = Color(0xFFFBF7F6);
  static const primary = Color(0xFFE25A6A);
  static const primaryDark = Color(0xFFC94356);
  static const ink = Color(0xFF1E1E24);
  static const inkSoft = Color(0xFF8B8B96);
  static const border = Color(0xFFF0EAEC);
  static const gold = Color(0xFFDDAA3E);
  static const blue = Color(0xFF5A94D6);
  static const green = Color(0xFF5FAE72);
  static const purple = Color(0xFFA477D9);
}

// ============================================================
// MODELE STATIQUE DES TUILES DU MENU INVITE
// ============================================================
enum _BadgeType { none, alert, count, live }

class _GuestMenuItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;
  final _BadgeType badgeType;
  final int? badgeCount;

  const _GuestMenuItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
    this.badgeType = _BadgeType.none,
    this.badgeCount,
  });
}

const List<_GuestMenuItem> _kGuestMenu = [
  _GuestMenuItem(title: 'Invitation', subtitle: 'Voir les détails', icon: Icons.mail_outline_rounded, color: _P.primary, route: 'invitation'),
  _GuestMenuItem(title: 'Programme', subtitle: 'Déroulé de la journée', icon: Icons.event_note_outlined, color: Color(0xFFE39A4B), route: 'programme'),
  _GuestMenuItem(title: 'Lieu & Accès', subtitle: 'Itinéraire & infos', icon: Icons.location_on_outlined, color: _P.green, route: 'lieu'),
  _GuestMenuItem(title: 'RSVP', subtitle: 'Confirmer ma présence', icon: Icons.people_alt_outlined, color: _P.purple, route: 'rsvp', badgeType: _BadgeType.alert),
  _GuestMenuItem(title: 'Liste de cadeaux', subtitle: 'Voir & contribuer', icon: Icons.card_giftcard_outlined, color: _P.gold, route: 'cadeaux'),
  _GuestMenuItem(title: 'Galerie', subtitle: 'Photos & vidéos', icon: Icons.photo_library_outlined, color: _P.blue, route: 'galerie'),
  _GuestMenuItem(title: 'Livre d\'or', subtitle: 'Laisser un message', icon: Icons.edit_outlined, color: _P.primary, route: 'livre-or'),
  _GuestMenuItem(title: 'Live', subtitle: 'Suivre en direct', icon: Icons.podcasts_outlined, color: Color(0xFFE07A6B), route: 'live', badgeType: _BadgeType.live),
  _GuestMenuItem(title: 'Annonces', subtitle: 'Infos importantes', icon: Icons.campaign_outlined, color: _P.purple, route: 'annonces', badgeType: _BadgeType.count, badgeCount: 3),
  _GuestMenuItem(title: 'FAQ', subtitle: 'Vos questions', icon: Icons.help_outline_rounded, color: _P.blue, route: 'faq'),
  _GuestMenuItem(title: 'Nos remerciements', subtitle: 'Un mot pour vous', icon: Icons.volunteer_activism_outlined, color: _P.green, route: 'remerciements'),
  _GuestMenuItem(title: 'Plus', subtitle: 'Autres options', icon: Icons.more_horiz_rounded, color: Color(0xFF9A9AA5), route: 'plus'),
];

// ============================================================
// PROVIDERS COMPLEMENTAIRES
// ============================================================
@riverpod
Future<Map<String, int>> guestEventStats(GuestEventStatsRef ref, String weddingId) async {
  await Future.delayed(const Duration(milliseconds: 200));
  return {'Invités confirmés': 84, 'En attente': 12, 'Cadeaux reçus': 19, 'Photos partagées': 56};
}

@riverpod
Future<List<Map<String, dynamic>>> guestVendors(GuestVendorsRef ref, String weddingId) async {
  await Future.delayed(const Duration(milliseconds: 250));
  return [
    {'name': 'Salle Émeraude', 'category': 'Lieu de réception', 'zone': 'Gombe', 'rating': 4.8, 'icon': Icons.villa_outlined, 'colors': [const Color(0xFFFBF0DB), const Color(0xFFF5E2B8)]},
    {'name': 'Chef Amani', 'category': 'Traiteur', 'zone': 'Limete', 'rating': 4.7, 'icon': Icons.restaurant_outlined, 'colors': [const Color(0xFFE4EEFB), const Color(0xFFCFE1F7)]},
    {'name': 'Studio Lumière', 'category': 'Photographe', 'zone': 'Kintambo', 'rating': 4.9, 'icon': Icons.camera_alt_outlined, 'colors': [const Color(0xFFF0E9FA), const Color(0xFFE1D3F5)]},
    {'name': 'Fleurs de Kin', 'category': 'Décoration', 'zone': 'Ngaliema', 'rating': 4.8, 'icon': Icons.local_florist_outlined, 'colors': [const Color(0xFFE7F5EA), const Color(0xFFD3ECD9)]},
  ];
}

@riverpod
Future<List<Map<String, dynamic>>> guestUpdates(GuestUpdatesRef ref, String weddingId) async {
  await Future.delayed(const Duration(milliseconds: 200));
  return [
    {'tag': 'PARKING', 'tagColor': _P.blue, 'title': 'Parking disponible', 'subtitle': 'À partir de 15h', 'icon': Icons.local_parking_outlined},
    {'tag': 'DRESS CODE', 'tagColor': _P.gold, 'title': 'Tenue élégante', 'subtitle': 'Couleurs pastel conseillées', 'icon': Icons.checkroom_outlined},
    {'tag': 'TRANSPORT', 'tagColor': _P.green, 'title': 'Navette gratuite', 'subtitle': 'Départ 15h30, Place Victoire', 'icon': Icons.directions_bus_outlined},
  ];
}

// ============================================================
// PAGE
// ============================================================
class GuestHomePage extends ConsumerStatefulWidget {
  final String weddingId;
  const GuestHomePage({super.key, required this.weddingId});

  @override
  ConsumerState<GuestHomePage> createState() => _GuestHomePageState();
}

class _GuestHomePageState extends ConsumerState<GuestHomePage> {
  Future<void> _onRefresh() async {
    ref.invalidate(guestWeddingProvider(widget.weddingId));
    await ref.read(guestWeddingProvider(widget.weddingId).future);
  }

  void _onTapGeneric(String label) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label bientôt disponible')));
  }

  @override
  Widget build(BuildContext context) {
    final weddingAsync = ref.watch(guestWeddingProvider(widget.weddingId));
    final statsAsync = ref.watch(guestEventStatsProvider(widget.weddingId));
    final vendorsAsync = ref.watch(guestVendorsProvider(widget.weddingId));
    final updatesAsync = ref.watch(guestUpdatesProvider(widget.weddingId));

    return Scaffold(
      backgroundColor: _P.bg,
      body: RefreshIndicator(
        color: _P.primary,
        onRefresh: _onRefresh,
        child: weddingAsync.when(
          data: (wedding) {
            final countdownState = ref.watch(countdownProvider(wedding.date)).value;

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // HEADER — Bonjour Invité / menu / langue / avatar
                SliverToBoxAdapter(
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: _GuestHeader(),
                    ),
                  ),
                ),

                // HERO COUPLE — seul visuel "mock-up" conservé (photo réelle du couple)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: _CoupleHero(
                      coupleNames: wedding.coupleNames,
                      welcomeMessage: wedding.welcomeMessage,
                      coverImageUrl: wedding.coverImageUrl,
                      countdownState: countdownState,
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 18)),

                // EN UN COUP D'OEIL — stats de l'événement
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: _SectionHeader(icon: Icons.insights_rounded, title: 'En un coup d\'œil'),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 10)),
                SliverToBoxAdapter(
                  child: statsAsync.when(
                    data: (stats) => _StatsRow(stats: stats),
                    loading: () => const SizedBox(height: 78),
                    error: (_, __) => const SizedBox(),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 22)),

                // GRILLE MENU — 12 cartes compactes, badges d'icônes colorés
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: _SectionHeader(title: 'Toutes les rubriques'),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 10)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.32,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = _kGuestMenu[index];
                        return _GuestMenuTile(
                          item: item,
                          onTap: () => context.push('/thix-weeding/guest/${widget.weddingId}/${item.route}'),
                        );
                      },
                      childCount: _kGuestMenu.length,
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 22)),

                // NOS PRESTATAIRES
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: _SectionHeader(title: 'Nos prestataires'),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 10)),
                SliverToBoxAdapter(
                  child: vendorsAsync.when(
                    data: (vendors) => _VendorsList(vendors: vendors, onTap: _onTapGeneric),
                    loading: () => const SizedBox(height: 208, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                    error: (_, __) => const SizedBox(),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 22)),

                // INFOS PRATIQUES
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: _SectionHeader(title: 'Infos pratiques'),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 10)),
                SliverToBoxAdapter(
                  child: updatesAsync.when(
                    data: (items) => _UpdatesList(items: items, onTap: _onTapGeneric),
                    loading: () => const SizedBox(height: 148, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                    error: (_, __) => const SizedBox(),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 22)),

                // BANDEAU ANNONCE PRINCIPALE
                if (wedding.hasAnnouncement)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _NewsBanner(text: wedding.announcement),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 14)),

                // BANDEAU DE CONFIANCE
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: _TrustRow(),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            );
          },
          loading: () => const CustomScrollView(
            slivers: [SliverFillRemaining(child: Center(child: CircularProgressIndicator(strokeWidth: 2)))],
          ),
          error: (e, _) => CustomScrollView(
            slivers: [SliverFillRemaining(child: Center(child: _ErrorView(error: e, weddingId: widget.weddingId)))],
          ),
        ),
      ),
      bottomNavigationBar: _GuestBottomNav(),
    );
  }
}

// ============================================================
// HEADER
// ============================================================
class _GuestHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundIconButton(icon: Icons.menu_rounded, onTap: () {}),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bonjour 👋', style: TextStyle(fontSize: 13, color: _P.inkSoft, fontWeight: FontWeight.w500)),
              Text('Invité 💗', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: _P.ink)),
            ],
          ),
        ),
        _RoundIconButton(
          onTap: () {},
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.language_rounded, size: 15, color: Color(0xFF1B3A6B)),
              Text('FR', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Color(0xFF1B3A6B))),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, border: Border.all(color: _P.border, width: 1)),
              child: const Icon(Icons.person_rounded, color: _P.inkSoft, size: 22),
            ),
            Positioned(
              top: -1,
              right: -1,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: _P.primary, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData? icon;
  final Widget? child;
  final VoidCallback onTap;
  const _RoundIconButton({this.icon, this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: Center(child: child ?? Icon(icon, size: 20, color: _P.ink)),
      ),
    );
  }
}

// ============================================================
// HERO COUPLE + COUNTDOWN
// ============================================================
class _CoupleHero extends StatelessWidget {
  final String coupleNames;
  final String welcomeMessage;
  final String coverImageUrl;
  final CountdownState? countdownState;

  const _CoupleHero({
    required this.coupleNames,
    required this.welcomeMessage,
    required this.coverImageUrl,
    required this.countdownState,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 0.93,
            child: Image.network(
              coverImageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: const Color(0xFFF3D9DC)),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.06), Colors.transparent, Colors.black.withOpacity(0.10)],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            top: 20,
            left: 20,
            right: 90,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coupleNames,
                  style: const TextStyle(fontFamily: 'Serif', fontSize: 30, color: _P.primary, fontWeight: FontWeight.w500, height: 1.1),
                ),
                const SizedBox(height: 8),
                Text(welcomeMessage, style: const TextStyle(color: _P.ink, fontSize: 13, height: 1.35, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Positioned(
            top: 18,
            right: 16,
            child: FilledButton.tonalIcon(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.92),
                foregroundColor: _P.ink,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              icon: const Icon(Icons.ios_share_rounded, size: 15),
              label: const Text('Partager', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
            ),
          ),
          Positioned(left: 12, right: 12, bottom: 14, child: _CountdownCard(state: countdownState)),
        ],
      ),
    );
  }
}

class _CountdownCard extends StatelessWidget {
  final CountdownState? state;
  const _CountdownCard({this.state});

  @override
  Widget build(BuildContext context) {
    if (state == null) return const SizedBox(height: 84);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(color: _P.primary, shape: BoxShape.circle),
            child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('JOUR J DANS', style: TextStyle(fontSize: 9.5, color: _P.inkSoft, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _CountItem(value: state!.days, label: 'Jours'),
                    _CountItem(value: state!.hours, label: 'Heures'),
                    _CountItem(value: state!.minutes, label: 'Minutes'),
                    _CountItem(value: state!.seconds, label: 'Secondes'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CountItem extends StatelessWidget {
  final int value;
  final String label;
  const _CountItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text('$value', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19, color: _P.ink)),
          Text(label, style: const TextStyle(fontSize: 9.5, color: _P.inkSoft, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ============================================================
// SECTION HEADER
// ============================================================
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  const _SectionHeader({required this.title, this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (icon != null) ...[Icon(icon, size: 16, color: _P.primary), const SizedBox(width: 6)],
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: _P.ink)),
          ],
        ),
        InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(6),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Text('Voir tout', style: TextStyle(fontSize: 12, color: _P.primary, fontWeight: FontWeight.w600)),
                Icon(Icons.chevron_right_rounded, size: 15, color: _P.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// STATS ROW
// ============================================================
class _StatsRow extends StatelessWidget {
  final Map<String, int> stats;
  const _StatsRow({required this.stats});

  static const _icons = {
    'Invités confirmés': Icons.how_to_reg_outlined,
    'En attente': Icons.hourglass_bottom_rounded,
    'Cadeaux reçus': Icons.card_giftcard_outlined,
    'Photos partagées': Icons.photo_camera_outlined,
  };

  static const _colors = {
    'Invités confirmés': _P.green,
    'En attente': _P.gold,
    'Cadeaux reçus': _P.purple,
    'Photos partagées': _P.blue,
  };

  @override
  Widget build(BuildContext context) {
    final entries = stats.entries.toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(entries.length, (i) {
          final e = entries[i];
          final color = _colors[e.key] ?? _P.primary;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i == entries.length - 1 ? 0 : 8),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: _P.border)),
              child: Column(
                children: [
                  Icon(_icons[e.key] ?? Icons.info_outline, size: 18, color: color),
                  const SizedBox(height: 6),
                  Text('${e.value}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _P.ink)),
                  const SizedBox(height: 2),
                  Text(e.key, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 8.5, color: _P.inkSoft, fontWeight: FontWeight.w500, height: 1.1)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ============================================================
// TUILE DE MENU
// ============================================================
class _GuestMenuTile extends StatelessWidget {
  final _GuestMenuItem item;
  final VoidCallback onTap;
  const _GuestMenuTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: _P.border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(color: item.color.withOpacity(0.13), shape: BoxShape.circle),
                  child: Icon(item.icon, color: item.color, size: 20),
                ),
                if (item.badgeType == _BadgeType.alert)
                  Positioned(top: -4, right: -4, child: _DotBadge(child: const Text('!', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w800)))),
                if (item.badgeType == _BadgeType.count)
                  Positioned(top: -4, right: -4, child: _DotBadge(child: Text('${item.badgeCount}', style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w800)))),
                if (item.badgeType == _BadgeType.live)
                  Positioned(
                    top: -2,
                    right: -30,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: _P.primary, borderRadius: BorderRadius.circular(6)),
                      child: const Text('LIVE', style: TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: _P.ink)),
            const SizedBox(height: 2),
            Text(item.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, color: _P.inkSoft, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _DotBadge extends StatelessWidget {
  final Widget child;
  const _DotBadge({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 17,
      height: 17,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: _P.primary, shape: BoxShape.circle),
      child: child,
    );
  }
}

// ============================================================
// NOS PRESTATAIRES
// ============================================================
class _VendorsList extends StatelessWidget {
  final List<Map<String, dynamic>> vendors;
  final void Function(String) onTap;
  const _VendorsList({required this.vendors, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 208,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: vendors.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final v = vendors[i];
          final colors = v['colors'] as List<Color>;
          return InkWell(
            onTap: () => onTap(v['name'] as String),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 158,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _P.border)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 100,
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          child: Center(child: Icon(v['icon'] as IconData, size: 32, color: Colors.white.withOpacity(0.9))),
                        ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.92), borderRadius: BorderRadius.circular(6)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, size: 12, color: _P.gold),
                                const SizedBox(width: 2),
                                Text('${v['rating']}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _P.ink)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(v['name'] as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _P.ink)),
                        Text(v['category'] as String, style: const TextStyle(fontSize: 10.5, color: _P.inkSoft, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.place_outlined, size: 11, color: _P.inkSoft),
                            const SizedBox(width: 2),
                            Expanded(child: Text(v['zone'] as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9.5, color: _P.inkSoft))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// INFOS PRATIQUES
// ============================================================
class _UpdatesList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final void Function(String) onTap;
  const _UpdatesList({required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 148,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final a = items[i];
          final tagColor = a['tagColor'] as Color;
          return InkWell(
            onTap: () => onTap(a['title'] as String),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 148,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _P.border)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 76,
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(color: tagColor.withOpacity(0.10), borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
                          child: Center(child: Icon(a['icon'] as IconData, size: 26, color: tagColor)),
                        ),
                        Positioned(
                          top: 7,
                          left: 7,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: tagColor, borderRadius: BorderRadius.circular(6)),
                            child: Text(a['tag'] as String, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.3)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(9, 7, 9, 9),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a['title'] as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: _P.ink)),
                        Text(a['subtitle'] as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: _P.inkSoft, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// BANDEAU ANNONCE PRINCIPALE
// ============================================================
class _NewsBanner extends StatelessWidget {
  final String text;
  const _NewsBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFFCE9EB), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(color: _P.primary, shape: BoxShape.circle),
            child: const Icon(Icons.notifications_rounded, color: Colors.white, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nouveauté !', style: TextStyle(color: _P.primaryDark, fontWeight: FontWeight.w700, fontSize: 12)),
                const SizedBox(height: 1),
                Text(text, style: const TextStyle(fontSize: 12.5, color: _P.ink, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          InkWell(
            onTap: () {},
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Voir tout', style: TextStyle(fontSize: 11.5, color: _P.primaryDark, fontWeight: FontWeight.w700)),
                Icon(Icons.chevron_right_rounded, size: 15, color: _P.primaryDark),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// BANDEAU DE CONFIANCE
// ============================================================
class _TrustRow extends StatelessWidget {
  const _TrustRow();

  static const _items = [
    {'icon': Icons.favorite_border_rounded, 'label': 'Merci pour\nvotre présence'},
    {'icon': Icons.lock_outline_rounded, 'label': 'Vos données\nprotégées'},
    {'icon': Icons.support_agent_rounded, 'label': 'Assistance\ndédiée'},
    {'icon': Icons.qr_code_rounded, 'label': 'Accès via\nQR / ID'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _P.border)),
      child: Row(
        children: _items.map((e) {
          return Expanded(
            child: Column(
              children: [
                Icon(e['icon'] as IconData, size: 20, color: _P.primary),
                const SizedBox(height: 6),
                Text(e['label'] as String, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, color: _P.inkSoft, fontWeight: FontWeight.w600, height: 1.2)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ============================================================
// BOTTOM NAV
// ============================================================
class _GuestBottomNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 62,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              const _NavItem(icon: Icons.home_rounded, label: 'Accueil', selected: true),
              const _NavItem(icon: Icons.event_outlined, label: 'Evènement'),
              _HeartNavButton(onTap: () {}),
              const _NavItem(icon: Icons.chat_bubble_outline_rounded, label: 'Messages'),
              const _NavItem(icon: Icons.person_outline_rounded, label: 'Profil'),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  const _NavItem({required this.icon, required this.label, this.selected = false});

  @override
  Widget build(BuildContext context) {
    final color = selected ? _P.primary : _P.inkSoft;
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 21, color: color),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 9.5, color: color, fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
        ],
      ),
    );
  }
}

class _HeartNavButton extends StatelessWidget {
  final VoidCallback onTap;
  const _HeartNavButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: _P.primary,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: _P.primary.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 22),
      ),
    );
  }
}

// ============================================================
// ERREUR
// ============================================================
class _ErrorView extends ConsumerWidget {
  final Object error;
  final String weddingId;
  const _ErrorView({required this.error, required this.weddingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline_rounded, size: 44, color: _P.inkSoft),
        const SizedBox(height: 12),
        Text(
          error is Failure ? (error as Failure).message : 'Erreur de chargement',
          textAlign: TextAlign.center,
          style: const TextStyle(color: _P.inkSoft),
        ),
        const SizedBox(height: 16),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _P.primary),
          onPressed: () => ref.invalidate(guestWeddingProvider(weddingId)),
          child: const Text('Réessayer'),
        ),
      ],
    );
  }
}
