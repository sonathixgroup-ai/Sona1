// lib/presentation/thix_weeding/pages/guest/guest_home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/failure.dart';
import '../../data/repositories/wedding_repository_impl.dart';
import '../../providers/wedding_provider.dart';
import '../../providers/countdown_provider.dart';
import '../../providers/guest_menu_provider.dart';

class GuestHomePage extends ConsumerStatefulWidget {
  final String weddingId;
  const GuestHomePage({super.key, required this.weddingId});

  @override
  ConsumerState<GuestHomePage> createState() => _GuestHomePageState();
}

class _GuestHomePageState extends ConsumerState<GuestHomePage> {
  Future<void> _onRefresh() async {
    // Invalidation = re-fetch avec cache fallback
    ref.invalidate(guestWeddingProvider(widget.weddingId));
    // Attend le nouveau fetch
    await ref.read(guestWeddingProvider(widget.weddingId).future);
  }

  @override
  Widget build(BuildContext context) {
    final weddingAsync = ref.watch(guestWeddingProvider(widget.weddingId));

    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F7),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: weddingAsync.when(
          data: (wedding) {
            final countdownState = ref.watch(countdownProvider(wedding.date)).value;
            final menu = ref.watch(guestMenuProvider(widget.weddingId));

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // HERO COUPLE - comme maquette Sarah & David
                SliverAppBar(
                  expandedHeight: 380,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(wedding.coverImageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.pink.shade50)),
                        Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.2)]))),
                        Positioned(
                          top: 60,
                          left: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(wedding.coupleNames, style: const TextStyle(fontFamily: 'Serif', fontSize: 34, color: Color(0xFFB84B5A), fontWeight: FontWeight.w500)),
                              const SizedBox(height: 8),
                              SizedBox(width: 260, child: Text(wedding.welcomeMessage, style: const TextStyle(color: Colors.black87, fontSize: 14))),
                            ],
                          ),
                        ),
                        Positioned(top: 50, right: 16, child: FilledButton.tonalIcon(onPressed: () {}, icon: const Icon(Icons.share_outlined, size: 18), label: const Text('Partager'))),
                      ],
                    ),
                  ),
                ),

                // COUNTDOWN CARD - chevauche le hero
                SliverToBoxAdapter(
                  child: Transform.translate(
                    offset: const Offset(0, -30),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _CountdownCard(state: countdownState),
                    ),
                  ),
                ),

                // GRILLE MENU - 2 colonnes perf SliverGrid
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.35),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = menu[index];
                      return _GuestMenuTile(item: item, weddingId: widget.weddingId);
                    }, childCount: menu.length),
                  ),
                ),

                // BANNER ANNONCE
                SliverToBoxAdapter(
                  child: wedding.hasAnnouncement
                     ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: _NewsBanner(text: wedding.announcement),
                        )
                      : const SizedBox(height: 24),
                ),
              ],
            );
          },
          loading: () => const CustomScrollView(slivers: [SliverFillRemaining(child: Center(child: CircularProgressIndicator()))]),
          error: (e, _) => CustomScrollView(slivers: [SliverFillRemaining(child: Center(child: _ErrorView(error: e, weddingId: widget.weddingId)))]),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Accueil'),
          NavigationDestination(icon: Icon(Icons.event_outlined), label: 'Événement'),
          NavigationDestination(icon: Icon(Icons.favorite, color: Colors.pink), label: ''),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Messages'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profil'),
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
    if (state == null) return const SizedBox(height: 90);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _CountItem(icon: Icons.calendar_today, value: state!.days, label: 'Jours'),
            _CountItem(value: state!.hours, label: 'Heures'),
            _CountItem(value: state!.minutes, label: 'Minutes'),
            _CountItem(value: state!.seconds, label: 'Secondes'),
          ],
        ),
      ),
    );
  }
}

class _CountItem extends StatelessWidget {
  final IconData? icon;
  final int value;
  final String label;
  const _CountItem({this.icon, required this.value, required this.label});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      if (icon!= null) CircleAvatar(radius: 18, backgroundColor: const Color(0xFFE25A6A), child: Icon(icon, size: 16, color: Colors.white)),
      if (icon!= null) const SizedBox(height: 6),
      Text('$value', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
    ]);
  }
}

class _GuestMenuTile extends StatelessWidget {
  final dynamic item;
  final String weddingId;
  const _GuestMenuTile({required this.item, required this.weddingId});
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Pas de context async
          context.push('/thix-weeding/guest/$weddingId/${item.routeName}');
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(children: [
                CircleAvatar(backgroundColor: item.bgColor, child: Icon(item.icon, color: item.iconColor)),
                if (item.badge!= null) Positioned(right: 0, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: Text(item.badge!, style: const TextStyle(fontSize: 8, color: Colors.white)))),
              ]),
              const Spacer(),
              Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(item.subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewsBanner extends StatelessWidget {
  final String text;
  const _NewsBanner({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFFFF0F2), borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Color(0xFFE25A6A), shape: BoxShape.circle), child: const Icon(Icons.notifications, color: Colors.white, size: 18)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Nouveauté!', style: TextStyle(color: Color(0xFFE25A6A), fontWeight: FontWeight.bold, fontSize: 12)), Text(text, style: const TextStyle(fontSize: 13))])),
        const Icon(Icons.chevron_right, color: Color(0xFFE25A6A)),
      ]),
    );
  }
}

class _ErrorView extends ConsumerWidget {
  final Object error;
  final String weddingId;
  const _ErrorView({required this.error, required this.weddingId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline, size: 48, color: Colors.grey),
      const SizedBox(height: 12),
      Text(error is Failure? (error as Failure).message : 'Erreur de chargement', textAlign: TextAlign.center),
      const SizedBox(height: 16),
      FilledButton(onPressed: () => ref.invalidate(guestWeddingProvider(weddingId)), child: const Text('Réessayer')),
    ]);
  }
}
