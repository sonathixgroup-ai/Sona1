// lib/presentation/mon_pays/pages/authorities/authorities_page.dart

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
  String _selectedCategory = 'Tous';
  final TextEditingController _searchController = TextEditingController();

  static const Color navyDeep = Color(0xFF0A1F44);
  static const Color navy = Color(0xFF123B7A);
  static const Color primaryBlue = Color(0xFF2D6CDF);
  static const Color gold = Color(0xFFE3B23C);
  static const Color ivory = Color(0xFFF6F7FB);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color darkText = Color(0xFF10182B);
  static const Color mutedText = Color(0xFF6B7690);
  static const Color danger = Color(0xFFD64545);
  static const Color hairline = Color(0xFFE7EAF3);

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'Tous';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Permet de forcer le rechargement de la page pour éviter le cache
  Future<void> _refreshData() async {
    ref.invalidate(authoritiesProvider);
    ref.invalidate(searchAuthoritiesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final searchText = _searchController.text.trim();
    final isSearching = searchText.isNotEmpty;

    final authoritiesAsync = ref.watch(
      isSearching ? searchAuthoritiesProvider(searchText) : authoritiesProvider(_selectedCategory),
    );

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
              child: authoritiesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: navy),
                ),
                error: (error, _) => Center(
                  child: Text('Erreur: $error', style: const TextStyle(color: danger)),
                ),
                data: (authorities) => _buildAuthorityList(authorities, isSearching),
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
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(9), border: Border.all(color: gold.withOpacity(0.5))),
            child: const Icon(Icons.account_balance_rounded, color: gold, size: 16),
          ),
          const SizedBox(width: 10),
          const Text('Autorités', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
        ],
      ),
      actions: [
        // Bouton Rafraîchir pour nettoyer le cache
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
        decoration: BoxDecoration(color: pureWhite, borderRadius: BorderRadius.circular(14), border: Border.all(color: hairline)),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Rechercher une autorité, un titre…',
            prefixIcon: const Icon(Icons.search_rounded, color: navy, size: 20),
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _searchController.clear())) : null,
          ),
          onChanged: (v) => setState(() {}),
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
                    _searchController.clear();
                  });
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildAuthorityList(List<Authority> authorities, bool isSearching) {
    if (authorities.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          const Icon(Icons.people_outline_rounded, size: 48, color: mutedText),
          const SizedBox(height: 12),
          Center(
            child: Text(
              isSearching ? 'Aucun résultat trouvé' : 'Aucune autorité enregistrée', 
              style: const TextStyle(fontWeight: FontWeight.bold, color: darkText)
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(), // Important pour que le RefreshIndicator fonctionne
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      itemCount: authorities.length,
      itemBuilder: (context, index) {
        final authority = authorities[index];
        return AuthorityCard(
          authority: authority,
          onTap: () => context.go('/mon-pays/authority/${authority.id}'),
        );
      },
    );
  }
}
