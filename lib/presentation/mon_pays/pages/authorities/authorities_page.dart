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

  // Les 4 titres principaux à afficher
  static const Set<String> topTitles = {
    'Président de la République',
    'Président du Sénat',
    'Président de l\'Assemblée Nationale',
    'Première Ministre',
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Rafraîchir les données
  Future<void> _refreshData() async {
    ref.invalidate(topAuthoritiesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final searchText = _searchController.text.trim().toLowerCase();
    final authoritiesAsync = ref.watch(topAuthoritiesProvider);

    return Scaffold(
      backgroundColor: ivory,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          const SizedBox(height: 4),
          _buildSubtitle(),
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
                data: (authorities) {
                  // Filtre local par recherche
                  List<Authority> filtered = authorities;
                  if (searchText.isNotEmpty) {
                    filtered = authorities.where((a) =>
                      a.name.toLowerCase().contains(searchText) ||
                      a.title.toLowerCase().contains(searchText)
                    ).toList();
                  }
                  return _buildAuthorityList(filtered, searchText.isNotEmpty);
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
          const Text(
            'Hautes Autorités',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
          ),
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
                    onPressed: () => setState(() => _searchController.clear()),
                  )
                : null,
          ),
          onChanged: (_) => setState(() {}),
        ),
      ),
    );
  }

  Widget _buildSubtitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Président de la République • Président du Sénat • Président de l\'AN • Première Ministre',
              style: TextStyle(fontSize: 11, color: mutedText),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: navy.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '4 autorités',
              style: TextStyle(fontSize: 10, color: navy, fontWeight: FontWeight.w600),
            ),
          ),
        ],
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
              style: const TextStyle(fontWeight: FontWeight.bold, color: darkText),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
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
