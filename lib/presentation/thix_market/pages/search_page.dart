import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/search_provider.dart';
import '../widgets/search/filter_bottom_sheet.dart';
import '../widgets/products/product_card.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showRecentSearches = true;
  final ScrollController _scrollController = ScrollController();

  // ============================================================
  // CHARTE ÉLITE (identique à MarketHomePage)
  // ============================================================
  static const Color navyDeep = Color(0xFF0A1F44);
  static const Color navy = Color(0xFF123B7A);
  static const Color primaryBlue = Color(0xFF2D6CDF);
  static const Color softBlue = Color(0xFFEFF5FF);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color darkText = Color(0xFF10192E);
  static const Color mutedText = Color(0xFF7386A8);
  static const Color gold = Color(0xFFE3B23C);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SearchProvider>().loadRecentSearches();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final provider = context.read<SearchProvider>();
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (provider.hasMore && !provider.isLoading && _searchController.text.isNotEmpty) {
        provider.searchProducts(_searchController.text);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchProvider = context.watch<SearchProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: _buildAppBar(searchProvider),
      body: _buildBody(searchProvider),
    );
  }

  // ─── APP BAR (dégradé élite) ──────────────────────────────────────
  PreferredSizeWidget _buildAppBar(SearchProvider provider) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [navyDeep, navy, primaryBlue],
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      title: Container(
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Icon(Icons.search, color: Colors.white70, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Rechercher produits, boutiques...',
                  hintStyle: TextStyle(color: Colors.white60),
                  border: InputBorder.none,
                  isDense: true,
                ),
                onSubmitted: (value) {
                  setState(() => _showRecentSearches = false);
                  provider.searchProducts(value);
                },
              ),
            ),
            if (_searchController.text.isNotEmpty)
              IconButton(
                icon: Icon(Icons.clear, color: Colors.white70, size: 18),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _showRecentSearches = true);
                  context.read<SearchProvider>().reset();
                },
              ),
            const SizedBox(width: 4),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.tune_rounded, color: Colors.white),
          onPressed: () => _showFilterBottomSheet(context, provider),
        ),
      ],
    );
  }

  // ─── BODY ──────────────────────────────────────────────────────────
  Widget _buildBody(SearchProvider provider) {
    if (provider.isLoading && provider.searchResults.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: primaryBlue));
    }

    if (_showRecentSearches && provider.recentSearches.isNotEmpty) {
      return _buildRecentSearches(provider);
    }

    if (provider.searchResults.isEmpty && _searchController.text.isNotEmpty) {
      return _buildEmptyState();
    }

    return _buildSearchResults(provider);
  }

  // ─── RECHERCHES RÉCENTES ──────────────────────────────────────────
  Widget _buildRecentSearches(SearchProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recherches récentes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: darkText),
              ),
              TextButton(
                onPressed: () => provider.clearRecentSearches(),
                child: const Text(
                  'Effacer tout',
                  style: TextStyle(color: Color(0xFFFF5B3D), fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        ...provider.recentSearches.map((search) => ListTile(
          leading: const Icon(Icons.history, color: mutedText),
          title: Text(
            search,
            style: const TextStyle(fontSize: 14, color: darkText),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.close, size: 18, color: mutedText),
            onPressed: () => provider.removeRecentSearch(search),
          ),
          onTap: () {
            _searchController.text = search;
            setState(() => _showRecentSearches = false);
            provider.searchProducts(search);
          },
        )),
        const Divider(height: 1, color: softBlue),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Suggestions de catégories',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: darkText),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildCategoryChip('Mode', Icons.checkroom_rounded),
                  _buildCategoryChip('Électronique', Icons.phone_android_rounded),
                  _buildCategoryChip('Maison', Icons.chair_rounded),
                  _buildCategoryChip('Sport', Icons.sports_soccer_rounded),
                  _buildCategoryChip('Beauté', Icons.spa_rounded),
                  _buildCategoryChip('Auto', Icons.directions_car_rounded),
                  _buildCategoryChip('Immobilier', Icons.house_rounded),
                  _buildCategoryChip('Services', Icons.build_rounded),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String label, IconData icon) {
    return ActionChip(
      label: Text(label),
      avatar: Icon(icon, size: 16, color: primaryBlue),
      onPressed: () {
        _searchController.text = label;
        setState(() => _showRecentSearches = false);
        context.read<SearchProvider>().searchProducts(label);
      },
      backgroundColor: pureWhite,
      side: BorderSide(color: Colors.grey[200]!),
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: darkText),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  // ─── ÉTAT VIDE ─────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: mutedText),
          const SizedBox(height: 16),
          const Text(
            'Aucun résultat trouvé',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: darkText),
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez d\'autres mots-clés',
            style: TextStyle(color: mutedText),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              _searchController.clear();
              setState(() => _showRecentSearches = true);
              context.read<SearchProvider>().reset();
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Nouvelle recherche'),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: primaryBlue),
              foregroundColor: primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── RÉSULTATS DE RECHERCHE ──────────────────────────────────────
  Widget _buildSearchResults(SearchProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.transparent,
          child: Row(
            children: [
              Text(
                '${provider.totalResults} résultats',
                style: TextStyle(color: mutedText, fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _showFilterBottomSheet(context, provider),
                child: Row(
                  children: [
                    Icon(Icons.tune_rounded, size: 16, color: primaryBlue),
                    const SizedBox(width: 4),
                    Text(
                      'Filtrer',
                      style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.68,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: provider.searchResults.length + (provider.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == provider.searchResults.length && provider.hasMore) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(color: primaryBlue),
                  ),
                );
              }
              final product = provider.searchResults[index];
              return ProductCard(
                product: product,
                onTap: (_) => context.push('/market/product/${product['id']}'),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── FILTRES ──────────────────────────────────────────────────────
  void _showFilterBottomSheet(BuildContext context, SearchProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: pureWhite,
      builder: (context) => FilterBottomSheet(
        onApply: (filters) {
          provider.applyFilters(filters);
        },
        currentFilters: provider.currentFilters,
      ),
    );
  }
}
