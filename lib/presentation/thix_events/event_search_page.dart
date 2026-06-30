// lib/presentation/thix_event/event_search_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/event_provider.dart';
import '../../models/event_model.dart';
import 'widgets/event_card.dart';

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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            onChanged: _performSearch,
            decoration: InputDecoration(
              hintText: 'Rechercher un événement, artiste, lieu...',
              hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
              prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (_searchController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildFilterChip('Tous', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Aujourd\'hui', 'today'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Cette semaine', 'week'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Gratuits', 'free'),
                ],
              ),
            ),
          if (_searchController.text.isNotEmpty && _cities.length > 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _cities.map((city) => _buildCityChip(city)).toList(),
                ),
              ),
            ),
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty && _searchController.text.isNotEmpty
                    ? _buildEmptyState()
                    : _results.isEmpty
                        ? _buildInitialState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _results.length,
                            itemBuilder: (context, index) => EventCard(
                              event: _results[index],
                              isCompact: true,
                              onTap: () => context.push('/thix-event/event/${_results[index].id}'),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      selected: isSelected,
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onSelected: (selected) {
        setState(() => _selectedFilter = value);
        _performSearch(_searchController.text);
      },
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFFD4AF37).withOpacity(0.15),
      side: BorderSide(color: isSelected ? const Color(0xFFD4AF37) : Colors.grey[300]!),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    );
  }

  Widget _buildCityChip(String city) {
    final isSelected = _selectedCity == city;
    final displayName = city == 'all' ? 'Toutes villes' : city;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(displayName, style: const TextStyle(fontSize: 11)),
        onSelected: (selected) {
          setState(() => _selectedCity = city);
          _performSearch(_searchController.text);
        },
        backgroundColor: Colors.white,
        selectedColor: Colors.blue.withOpacity(0.1),
        side: BorderSide(color: isSelected ? Colors.blue : Colors.grey[300]!),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('Aucun résultat pour "${_searchController.text}"', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text('Essayez avec d\'autres mots-clés', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('Recherchez un événement', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text('Tapez un mot-clé pour commencer', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ],
      ),
    );
  }
}
