import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/event_item.dart';
import '../../models/event_registration.dart';
import '../../services/event_service.dart';

class UserEventDashboardPage extends StatefulWidget {
  const UserEventDashboardPage({super.key});

  @override
  State<UserEventDashboardPage> createState() =>
      _UserEventDashboardPageState();
}

class _UserEventDashboardPageState
    extends State<UserEventDashboardPage> {
  late EventService _eventService;

  bool _loading = true;

  List<EventRegistration> _registrations = [];

  final Map<String, EventItem> _events = {};

  @override
  void initState() {
    super.initState();

    _eventService = EventService(
      Supabase.instance.client,
    );

    _loadTickets();
  }

  Future<void> _loadTickets() async {
    try {
      final user =
          Supabase.instance.client.auth.currentUser;

      if (user == null) {
        return;
      }

      final registrations =
          await _eventService.getUserRegistrations(
        user.id,
      );

      final Map<String, EventItem> eventsMap = {};

      for (final registration in registrations) {
        final event =
            await _eventService.getEventById(
          registration.eventId,
        );

        if (event != null) {
          eventsMap[event.id] = event;
        }
      }

      if (!mounted) return;

      setState(() {
        _registrations = registrations;
        _events.clear();
        _events.addAll(eventsMap);
        _loading = false;
      });
    } catch (e) {
      debugPrint(e.toString());

      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _cancelTicket(
    EventRegistration registration,
  ) async {
    await _eventService.cancelRegistration(
      registration.id,
    );

    await _loadTickets();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Réservation annulée',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8F9FC),

      appBar: AppBar(
        title: const Text(
          "Mes Billets",
        ),
        centerTitle: true,
      ),

      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadTickets,
              child: _registrations.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding:
                          const EdgeInsets.all(
                              16),
                      itemCount:
                          _registrations.length,
                      itemBuilder:
                          (context, index) {
                        final registration =
                            _registrations[
                                index];

                        final event =
                            _events[
                                registration
                                    .eventId];

                        if (event == null) {
                          return const SizedBox
                              .shrink();
                        }

                        return _TicketCard(
                          registration:
                              registration,
                          event: event,
                          onViewTicket: () {
                            context.push(
                              '/events/${event.id}/ticket/${registration.id}',
                            );
                          },
                          onCancel: () {
                            _showCancelDialog(
                              registration,
                            );
                          },
                        );
                      },
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        const SizedBox(height: 120),
        const Icon(
          Icons.confirmation_number_outlined,
          size: 80,
          color: Colors.grey,
        ),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            "Aucun billet trouvé",
            style: TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Center(
          child: Text(
            "Réservez votre premier événement",
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding:
              const EdgeInsets.symmetric(
                  horizontal: 40),
          child: ElevatedButton(
            onPressed: () {
              context.go('/events');
            },
            child: const Text(
              "Explorer les événements",
            ),
          ),
        ),
      ],
    );
  }

  void _showCancelDialog(
    EventRegistration registration,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title:
            const Text("Annuler le billet"),
        content: const Text(
          "Voulez-vous vraiment annuler cette réservation ?",
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context),
            child: const Text("Non"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              await _cancelTicket(
                registration,
              );
            },
            child: const Text("Oui"),
          ),
        ],
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final EventRegistration registration;
  final EventItem event;

  final VoidCallback onViewTicket;
  final VoidCallback onCancel;

  const _TicketCard({
    required this.registration,
    required this.event,
    required this.onViewTicket,
    required this.onCancel,
  });

  String _formatDate(
    DateTime date,
  ) {
    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    final isCancelled =
        registration.status ==
            'cancelled';

    return Card(
      margin:
          const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    style:
                        const TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration:
                      BoxDecoration(
                    color: isCancelled
                        ? Colors.red
                            .shade100
                        : Colors.green
                            .shade100,
                    borderRadius:
                        BorderRadius
                            .circular(
                                20),
                  ),
                  child: Text(
                    isCancelled
                        ? 'Annulé'
                        : 'Valide',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(
                    event.startsAt,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    event.location,
                  ),
                ),
              ],
            ),

            const Divider(
              height: 24,
            ),

            Text(
              "Code billet",
              style: TextStyle(
                color: Colors.grey[700],
              ),
            ),

            const SizedBox(height: 4),

            SelectableText(
              registration.ticketCode,
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child:
                      ElevatedButton.icon(
                    onPressed:
                        onViewTicket,
                    icon: const Icon(
                      Icons.qr_code,
                    ),
                    label: const Text(
                      "Voir billet",
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                if (!isCancelled)
                  Expanded(
                    child:
                        OutlinedButton.icon(
                      onPressed:
                          onCancel,
                      icon: const Icon(
                        Icons.cancel,
                      ),
                      label:
                          const Text(
                        "Annuler",
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
