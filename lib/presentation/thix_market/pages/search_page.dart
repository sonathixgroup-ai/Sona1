import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/search_provider.dart';
import '../widgets/search/filter_bottom_sheet.dart';
import '../widgets/product/product_card.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showRecentSearches = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SearchProvider>().loadRecentSearches();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchProvider = context.watch<SearchProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Icon(Icons.search, color: Colors.grey[400]),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  decoration: const InputDecoration(
                    hintText: 'Rechercher produits, boutiques...',
                    border: InputBorder.none,
                    isDense: true,
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
                  },
                ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.black),
            onPressed: () => _showFilterBottomSheet(context, searchProvider),
          ),
        ],
      ),
      body: _buildBody(searchProvider),
    );
  }

  Widget _buildBody(SearchProvider provider) {
    if (provider.isLoading) {
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

  Widget _buildRecentSearches(SearchProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recherches récentes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => provider.clearRecentSearches(),
                child: const Text('Effacer tout'),
              ),
            ],
          ),
        ),
        ...provider.recentSearches.map((search) => ListTile(
          leading: const Icon(Icons.history),
          title: Text(search),
          trailing: IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => provider.removeRecentSearch(search),
          ),
          onTap: () {
            _searchController.text = search;
            setState(() => _showRecentSearches = false);
            provider.searchProducts(search);
          },
        )),
        const Divider(),
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
                  _buildChip('Mode', Icons.checkroom),
                  _buildChip('Électronique', Icons.phone_android),
                  _buildChip('Maison', Icons.home),
                  _buildChip('Sport', Icons.sports_soccer),
                  _buildChip('Beauté', Icons.spa),
                  _buildChip('Auto', Icons.directions_car),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChip(String label, IconData icon) {
    return ActionChip(
      label: Text(label),
      avatar: Icon(icon, size: 16),
      onPressed: () {
        _searchController.text = label;
        setState(() => _showRecentSearches = false);
        context.read<SearchProvider>().searchProducts(label);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Aucun résultat trouvé',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez d\'autres mots-clés',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(SearchProvider provider) {
    if (provider.searchResults.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '${provider.totalResults} résultats trouvés',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: provider.searchResults.length,
            itemBuilder: (context, index) {
              final product = provider.searchResults[index];
              return ProductCard(
                product: product,
                onTap: () => _gotoProductDetail(product['id']),
              );
            },
          ),
        ),
      ],
    );
  }

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

  void _gotoProductDetail(String productId) {
    Navigator.pushNamed(context, '/product/$productId');
  }
}
