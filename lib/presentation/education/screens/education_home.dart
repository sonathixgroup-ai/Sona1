// lib/presentation/education/screens/education_home.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:thix_id/presentation/education/providers/education_provider.dart';
import 'package:thix_id/presentation/education/providers/progress_provider.dart';
import 'package:thix_id/presentation/education/providers/certificate_provider.dart';
import 'package:thix_id/presentation/education/providers/recommendation_provider.dart';
import 'package:thix_id/presentation/education/widgets/education_carousel.dart';
import 'package:thix_id/presentation/education/widgets/common/education_category_chip.dart';
import 'package:thix_id/presentation/education/widgets/common/formation_card.dart';
import 'package:thix_id/presentation/education/widgets/recommendations/recommendation_carousel.dart';
import 'package:thix_id/presentation/education/models/category.dart';
import 'package:thix_id/presentation/education/models/formation.dart';
import 'package:thix_id/presentation/education/models/certificate.dart';

// ============================================================================
// CHARTE THIX EDUCATION — Élite Institutionnel Bleu / Blanc
// ============================================================================
class _EduColors {
  static const Color navyDeep = Color(0xFF0A1F44);
  static const Color navy = Color(0xFF123B7A);
  static const Color primaryBlue = Color(0xFF2D6CDF);
  static const Color softBlue = Color(0xFFEFF5FF);
  static const Color background = Color(0xFFF7FAFF);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color darkText = Color(0xFF10192E);
  static const Color mutedText = Color(0xFF7386A8);
  static const Color border = Color(0xFFE7EEFC);
  static const Color gold = Color(0xFFE3B23C);
  static const Color green = Color(0xFF10B981);
}

// ============================================================================
// PAGE PRINCIPALE AVEC BOTTOM NAVIGATION
// ============================================================================
class EducationHome extends StatefulWidget {
  const EducationHome({super.key});

  @override
  State<EducationHome> createState() => _EducationHomeState();
}

