import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/event_item.dart';
import '../../models/event_registration.dart';
import '../../services/event_service.dart';

class EventRegistrationPage extends StatefulWidget {
  final String eventId;

  const EventRegistrationPage({
    super.key,
    required this.eventId,
  });

  @override
  State<EventRegistrationPage> createState() => _EventRegistrationPageState();
}

class _EventRegistrationPageState extends State<EventRegistrationPage> {
  late final EventService _eventService;

  bool _loading = true;
  bool _submitting = false;

  EventItem? _event;
  int _tickets = 1;
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _eventService = EventService(Supabase.instance.client);
    _loadEvent();
  }

  Future<void> _loadEvent() async {
    try {
      final event = await _eventService.getEventById(widget.eventId);
      if (!mounted) return;

      setState(() {
        _event = event;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de charger l\'événement')),
      );
    }
  }

  double get _totalPrice {
    if (_event == null) return 0;
    return (_event!.price ?? 0) * _tickets;
  }

  Future<void> _register() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez vous connecter')),
      );
      return;
    }

    if (_event == null) return;

    setState(() => _submitting = true);

    try {
      final registration = await _eventService.createRegistration(
        userId: user.id,
        eventId: _event!.id,
        metadata: {
          'tickets': _tickets,
          'note': _noteController.text.trim(),
        },
      );

      if (registration != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Réservation confirmée avec succès !')),
        );

        // Redirection vers la page du ticket
        context.go('/events/${_event!.id}/ticket/${registration.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la réservation: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_event == null) {
      return const Scaffold(
        body: Center(child: Text('Événement introuvable')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: const Text('Réserver'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xff0F172A),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildEventCard(),
            const SizedBox(height: 24),
            _buildTicketSelector(),
            const SizedBox(height: 24),
            _buildNoteField(),
            const SizedBox(height: 24),
            _buildPriceSummary(),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: FilledButton(
                onPressed: _submitting ? null : _register,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xff2563EB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _submitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Confirmer la réservation'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _event!.title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on, size: 18, color: Color(0xff2563EB)),
              const SizedBox(width: 6),
              Expanded(child: Text(_event!.location)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_month, size: 18, color: Color(0xff2563EB)),
              const SizedBox(width: 6),
              Text(_formatDate(_event!.startsAt)),
            ],
          ),
          if (_event!.price != null && _event!.price! > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.attach_money, size: 18, color: Color(0xff2563EB)),
                const SizedBox(width: 6),
                Text(
                  '${_event!.price} USD',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTicketSelector() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nombre de billets',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _tickets > 1 ? () => setState(() => _tickets--) : null,
                icon: const Icon(Icons.remove_circle, size: 32),
                color: const Color(0xff2563EB),
              ),
              const SizedBox(width: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _tickets.toString(),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 20),
              IconButton(
                onPressed: () => setState(() => _tickets++),
                icon: const Icon(Icons.add_circle, size: 32),
                color: const Color(0xff2563EB),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoteField() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Note (optionnel)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Ajoutez une note à votre réservation...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xff2563EB)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSummary() {
    final bool hasPrice = _event!.price != null && _event!.price! > 0;
    
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Résumé de la commande',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          if (hasPrice) ...[
            _row('Prix unitaire', '${_event!.price} USD'),
            const SizedBox(height: 8),
            _row('Nombre de billets', _tickets.toString()),
            const Divider(height: 30),
            _row('TOTAL', '${_totalPrice.toStringAsFixed(2)} USD', bold: true),
          ] else ...[
            _row('Nombre de billets', _tickets.toString()),
            const Divider(height: 30),
            _row('TOTAL', 'Gratuit', bold: true),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            fontSize: bold ? 18 : 16,
            color: bold ? const Color(0xff2563EB) : null,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }
}
