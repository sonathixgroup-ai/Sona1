// lib/presentation/thix_event/event_category_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/event_provider.dart';
import '../../models/event_model.dart';
import 'widgets/event_card.dart';

class EventCategoryPage extends StatefulWidget {
  final String category;
  const EventCategoryPage({super.key, required this.category});

  @override
  State<EventCategoryPage> createState() => _EventCategoryPageState();
}

class _EventCategoryPageState extends State<EventCategoryPage> {
  List<Event> _events = [];
  bool _isLoading = true;

  final Map<String, String> _categoryNames = {
    'musique': 'Musique & Concerts',
    'conference': 'Conférences & Séminaires',
    'culture': 'Culture & Art',
    'sport': 'Sport & Loisirs',
    'festival': 'Festivals & Soirées',
    'spectacle': 'Spectacles',
    'exposition': 'Expositions',
  };

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final provider = context.read<EventProvider>();
    final events = await provider.fetchEventsByCategory(widget.category);
    setState(() {
      _events = events;
      _isLoading = false;
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
        title: Text(
          _categoryNames[widget.category] ?? widget.category,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _events.isEmpty
              ? _buildEmptyState()
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _events.length,
                  itemBuilder: (context, index) => EventCard(
                    event: _events[index],
                    onTap: () => context.push('/thix-event/event/${_events[index].id}'),
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('Aucun événement dans cette catégorie', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text('Revenez plus tard', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ],
      ),
    );
  }
}
