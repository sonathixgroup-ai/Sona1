// lib/presentation/thix_event/my_tickets_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../providers/event_provider.dart';
import '../../models/event_model.dart';

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
    final provider = context.read<EventProvider>();
    final tickets = await provider.getMyTickets();
    setState(() {
      _tickets = tickets;
      _isLoading = false;
    });
  }

  void _showTicketDetails(EventBooking ticket) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TicketDetailSheet(ticket: ticket),
    );
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
        title: const Text('Mes billets', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tickets.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _tickets.length,
                  itemBuilder: (context, index) => _buildTicketCard(_tickets[index]),
                ),
    );
  }

  Widget _buildTicketCard(EventBooking ticket) {
    final isUpcoming = DateTime.now().isBefore(ticket.eventDate);
    
    return GestureDetector(
      onTap: () => _showTicketDetails(ticket),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4)],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  if (ticket.eventImageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        ticket.eventImageUrl!,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 70,
                          height: 70,
                          color: Colors.grey[200],
                          child: const Icon(Icons.event, size: 30, color: Colors.grey),
                        ),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isUpcoming ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isUpcoming ? 'À VENIR' : 'TERMINÉ',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: isUpcoming ? Colors.green : Colors.grey),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(ticket.eventTitle, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold), maxLines: 2),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd MMM yyyy • HH:mm').format(ticket.eventDate),
                          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 2),
                        Text(ticket.eventLocation, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.confirmation_number, size: 12, color: Color(0xFFD4AF37)),
                            const SizedBox(width: 4),
                            Text('${ticket.ticketQuantity} billet(s)', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                            const Spacer(),
                            Text(
                              '${ticket.totalPrice.toStringAsFixed(0)} FC',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Code: ${ticket.ticketCode}', style: TextStyle(fontSize: 9, color: Colors.grey[500])),
                  const Icon(Icons.qr_code_scanner, size: 16, color: Color(0xFFD4AF37)),
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
          Icon(Icons.confirmation_number, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('Aucun billet', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text('Réservez votre premier événement', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go('/thix-event'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
            child: const Text('Découvrir', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _TicketDetailSheet extends StatelessWidget {
  final EventBooking ticket;

  const _TicketDetailSheet({required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.qr_code_scanner, size: 120, color: Color(0xFFD4AF37)),
                const SizedBox(height: 16),
                Center(
  child: Text(
    'Aucun billet',
    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
  ),
),
                const SizedBox(height: 12),
                _buildInfoRow('Date', DateFormat('dd MMMM yyyy • HH:mm').format(ticket.eventDate)),
                const SizedBox(height: 8),
                _buildInfoRow('Lieu', ticket.eventLocation),
                const SizedBox(height: 8),
                _buildInfoRow('Quantité', '${ticket.ticketQuantity} billet(s)'),
                const SizedBox(height: 8),
                _buildInfoRow('Code', ticket.ticketCode),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      Text(
                        '${ticket.totalPrice.toStringAsFixed(0)} FC',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: const Color(0xFF0B1B3D),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text('FERMER', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}
