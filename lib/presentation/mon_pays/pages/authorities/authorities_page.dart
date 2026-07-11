// lib/presentation/mon_pays/pages/authorities/authorities_page.dart
// Liste complète des autorités avec filtres, recherche, favoris et pagination

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../utils/constants.dart';
import '../../providers/authorities_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../cards/authority_card.dart';
import 'authority_profile_page.dart';

class AuthoritiesPage extends ConsumerStatefulWidget {
  final String? initialCategory;

  const AuthoritiesPage({super.key, this.initialCategory});

  @override
  ConsumerState<AuthoritiesPage> createState() => _AuthoritiesPageState();
}

class _AuthoritiesPageState extends ConsumerState<AuthoritiesPage> {
  String _selectedCategory = 'Tous';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSearching = false;

  // Pagination
  static const int _pageSize = 20;
  int _currentPage = 0;
  List<Authority> _allAuthorities = [];
  bool _hasMore = true;
  bool _isLoadingMore = false;

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
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _isSearching) return;
    setState(() => _isLoadingMore = true);

    try {
      final service = ref.read(authoritiesServiceProvider);
      final allData = await service.getAuthorities(category: _selectedCategory);
      final start = _currentPage * _pageSize;
      final end = (start + _pageSize).clamp(0, allData.length);

      if (start >= allData.length) {
        setState(() => _hasMore = false);
      } else {
        final newItems = allData.sublist(start, end);
        setState(() {
          _allAuthorities.addAll(newItems);
          _currentPage++;
          _hasMore = end < allData.length;
        });
      }
    } catch (e) {
      // Gérer l'erreur
    } finally {
      setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchText = _searchController.text.trim();
    final isSearching = searchText.isNotEmpty;

    // Provider pour la recherche ou la liste
    final authoritiesAsync = ref.watch(
      isSearching
          ? searchAuthoritiesProvider(searchText)
          : authoritiesProvider(_selectedCategory),
    );

    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildCategoryFilters(),
          const Divider(height: 1),
          Expanded(
            child: authoritiesAsync.when(
              loading: () => _buildLoadingState(),
              error: (error, stack) => _buildErrorState(error),
              data: (authorities) => _buildAuthorityList(authorities, isSearching),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== APP BAR ====================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          const Icon(Icons.account_balance, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          const Text(
            'Autorités',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          // Compteur
          Consumer(
            builder: (context, ref, child) {
              final favorites = ref.watch(favoritesProvider);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '⭐ ${favorites.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      actions: [
        // Bouton favoris
        IconButton(
          icon: const Icon(Icons.favorite),
          onPressed: () => _showFavorites(context),
          tooltip: 'Mes favoris',
        ),
        // Bouton filtre
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: () => _showFilterDialog(context),
          tooltip: 'Filtres avancés',
        ),
        // Bouton rafraîchir
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            setState(() {
              _currentPage = 0;
              _allAuthorities = [];
              _hasMore = true;
            });
            ref.invalidate(authoritiesProvider(_selectedCategory));
          },
          tooltip: 'Rafraîchir',
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(4),
        child: Container(
          height: 3,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.3),
                Colors.white.withOpacity(0.1),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== SEARCH BAR ====================

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher une autorité, un titre...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _currentPage = 0;
                      _allAuthorities = [];
                      _hasMore = true;
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
        onChanged: (value) {
          setState(() {
            _isSearching = value.isNotEmpty;
            _currentPage = 0;
            _allAuthorities = [];
            _hasMore = true;
          });
        },
      ),
    );
  }

  // ==================== CATEGORY FILTERS ====================

  Widget _buildCategoryFilters() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        itemCount: MonPaysConstants.authorityCategories.length,
        itemBuilder: (context, index) {
          final category = MonPaysConstants.authorityCategories[index];
          final isSelected = category == _selectedCategory;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Text(
                category,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _selectedCategory = category;
                  _searchController.clear();
                  _currentPage = 0;
                  _allAuthorities = [];
                  _hasMore = true;
                });
                ref.invalidate(authoritiesProvider(category));
              },
              backgroundColor: Colors.grey.shade100,
              selectedColor: const Color(0xFF1A5276).withOpacity(0.12),
              checkmarkColor: const Color(0xFF1A5276),
              side: isSelected
                  ? const BorderSide(color: Color(0xFF1A5276), width: 1.5)
                  : BorderSide(color: Colors.grey.shade300, width: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: isSelected ? 2 : 0,
            ),
          );
        },
      ),
    );
  }

  // ==================== AUTHORITY LIST ====================

  Widget _buildAuthorityList(List<Authority> authorities, bool isSearching) {
    if (authorities.isEmpty) {
      return _buildEmptyState(isSearching);
    }

    // Si c'est une recherche, afficher tous les résultats
    if (isSearching) {
      return ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        itemCount: authorities.length,
        itemBuilder: (context, index) {
          final authority = authorities[index];
          return AuthorityCard(
            authority: authority,
            onTap: () {
              context.go('/mon-pays/authority/${authority.id}');
            },
          );
        },
      );
    }

    // Sinon, afficher avec pagination
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      itemCount: _allAuthorities.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _allAuthorities.length && _hasMore) {
          return _buildLoadingMoreIndicator();
        }
        if (index < _allAuthorities.length) {
          final authority = _allAuthorities[index];
          return AuthorityCard(
            authority: authority,
            onTap: () {
              context.go('/mon-pays/authority/${authority.id}');
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  // ==================== LOADING STATES ====================

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A5276)),
          ),
          SizedBox(height: 16),
          Text(
            'Chargement des autorités...',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A5276)),
          ),
        ),
      ),
    );
  }

  // ==================== ERROR STATE ====================

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              color: Colors.red.shade400,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _currentPage = 0;
                _allAuthorities = [];
                _hasMore = true;
              });
              ref.invalidate(authoritiesProvider(_selectedCategory));
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A5276),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== EMPTY STATE ====================

  Widget _buildEmptyState(bool isSearching) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.people_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            isSearching ? 'Aucun résultat trouvé' : 'Aucune autorité enregistrée',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSearching
                ? 'Essayez de modifier votre recherche'
                : 'Les autorités seront bientôt disponibles',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
          if (isSearching) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _currentPage = 0;
                  _allAuthorities = [];
                  _hasMore = true;
                });
              },
              icon: const Icon(Icons.clear),
              label: const Text('Effacer la recherche'),
            ),
          ],
        ],
      ),
    );
  }

  // ==================== FILTER DIALOG ====================

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Filtres avancés'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Filtre par parti politique
            const Text(
              'Parti politique',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                'Tous',
                'UDPS',
                'UNC',
                'PPRD',
                'AFDC',
                'AA',
              ].map((party) {
                return ChoiceChip(
                  label: Text(party),
                  selected: false,
                  onSelected: (_) {
                    // TODO: Implémenter le filtre par parti
                    Navigator.pop(ctx);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Filtre par province
            const Text(
              'Province',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                'Tous',
                'Kinshasa',
                'Lubumbashi',
                'Goma',
                'Bukavu',
                'Kisangani',
              ].map((province) {
                return ChoiceChip(
                  label: Text(province),
                  selected: false,
                  onSelected: (_) {
                    // TODO: Implémenter le filtre par province
                    Navigator.pop(ctx);
                  },
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  // ==================== FAVORITES BOTTOM SHEET ====================

  void _showFavorites(BuildContext context) {
    final favorites = ref.read(favoritesProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                final allAuthorities = snapshot.data!;
                final favAuthorities = allAuthorities
                    .where((a) => favorites.contains(a.id))
                    .toList();

                return Column(
                  children: [
                    // Handle
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '⭐ Mes favoris (${favAuthorities.length})',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (favAuthorities.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                ref.read(favoritesProvider.notifier).clearFavorites();
                                setState(() {});
                              },
                              child: const Text(
                                'Tout supprimer',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Divider(),
                    // Liste
                    Expanded(
                      child: favAuthorities.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.favorite_border,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Aucun favori',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Ajoutez vos autorités préférées',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
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
                                  context.go('/mon-pays/authority/${favAuthorities[i].id}');
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
