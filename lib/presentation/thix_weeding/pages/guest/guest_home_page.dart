// lib/presentation/thix_weeding/pages/guest/guest_home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/failure.dart';
import '../../providers/wedding_provider.dart';
import '../../providers/countdown_provider.dart';

// ============================================================
// PALETTE — Charte THIX
// ============================================================
class _GuestPalette {
  static const bg = Color(0xFFFBF7F6);
  static const primary = Color(0xFFE25A6A);
  static const primaryDark = Color(0xFFC94356);
  static const ink = Color(0xFF1E1E24);
  static const inkSoft = Color(0xFF8B8B96);
  static const border = Color(0xFFF0EAEC);
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
  _GuestMenuItem(title: 'Invitation', subtitle: 'Voir les détails', icon: Icons.mail_outline_rounded, color: _GuestPalette.primary, route: 'invitation'),
  _GuestMenuItem(title: 'Programme', subtitle: 'Déroulé de la journée', icon: Icons.event_note_outlined, color: Color(0xFFE39A4B), route: 'programme'),
  _GuestMenuItem(title: 'Lieu & Accès', subtitle: 'Itinéraire & infos', icon: Icons.location_on_outlined, color: Color(0xFF5FAE72), route: 'lieu'),
  _GuestMenuItem(title: 'RSVP', subtitle: 'Confirmer ma présence', icon: Icons.people_alt_outlined, color: Color(0xFFA477D9), route: 'rsvp', badgeType: _BadgeType.alert),
  _GuestMenuItem(title: 'Liste de cadeaux', subtitle: 'Voir & contribuer', icon: Icons.card_giftcard_outlined, color: Color(0xFFDDAA3E), route: 'cadeaux'),
  _GuestMenuItem(title: 'Galerie', subtitle: 'Photos & vidéos', icon: Icons.photo_library_outlined, color: Color(0xFF5A94D6), route: 'galerie'),
  _GuestMenuItem(title: 'Livre d\'or', subtitle: 'Laisser un message', icon: Icons.edit_outlined, color: _GuestPalette.primary, route: 'livre-or'),
  _GuestMenuItem(title: 'Live', subtitle: 'Suivre en direct', icon: Icons.podcasts_outlined, color: Color(0xFFE07A6B), route: 'live', badgeType: _BadgeType.live),
  _GuestMenuItem(title: 'Annonces', subtitle: 'Infos importantes', icon: Icons.campaign_outlined, color: Color(0xFFA477D9), route: 'annonces', badgeType: _BadgeType.count, badgeCount: 3),
  _GuestMenuItem(title: 'FAQ', subtitle: 'Vos questions', icon: Icons.help_outline_rounded, color: Color(0xFF5A94D6), route: 'faq'),
  _GuestMenuItem(title: 'Nos remerciements', subtitle: 'Un mot pour vous', icon: Icons.volunteer_activism_outlined, color: Color(0xFF5FAE72), route: 'remerciements'),
  _GuestMenuItem(title: 'Plus', subtitle: 'Autres options', icon: Icons.more_horiz_rounded, color: Color(0xFF9A9AA5), route: 'plus'),
];

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

  @override
  Widget build(BuildContext context) {
    final weddingAsync = ref.watch(guestWeddingProvider(widget.weddingId));

    return Scaffold(
      backgroundColor: _GuestPalette.bg,
      body: RefreshIndicator(
        color: _GuestPalette.primary,
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

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // GRILLE MENU — 12 cartes compactes, badges d'icônes colorés
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

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // BANDEAU ANNONCE
                if (wedding.hasAnnouncement)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _NewsBanner(text: wedding.announcement),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 90)),
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
              Text('Bonjour 👋', style: TextStyle(fontSize: 13, color: _GuestPalette.inkSoft, fontWeight: FontWeight.w500)),
              Text(
                'Invité 💗',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: _GuestPalette.ink),
              ),
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
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: _GuestPalette.border, width: 1),
              ),
              child: const Icon(Icons.person_rounded, color: _GuestPalette.inkSoft, size: 22),
            ),
            Positioned(
              top: -1,
              right: -1,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _GuestPalette.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
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
        child: Center(child: child ?? Icon(icon, size: 20, color: _GuestPalette.ink)),
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
                  style: const TextStyle(
                    fontFamily: 'Serif',
                    fontSize: 30,
                    color: _GuestPalette.primary,
                    fontWeight: FontWeight.w500,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  welcomeMessage,
                  style: const TextStyle(color: _GuestPalette.ink, fontSize: 13, height: 1.35, fontWeight: FontWeight.w500),
                ),
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
                foregroundColor: _GuestPalette.ink,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              icon: const Icon(Icons.ios_share_rounded, size: 15),
              label: const Text('Partager', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 14,
            child: _CountdownCard(state: countdownState),
          ),
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
            decoration: const BoxDecoration(color: _GuestPalette.primary, shape: BoxShape.circle),
            child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('JOUR J DANS', style: TextStyle(fontSize: 9.5, color: _GuestPalette.inkSoft, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
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
          Text('$value', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19, color: _GuestPalette.ink)),
          Text(label, style: const TextStyle(fontSize: 9.5, color: _GuestPalette.inkSoft, fontWeight: FontWeight.w500)),
        ],
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _GuestPalette.border),
        ),
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
                      decoration: BoxDecoration(color: _GuestPalette.primary, borderRadius: BorderRadius.circular(6)),
                      child: const Text('LIVE', style: TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: _GuestPalette.ink)),
            const SizedBox(height: 2),
            Text(
              item.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10.5, color: _GuestPalette.inkSoft, fontWeight: FontWeight.w500),
            ),
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
      decoration: const BoxDecoration(color: _GuestPalette.primary, shape: BoxShape.circle),
      child: child,
    );
  }
}

// ============================================================
// BANDEAU ANNONCE
// ============================================================
class _NewsBanner extends StatelessWidget {
  final String text;
  const _NewsBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFCE9EB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(color: _GuestPalette.primary, shape: BoxShape.circle),
            child: const Icon(Icons.notifications_rounded, color: Colors.white, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nouveauté !', style: TextStyle(color: _GuestPalette.primaryDark, fontWeight: FontWeight.w700, fontSize: 12)),
                const SizedBox(height: 1),
                Text(text, style: const TextStyle(fontSize: 12.5, color: _GuestPalette.ink, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          InkWell(
            onTap: () {},
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Voir tout', style: TextStyle(fontSize: 11.5, color: _GuestPalette.primaryDark, fontWeight: FontWeight.w700)),
                Icon(Icons.chevron_right_rounded, size: 15, color: _GuestPalette.primaryDark),
              ],
            ),
          ),
        ],
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
    final color = selected ? _GuestPalette.primary : _GuestPalette.inkSoft;
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
          color: _GuestPalette.primary,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: _GuestPalette.primary.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))],
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
        const Icon(Icons.error_outline_rounded, size: 44, color: _GuestPalette.inkSoft),
        const SizedBox(height: 12),
        Text(
          error is Failure ? (error as Failure).message : 'Erreur de chargement',
          textAlign: TextAlign.center,
          style: const TextStyle(color: _GuestPalette.inkSoft),
        ),
        const SizedBox(height: 16),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _GuestPalette.primary),
          onPressed: () => ref.invalidate(guestWeddingProvider(weddingId)),
          child: const Text('Réessayer'),
        ),
      ],
    );
  }
}
