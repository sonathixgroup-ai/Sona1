// lib/presentation/mon_pays/pages/authorities/authorities_page.dart
// Liste complète des autorités avec filtres et recherche

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/constants.dart';
import '../../providers/authorities_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../cards/authority_card.dart';
import 'authority_profile_page.dart';

class AuthoritiesPage extends ConsumerStatefulWidget {
  const AuthoritiesPage({super.key});

  @override
  ConsumerState<AuthoritiesPage> createState() => _AuthoritiesPageState();
}

class _AuthoritiesPageState extends ConsumerState<AuthoritiesPage> {
  String _selectedCategory = 'Tous';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchText = _searchController.text.trim();
    final authoritiesAsync = ref.watch(
      searchText.isNotEmpty
          ? searchAuthoritiesProvider(searchText)
          : authoritiesProvider(_selectedCategory),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Autorités'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () {
              _showFavorites(context);
            },
            tooltip: 'Mes favoris',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher une autorité...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                suffixIcon: searchText.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filtres
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: MonPaysConstants.authorityCategories.length,
              itemBuilder: (context, index) {
                final category = MonPaysConstants.authorityCategories[index];
                final isSelected = category == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _selectedCategory = category;
                        _searchController.clear();
                      });
                    },
                    backgroundColor: Colors.grey.shade200,
                    selectedColor: const Color(0xFF1A5276).withOpacity(0.15),
                    labelStyle: TextStyle(
                      color: isSelected ? const Color(0xFF1A5276) : Colors.black87,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    side: isSelected
                        ? const BorderSide(color: Color(0xFF1A5276))
                        : BorderSide.none,
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          // Liste
          Expanded(
            child: authoritiesAsync.when(
              loading: () => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Chargement des autorités...'),
                  ],
                ),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Erreur: ${error.toString()}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(authoritiesProvider(_selectedCategory));
                      },
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
              data: (authorities) {
                if (authorities.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 48, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          'Aucun résultat trouvé',
                          style: TextStyle(color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Essayez de modifier votre recherche',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  itemCount: authorities.length,
                  itemBuilder: (context, index) {
                    final authority = authorities[index];
                    return AuthorityCard(
                      authority: authority,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AuthorityProfilePage(
                              authorityId: authority.id,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFavorites(BuildContext context) {
    final favorites = ref.read(favoritesProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: FutureBuilder(
              future: ref.read(authoritiesServiceProvider).getAuthorities(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final allAuthorities = snapshot.data!;
                final favAuthorities = allAuthorities
                    .where((a) => favorites.contains(a.id))
                    .toList();

                return Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '⭐ Mes favoris',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    Expanded(
                      child: favAuthorities.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.favorite_border, size: 48, color: Colors.grey),
                                  SizedBox(height: 12),
                                  Text(
                                    'Aucun favori',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Ajoutez vos autorités préférées',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: favAuthorities.length,
                              itemBuilder: (_, i) => AuthorityCard(
                                authority: favAuthorities[i],
                                onTap: () {
                                  Navigator.pop(ctx);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AuthorityProfilePage(
                                        authorityId: favAuthorities[i].id,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
