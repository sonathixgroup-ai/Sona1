// lib/presentation/thix_event/event_ticket_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart'; // Assurez-vous d'avoir ce package pour le QR code (ou utilisez votre widget existant)

import '../../providers/event_provider.dart';
import '../../models/event_booking.dart';

class EventTicketPage extends StatefulWidget {
  final String bookingId;

  const EventTicketPage({super.key, required this.bookingId});

  @override
  State<EventTicketPage> createState() => _EventTicketPageState();
}

class _EventTicketPageState extends State<EventTicketPage> {
  bool _isLoading = true;
  EventBooking? _ticket;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTicketDetails();
  }

  Future<void> _loadTicketDetails() async {
    try {
      final provider = context.read<EventProvider>();
      // Récupération du billet via son ID de réservation
      final ticket = await provider.getBookingById(widget.bookingId);
      setState(() {
        _ticket = ticket;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF6B3CE2),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_error != null || _ticket == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF6B3CE2),
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(
          child: Text('Erreur: Impossible de charger le billet', style: const TextStyle(color: Colors.white)),
        ),
      );
    }

    final ticket = _ticket!;

    return Scaffold(
      backgroundColor: const Color(0xFF6B3CE2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Votre Billet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 🟢 VRAIE IMAGE DE L'ÉVÉNEMENT (au lieu de la maquette statique)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: ticket.eventImageUrl != null
                    ? Image.network(
                        ticket.eventImageUrl!,
                        height: 180,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 180,
                          color: Colors.grey[200],
                          child: const Icon(Icons.event, size: 50, color: Colors.grey),
                        ),
                      )
                    : Container(
                        height: 180,
                        color: const Color(0xFF6B3CE2).withOpacity(0.1),
                        child: const Icon(Icons.event, size: 50, color: Color(0xFF6B3CE2)),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🟢 VRAI TITRE
                    Text(
                      ticket.eventTitle,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87),
                    ),
                    const SizedBox(height: 16),

                    // 🟢 VRAIE DATE
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF6B3CE2)),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Date & Heure', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            Text(
                              DateFormat('dd MMM yyyy • HH:mm').format(ticket.eventDate),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 🟢 VRAI LIEU
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 18, color: Color(0xFF6B3CE2)),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Lieu', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            Text(
                              ticket.eventLocation,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 30),

                    // 🟢 INFORMATIONS DU BILLET (Quantité, Type, Statut)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Billet(s)', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text('${ticket.ticketQuantity}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total payé', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text('${ticket.totalPrice.toStringAsFixed(0)} FC', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37))),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Statut', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text(
                              ticket.paymentStatus.toUpperCase(),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 30),

                    // 🟢 QR CODE DYNAMIQUE ET CODE TICKET
                    Center(
                      child: Column(
                        children: [
                          ticket.ticketCode.isNotEmpty
                              ? SizedBox(
                                  width: 180,
                                  height: 180,
                                  child: QrImageView(
                                    data: ticket.ticketCode,
                                    version: QrVersions.auto,
                                    gapless: false,
                                  ),
                                )
                              : const Icon(Icons.qr_code, size: 150),
                          const SizedBox(height: 12),
                          Text(
                            'Ticket ID: ${ticket.ticketCode}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Présentez ce QR code à l\'entrée',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
