// lib/presentation/education/screens/education_search_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/presentation/education/models/formation.dart';
import 'package:thix_id/presentation/education/providers/education_provider.dart';
import 'package:thix_id/presentation/education/widgets/common/education_empty_state.dart';
import 'package:thix_id/presentation/education/widgets/common/formation_card.dart';

class EducationSearchPage extends StatefulWidget {
  const EducationSearchPage({super.key});

  @override
  State<EducationSearchPage> createState() => _EducationSearchPageState();
}

class _EducationSearchPageState extends State<EducationSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<Formation> _results = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    try {
      final provider = context.read<EducationProvider>();
      // Utilise loadFormations avec le paramètre search
      await provider.loadFormations(search: query);
      // La liste des formations est maintenant disponible dans provider.formations
      setState(() {
        _results = provider.formations;
      });
    } catch (e) {
      // ignore
    } finally {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: AppBar(
        title: Container(
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              const Icon(Icons.search_rounded, color: Color(0xFF7386A8)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  decoration: const InputDecoration(
                    hintText: 'Rechercher une formation...',
                    border: InputBorder.none,
                    isDense: true,
                    hintStyle: TextStyle(fontSize: 14, color: Color(0xFF7386A8)),
                  ),
                  onChanged: _performSearch,
                ),
              ),
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear_rounded, color: Color(0xFF7386A8), size: 18),
                  onPressed: () {
                    _searchController.clear();
                    _performSearch('');
                    _focusNode.requestFocus();
                  },
                ),
              const SizedBox(width: 4),
            ],
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1A2E)),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isSearching
          ? const Center(child: CircularProgressIndicator())
          : _results.isEmpty && _searchController.text.isNotEmpty
              ? EducationEmptyState(
                  title: 'Aucun résultat',
                  subtitle: 'Aucune formation ne correspond à votre recherche',
                  icon: Icons.search_off_rounded,
                  buttonText: 'Réessayer',
                  onButtonPressed: () {
                    _searchController.clear();
                    _performSearch('');
                    _focusNode.requestFocus();
                  },
                )
              : _results.isNotEmpty
                  ? ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final formation = _results[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: FormationCard(
                            formation: formation,
                            onTap: () => context.push('/education/formation/${formation.id}'),
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_rounded, size: 64, color: Color(0xFFD1D5DB)),
                          const SizedBox(height: 16),
                          const Text(
                            'Recherchez une formation',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tapez un mot-clé pour commencer',
                            style: TextStyle(color: Color(0xFF7386A8)),
                          ),
                        ],
                      ),
                    ),
    );
  }
}
