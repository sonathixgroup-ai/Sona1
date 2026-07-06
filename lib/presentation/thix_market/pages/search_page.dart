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

  static const Color primaryBlue = Color(0xFF1A73E8);
  static const Color bgLight = Color(0xFFF8F9FA);

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
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: Container(
          height: 46,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Icon(Icons.search, color: Colors.grey[500], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  decoration: const InputDecoration(
                    hintText: 'Rechercher produits, boutiques...',
                    border: InputBorder.none,
                    isDense: true,
                    hintStyle: TextStyle(fontSize: 14),
                  ),
                  onSubmitted: (value) {
                    setState(() => _showRecentSearches = false);
                    searchProvider.searchProducts(value);
                  },
                ),
              ),
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[400], size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _showRecentSearches = true);
                    // ✅ Utilisation de reset()
                    context.read<SearchProvider>().reset();
                  },
                ),
              const SizedBox(width: 4),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.black87),
            onPressed: () => _showFilterBottomSheet(context, searchProvider),
          ),
        ],
      ),
      body: _buildBody(searchProvider),
    );
  }

  Widget _buildBody(SearchProvider provider) {
    if (provider.isLoading && provider.searchResults.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_showRecentSearches && provider.recentSearches.isNotEmpty) {
      return _buildRecentSearches(provider);
    }

    if (provider.searchResults.isEmpty && _searchController.text.isNotEmpty) {
      return _buildEmptyState();
    }

    return _buildSearchResults(provider);
  }

  // ============================================================
  // RECHERCHES RÉCENTES
  // ============================================================
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
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => provider.clearRecentSearches(),
                child: const Text(
                  'Effacer tout',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ),
        ...provider.recentSearches.map((search) => ListTile(
          leading: const Icon(Icons.history, color: Colors.grey),
          title: Text(
            search,
            style: const TextStyle(fontSize: 14),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.close, size: 18, color: Colors.grey),
            onPressed: () => provider.removeRecentSearch(search),
          ),
          onTap: () {
            _searchController.text = search;
            setState(() => _showRecentSearches = false);
            provider.searchProducts(search);
          },
        )),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Suggestions de catégories',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildCategoryChip('Mode', Icons.checkroom),
                  _buildCategoryChip('Électronique', Icons.phone_android),
                  _buildCategoryChip('Maison', Icons.home),
                  _buildCategoryChip('Sport', Icons.sports_soccer),
                  _buildCategoryChip('Beauté', Icons.spa),
                  _buildCategoryChip('Auto', Icons.directions_car),
                  _buildCategoryChip('Immobilier', Icons.house),
                  _buildCategoryChip('Services', Icons.build),
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
      backgroundColor: Colors.white,
      side: BorderSide(color: Colors.grey[200]!),
      labelStyle: const TextStyle(fontSize: 13),
    );
  }

  // ============================================================
  // ÉTAT VIDE
  // ============================================================
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'Aucun résultat trouvé',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez d\'autres mots-clés',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              _searchController.clear();
              setState(() => _showRecentSearches = true);
              // ✅ Utilisation de reset()
              context.read<SearchProvider>().reset();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Nouvelle recherche'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RÉSULTATS DE RECHERCHE
  // ============================================================
  Widget _buildSearchResults(SearchProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Text(
                '${provider.totalResults} résultats',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _showFilterBottomSheet(context, provider),
                child: Row(
                  children: [
                    Icon(Icons.tune, size: 16, color: primaryBlue),
                    const SizedBox(width: 4),
                    Text(
                      'Filtrer',
                      style: TextStyle(color: primaryBlue, fontSize: 13),
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
              childAspectRatio: 0.7,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: provider.searchResults.length + (provider.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == provider.searchResults.length && provider.hasMore) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
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

  // ============================================================
  // FILTRES
  // ============================================================
  void _showFilterBottomSheet(BuildContext context, SearchProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => FilterBottomSheet(
        onApply: (filters) {
          provider.applyFilters(filters);
        },
        currentFilters: provider.currentFilters,
      ),
    );
  }
}