class _EducationHomeState extends State<EducationHome> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const _HomePage(),
    const _MyLearningPage(),
    const _AllFormationsPage(),
    const _CertificatesPage(),
    const _LibraryPage(),
    const _ProfilePage(),
  ];

  final List<String> _titles = [
    'Accueil',
    'Mes cours',
    'Apprendre',
    'Certificats',
    'Bibliothèque',
    'Profil',
  ];

  final List<IconData> _navIcons = [
    Icons.home_rounded,
    Icons.book_rounded,
    Icons.school_rounded,
    Icons.verified_rounded,
    Icons.library_books_rounded,
    Icons.person_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _EduColors.background,
      appBar: _buildAppBar(),
      body: _pages[_selectedIndex],
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // ============================================================
  // APP BAR — dégradé incurvé bleu institutionnel
  // ============================================================
  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(72),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_EduColors.navyDeep, _EduColors.navy, _EduColors.primaryBlue],
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(26),
            bottomRight: Radius.circular(26),
          ),
          boxShadow: [
            BoxShadow(color: Color(0x332D6CDF), blurRadius: 22, offset: Offset(0, 10)),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), borderRadius: BorderRadius.circular(10)),
                  child: Icon(_navIcons[_selectedIndex], size: 16, color: _EduColors.gold),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    _titles[_selectedIndex],
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                if (_selectedIndex == 0) _appBarIcon(Icons.search_rounded, () => context.push('/education/search')),
                _appBarIcon(Icons.notifications_none_rounded, () {}),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _appBarIcon(IconData icon, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(11),
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 17),
      ),
    );
  }

  // ============================================================
  // BOTTOM NAV — flottante, incurvée
  // ============================================================
  Widget _buildBottomNavBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      decoration: BoxDecoration(
        color: _EduColors.pureWhite,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(color: _EduColors.navyDeep.withOpacity(0.12), blurRadius: 22, offset: const Offset(0, 9)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_titles.length, (index) {
              return _navItem(
                _navIcons[index],
                _titles[index],
                _selectedIndex == index,
                () => setState(() => _selectedIndex = index),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: isSelected ? _EduColors.softBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: isSelected ? _EduColors.primaryBlue : _EduColors.mutedText, size: 20),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: isSelected ? _EduColors.primaryBlue : _EduColors.mutedText,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// PAGE 1 : ACCUEIL (AVEC BANNIÈRE À LA UNE)
// ============================================================================
class _HomePage extends StatefulWidget {
  const _HomePage();

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      final educationProvider = context.read<EducationProvider>();
      educationProvider.loadFormations();
      educationProvider.loadCategories();
      if (userId != null) {
        context.read<RecommendationProvider>().loadRecommendations(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final educationProvider = context.watch<EducationProvider>();
    final categories = educationProvider.categories;
    final formations = educationProvider.formations;
    final isLoading = educationProvider.isLoading;

    // Sélectionner la formation "À la une" (par exemple la plus récente, ou une formation spécifique)
    final featuredFormation = formations.isNotEmpty ? formations.first : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── BANNIÈRE À LA UNE ────────────────────────────
          if (featuredFormation != null)
            _FeaturedBanner(formation: featuredFormation)
          else
            Container(
              height: 130,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_EduColors.navyDeep, _EduColors.navy, _EduColors.primaryBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: _EduColors.navyDeep.withOpacity(0.18), blurRadius: 18, offset: const Offset(0, 9)),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: const Row(
                children: [
                  Expanded(
                    child: Text(
                      '🚀 À la une : Découvrez nos formations du moment !',
                      style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, height: 1.25),
                    ),
                  ),
                  Icon(Icons.trending_up_rounded, color: Colors.white, size: 38),
                ],
              ),
            ),
          const SizedBox(height: 22),

          // ─── CATÉGORIES ────────────────────────────────────
          const Text(
            'Catégories',
            style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: _EduColors.darkText),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                EducationCategoryChip(
                  label: 'Tous',
                  isSelected: _selectedCategory == 'all',
                  onTap: () {
                    setState(() => _selectedCategory = 'all');
                    educationProvider.loadFormations();
                  },
                ),
                ...categories.map((cat) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: EducationCategoryChip(
                      label: cat.name,
                      isSelected: _selectedCategory == cat.id,
                      onTap: () {
                        setState(() => _selectedCategory = cat.id);
                        educationProvider.loadFormations(categoryId: cat.id);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // ─── CONTINUER VOTRE APPRENTISSAGE ──────────────
          const Text(
            'Continuer votre apprentissage',
            style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: _EduColors.darkText),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _EduColors.pureWhite,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _EduColors.border),
              boxShadow: [
                BoxShadow(
                  color: _EduColors.navyDeep.withOpacity(0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_EduColors.softBlue, Color(0xFFE3EDFF)]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.play_circle_filled_rounded, color: _EduColors.primaryBlue, size: 36),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Flutter & Dart – Maîtrisez...',
                        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: _EduColors.darkText),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Progression : 65%',
                        style: TextStyle(fontSize: 12, color: _EduColors.mutedText, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          value: 0.65,
                          backgroundColor: _EduColors.softBlue,
                          color: _EduColors.primaryBlue,
                          minHeight: 7,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: _EduColors.softBlue, borderRadius: BorderRadius.circular(20)),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: _EduColors.navy),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // ─── FORMATIONS POPULAIRES ──────────────────────
          const Text(
            'Les plus populaires',
            style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: _EduColors.darkText),
          ),
          const SizedBox(height: 10),
          EducationCarousel(
            formations: formations.take(5).toList(),
          ),
          const SizedBox(height: 22),

          // ─── RECOMMANDATIONS ─────────────────────────────
          const Text(
            'Recommandé pour vous',
            style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: _EduColors.darkText),
          ),
          const SizedBox(height: 10),
          RecommendationCarousel(),
          const SizedBox(height: 22),

          // ─── TOUTES LES FORMATIONS (GRILLE) ─────────────
          const Text(
            'Toutes les formations',
            style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: _EduColors.darkText),
          ),
          const SizedBox(height: 10),
          if (formations.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(color: _EduColors.softBlue, shape: BoxShape.circle),
                      child: Icon(Icons.school_rounded, size: 32, color: _EduColors.navy.withOpacity(0.5)),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Aucune formation disponible pour le moment.',
                      style: TextStyle(color: _EduColors.mutedText),
                    ),
                  ],
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: formations.length,
              itemBuilder: (context, index) {
                final formation = formations[index];
                return FormationCard(
                  formation: formation,
                  onTap: () => context.push('/education/formation/${formation.id}'),
                );
              },
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── WIDGET BANNIÈRE À LA UNE ──────────────────────────────────────
class _FeaturedBanner extends StatelessWidget {
  final Formation formation;
  const _FeaturedBanner({required this.formation});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/education/formation/${formation.id}'),
      child: Container(
        height: 148,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_EduColors.navyDeep, _EduColors.navy, _EduColors.primaryBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _EduColors.navyDeep.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _EduColors.gold,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'À LA UNE',
                      style: TextStyle(
                        color: _EduColors.navyDeep,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formation.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 16),
                      const SizedBox(width: 4),
                      Text(
                        formation.rating.toStringAsFixed(1),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 12),
                      if (!formation.isFree)
                        Text(
                          '${formation.price.toInt()} ${formation.currency}',
                          style: const TextStyle(color: Color(0xFFCBD5E1), fontWeight: FontWeight.w700),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Gratuit',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.18)),
              ),
              child: formation.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.network(
                        formation.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.image_rounded, color: Colors.white38, size: 38),
                      ),
                    )
                  : const Icon(Icons.school_rounded, color: Colors.white38, size: 38),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// PAGE 2 : MES COURS
// ============================================================================
class _MyLearningPage extends StatefulWidget {
  const _MyLearningPage();

  @override
  State<_MyLearningPage> createState() => _MyLearningPageState();
}

class _MyLearningPageState extends State<_MyLearningPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final provider = context.read<EducationProvider>();
    await provider.loadMyEnrollments(userId);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EducationProvider>();
    final enrollments = provider.myEnrollments;

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator(color: _EduColors.primaryBlue));
    }

    if (enrollments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(color: _EduColors.softBlue, shape: BoxShape.circle),
              child: Icon(Icons.book_rounded, size: 36, color: _EduColors.navy.withOpacity(0.5)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucune formation en cours',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _EduColors.darkText),
            ),
            const SizedBox(height: 8),
            const Text(
              'Inscrivez-vous à une formation pour commencer',
              style: TextStyle(color: _EduColors.mutedText),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: enrollments.length,
      itemBuilder: (context, index) {
        final enrollment = enrollments[index];
        final formation = enrollment.formation;
        if (formation == null) return const SizedBox();
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: FormationCard(
            formation: formation,
            onTap: () => context.push('/education/formation/${formation.id}'),
            progress: enrollment.progress,
          ),
        );
      },
    );
  }
}

