// lib/presentation/thix_event/event_search_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/event_provider.dart';
import '../../models/event_model.dart';
import 'widgets/event_card.dart';

class _ThixColors {
  static const Color primary = Color(0xFF6B3CE2);
  static const Color darkText = Color(0xFF1E1B4B);
  static const Color mutedText = Color(0xFF8B8BA7);
  static const Color lightBg = Color(0xFFF8F9FA);
}

class EventSearchPage extends StatefulWidget {
  const EventSearchPage({super.key});

  @override
  State<EventSearchPage> createState() => _EventSearchPageState();
}

class _EventSearchPageState extends State<EventSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<Event> _results = [];
  bool _isSearching = false;
  String _selectedFilter = 'all';
  String _selectedCity = 'all';

  final List<String> _cities = ['all', 'Kinshasa', 'Lubumbashi', 'Goma', 'Bukavu', 'Kisangani'];

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    final provider = context.read<EventProvider>();
    var results = await provider.searchEvents(query);
    
    if (_selectedCity != 'all') {
      results = results.where((e) => e.city == _selectedCity).toList();
    }
    
    setState(() {
      _results = results;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ThixColors.lightBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _ThixColors.darkText),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: _ThixColors.lightBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              onChanged: _performSearch,
              cursorColor: _ThixColors.primary,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _ThixColors.darkText),
              decoration: InputDecoration(
                hintText: 'Rechercher un événement, lieu...',
                hintStyle: const TextStyle(fontSize: 13, color: _ThixColors.mutedText, fontWeight: FontWeight.w400),
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: _ThixColors.mutedText),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18, color: _ThixColors.mutedText),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_searchController.text.isNotEmpty)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _buildModernChip('Tous', 'all', _selectedFilter, (val) => setState(() { _selectedFilter = val; _performSearch(_searchController.text); })),
                        const SizedBox(width: 8),
                        _buildModernChip('Aujourd\'hui', 'today', _selectedFilter, (val) => setState(() { _selectedFilter = val; _performSearch(_searchController.text); })),
                        const SizedBox(width: 8),
                        _buildModernChip('Cette semaine', 'week', _selectedFilter, (val) => setState(() { _selectedFilter = val; _performSearch(_searchController.text); })),
                        const SizedBox(width: 8),
                        _buildModernChip('Gratuits', 'free', _selectedFilter, (val) => setState(() { _selectedFilter = val; _performSearch(_searchController.text); })),
                      ],
                    ),
                  ),
                  if (_cities.length > 1) ...[
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: _cities.map((city) {
                          final displayName = city == 'all' ? 'Toutes villes' : city;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildModernChip(displayName, city, _selectedCity, (val) => setState(() { _selectedCity = val; _performSearch(_searchController.text); }), isCity: true),
                          );
                        }).toList(),
                      ),
                    ),
                  ]
                ],
              ),
            ),
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator(color: _ThixColors.primary))
                : _results.isEmpty && _searchController.text.isNotEmpty
                    ? _buildEmptyState()
                    : _results.isEmpty
                        ? _buildInitialState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _results.length,
                            itemBuilder: (context, index) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: EventCard(
                                event: _results[index],
                                isCompact: true,
                                onTap: () => context.push('/thix-event/event/${_results[index].id}'),
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  // 🟢 Design des "Chips" (Boutons de filtre) harmonisé
  Widget _buildModernChip(String label, String value, String groupValue, Function(String) onSelected, {bool isCity = false}) {
    final isSelected = groupValue == value;
    return GestureDetector(
      onTap: () => onSelected(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _ThixColors.primary.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _ThixColors.primary : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCity && isSelected) ...[
              const Icon(Icons.location_on_rounded, size: 14, color: _ThixColors.primary),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? _ThixColors.primary : _ThixColors.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🟢 "Empty State" professionnel pour Aucun Résultat
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: _ThixColors.primary.withOpacity(0.05), shape: BoxShape.circle),
            child: const Icon(Icons.search_off_rounded, size: 50, color: _ThixColors.primary),
          ),
          const SizedBox(height: 20),
          Text('Aucun résultat', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _ThixColors.darkText)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Nous n\'avons trouvé aucun événement correspondant à "${_searchController.text}".',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: _ThixColors.mutedText, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  // 🟢 "Empty State" professionnel pour l'état Initial
  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: _ThixColors.primary.withOpacity(0.05), shape: BoxShape.circle),
            child: const Icon(Icons.travel_explore_rounded, size: 50, color: _ThixColors.primary),
          ),
          const SizedBox(height: 20),
          const Text('Trouvez votre prochaine sortie', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _ThixColors.darkText)),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Tapez un mot-clé, le nom d\'un artiste ou d\'un lieu pour lancer la recherche.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: _ThixColors.mutedText, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
