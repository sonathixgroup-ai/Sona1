// lib/presentation/thix_event/event_reservation_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/event_provider.dart';
import '../../models/event_model.dart';
import '../../models/event_seat.dart';
import '../../services/event_booking_limit_service.dart';
import '../../services/event_seat_service.dart';

class EventReservationPage extends StatefulWidget {
  final String eventId;
  final List<EventSeat>? selectedSeats;
  final double? totalPrice;
  final int quantity;

  const EventReservationPage({
    super.key,
    required this.eventId,
    this.selectedSeats,
    this.totalPrice,
    this.quantity = 1,
  });

  @override
  State<EventReservationPage> createState() => _EventReservationPageState();
}

class _EventReservationPageState extends State<EventReservationPage> {
  late Event _event;
  bool _isLoading = true;
  int _quantity = 1;
  bool _isProcessing = false;
  bool _isCheckingLimits = false;
  Map<String, dynamic>? _bookingLimit;

  @override
  void initState() {
    super.initState();
    _loadEvent();
    _quantity = widget.quantity;
  }

  Future<void> _loadEvent() async {
    final provider = context.read<EventProvider>();
    final event = await provider.fetchEventById(widget.eventId);
    if (event != null) {
      setState(() {
        _event = event;
        _isLoading = false;
      });
      await _loadBookingLimit();
    }
  }

  Future<void> _loadBookingLimit() async {
    try {
      final limitService = EventBookingLimitService(Supabase.instance.client);
      final limit = await limitService.getBookingLimit(widget.eventId);
      if (limit != null) {
        setState(() {
          _bookingLimit = {
            'eventId': limit.eventId,
            'maxPerPerson': limit.maxPerPerson,
            'maxPerTransaction': limit.maxPerTransaction,
            'requireIdVerification': limit.requireIdVerification,
            'memberOnlyLimit': limit.memberOnlyLimit,
            'restrictedZones': limit.restrictedZones,
          };
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading booking limit: $e');
    }
  }

  double get _totalPrice {
    if (widget.totalPrice != null) return widget.totalPrice!;
    return _event.price * _quantity;
  }

  Future<bool> _checkBookingLimits() async {
    setState(() => _isCheckingLimits = true);
    
    final limitService = EventBookingLimitService(Supabase.instance.client);
    final result = await limitService.canUserBook(widget.eventId, _quantity);
    
    setState(() => _isCheckingLimits = false);
    
    if (result['allowed'] == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['reason']), backgroundColor: Colors.red),
      );
      return false;
    }
    
    return true;
  }

  Future<void> _processReservation() async {
    if (!await _checkBookingLimits()) return;
    
    setState(() => _isProcessing = true);
    
    final provider = context.read<EventProvider>();
    String? bookingId;
    
    try {
      if (widget.selectedSeats != null && widget.selectedSeats!.isNotEmpty) {
        final seatService = EventSeatService(Supabase.instance.client);
        
        final booking = await provider.bookTicket(
          eventId: widget.eventId,
          quantity: widget.selectedSeats!.length,
          totalPrice: widget.totalPrice ?? _totalPrice,
        );
        
        if (booking != null) {
          final seatIds = widget.selectedSeats!.map((s) => s.id).toList();
          // Convertir l'ID en int (en prenant seulement les chiffres)
          final numericId = int.tryParse(booking.id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          await seatService.confirmSeats(widget.eventId, seatIds, numericId);
          bookingId = booking.id;
        }
      } else {
        final booking = await provider.bookTicket(
          eventId: widget.eventId,
          quantity: _quantity,
          totalPrice: _totalPrice,
        );
        bookingId = booking?.id;
      }
      
      if (bookingId != null && mounted) {
        final limitService = EventBookingLimitService(Supabase.instance.client);
        await limitService.recordBookingAttempt(widget.eventId, _quantity);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Réservation confirmée !'), backgroundColor: Colors.green),
        );
        context.go('/thix-event/my-tickets');
      } else {
        throw Exception('Erreur lors de la réservation');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Réservation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_event.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Text(_event.formattedDate, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Text(_event.location, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                    const Divider(),
                    if (widget.selectedSeats != null && widget.selectedSeats!.isNotEmpty) ...[
                      _buildInfoRow('Places sélectionnées', widget.selectedSeats!.map((s) => s.displayName).join(', ')),
                      const SizedBox(height: 8),
                      _buildInfoRow('Catégorie', widget.selectedSeats!.first.category.toString().split('.').last),
                      const Divider(),
                    ],
                    if (widget.selectedSeats == null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Prix unitaire', style: TextStyle(fontSize: 13)),
                          Text(_event.formattedPrice, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Quantité', style: TextStyle(fontSize: 13)),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, size: 24),
                                onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                              ),
                              Container(
                                width: 40,
                                alignment: Alignment.center,
                                child: Text('$_quantity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, size: 24),
                                onPressed: (_event.remainingTickets == null || _quantity < _event.remainingTickets!)
                                    ? () => setState(() => _quantity++)
                                    : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        Text(
                          '${NumberFormat('#,###').format(_totalPrice)} FC',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Informations du participant', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Nom complet',
                        hintText: 'Entrez votre nom',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'Entrez votre email',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Téléphone',
                        hintText: 'Entrez votre numéro',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_bookingLimit != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Maximum ${_bookingLimit!['maxPerPerson']} places par personne.',
                        style: TextStyle(fontSize: 11, color: Colors.blue[700]),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: (_isProcessing || _isCheckingLimits) ? null : _processReservation,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: const Color(0xFF0B1B3D),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: _isProcessing || _isCheckingLimits
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('CONFIRMER LA RÉSERVATION', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
