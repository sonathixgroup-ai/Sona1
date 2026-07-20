// lib/presentation/thix_event/event_category_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/event_provider.dart';
import '../../models/event_model.dart';
import 'widgets/event_card.dart';

class _ThixColors {
  static const Color primary = Color(0xFF6B3CE2);
  static const Color lightBg = Color(0xFFF8F9FA);
  static const Color darkText = Color(0xFF1E1B4B);
  static const Color mutedText = Color(0xFF8B8BA7);
}

class EventCategoryPage extends StatefulWidget {
  final String category;
  const EventCategoryPage({super.key, required this.category});

  @override
  State<EventCategoryPage> createState() => _EventCategoryPageState();
}

class _EventCategoryPageState extends State<EventCategoryPage> {
  final ScrollController _scrollController = ScrollController();
  
  List<Event> _events = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;

  // Pagination dynamique
  int _currentPage = 0;
  static const int _limit = 20;

  // 🟢 OPTIMISATION : Mis en statique pour de meilleures performances
  static const Map<String, String> _categoryNames = {
    'musique': 'Musique & Concerts',
    'concert': 'Musique & Concerts',
    'conference': 'Conférences & Séminaires',
    'culture': 'Culture & Art',
    'sport': 'Sport & Loisirs',
    'match': 'Sport & Loisirs',
    'festival': 'Festivals & Soirées',
    'spectacle': 'Spectacles',
    'exposition': 'Expositions',
  };

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadEvents();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && !_isLoadingMore && _hasMore) {
        _loadMoreEvents();
      }
    }
  }

  Future<void> _loadEvents({bool isRefresh = false}) async {
    if (!mounted) return;

    if (isRefresh) {
      setState(() {
        _currentPage = 0;
        _hasMore = true;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final provider = context.read<EventProvider>();
      final events = await provider.fetchEventsByCategory(widget.category);

      if (mounted) {
        setState(() {
          _events = events;
          _isLoading = false;
          _hasMore = events.length >= _limit; 
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Impossible de charger les événements. Veuillez vérifier votre connexion.";
        });
      }
    }
  }

  Future<void> _loadMoreEvents() async {
    if (!mounted) return;
    setState(() => _isLoadingMore = true);

    try {
      _currentPage++;
      final provider = context.read<EventProvider>();
      
      final newEvents = await provider.fetchEventsByCategory(widget.category);
      
      if (mounted) {
        setState(() {
          if (newEvents.isEmpty) {
            _hasMore = false;
          } else {
            // Désactivé temporairement tant que le backend ne pagine pas via offset/limit
            _hasMore = false; 
          }
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ThixColors.lightBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: const BoxDecoration(color: _ThixColors.lightBg, shape: BoxShape.circle),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: _ThixColors.darkText, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Text(
          _categoryNames[widget.category.toLowerCase()] ?? widget.category.toUpperCase(),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _ThixColors.darkText),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _ThixColors.primary));
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_events.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: _ThixColors.primary,
      backgroundColor: Colors.white,
      onRefresh: () => _loadEvents(isRefresh: true),
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.68, // 🟢 Légèrement ajusté pour éviter le débordement du texte sur les petits écrans
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return EventCard(
                    event: _events[index],
                    isCompact: true, // 🟢 Souvent préférable dans une grille à 2 colonnes
                    onTap: () => context.push('/thix-event/event/${_events[index].id}'),
                  );
                },
                childCount: _events.length,
              ),
            ),
          ),
          if (_isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: CircularProgressIndicator(color: _ThixColors.primary, strokeWidth: 3),
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)), 
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: _ThixColors.mutedText, fontSize: 14, height: 1.5, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _loadEvents(),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Réessayer', style: TextStyle(fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _ThixColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: _ThixColors.primary.withOpacity(0.05), shape: BoxShape.circle),
                  child: Icon(Icons.local_activity_outlined, size: 64, color: _ThixColors.primary.withOpacity(0.5)),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Aucun événement trouvé',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _ThixColors.darkText),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Il n\'y a pas encore d\'événements\ndans cette catégorie pour le moment.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: _ThixColors.mutedText, height: 1.5),
                ),
                const SizedBox(height: 32),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context), // 🟢 Retour facile pour l'utilisateur
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Retour', style: TextStyle(fontWeight: FontWeight.w800)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _ThixColors.primary,
                    side: const BorderSide(color: _ThixColors.primary, width: 1.5),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
