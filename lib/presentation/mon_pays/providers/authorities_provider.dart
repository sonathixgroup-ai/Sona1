// lib/presentation/mon_pays/pages/authorities/authorities_page.dart
// Liste complète des autorités avec filtres, recherche, favoris et pagination
// Affichage des 4 plus hautes autorités (Président, Sénat, AN, Première Ministre)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../utils/constants.dart';
import '../../providers/authorities_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../models/authority.dart';
import '../../cards/authority_card.dart';

class AuthoritiesPage extends ConsumerStatefulWidget {
  final String? initialCategory;

  const AuthoritiesPage({super.key, this.initialCategory});

  @override
  ConsumerState<AuthoritiesPage> createState() => _AuthoritiesPageState();
}

class _AuthoritiesPageState extends ConsumerState<AuthoritiesPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _selectedCategory = 'Tous';

  static const Color navyDeep = Color(0xFF0A1F44);
  static const Color navy = Color(0xFF123B7A);
  static const Color gold = Color(0xFFE3B23C);
  static const Color ivory = Color(0xFFF6F7FB);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color darkText = Color(0xFF10182B);
  static const Color mutedText = Color(0xFF6B7690);
  static const Color danger = Color(0xFFD64545);
  static const Color hairline = Color(0xFFE7EAF3);

  // Les 4 titres principaux (pour l'affichage)
  static const Set<String> topTitles = {
    'Président de la République',
    'Président du Sénat',
    'Président de l\'Assemblée Nationale',
    'Première Ministre',
  };

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'Tous';
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final notifier = ref.read(authoritiesPaginatedProvider.notifier);
      notifier.loadNextPage();
    }
  }

  Future<void> _refreshData() async {
    final notifier = ref.read(authoritiesPaginatedProvider.notifier);
    await notifier.refreshData();
  }

  void _applyFilters() {
    final notifier = ref.read(authoritiesPaginatedProvider.notifier);
    final category = _selectedCategory == 'Tous' ? null : _selectedCategory;
    final search = _searchController.text.trim();
    notifier.loadFirstPage(
      category: category,
      search: search.isEmpty ? null : search,
      activeOnly: true, // On affiche que les actifs
    );
  }

  @override
  Widget build(BuildContext context) {
    final paginatedState = ref.watch(authoritiesPaginatedProvider);

    return Scaffold(
      backgroundColor: ivory,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildCategoryFilters(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshData,
              color: navy,
              child: paginatedState.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: navy),
                ),
                error: (error, _) => Center(
                  child: Text('Erreur: $error', style: const TextStyle(color: danger)),
                ),
                data: (result) {
                  if (result.data.isEmpty) {
                    return const Center(
                      child: Text('Aucune autorité enregistrée',
                          style: TextStyle(color: mutedText)),
                    );
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    itemCount: result.data.length + (result.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= result.data.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }
                      final authority = result.data[index];
                      return AuthorityCard(
                        authority: authority,
                        onTap: () => context.go('/mon-pays/authority/${authority.id}'),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: navyDeep,
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: gold.withOpacity(0.5)),
            ),
            child: const Icon(Icons.account_balance_rounded, color: gold, size: 16),
          ),
          const SizedBox(width: 10),
          const Text('Autorités', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: _refreshData,
          tooltip: 'Actualiser',
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Container(
        decoration: BoxDecoration(
          color: pureWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: hairline),
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Rechercher une autorité…',
            prefixIcon: const Icon(Icons.search_rounded, color: navy, size: 20),
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _applyFilters();
                    },
                  )
                : null,
          ),
          onChanged: (_) => _applyFilters(),
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: MonPaysConstants.authorityCategories.length,
        itemBuilder: (context, index) {
          final cat = MonPaysConstants.authorityCategories[index];
          final isSelected = cat == _selectedCategory;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(cat, style: TextStyle(color: isSelected ? gold : darkText, fontWeight: FontWeight.bold)),
              selected: isSelected,
              selectedColor: navyDeep,
              backgroundColor: pureWhite,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedCategory = cat;
                  });
                  _applyFilters();
                }
              },
            ),
          );
        },
      ),
    );
  }
}
