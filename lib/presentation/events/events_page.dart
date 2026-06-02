import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/event_item.dart';
import '../../services/event_service.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  late final EventService _eventService;

  final TextEditingController _searchController =
      TextEditingController();

  List<EventItem> _events = [];
  List<EventItem> _filteredEvents = [];

  bool _loading = true;

  String _selectedCategory = 'Tous';

  @override
  void initState() {
    super.initState();

    _eventService = EventService(
      Supabase.instance.client,
    );

    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _loading = true;
    });

    final events = await _eventService.getAllEvents();

    setState(() {
      _events = events;
      _filteredEvents = events;
      _loading = false;
    });
  }

  void _filterEvents() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _filteredEvents = _events.where((event) {
        final titleMatch =
            event.title.toLowerCase().contains(query);

        final locationMatch =
            event.location.toLowerCase().contains(query);

        final categoryMatch =
            _selectedCategory == 'Tous'
                ? true
                : event.category == _selectedCategory;

        return (titleMatch || locationMatch) &&
            categoryMatch;
      }).toList();
    });
  }

  List<String> get categories {
    final set = <String>{};

    for (final event in _events) {
      set.add(event.category);
    }

    return [
      'Tous',
      ...set,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'THIX Events',
          style: TextStyle(
            color: Color(0xff0F172A),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              context.push('/my-tickets');
            },
            icon: const Icon(
              Icons.confirmation_number,
              color: Color(0xff0F172A),
            ),
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _loadEvents,
        child: Column(
          children: [
            _buildSearchBar(),

            _buildCategories(),

            Expanded(
              child: _loading
                  ? const Center(
                      child:
                          CircularProgressIndicator(),
                    )
                  : _filteredEvents.isEmpty
                      ? _buildEmpty()
                      : ListView.builder(
                          padding:
                              const EdgeInsets.all(16),
                          itemCount:
                              _filteredEvents.length,
                          itemBuilder:
                              (context, index) {
                            return _EventCard(
                              event:
                                  _filteredEvents[index],
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => _filterEvents(),
        decoration: InputDecoration(
          hintText:
              'Rechercher un événement...',
          prefixIcon:
              const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 55,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding:
            const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];

          final selected =
              category == _selectedCategory;

          return Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 4,
            ),
            child: ChoiceChip(
              selected: selected,
              label: Text(category),
              onSelected: (_) {
                setState(() {
                  _selectedCategory = category;
                });

                _filterEvents();
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 15),
            const Text(
              'Aucun événement trouvé',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final EventItem event;

  const _EventCard({
    required this.event,
  });

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        context.push(
          '/events/${event.id}',
        );
      },
      child: Container(
        margin:
            const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              color:
                  Colors.black.withOpacity(0.04),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: event.imageAssetPath != null
                  ? Image.network(
                      event.imageAssetPath!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, __, ___) =>
                              _placeholder(),
                    )
                  : _placeholder(),
            ),

            Padding(
              padding:
                  const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration:
                        BoxDecoration(
                      color: Colors.blue
                          .withOpacity(.1),
                      borderRadius:
                          BorderRadius.circular(
                              20),
                    ),
                    child: Text(
                      event.category,
                      style:
                          const TextStyle(
                        color: Colors.blue,
                        fontWeight:
                            FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    event.title,
                    style:
                        const TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_month,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(
                            event.startsAt),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          event.location,
                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Text(
                        event.priceLabel,
                        style:
                            const TextStyle(
                          color: Colors.blue,
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () {
                          context.push(
                            '/events/${event.id}',
                          );
                        },
                        child: const Text(
                          'Voir',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      height: 180,
      color: Colors.blue.shade50,
      child: const Center(
        child: Icon(
          Icons.event,
          size: 50,
          color: Colors.blue,
        ),
      ),
    );
  }
}
