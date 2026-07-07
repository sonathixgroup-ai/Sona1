// lib/presentation/education/screens/education_home.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:thix_id/presentation/education/providers/education_provider.dart';
import 'package:thix_id/presentation/education/providers/recommendation_provider.dart';
import 'package:thix_id/presentation/education/widgets/education_carousel.dart';
import 'package:thix_id/presentation/education/widgets/common/education_category_chip.dart';
import 'package:thix_id/presentation/education/widgets/common/formation_card.dart';
import 'package:thix_id/presentation/education/widgets/recommendations/recommendation_carousel.dart';
import 'package:thix_id/presentation/education/models/category.dart';
import 'package:thix_id/presentation/education/models/formation.dart';

class EducationHome extends StatefulWidget {
  const EducationHome({super.key});

  @override
  State<EducationHome> createState() => _EducationHomeState();
}

class _EducationHomeState extends State<EducationHome> {
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

    // Données fictives pour un rendu immédiat (si aucune donnée réelle)
    final sampleCategories = [
      Category(id: '1', name: 'Développement', icon: null, createdAt: DateTime.now()),
      Category(id: '2', name: 'Design', icon: null, createdAt: DateTime.now()),
      Category(id: '3', name: 'Marketing', icon: null, createdAt: DateTime.now()),
      Category(id: '4', name: 'Business', icon: null, createdAt: DateTime.now()),
      Category(id: '5', name: 'Santé', icon: null, createdAt: DateTime.now()),
    ];

    final sampleFormations = [
      Formation(
        id: '1',
        title: 'Flutter & Dart – Maîtrisez le développement mobile',
        description: 'Apprenez à créer des applications mobiles performantes avec Flutter.',
        categoryId: '1',
        instructorId: '1',
        level: 'intermediate',
        duration: 120,
        price: 49.99,
        status: 'published',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        instructor: 'Jean Dupont',
        rating: 4.8,
        reviewsCount: 125,
        imageUrl: 'https://via.placeholder.com/300x200?text=Flutter',
        isFree: false,
        isCertifying: true,
        durationHours: 2,
        difficulty: 'intermediate',
      ),
      Formation(
        id: '2',
        title: 'UI/UX Design – Les fondamentaux',
        description: 'Maîtrisez les bases du design d’interface et d’expérience utilisateur.',
        categoryId: '2',
        instructorId: '2',
        level: 'beginner',
        duration: 90,
        price: 0.0,
        status: 'published',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        instructor: 'Marie Martin',
        rating: 4.9,
        reviewsCount: 98,
        imageUrl: 'https://via.placeholder.com/300x200?text=UI/UX',
        isFree: true,
        isCertifying: false,
        durationHours: 1.5,
        difficulty: 'beginner',
      ),
      // Ajoutez d'autres formations pour le rendu...
    ];

    final displayCategories = categories.isEmpty ? sampleCategories : categories;
    final displayFormations = formations.isEmpty ? sampleFormations : formations;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Text(
              'Formations',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.search_rounded, color: Color(0xFF475569)),
              onPressed: () => context.push('/education/search'),
            ),
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFE2E8F0),
              child: const Icon(Icons.person, size: 18, color: Color(0xFF475569)),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: isLoading
          ? const _ShimmerLoading()
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Bannière promotionnelle ---
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E293B), Color(0xFF2D6CDF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '🚀 Boostez vos compétences',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Découvrez nos formations certifiantes et passez au niveau supérieur.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFFCBD5E1),
                                ),
                              ),
                              const SizedBox(height: 14),
                              ElevatedButton(
                                onPressed: () => context.push('/education/all'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF1E293B),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: const Text('Voir toutes les formations'),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.school_rounded,
                          size: 60,
                          color: Color(0xFFCBD5E1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Catégories (scroll horizontal) ---
                  const Text(
                    'Catégories',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
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
                        ...displayCategories.map((cat) {
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

                  // --- Continuer votre apprentissage (si l'utilisateur a des inscriptions) ---
                  // TODO: Implémenter avec les données réelles des inscriptions
                  // Pour l'instant, on affiche un placeholder
                  const Text(
                    'Continuer votre apprentissage',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
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
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Progression : 65%',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: const Color(0xFF475569),
                                ),
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

                  // --- Formations populaires (carrousel) ---
                  const Text(
                    'Les plus populaires',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  EducationCarousel(
                    formations: displayFormations.take(5).toList(),
                  ),
                  const SizedBox(height: 24),

                  // --- Recommandations personnalisées ---
                  const Text(
                    'Recommandé pour vous',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  RecommendationCarousel(),
                  const SizedBox(height: 24),

                  // --- Toutes les formations (grille) ---
                  const Text(
                    'Toutes les formations',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (displayFormations.isEmpty)
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
                      itemCount: displayFormations.length,
                      itemBuilder: (context, index) {
                        final formation = displayFormations[index];
                        return FormationCard(
                          formation: formation,
                          onTap: () => context.push('/education/formation/${formation.id}'),
                        );
                      },
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}

// ── Widget de chargement (shimmer) ──
class _ShimmerLoading extends StatelessWidget {
  const _ShimmerLoading();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bannière
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 24),
          // Catégories
          Container(
            height: 40,
            color: const Color(0xFFE2E8F0),
          ),
          const SizedBox(height: 24),
          // Titre
          Container(
            width: 200,
            height: 20,
            color: const Color(0xFFE2E8F0),
          ),
          const SizedBox(height: 12),
          // Carte de progression
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 24),
          // Carrousel
          Container(
            height: 200,
            color: const Color(0xFFE2E8F0),
          ),
          const SizedBox(height: 24),
          // Grille
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: 4,
            itemBuilder: (_, __) => Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
