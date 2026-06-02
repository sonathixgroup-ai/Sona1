import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/event_item.dart';
import '../../models/event_registration.dart';
import '../../services/event_service.dart';

class EventTicketPage extends StatefulWidget {
  final String eventId;
  final String registrationId;

  const EventTicketPage({
    super.key,
    required this.eventId,
    required this.registrationId,
  });

  @override
  State<EventTicketPage> createState() => _EventTicketPageState();
}

class _EventTicketPageState extends State<EventTicketPage> {
  late final EventService _service;

  @override
  void initState() {
    super.initState();
    _service = EventService(Supabase.instance.client);
  }

  Future<_TicketData?> _loadTicket() async {
    try {
      final event = await _service.getEventById(widget.eventId);
      final registration =
          await _service.getRegistrationById(widget.registrationId);

      if (event == null || registration == null) {
        return null;
      }

      return _TicketData(
        event: event,
        registration: registration,
      );
    } catch (e) {
      debugPrint('Ticket loading error: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Mon billet',
          style: TextStyle(
            color: Color(0xff0F172A),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Color(0xff0F172A),
        ),
      ),
      body: FutureBuilder<_TicketData?>(
        future: _loadTicket(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData) {
            return _buildNotFound();
          }

          final data = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildTicketCard(
                  data.event,
                  data.registration,
                ),
                const SizedBox(height: 24),
                _buildInstructions(),
                const SizedBox(height: 20),
                _buildActions(data),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotFound() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.confirmation_number_outlined,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 20),
            const Text(
              'Billet introuvable',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Ce billet n’existe pas ou a été supprimé.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => context.pop(),
              child: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketCard(
    EventItem event,
    EventRegistration reg,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xff2563EB),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.verified,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                const Text(
                  'THIX TICKET',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    reg.status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  event.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                _infoRow(
                  Icons.calendar_month,
                  _formatDate(event.startsAt),
                ),

                const SizedBox(height: 10),

                _infoRow(
                  Icons.location_on,
                  event.location,
                ),

                const SizedBox(height: 20),

                BarcodeWidget(
                  barcode: Barcode.code128(),
                  data: reg.ticketCode,
                  drawText: false,
                  width: 300,
                  height: 90,
                ),

                const SizedBox(height: 15),

                SelectableText(
                  reg.ticketCode,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),

                const SizedBox(height: 20),

                const Divider(),

                const SizedBox(height: 10),

                _detailRow(
                  "THIX ID",
                  reg.attendeeThixId,
                ),

                _detailRow(
                  "Billets",
                  reg.tickets.toString(),
                ),

                _detailRow(
                  "Réservation",
                  reg.id,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xffEFF6FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.blue,
          ),
          SizedBox(height: 10),
          Text(
            "Présentez ce billet à l'entrée de l'événement. "
            "Le code-barres sera scanné pour valider votre accès.",
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActions(_TicketData data) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.event),
            label: const Text("Événement"),
            onPressed: () {
              context.push('/events/${data.event.id}');
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text("Scanner"),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "Billet prêt à être scanné",
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _infoRow(
    IconData icon,
    String value,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Colors.blue,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }

  Widget _detailRow(
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 6,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year} "
        "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }
}

class _TicketData {
  final EventItem event;
  final EventRegistration registration;

  const _TicketData({
    required this.event,
    required this.registration,
  });
}