// ============================================================================
// PAGE 3 : APPRENDRE (TOUTES LES FORMATIONS)
// ============================================================================
class _AllFormationsPage extends StatefulWidget {
  const _AllFormationsPage();

  @override
  State<_AllFormationsPage> createState() => _AllFormationsPageState();
}

class _AllFormationsPageState extends State<_AllFormationsPage> {
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EducationProvider>().loadFormations();
      context.read<EducationProvider>().loadCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EducationProvider>();
    final categories = provider.categories;
    final formations = provider.formations;

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator(color: _EduColors.primaryBlue));
    }

    return Column(
      children: [
        const SizedBox(height: 4),
        // Barre de catégories
        SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length + 1,
            itemBuilder: (context, index) {
              final cat = index == 0
                  ? Category(id: 'all', name: 'Tous', icon: null, createdAt: DateTime.now())
                  : categories[index - 1];
              final isSelected = _selectedCategory == cat.id;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: EducationCategoryChip(
                  label: cat.name,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() => _selectedCategory = cat.id);
                    provider.loadFormations(
                      categoryId: cat.id == 'all' ? null : cat.id,
                    );
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // Liste
        Expanded(
          child: formations.isEmpty
              ? const Center(
                  child: Text(
                    'Aucune formation disponible',
                    style: TextStyle(color: _EduColors.mutedText),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: formations.length,
                  itemBuilder: (context, index) {
                    final formation = formations[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: FormationCard(
                        formation: formation,
                        onTap: () => context.push('/education/formation/${formation.id}'),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ============================================================================
// PAGE 4 : CERTIFICATS
// ============================================================================
class _CertificatesPage extends StatefulWidget {
  const _CertificatesPage();

  @override
  State<_CertificatesPage> createState() => _CertificatesPageState();
}

class _CertificatesPageState extends State<_CertificatesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCertificates();
    });
  }

  Future<void> _loadCertificates() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final provider = context.read<CertificateProvider>();
    await provider.loadCertificates(userId);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CertificateProvider>();
    final certificates = provider.certificates;

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator(color: _EduColors.primaryBlue));
    }

    if (certificates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(color: _EduColors.softBlue, shape: BoxShape.circle),
              child: Icon(Icons.verified_rounded, size: 36, color: _EduColors.navy.withOpacity(0.5)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucun certificat',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _EduColors.darkText),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Terminez une formation certifiante pour obtenir votre certificat',
                textAlign: TextAlign.center,
                style: TextStyle(color: _EduColors.mutedText),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: certificates.length,
      itemBuilder: (context, index) {
        final cert = certificates[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _EduColors.pureWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _EduColors.border),
            boxShadow: [
              BoxShadow(color: _EduColors.navyDeep.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 6)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_EduColors.navyDeep, _EduColors.primaryBlue],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: _EduColors.primaryBlue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
                  ],
                ),
                child: const Icon(Icons.verified_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Certificat',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _EduColors.darkText),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Délivré le ${cert.issuedAt.day}/${cert.issuedAt.month}/${cert.issuedAt.year}',
                      style: const TextStyle(fontSize: 12, color: _EduColors.mutedText),
                    ),
                    Text(
                      'ID: ${cert.verificationHash.substring(0, 8)}...',
                      style: const TextStyle(fontSize: 11, color: _EduColors.mutedText),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(color: _EduColors.softBlue, borderRadius: BorderRadius.circular(20)),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.chevron_right_rounded, color: _EduColors.navy, size: 20),
                  onPressed: () => context.push('/education/certificate/${cert.id}', extra: cert),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================================
// PAGE 5 : BIBLIOTHÈQUE (PLACEHOLDER)
// ============================================================================
class _LibraryPage extends StatelessWidget {
  const _LibraryPage();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: const BoxDecoration(color: _EduColors.softBlue, shape: BoxShape.circle),
            child: Icon(Icons.library_books_rounded, size: 40, color: _EduColors.navy.withOpacity(0.5)),
          ),
          const SizedBox(height: 16),
          const Text(
            'Bibliothèque',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: _EduColors.darkText),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bientôt disponible',
            style: TextStyle(color: _EduColors.mutedText),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// PAGE 6 : PROFIL AVEC BASCULEMENT MODE FORMATEUR
// ============================================================================
class _ProfilePage extends StatelessWidget {
  const _ProfilePage();

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [_EduColors.navyDeep, _EduColors.primaryBlue]),
                boxShadow: [
                  BoxShadow(color: _EduColors.primaryBlue.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8)),
                ],
              ),
              child: const Icon(Icons.person_rounded, size: 48, color: Colors.white),
            ),
            const SizedBox(height: 18),
            Text(
              user?.email ?? 'Utilisateur',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _EduColors.darkText),
            ),
            const SizedBox(height: 6),
            Text(
              'ID: ${user?.id ?? 'Non connecté'}',
              style: const TextStyle(color: _EduColors.mutedText, fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 26),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/profile'),
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Éditer le profil'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _EduColors.navyDeep,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/instructor/dashboard'),
                icon: const Icon(Icons.school_rounded),
                label: const Text('Passer en mode formateur'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _EduColors.green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            TextButton(
              onPressed: () {},
              child: const Text('Se déconnecter', style: TextStyle(color: Color(0xFFE5484D), fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
