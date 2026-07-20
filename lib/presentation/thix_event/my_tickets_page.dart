// lib/presentation/thix_event/my_tickets_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart'; // 🟢 Ajout pour le vrai QR Code

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

    void _showTicketDetails(EventBooking ticket) {
    showDialog(
      context: context,
      // ✔️ Ligne supprimée ici
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent, // Le fond transparent reste bien appliqué ici
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: _TicketDetailModal(ticket: ticket),
      ),
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
      onTap: () => _showTicketDetails(ticket),
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
                        Text(DateFormat('dd MMM yyyy • HH:mm').format(ticket.eventDate), style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500)),
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

// 🟢 NOUVEAU DESIGN DE BILLET HD (Style carte d'embarquement)
class _TicketDetailModal extends StatelessWidget {
  final EventBooking ticket;

  const _TicketDetailModal({required this.ticket});

  @override
  Widget build(BuildContext context) {
    // Si votre modèle EventBooking ne contient pas encore la catégorie (ex: ticket.ticketCategory), 
    // on affiche "Standard" par défaut. Remplacez 'Standard' par votre variable si elle existe.
    final ticketCategory = "Standard"; // TODO: Lier avec la vraie catégorie si dispo dans Supabase
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // PARTIE HAUTE (Violette)
        Container(
          decoration: const BoxDecoration(
            color: Color(0xFF6B3CE2),
            borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                    child: const Text('BILLET CONFIRMÉ', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(ticket.eventTitle, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, color: Colors.white70, size: 16),
                  const SizedBox(width: 8),
                  Text(DateFormat('dd MMMM yyyy • HH:mm', 'fr').format(ticket.eventDate), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, color: Colors.white70, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(ticket.eventLocation, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500))),
                ],
              ),
            ],
          ),
        ),

        // LIGNE DE DÉCOUPE
        Container(
          color: Colors.white,
          child: Row(
            children: [
              SizedBox(height: 20, width: 10, child: DecoratedBox(decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: const BorderRadius.only(topRight: Radius.circular(10), bottomRight: Radius.circular(10))))),
              Expanded(child: LayoutBuilder(builder: (context, constraints) {
                return Flex(
                  direction: Axis.horizontal,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate((constraints.constrainWidth() / 10).floor(), (index) => const SizedBox(width: 5, height: 1, child: DecoratedBox(decoration: BoxDecoration(color: Colors.grey)))),
                );
              })),
              SizedBox(height: 20, width: 10, child: DecoratedBox(decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: const BorderRadius.only(topLeft: Radius.circular(10), bottomLeft: Radius.circular(10))))),
            ],
          ),
        ),

        // PARTIE BASSE (Blanche - QR et Infos)
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDetailCol('Catégorie', ticketCategory, color: const Color(0xFF6B3CE2)),
                  _buildDetailCol('Quantité', '${ticket.ticketQuantity}'),
                  _buildDetailCol('Total', '${ticket.totalPrice.toStringAsFixed(0)} FC', color: const Color(0xFFD4AF37)),
                ],
              ),
              const SizedBox(height: 30),
              
              // Vrai QR Code généré dynamiquement
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200, width: 2),
                ),
                child: QrImageView(
                  data: ticket.ticketCode.isNotEmpty ? ticket.ticketCode : ticket.id,
                  version: QrVersions.auto,
                  size: 140.0,
                  foregroundColor: const Color(0xFF1E1B4B),
                ),
              ),
              const SizedBox(height: 16),
              Text(ticket.ticketCode, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2, color: Color(0xFF1E1B4B))),
              const SizedBox(height: 4),
              const Text('Présentez ce QR code à l\'entrée', style: TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailCol(String label, String value, {Color color = const Color(0xFF1E1B4B)}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }
}
