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

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: AppBar(
        title: const Text('Formations', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
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
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recommandations
                  RecommendationCarousel(), // ← supprimer const

                  // Catégories
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SingleChildScrollView(
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
                  ),
                  const SizedBox(height: 16),

                  // Carrousel des formations en vedette
                  EducationCarousel(formations: formations.take(5).toList()),

                  const SizedBox(height: 16),

                  // Liste des formations
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: formations.skip(5).map((formation) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: FormationCard(
                            formation: formation,
                            onTap: () => context.push('/education/formation/${formation.id}'),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
