// lib/presentation/thix_event/seat_selection_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/event_provider.dart';
import '../../models/event_model.dart';
import '../../models/event_seat.dart';
import '../../services/event_seat_service.dart';
import 'event_reservation_page.dart';

class SeatSelectionPage extends StatefulWidget {
  final String eventId;
  final Event? event;
  final int? requestedQuantity;

  const SeatSelectionPage({
    super.key,
    required this.eventId,
    this.event,
    this.requestedQuantity,
  });

  @override
  State<SeatSelectionPage> createState() => _SeatSelectionPageState();
}

class _SeatSelectionPageState extends State<SeatSelectionPage> {
  late EventSeatService _seatService;
  List<EventSeat> _seats = [];
  List<EventSeat> _selectedSeats = [];
  bool _isLoading = true;
  bool _isConfirming = false;
  int _availableSeats = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _seatService = EventSeatService(Supabase.instance.client);
    _loadSeatMap();
  }
  
  @override
  void dispose() {
    _releaseTemporaryReservations();
    super.dispose();
  }

  Future<void> _releaseTemporaryReservations() async {
    if (_selectedSeats.isNotEmpty) {
      final seatIds = _selectedSeats.map((s) => s.id).toList();
      await _seatService.releaseSeats(widget.eventId, seatIds);
    }
  }

  Future<void> _loadSeatMap() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final seats = await _seatService.getSeatMap(widget.eventId);
      final available = await _seatService.getAvailableSeatsCount(widget.eventId);
      
      setState(() {
        _seats = seats;
        _availableSeats = available;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Impossible de charger le plan des places: $e';
        _isLoading = false;
      });
    }
  }

  void _onSeatSelected(EventSeat seat) {
    setState(() {
      if (_selectedSeats.contains(seat)) {
        _selectedSeats.remove(seat);
      } else {
        if (widget.requestedQuantity != null && 
            _selectedSeats.length >= widget.requestedQuantity!) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Vous ne pouvez sélectionner que ${widget.requestedQuantity} place(s)'),
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }
        _selectedSeats.add(seat);
      }
    });
  }

  double get _totalPrice {
    return _selectedSeats.fold(0, (sum, seat) => sum + seat.categoryPrice);
  }

  Future<void> _confirmSelection() async {
    if (_selectedSeats.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner des places')),
      );
      return;
    }

    setState(() => _isConfirming = true);

    try {
      final seatIds = _selectedSeats.map((s) => s.id).toList();
      final reserved = await _seatService.reserveSeats(widget.eventId, seatIds);
      
      if (reserved && mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventReservationPage(
              eventId: widget.eventId,
              selectedSeats: _selectedSeats,
              totalPrice: _totalPrice,
              quantity: _selectedSeats.length,
            ),
          ),
        );
        _loadSeatMap();
        setState(() => _selectedSeats.clear());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la réservation des places')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      if (mounted) setState(() => _isConfirming = false);
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Choisissez vos places', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        actions: [
          if (widget.requestedQuantity != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${_selectedSeats.length}/${widget.requestedQuantity}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37)),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadSeatMap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF37),
                          foregroundColor: const Color(0xFF0B1B3D),
                        ),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.all(12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Places disponibles', style: TextStyle(fontSize: 13)),
                          Text(
                            '$_availableSeats',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37)),
                          ),
                        ],
                      ),
                    ),
                    _buildLegend(),
                    Expanded(child: _buildSeatMap()),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_selectedSeats.length} place(s) sélectionnée(s)',
                                style: const TextStyle(fontSize: 13),
                              ),
                              Text(
                                '${_totalPrice.toStringAsFixed(0)} FCFA',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: (_selectedSeats.isEmpty || _isConfirming) ? null : _confirmSelection,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD4AF37),
                                foregroundColor: const Color(0xFF0B1B3D),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              ),
                              child: _isConfirming
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0B1B3D)),
                                    )
                                  : const Text('VALIDER', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        children: [
          _legendItem(Colors.green, 'Disponible'),
          _legendItem(const Color(0xFFD4AF37), 'Sélectionnée'),
          _legendItem(Colors.orange, 'Réservée (15min)'),
          _legendItem(Colors.red, 'Vendue'),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            border: Border.all(color: color, width: 1.5),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  Widget _buildSeatMap() {
    if (_seats.isEmpty) {
      return const Center(child: Text('Aucune place disponible pour cet événement'));
    }

    final Map<String, List<EventSeat>> rows = {};
    for (var seat in _seats) {
      rows.putIfAbsent(seat.row, () => []).add(seat);
    }

    final sortedRows = rows.keys.toList()..sort();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text('SCÈNE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),
            ),
          ),
          for (var row in sortedRows)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 30,
                    child: Text(row, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: rows[row]!.map((seat) {
                        final isSelected = _selectedSeats.contains(seat);
                        final isAvailable = seat.isAvailable;
                        final isReserved = seat.isReserved;
                        final isSold = seat.isSold;
                        
                        Color seatColor;
                        if (isSelected) seatColor = const Color(0xFFD4AF37);
                        else if (isSold) seatColor = Colors.red;
                        else if (isReserved) seatColor = Colors.orange;
                        else seatColor = Colors.green;
                        
                        return GestureDetector(
                          onTap: (isAvailable || isSelected) && !_isConfirming ? () => _onSeatSelected(seat) : null,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: seatColor.withOpacity(0.15),
                              border: Border.all(color: seatColor, width: 1.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                seat.number.toString(),
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: seatColor),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
