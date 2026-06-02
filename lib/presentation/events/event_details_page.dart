import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/event_item.dart';
import '../../services/event_service.dart';
import '../../app_router.dart';

class EventDetailsPage extends StatefulWidget {
  final String eventId;
  final EventItem? event; // Optionnel : peut être passé via extra

  const EventDetailsPage({
    super.key,
    required this.eventId,
    this.event,
  });

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  late final EventService _eventService;

  EventItem? _event;
  bool _isLoading = true;
  bool _isRegistering = false;
  bool _hasTicket = false;

  @override
  void initState() {
    super.initState();
    _eventService = EventService(Supabase.instance.client);
    _loadEvent();
  }

  Future<void> _loadEvent() async {
    try {
      // Si l'événement a été passé via extra, on l'utilise directement
      if (widget.event != null) {
        _event = widget.event;
        _isLoading = false;
        await _checkTicketStatus();
        if (mounted) setState(() {});
        return;
      }

      // Sinon on le charge depuis l'API
      final event = await _eventService.getEventById(widget.eventId);
      _event = event;
      _isLoading = false;
      await _checkTicketStatus();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkTicketStatus() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && _event != null) {
      _hasTicket = await _eventService.hasUserTicket(user.id, _event!.id);
    }
  }

  Future<void> _reserveTicket() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      context.push(AppRoutes.login);
      return;
    }

    setState(() {
      _isRegistering = true;
    });

    try {
      final success = await _eventService.registerForEvent(
        userId: user.id,
        eventId: widget.eventId,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Billet réservé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadEvent();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vous avez déjà un billet'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la réservation'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRegistering = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_event == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Événement introuvable')),
      );
    }

    final event = _event!;

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            foregroundColor: Colors.black,
            flexibleSpace: FlexibleSpaceBar(
              background: event.imageAssetPath != null
                  ? Image.asset(
                      event.imageAssetPath!,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: Colors.blue.shade100,
                      child: const Center(
                        child: Icon(
                          Icons.event,
                          size: 80,
                          color: Colors.blue,
                        ),
                      ),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      event.category,
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _infoTile(
                    Icons.calendar_month,
                    "Date",
                    _formatDate(event.startsAt),
                  ),
                  const SizedBox(height: 12),
                  _infoTile(
                    Icons.access_time,
                    "Heure",
                    _formatTime(event.startsAt),
                  ),
                  const SizedBox(height: 12),
                  _infoTile(
                    Icons.location_on,
                    "Lieu",
                    event.location,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Description",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    event.description,
                    style: const TextStyle(
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.confirmation_number,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            event.priceLabel,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 12,
              color: Colors.black12,
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 55,
            child: _hasTicket
                ? ElevatedButton.icon(
                    onPressed: () => context.push(AppRoutes.userEventsDashboard),
                    icon: const Icon(Icons.confirmation_number),
                    label: const Text("Voir mon billet"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: _isRegistering ? null : _reserveTicket,
                    icon: _isRegistering
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.event_available),
                    label: Text(
                      _isRegistering ? "Réservation..." : "Réserver maintenant",
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
