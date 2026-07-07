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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
          ),
        ),
        actions: [
          if (_selectedIndex == 0)
            IconButton(
              icon: const Icon(Icons.search_rounded, color: Color(0xFF475569)),
              onPressed: () => context.push('/education/search'),
            ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF475569)),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF2D6CDF),
        unselectedItemColor: const Color(0xFF64748B),
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_rounded),
            label: 'Mes cours',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school_rounded),
            label: 'Apprendre',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.verified_rounded),
            label: 'Certificats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books_rounded),
            label: 'Bibliothèque',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── BANNIÈRE À LA UNE ────────────────────────────
          // (Cette bannière pourra être gérée depuis l'espace instructeur plus tard)
          if (featuredFormation != null)
            _FeaturedBanner(formation: featuredFormation)
          else
            Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF2D6CDF)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(20),
              child: const Row(
                children: [
                  Expanded(
                    child: Text(
                      '🚀 À la une : Découvrez nos formations du moment !',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                  Icon(Icons.trending_up_rounded, color: Colors.white, size: 40),
                ],
              ),
            ),
          const SizedBox(height: 24),

          // ─── CATÉGORIES ────────────────────────────────────
          const Text(
            'Catégories',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 24),

          // ─── CONTINUER VOTRE APPRENTISSAGE ──────────────
          const Text(
            'Continuer votre apprentissage',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0A1F44).withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.play_circle_filled, color: Color(0xFF2D6CDF), size: 40),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Flutter & Dart – Maîtrisez...',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Progression : 65%',
                        style: TextStyle(fontSize: 13, color: const Color(0xFF475569)),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: 0.65,
                          backgroundColor: const Color(0xFFE2E8F0),
                          color: const Color(0xFF2D6CDF),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ─── FORMATIONS POPULAIRES ──────────────────────
          const Text(
            'Les plus populaires',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 12),
          EducationCarousel(
            formations: formations.take(5).toList(),
          ),
          const SizedBox(height: 24),

          // ─── RECOMMANDATIONS ─────────────────────────────
          const Text(
            'Recommandé pour vous',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 12),
          RecommendationCarousel(),
          const SizedBox(height: 24),

          // ─── TOUTES LES FORMATIONS (GRILLE) ─────────────
          const Text(
            'Toutes les formations',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 12),
          if (formations.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text(
                  'Aucune formation disponible pour le moment.',
                  style: TextStyle(color: Color(0xFF7386A8)),
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
        height: 140,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E293B), Color(0xFF2D6CDF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0A1F44).withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
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
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'À LA UNE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formation.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
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
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
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
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: formation.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        formation.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.image_rounded, color: Colors.white38, size: 40),
                      ),
                    )
                  : const Icon(Icons.school_rounded, color: Colors.white38, size: 40),
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
      return const Center(child: CircularProgressIndicator());
    }

    if (enrollments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book_rounded, size: 64, color: Color(0xFFD1D5DB)),
            SizedBox(height: 16),
            Text(
              'Aucune formation en cours',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
            ),
            SizedBox(height: 8),
            Text(
              'Inscrivez-vous à une formation pour commencer',
              style: TextStyle(color: Color(0xFF7386A8)),
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
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
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
                    style: TextStyle(color: Color(0xFF7386A8)),
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
      return const Center(child: CircularProgressIndicator());
    }

    if (certificates.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_rounded, size: 64, color: Color(0xFFD1D5DB)),
            SizedBox(height: 16),
            Text(
              'Aucun certificat',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
            ),
            SizedBox(height: 8),
            Text(
              'Terminez une formation certifiante pour obtenir votre certificat',
              style: TextStyle(color: Color(0xFF7386A8)),
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE7EEFC)),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2D6CDF), Color(0xFF123B7A)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.verified_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Certificat',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Délivré le ${cert.issuedAt.day}/${cert.issuedAt.month}/${cert.issuedAt.year}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF7386A8)),
                    ),
                    Text(
                      'ID: ${cert.verificationHash.substring(0, 8)}...',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF7386A8)),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, color: Color(0xFF7386A8)),
                onPressed: () => context.push('/education/certificate/${cert.id}', extra: cert),
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
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_books_rounded, size: 64, color: Color(0xFFD1D5DB)),
          SizedBox(height: 16),
          Text(
            'Bibliothèque',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
          ),
          SizedBox(height: 8),
          Text(
            'Bientôt disponible',
            style: TextStyle(color: Color(0xFF7386A8)),
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
            const CircleAvatar(
              radius: 48,
              backgroundColor: Color(0xFFE2E8F0),
              child: Icon(Icons.person, size: 48, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 16),
            Text(
              user?.email ?? 'Utilisateur',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            Text(
              'ID: ${user?.id ?? 'Non connecté'}',
              style: const TextStyle(color: Color(0xFF7386A8)),
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: () => context.push('/profile'),
              icon: const Icon(Icons.edit_rounded),
              label: const Text('Éditer le profil'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D6CDF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: () => context.push('/instructor/dashboard'),
              icon: const Icon(Icons.school_rounded),
              label: const Text('Passer en mode formateur'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
            const SizedBox(height: 12),

            TextButton(
              onPressed: () {},
              child: const Text('Se déconnecter', style: TextStyle(color: Color(0xFFEF4444))),
            ),
          ],
        ),
      ),
    );
  }
}
