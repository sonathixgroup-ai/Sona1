// lib/presentation/mon_pays/mon_pays_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/provinces_provider.dart';
import 'package:thix_id/presentation/mon_pays/providers/authorities_provider.dart';
import 'sections/authorities_section.dart';

class MonPaysPage extends ConsumerStatefulWidget {
  const MonPaysPage({super.key});
  @override
  ConsumerState<MonPaysPage> createState() => _MonPaysPageState();
}

class _MonPaysPageState extends ConsumerState<MonPaysPage> {
  static const Color primaryBlue = Color(0xFF0B3D91);
  static const Color lightBg = Color(0xFFF6F8FB);
  static const Color gold = Color(0xFFF7C948);
  static const Color rdcRed = Color(0xFFCE1126);
  static const Color mutedText = Color(0xFF6B7690);
  static const Color cardBorder = Color(0xFFEEF1F7);
  static const Color darkText = Color(0xFF10182B);

  final PageController _patrioticCtrl = PageController(viewportFraction: 0.92);
  Timer? _timer;
  int _currentPatriotic = 0;

  final List<Map<String, String>> patrioticPosters = [
    {'title': 'Unité Nationale', 'subtitle': 'Bendele ya Congo', 'img': 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4'},
    {'title': 'Devoir Civique', 'subtitle': 'S\'engager pour la Patrie', 'img': 'https://images.unsplash.com/photo-1529156069898-49953e39b3ac'},
    {'title': 'Mémoire Collective', 'subtitle': 'Honorer nos Héros', 'img': 'https://images.unsplash.com/photo-1497895121-66bdc4d7d3b2'},
    {'title': 'Travail et Progrès', 'subtitle': 'Bâtir la RDC', 'img': 'https://images.unsplash.com/photo-1516026672322-bc52d61a55e5'},
    {'title': 'Education pour Tous', 'subtitle': 'Avenir de la Nation', 'img': 'https://images.unsplash.com/photo-1503676260728-1c00da094a0b'},
    {'title': 'Paix et Sécurité', 'subtitle': 'Fondement du Développement', 'img': 'https://images.unsplash.com/photo-1447069387593-a5de0862481e'},
    {'title': 'Culture et Identité', 'subtitle': 'Notre Richesse', 'img': 'https://images.unsplash.com/photo-1533174072545-7a4b6ad7a6c3'},
    {'title': 'Jeunesse d\'Avenir', 'subtitle': 'Espoir de la République', 'img': 'https://images.unsplash.com/photo-1529390079861-591de354faf5'},
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (t) {
      if (_patrioticCtrl.hasClients) {
        _currentPatriotic = (_currentPatriotic + 1) % patrioticPosters.length;
        _patrioticCtrl.animateToPage(_currentPatriotic, duration: const Duration(milliseconds: 600), curve: Curves.easeInOut);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _patrioticCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      body: CustomScrollView(
        slivers: [
          _buildTopBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 12),
                _buildPatrioticCarousel(),
                const SizedBox(height: 20),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _buildAutoritesFullWidth()),
                const SizedBox(height: 20),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _buildAgencesFull()),
                const SizedBox(height: 20),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _buildALaUneFull()),
                const SizedBox(height: 20),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _buildProvincesSection()),
                const SizedBox(height: 20),
                _buildQuickAccess(),
                const SizedBox(height: 16),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _buildAlertRow()),
                const SizedBox(height: 20),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _buildFiguresHistoriquesBig()),
                const SizedBox(height: 20),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _buildCitoyensBanner()),
                const SizedBox(height: 110),
              ],
            ),
          )
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildTopBar() {
    return SliverAppBar(
      pinned: true,
      floating: true,
      elevation: 0,
      backgroundColor: Colors.white,
      toolbarHeight: 64,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          const Icon(Icons.menu, color: primaryBlue, size: 28),
          const SizedBox(width: 12),
          Container(
            width: 32, 
            height: 22, 
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(3), color: primaryBlue), 
            child: const Center(child: Text('CD', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)))
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('RÉPUBLIQUE DÉMOCRATIQUE\nDU CONGO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: primaryBlue, height: 1.1))
          ),
          _circleIcon(Icons.search, () => _showComingSoon()),
          const SizedBox(width: 8),
          Stack(
            clipBehavior: Clip.none, 
            children: [
              _circleIcon(Icons.notifications_none_rounded, () {}),
              Positioned(
                top: -4, 
                right: -4, 
                child: Container(
                  padding: const EdgeInsets.all(4), 
                  decoration: const BoxDecoration(color: gold, shape: BoxShape.circle), 
                  child: const Text('3', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold))
                )
              ),
            ]
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => context.push('/mon-pays/admin'), 
            child: const CircleAvatar(radius: 18, backgroundImage: NetworkImage('https://i.pravatar.cc/100'))
          ),
        ],
      ),
    );
  }

  Widget _circleIcon(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(8), 
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: cardBorder), color: Colors.white), 
        child: Icon(icon, size: 20, color: primaryBlue)
      ),
    );
  }

  Widget _buildPatrioticCarousel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: primaryBlue, borderRadius: BorderRadius.circular(14)),
          child: const Row(
            children: [
              Text('Espace Citoyen', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)), 
              SizedBox(width: 8), 
              Expanded(child: Text('Informer • Comprendre • Participer', style: TextStyle(color: gold, fontSize: 10, fontWeight: FontWeight.w600)))
            ]
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _patrioticCtrl,
            itemCount: patrioticPosters.length,
            onPageChanged: (v) => setState(() => _currentPatriotic = v),
            itemBuilder: (context, index) {
              final p = patrioticPosters[index];
              return Container(
                margin: const EdgeInsets.only(right: 12, left: 4),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), image: DecorationImage(image: NetworkImage(p['img']!), fit: BoxFit.cover)),
                child: Container(
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [primaryBlue.withOpacity(0.95), Colors.transparent])),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    mainAxisAlignment: MainAxisAlignment.center, 
                    children: [
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: gold, borderRadius: BorderRadius.circular(20)), child: Text(p['title']!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                      const SizedBox(height: 8),
                      Text(p['subtitle']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                    ]
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center, 
          children: List.generate(
            patrioticPosters.length, 
            (i) => Container(
              width: i == _currentPatriotic ? 18 : 6, 
              height: 6, 
              margin: const EdgeInsets.symmetric(horizontal: 3), 
              decoration: BoxDecoration(color: i == _currentPatriotic ? primaryBlue : Colors.grey.shade300, borderRadius: BorderRadius.circular(10))
            )
          )
        ),
      ],
    );
  }

  Widget _buildAutoritesFullWidth() {
    final authAsync = ref.watch(authoritiesProvider(null));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: cardBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Row(
            children: [
              const Text('1. Les Autorités', style: TextStyle(fontWeight: FontWeight.w900, color: primaryBlue, fontSize: 18)), 
              const Spacer(), 
              InkWell(
                onTap: () => context.push('/mon-pays/authorities'), 
                child: const Row(children: [Text('Voir tout', style: TextStyle(color: Color(0xFF5B8DEF), fontSize: 13)), Icon(Icons.chevron_right, size: 18, color: Color(0xFF5B8DEF))])
              )
            ]
          ),
          const SizedBox(height: 14),
          const Row(children: [Icon(Icons.account_balance, size: 18, color: primaryBlue), SizedBox(width: 6), Text('Hautes Autorités', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14))]),
          const SizedBox(height: 14),
          authAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            error: (e, s) => const Text('Erreur chargement autorités'),
            data: (authorities) {
              if (authorities.isEmpty) return const AuthoritiesSection();
              
              // ==========================================
              // LOGIQUE DE TRI INTELLIGENT (Système de priorité)
              // ==========================================
              int getPriority(String? title) {
                if (title == null) return 99; // Priorité la plus basse
                final t = title.toLowerCase();
                if (t.contains('président de la république') || t.contains('president de la republique')) return 1;
                if (t.contains('premier ministre')) return 2;
                if (t.contains('sénat') || t.contains('senat')) return 3;
                if (t.contains('assemblée') || t.contains('assemblee')) return 4;
                return 99; // Les autres ministres iront après
              }

              // On clone la liste et on la trie selon la fonction ci-dessus
              final sortedList = authorities.toList()
                ..sort((a, b) => getPriority(a.title).compareTo(getPriority(b.title)));

              // Le premier devient automatiquement le président (ou l'autorité la plus haute disponible)
              final president = sortedList.first;
              
              // On prend les 3 suivants maximum pour l'affichage de la grille
              final others = sortedList.length > 1 ? sortedList.sublist(1).take(3).toList() : [];
              // ==========================================

              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: lightBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: gold.withOpacity(0.6), width: 1.2)),
                    child: Row(
                      children: [
                        Container(padding: const EdgeInsets.all(3), decoration: const BoxDecoration(shape: BoxShape.circle, color: gold), child: CircleAvatar(radius: 42, backgroundImage: NetworkImage(president.imageUrl ?? 'https://i.pravatar.cc/200?u=president'))),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start, 
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: primaryBlue, borderRadius: BorderRadius.circular(20)), child: const Text('PRÉSIDENT DE LA RÉPUBLIQUE', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold))),
                              const SizedBox(height: 6),
                              Text(president.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: darkText)),
                              Text(president.title ?? 'Président de la République', style: const TextStyle(fontSize: 12, color: mutedText, fontWeight: FontWeight.w600)),
                            ]
                          )
                        ),
                      ]
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (others.isNotEmpty)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 0.85, crossAxisSpacing: 10, mainAxisSpacing: 10),
                      itemCount: others.length,
                      itemBuilder: (context, i) {
                        final a = others[i];
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(padding: const EdgeInsets.all(2.5), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: gold, width: 1.5)), child: CircleAvatar(radius: 34, backgroundImage: NetworkImage(a.imageUrl ?? 'https://i.pravatar.cc/100?u=$i'))),
                            const SizedBox(height: 6),
                            Text(a.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
                            Text(a.title ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, color: mutedText)),
                          ]
                        );
                      },
                    ),
                ]
              );
            },
          ),
        ]
      ),
    );
  }

  Widget _buildAgencesFull() {
    final items = [
      {'icon': Icons.account_balance, 'label': 'Présidence'},
      {'icon': Icons.flag, 'label': 'Gouvernement'},
      {'icon': Icons.gavel, 'label': 'Parlement'},
      {'icon': Icons.work, 'label': 'Ministères'},
      {'icon': Icons.map, 'label': 'Provinces', 'route': '/mon-pays/provinces'},
      {'icon': Icons.business, 'label': 'Entreprises Publiques'},
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: cardBorder)),
      child: Column(
        children: [
          Row(
            children: [
              const Text('4. Agences et Institutions', style: TextStyle(fontWeight: FontWeight.w900, color: primaryBlue, fontSize: 16)), 
              const Spacer(), 
              InkWell(onTap: () => _showComingSoon(), child: const Text('Explorer', style: TextStyle(color: Color(0xFF5B8DEF), fontSize: 13)))
            ]
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true, 
            physics: const NeverScrollableScrollPhysics(), 
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 1.2, crossAxisSpacing: 10, mainAxisSpacing: 10), 
            itemCount: items.length, 
            itemBuilder: (context, i) => InkWell(
              onTap: () => items[i]['route'] != null ? context.push(items[i]['route'] as String) : _showComingSoon(), 
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(padding: const EdgeInsets.all(14), decoration: const BoxDecoration(color: lightBg, shape: BoxShape.circle), child: Icon(items[i]['icon'] as IconData, color: primaryBlue)), 
                  const SizedBox(height: 6), 
                  Text(items[i]['label'] as String, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))
                ]
              )
            )
          ),
        ]
      ),
    );
  }

  Widget _buildALaUneFull() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: cardBorder)),
      child: Column(
        children: [
          Row(children: [const Text('3. À la Une', style: TextStyle(fontWeight: FontWeight.w900, color: primaryBlue, fontSize: 16)), const Spacer(), InkWell(onTap: () => _showComingSoon(), child: const Text('Voir toutes', style: TextStyle(color: Color(0xFF5B8DEF), fontSize: 13)))]),
          const SizedBox(height: 12),
          SizedBox(
            height: 165, 
            child: ListView.separated(
              scrollDirection: Axis.horizontal, 
              itemCount: 5, 
              separatorBuilder: (_, __) => const SizedBox(width: 10), 
              itemBuilder: (context, i) {
                return Container(
                  width: 140, 
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: lightBg), 
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(14)), child: Image.network('https://picsum.photos/200/120?random=$i', height: 90, width: 140, fit: BoxFit.cover)),
                      const Padding(
                        padding: EdgeInsets.all(8), 
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start, 
                          children: [Text('27 Mai 2025', style: TextStyle(fontSize: 9, color: mutedText)), SizedBox(height: 2), Text('Inauguration du Pont Maréchal', maxLines: 2, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700))]
                        )
                      )
                    ]
                  )
                );
              }
            )
          )
        ]
      ),
    );
  }

  Widget _buildProvincesSection() {
    final prov = ref.watch(provincesProvider(null));
    return prov.when(
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
      data: (list) {
        if (list.isEmpty) return const SizedBox();
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: cardBorder)),
          child: Column(
            children: [
              Row(children: [const Text('Provinces', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)), const Spacer(), InkWell(onTap: () => context.push('/mon-pays/provinces'), child: const Text('Voir toutes', style: TextStyle(color: primaryBlue)))]),
              const SizedBox(height: 10),
              SizedBox(
                height: 90, 
                child: ListView.separated(
                  scrollDirection: Axis.horizontal, 
                  itemCount: list.take(8).length, 
                  separatorBuilder: (_, __) => const SizedBox(width: 10), 
                  itemBuilder: (c, i) { 
                    final p = list[i]; 
                    return InkWell(
                      onTap: () => context.push('/mon-pays/provinces/${p.id}'), 
                      child: Container(
                        width: 120, 
                        padding: const EdgeInsets.all(10), 
                        decoration: BoxDecoration(color: lightBg, borderRadius: BorderRadius.circular(14)), 
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start, 
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(radius: 16, child: Text(p.code.substring(0, 2))), 
                            const Spacer(), 
                            Text(p.name, maxLines: 1, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), 
                            Text(p.capital, style: const TextStyle(fontSize: 9, color: mutedText))
                          ]
                        )
                      )
                    ); 
                  }
                )
              )
            ]
          ),
        );
      },
    );
  }

  Widget _buildQuickAccess() {
    final items = [
      {'icon': Icons.videocam_rounded, 'label': 'Vidéos Officielles'},
      {'icon': Icons.folder_rounded, 'label': 'Documentaires'},
      {'icon': Icons.emoji_events_rounded, 'label': 'Citoyens'},
      {'icon': Icons.balance_rounded, 'label': 'Valeurs et Lois', 'route': '/mon-pays/laws'},
      {'icon': Icons.campaign_rounded, 'label': 'Participer'},
    ];
    return SizedBox(
      height: 90, 
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16), 
        scrollDirection: Axis.horizontal, 
        itemCount: items.length, 
        separatorBuilder: (_, __) => const SizedBox(width: 10), 
        itemBuilder: (c, i) => InkWell( // <--- AJOUT DU BOUTON CLIQUABLE ICI
          onTap: () {
            if (items[i]['route'] != null) {
              context.push(items[i]['route'] as String);
            } else {
              _showComingSoon();
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 80, 
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: cardBorder)), 
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, 
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(items[i]['icon'] as IconData, color: primaryBlue), 
                const SizedBox(height: 6), 
                Text(items[i]['label'] as String, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600))
              ]
            )
          )
        )
      )
    );
  }

  Widget _buildAlertRow() => Row(
    children: [
      Expanded(child: _alertCard(rdcRed, 'Personne Recherchée', Icons.warning_amber_rounded)), 
      const SizedBox(width: 12), 
      Expanded(child: _alertCard(primaryBlue, 'Recherche Personnalisée', Icons.search_rounded))
    ]
  );
  
  Widget _alertCard(Color c, String t, IconData ic) => Container(
    padding: const EdgeInsets.all(12), 
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: cardBorder)), 
    child: Row(
      children: [
        Icon(ic, color: c), 
        const SizedBox(width: 8), 
        Expanded(child: Text(t, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: c)))
      ]
    )
  );

  Widget _buildFiguresHistoriquesBig() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: cardBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Row(children: [const Text('2. Figures Historiques', style: TextStyle(fontWeight: FontWeight.w900, color: primaryBlue, fontSize: 18)), const Spacer(), InkWell(onTap: () => _showComingSoon(), child: const Text('Explorer', style: TextStyle(color: Color(0xFF5B8DEF))))]),
          const SizedBox(height: 6),
          const Text('Découvrez ceux qui ont marqué notre histoire.', style: TextStyle(color: mutedText, fontSize: 12)),
          const SizedBox(height: 14),
          SizedBox(
            height: 180, 
            child: ListView.separated(
              scrollDirection: Axis.horizontal, 
              itemCount: 6, 
              separatorBuilder: (_, __) => const SizedBox(width: 12), 
              itemBuilder: (context, i) { 
                return Container(
                  width: 140, 
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: lightBg, border: Border.all(color: cardBorder)), 
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), child: Image.network('https://i.pravatar.cc/200?img=${30 + i}', height: 110, width: 140, fit: BoxFit.cover)), 
                      const SizedBox(height: 8), 
                      const Text('Patrice Lumumba', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), 
                      const Text('1960 - Héros National', style: TextStyle(fontSize: 10, color: mutedText))
                    ]
                  )
                ); 
              }
            )
          )
        ]
      ),
    );
  }

  Widget _buildCitoyensBanner() => Container(
    padding: const EdgeInsets.all(16), 
    decoration: BoxDecoration(color: primaryBlue, borderRadius: BorderRadius.circular(20)), 
    child: Row(
      children: [
        const Icon(Icons.star, color: gold, size: 28), 
        const SizedBox(width: 10), 
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Citoyens Exemplaires', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), Text('Ils bâtissent la RDC chaque jour', style: TextStyle(color: Colors.white70, fontSize: 11))])), 
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: gold, foregroundColor: primaryBlue), onPressed: () => _showComingSoon(), child: const Text('Découvrir'))
      ]
    )
  );

  Widget _buildBottomNav() => Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16), 
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), 
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20)]), 
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround, 
      children: [
        _nav(Icons.home_rounded, 'Accueil', '/'), 
        _nav(Icons.flag_rounded, 'Mon Pays', '/mon-pays'), 
        Container(padding: const EdgeInsets.all(12), decoration: const BoxDecoration(color: primaryBlue, shape: BoxShape.circle), child: const Icon(Icons.shield, color: gold)), 
        _nav(Icons.grid_view_rounded, 'Services', null), 
        _nav(Icons.person_rounded, 'Mon Compte', null)
      ]
    )
  );
  
  Widget _nav(IconData i, String l, String? r) => InkWell(
    onTap: () => r != null ? context.go(r) : _showComingSoon(), 
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(i, color: l == 'Mon Pays' ? primaryBlue : mutedText, size: 22), 
        Text(l, style: TextStyle(fontSize: 10, color: l == 'Mon Pays' ? primaryBlue : mutedText))
      ]
    )
  );

  void _showComingSoon() { 
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Module en cours'), backgroundColor: Colors.orange, duration: Duration(seconds: 1))); 
  }
}
