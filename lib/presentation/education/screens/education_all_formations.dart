// lib/presentation/education/screens/education_all_formations.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:thix_id/presentation/education/providers/education_provider.dart';
import 'package:thix_id/presentation/education/models/category.dart';
import 'package:thix_id/presentation/education/widgets/common/education_category_chip.dart';
import 'package:thix_id/presentation/education/widgets/common/education_loading_shimmer.dart';
import 'package:thix_id/presentation/education/widgets/common/formation_card.dart';

class EducationAllFormations extends StatefulWidget {
  const EducationAllFormations({super.key});

  @override
  State<EducationAllFormations> createState() => _EducationAllFormationsState();
}

class _EducationAllFormationsState extends State<EducationAllFormations> {
  String _selectedCategory = 'all';
  String _selectedLevel = 'all';

  // Catégorie "Tous" pour l'affichage (sans description, car le modèle n'en a pas)
  Category get _allCategory => Category(
        id: 'all',
        name: 'Tous',
        icon: null,
        createdAt: DateTime.now(),
        formations: null,
      );

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

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: AppBar(
        title: const Text(
          'Toutes les formations',
          style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1A2E)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded, color: Color(0xFF1A1A2E)),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: provider.isLoading
          ? const EducationLoadingShimmer()
          : Column(
              children: [
                // Barre de catégories
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: categories.length + 1,
                    itemBuilder: (context, index) {
                      final cat = index == 0
                          ? _allCategory
                          : categories[index - 1];
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
                            provider.loadFormations(
                              categoryId: cat.id == 'all' ? null : cat.id,
                              level: _selectedLevel == 'all' ? null : _selectedLevel,
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                // Liste des formations
                Expanded(
                  child: formations.isEmpty
                      ? Center(
                          child: Text(
                            'Aucune formation disponible',
                            style: TextStyle(color: const Color(0xFF7386A8)),
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
            ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrer', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Niveau', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildLevelChip('all', 'Tous'),
                _buildLevelChip('beginner', 'Débutant'),
                _buildLevelChip('intermediate', 'Intermédiaire'),
                _buildLevelChip('advanced', 'Avancé'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Appliquer'),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelChip(String value, String label) {
    final isSelected = _selectedLevel == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedLevel = value;
        });
        final provider = context.read<EducationProvider>();
        provider.loadFormations(
          categoryId: _selectedCategory == 'all' ? null : _selectedCategory,
          level: value == 'all' ? null : value,
        );
        Navigator.pop(context);
      },
      selectedColor: const Color(0xFF2D6CDF).withOpacity(0.1),
      checkmarkColor: const Color(0xFF2D6CDF),
    );
  }
}
