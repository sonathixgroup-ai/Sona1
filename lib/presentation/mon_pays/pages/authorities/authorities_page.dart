// lib/presentation/mon_pays/pages/authorities/authorities_page.dart
// Liste complète des autorités avec filtres, recherche, favoris et pagination

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../utils/constants.dart';
import '../../providers/authorities_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../models/authority.dart';
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

  // ============================================================
  // CHARTE THIX ID — Design Institutionnel Premium (Navy / Bleu / Or)
  // ============================================================
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

    final authoritiesAsync = ref.watch(
      isSearching
          ? searchAuthoritiesProvider(searchText)
          : authoritiesProvider(_selectedCategory),
    );

    return Scaffold(
      backgroundColor: ivory,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildCategoryFilters(),
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

  // ============================================================
  // APP BAR — dégradé navy, compteur favoris en pilule or
  // ============================================================
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: navyDeep,
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [navyDeep, navy],
          ),
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: gold.withOpacity(0.5)),
            ),
            child: const Icon(Icons.account_balance_rounded, color: gold, size: 16),
          ),
          const SizedBox(width: 10),
          const Text(
            'Autorités',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const Spacer(),
          Consumer(
            builder: (context, ref, child) {
              final favorites = ref.watch(favoritesProvider);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: gold,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, size: 12, color: navyDeep),
                    const SizedBox(width: 4),
                    Text(
                      '${favorites.length}',
                      style: const TextStyle(color: navyDeep, fontSize: 11.5, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      actions: [
        _appBarIconButton(Icons.favorite_rounded, () => _showFavorites(context), tooltip: 'Mes favoris'),
        _appBarIconButton(Icons.filter_list_rounded, () => _showFilterDialog(context), tooltip: 'Filtres avancés'),
        _appBarIconButton(Icons.refresh_rounded, () {
          setState(() {
            _currentPage = 0;
            _allAuthorities = [];
            _hasMore = true;
          });
          ref.invalidate(authoritiesProvider(_selectedCategory));
        }, tooltip: 'Rafraîchir'),
        const SizedBox(width: 6),
      ],
    );
  }

  Widget _appBarIconButton(IconData icon, VoidCallback onTap, {String? tooltip}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Tooltip(
          message: tooltip ?? '',
          child: Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.16)),
            ),
            child: Icon(icon, size: 16, color: Colors.white),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BARRE DE RECHERCHE — carte blanche, coins arrondis
  // ============================================================
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      color: ivory,
      child: Container(
        decoration: BoxDecoration(
          color: pureWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: hairline),
          boxShadow: [BoxShadow(color: navyDeep.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(fontSize: 13, color: darkText, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: 'Rechercher une autorité, un titre…',
            hintStyle: const TextStyle(color: mutedText, fontSize: 12.5, fontWeight: FontWeight.w500),
            prefixIcon: const Icon(Icons.search_rounded, color: navy, size: 20),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18, color: mutedText),
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
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
      ),
    );
  }

  // ============================================================
  // FILTRES CATÉGORIES — chips navy plein quand actif
  // ============================================================
  Widget _buildCategoryFilters() {
    return Container(
      color: ivory,
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        height: 42,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          itemCount: MonPaysConstants.authorityCategories.length,
          itemBuilder: (context, index) {
            final category = MonPaysConstants.authorityCategories[index];
            final isSelected = category == _selectedCategory;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  setState(() {
                    _selectedCategory = category;
                    _searchController.clear();
                    _currentPage = 0;
                    _allAuthorities = [];
                    _hasMore = true;
                  });
                  ref.invalidate(authoritiesProvider(category));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
                  decoration: BoxDecoration(
                    color: isSelected ? navyDeep : pureWhite,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? navyDeep : hairline),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? gold : darkText,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // LISTE DES AUTORITÉS
  // ============================================================
  Widget _buildAuthorityList(List<Authority> authorities, bool isSearching) {
    if (authorities.isEmpty) {
      return _buildEmptyState(isSearching);
    }

    if (isSearching) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
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

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
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

  // ============================================================
  // ÉTATS DE CHARGEMENT
  // ============================================================
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primaryBlue)),
          SizedBox(height: 16),
          Text(
            'Chargement des autorités…',
            style: TextStyle(color: mutedText, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 18),
      child: Center(
        child: SizedBox(
          height: 22,
          width: 22,
          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(navy)),
        ),
      ),
    );
  }

  // ============================================================
  // ÉTAT D'ERREUR
  // ============================================================
  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: danger.withOpacity(0.08), shape: BoxShape.circle),
            child: const Icon(Icons.error_outline_rounded, color: danger, size: 42),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: mutedText, fontSize: 12.5, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 18),
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              setState(() {
                _currentPage = 0;
                _allAuthorities = [];
                _hasMore = true;
              });
              ref.invalidate(authoritiesProvider(_selectedCategory));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [navyDeep, navy]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh_rounded, size: 16, color: gold),
                  SizedBox(width: 8),
                  Text('Réessayer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ÉTAT VIDE
  // ============================================================
  Widget _buildEmptyState(bool isSearching) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(color: ivory, shape: BoxShape.circle),
            child: Icon(
              isSearching ? Icons.search_off_rounded : Icons.people_outline_rounded,
              size: 36,
              color: mutedText,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isSearching ? 'Aucun résultat trouvé' : 'Aucune autorité enregistrée',
            style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: darkText),
          ),
          const SizedBox(height: 6),
          Text(
            isSearching
                ? 'Essayez de modifier votre recherche'
                : 'Les autorités seront bientôt disponibles',
            style: const TextStyle(fontSize: 12, color: mutedText, fontWeight: FontWeight.w500),
          ),
          if (isSearching) ...[
            const SizedBox(height: 16),
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                setState(() {
                  _searchController.clear();
                  _currentPage = 0;
                  _allAuthorities = [];
                  _hasMore = true;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: ivory,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: hairline),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.clear_rounded, size: 15, color: navy),
                    SizedBox(width: 6),
                    Text('Effacer la recherche', style: TextStyle(color: navy, fontWeight: FontWeight.w700, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // DIALOGUE FILTRES AVANCÉS
  // ============================================================
  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(color: navyDeep, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.filter_list_rounded, size: 16, color: gold),
                  ),
                  const SizedBox(width: 10),
                  const Text('Filtres avancés', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: darkText)),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Parti politique', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: darkText)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['Tous', 'UDPS', 'UNC', 'PPRD', 'AFDC', 'AA'].map((party) {
                  return _filterChip(party, () => Navigator.pop(ctx));
                }).toList(),
              ),
              const SizedBox(height: 18),
              const Text('Province', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: darkText)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['Tous', 'Kinshasa', 'Lubumbashi', 'Goma', 'Bukavu', 'Kisangani'].map((province) {
                  return _filterChip(province, () => Navigator.pop(ctx));
                }).toList(),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Fermer', style: TextStyle(color: mutedText, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip(String label, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: ivory,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: hairline),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: darkText)),
      ),
    );
  }

  // ============================================================
  // BOTTOM SHEET FAVORIS
  // ============================================================
  void _showFavorites(BuildContext context) {
    final favorites = ref.read(favoritesProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: pureWhite,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: FutureBuilder(
              future: ref.read(authoritiesServiceProvider).getAuthorities(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(color: primaryBlue),
                    ),
                  );
                }
                final allAuthorities = snapshot.data!;
                final favAuthorities = allAuthorities
                    .where((a) => favorites.contains(a.id))
                    .toList();

                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: hairline, borderRadius: BorderRadius.circular(4)),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, size: 18, color: gold),
                              const SizedBox(width: 6),
                              Text(
                                'Mes favoris (${favAuthorities.length})',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: darkText),
                              ),
                            ],
                          ),
                          if (favAuthorities.isNotEmpty)
                            InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                ref.read(favoritesProvider.notifier).clearFavorites();
                                setState(() {});
                              },
                              child: const Text(
                                'Tout supprimer',
                                style: TextStyle(color: danger, fontWeight: FontWeight.w700, fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(height: 1, color: hairline, margin: const EdgeInsets.symmetric(horizontal: 18)),
                    Expanded(
                      child: favAuthorities.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(color: ivory, shape: BoxShape.circle),
                                    child: const Icon(Icons.favorite_border_rounded, size: 30, color: mutedText),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Aucun favori',
                                    style: TextStyle(fontSize: 14.5, color: darkText, fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Ajoutez vos autorités préférées',
                                    style: TextStyle(fontSize: 11.5, color: mutedText, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
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
