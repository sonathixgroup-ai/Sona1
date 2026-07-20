// lib/presentation/thix_event/my_tickets_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../providers/event_provider.dart';
import '../../models/event_booking.dart'; 

class MyTicketsPage extends StatefulWidget {
  const MyTicketsPage({super.key});

  @override
  State<MyTicketsPage> createState() => _MyTicketsPageState();
}

class _MyTicketsPageState extends State<MyTicketsPage> {
  List<EventBooking> _tickets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    try {
      final provider = context.read<EventProvider>();
      final tickets = await provider.getMyTickets();
      setState(() {
        _tickets = tickets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
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
          onPressed: () => context.go('/thix-event'), // Retour accueil
        ),
        title: const Text('Mes billets', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6B3CE2)))
          : _tickets.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _tickets.length,
                  itemBuilder: (context, index) => _buildTicketCard(_tickets[index]),
                ),
    );
  }

  Widget _buildTicketCard(EventBooking ticket) {
    final isUpcoming = DateTime.now().isBefore(ticket.eventDate);
    
    return GestureDetector(
      onTap: () {
        // 🟢 C'est ici la magie : On redirige directement vers la page de CONFIRMATION
        // au lieu d'ouvrir un pop-up ! Le design sera 100% identique.
        context.push('/thix-event/ticket/${ticket.id}');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  if (ticket.eventImageUrl != null && ticket.eventImageUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        ticket.eventImageUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 80, height: 80, color: Colors.grey[200],
                          child: const Icon(Icons.event, size: 30, color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(color: const Color(0xFF6B3CE2).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.confirmation_num, color: Color(0xFF6B3CE2), size: 30),
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isUpcoming ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isUpcoming ? 'À VENIR' : 'TERMINÉ',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isUpcoming ? Colors.green : Colors.grey),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(ticket.eventTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B)), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        // 🟢 Date ET Heure formatées proprement
                        Text(DateFormat('dd MMMM yyyy • HH:mm', 'fr').format(ticket.eventDate), style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFF8F9FA),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.sell_rounded, size: 14, color: Color(0xFFD4AF37)),
                      const SizedBox(width: 6),
                      Text('${ticket.ticketQuantity} billet(s)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                    ],
                  ),
                  Text('${ticket.totalPrice.toStringAsFixed(0)} FC', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFFD4AF37))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: const Color(0xFF6B3CE2).withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.local_activity_rounded, size: 60, color: Color(0xFF6B3CE2)),
          ),
          const SizedBox(height: 24),
          const Text('Aucun billet pour le moment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B))),
          const SizedBox(height: 8),
          const Text('Vos réservations apparaîtront ici', style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/thix-event'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B3CE2),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: const Text('Découvrir les événements', style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
