// lib/presentation/education/screens/education_home.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../widgets/common/education_category_chip.dart';
import '../widgets/common/education_loading_shimmer.dart';
import '../widgets/education_carousel.dart';
import '../widgets/recommendations/recommendation_carousel.dart';
import '../widgets/formation_card.dart';
import '../../../providers/education_provider.dart';
import '../../../providers/recommendation_provider.dart';

class EducationHome extends StatefulWidget {
  const EducationHome({super.key});

  @override
  State<EducationHome> createState() => _EducationHomeState();
}

class _EducationHomeState extends State<EducationHome> {
  String _selectedCategory = 'all';
  final ScrollController _scrollController = ScrollController();

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
    final educationProvider = context.read<EducationProvider>();
    await educationProvider.loadFormations();
    await educationProvider.loadCategories();
    final recommendationProvider = context.read<RecommendationProvider>();
    await recommendationProvider.loadRecommendations(userId);
  }

  @override
  Widget build(BuildContext context) {
    final educationProvider = context.watch<EducationProvider>();
    final categories = educationProvider.categories;
    final featuredFormations = educationProvider.formations.take(6).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: AppBar(
        title: const Text(
          'THIX Education',
          style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Color(0xFF1A1A2E)),
            onPressed: () => context.push('/education/search'),
          ),
        ],
      ),
      body: educationProvider.isLoading
          ? const EducationLoadingShimmer()
          : RefreshIndicator(
              color: const Color(0xFF2D6CDF),
              onRefresh: _loadData,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Bannière ou message de bienvenue
                          _buildWelcomeBanner(),
                          const SizedBox(height: 16),
                          // Catégories
                          _buildCategoryRow(categories),
                          const SizedBox(height: 16),
                          // Formations en vedette
                          if (featuredFormations.isNotEmpty) ...[
                            const Text(
                              'Formations en vedette',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A1A2E),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildFeaturedCarousel(featuredFormations),
                            const SizedBox(height: 24),
                          ],
                          // Recommandations personnalisées
                          if (educationProvider.myEnrollments.isNotEmpty)
                            RecommendationCarousel(
                              userId: Supabase.instance.client.auth.currentUser!.id,
                              limit: 6,
                            ),
                          const SizedBox(height: 16),
                          // Toutes les formations
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Toutes les formations',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1A1A2E),
                                ),
                              ),
                              TextButton(
                                onPressed: () => context.push('/education/all'),
                                child: const Text(
                                  'Voir tout',
                                  style: TextStyle(color: Color(0xFF2D6CDF), fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final formation = educationProvider.formations.elementAt(index);
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: FormationCard(
                            formation: formation,
                            onTap: () => context.push('/education/formation/${formation.id}'),
                          ),
                        );
                      },
                      childCount: educationProvider.formations.length,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            ),
    );
  }

  Widget _buildWelcomeBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A1F44), Color(0xFF2D6CDF)],
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
              children: const [
                Text(
                  'Apprenez à votre rythme',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Des formations premium pour booster vos compétences',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                SizedBox(height: 12),
                Text(
                  '🎓 50+ formations disponibles',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(Icons.school_rounded, color: Colors.white, size: 48),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(List<Category> categories) {
    if (categories.isEmpty) return const SizedBox();
    final displayed = [Category(id: 'all', name: 'Tous', description: '', createdAt: DateTime.now()), ...categories];
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: displayed.length,
        itemBuilder: (context, index) {
          final cat = displayed[index];
          final isSelected = _selectedCategory == cat.id;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: EducationCategoryChip(
              label: cat.name,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  _selectedCategory = cat.id;
                });
                final provider = context.read<EducationProvider>();
                provider.loadFormations(categoryId: cat.id == 'all' ? null : cat.id);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedCarousel(List<Formation> formations) {
    return SizedBox(
      height: 230,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: formations.length,
        itemBuilder: (context, index) {
          final formation = formations[index];
          return Container(
            width: 180,
            margin: const EdgeInsets.only(right: 12),
            child: FormationCard(
              formation: formation,
              onTap: () => context.push('/education/formation/${formation.id}'),
            ),
          );
        },
      ),
    );
  }
}
