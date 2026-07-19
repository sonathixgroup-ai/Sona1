// lib/presentation/thix_event/seat_selection_page.dart
import 'dart:math';
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
  
  // Couleurs de l'application
  static const Color appViolet = Color(0xFF6B3CE2);
  static const Color textDark = Color(0xFF1A1A2E);
  static const Color availableSeatColor = Color(0xFFE0E0E0);
  static const Color reservedByOtherColor = Colors.orange;
  static const Color soldColor = Colors.red;

  List<EventSeat> _seats = [];
  List<EventSeat> _selectedSeats = [];
  Set<String> _processingSeats = {}; // Pour bloquer les clics répétés sur un même siège
  
  bool _isLoading = true;
  bool _isConfirming = false;
  int _availableSeats = 0;
  String? _error;

  // Limite stricte de sécurité
  int get _maxAllowedSeats {
    int maxLimit = 5;
    if (widget.requestedQuantity != null && widget.requestedQuantity! < maxLimit) {
      return widget.requestedQuantity!;
    }
    return maxLimit;
  }

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

  // Libère toutes les places sécurisées si l'utilisateur quitte sans payer
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

  // SÉCURITÉ : Verrouillage/Déverrouillage immédiat en base de données
  Future<void> _onSeatSelected(EventSeat seat) async {
    if (_processingSeats.contains(seat.id)) return; // Anti-spam clic

    setState(() => _processingSeats.add(seat.id));

    try {
      if (_selectedSeats.contains(seat)) {
        // DÉVERROUILLER LA PLACE
        final released = await _seatService.releaseSeats(widget.eventId, [seat.id]);
        if (released && mounted) {
          setState(() {
            _selectedSeats.remove(seat);
            _availableSeats += 1;
          });
        }
      } else {
        // VÉRIFIER LA LIMITE STRICTE DE 5
        if (_selectedSeats.length >= _maxAllowedSeats) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Limite atteinte : Vous ne pouvez réserver que $_maxAllowedSeats place(s) maximum.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
          setState(() => _processingSeats.remove(seat.id));
          return;
        }

        // VERROUILLER LA PLACE
        final reserved = await _seatService.reserveSeats(widget.eventId, [seat.id]);
        if (reserved && mounted) {
          setState(() {
            _selectedSeats.add(seat);
            _availableSeats -= 1;
          });
        } else {
          // La place vient d'être prise par quelqu'un d'autre in-extremis
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Trop tard ! Cette place vient d\'être prise.'),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
              ),
            );
            _loadSeatMap(); // Rafraîchir la carte
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de connexion : $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _processingSeats.remove(seat.id));
    }
  }

  double get _totalPrice {
    return _selectedSeats.fold(0, (sum, seat) => sum + seat.categoryPrice);
  }

  void _confirmSelection() {
    if (_selectedSeats.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner au moins une place')),
      );
      return;
    }

    // Les places sont DÉJÀ verrouillées en BDD à ce stade, on passe direct au paiement
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventReservationPage(
          eventId: widget.eventId,
          selectedSeats: _selectedSeats,
          totalPrice: _totalPrice,
          quantity: _selectedSeats.length,
        ),
      ),
    ).then((_) {
      // Si l'utilisateur revient en arrière depuis la page de réservation
      _loadSeatMap();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Choisissez vos places', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textDark)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: appViolet.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_selectedSeats.length} / $_maxAllowedSeats',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: appViolet),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: appViolet))
          : _error != null
              ? _buildErrorView()
              : Column(
                  children: [
                    _buildAvailabilityBanner(),
                    Expanded(child: _buildSeatMap()),
                    _buildLegend(),
                    _buildBottomBar(),
                  ],
                ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadSeatMap,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: appViolet,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.event_seat, color: Colors.grey.shade600, size: 20),
              const SizedBox(width: 8),
              const Text('Places disponibles', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
          Text(
            '$_availableSeats',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: appViolet),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _legendItem(availableSeatColor, 'Libre', isFilled: false),
          _legendItem(appViolet, 'Sélection', isFilled: true),
          _legendItem(reservedByOtherColor, 'En cours', isFilled: true),
          _legendItem(soldColor, 'Vendue', isFilled: true),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label, {required bool isFilled}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: isFilled ? color : Colors.transparent,
            border: Border.all(color: isFilled ? color : Colors.grey.shade400, width: 1.5),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
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

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 2.5,
      boundaryMargin: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 10, bottom: 40, left: 16, right: 16),
        child: Column(
          children: [
            // Dessin de la Scène courbée
            CustomPaint(
              size: const Size(250, 40),
              painter: ScenePainter(),
            ),
            const SizedBox(height: 12),
            const Text('SCÈNE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 4, color: Colors.grey)),
            const SizedBox(height: 40),
            
            // Grille des sièges
            for (var row in sortedRows)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 24,
                      child: Text(row, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                    ),
                    const SizedBox(width: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: rows[row]!.map((seat) {
                        final isSelectedByMe = _selectedSeats.contains(seat);
                        final isProcessing = _processingSeats.contains(seat.id);
                        final isAvailable = seat.isAvailable;
                        final isReservedByOther = seat.isReserved && !isSelectedByMe;
                        final isSold = seat.isSold;
                        
                        Color seatColor;
                        Color textColor = Colors.white;

                        if (isSelectedByMe) {
                          seatColor = appViolet;
                        } else if (isSold) {
                          seatColor = soldColor;
                        } else if (isReservedByOther) {
                          seatColor = reservedByOtherColor;
                        } else {
                          seatColor = Colors.white;
                          textColor = Colors.grey.shade700;
                        }
                        
                        return GestureDetector(
                          onTap: (isAvailable || isSelectedByMe) && !_isConfirming ? () => _onSeatSelected(seat) : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: seatColor,
                              border: Border.all(
                                color: isSelectedByMe ? appViolet : (isAvailable ? Colors.grey.shade400 : seatColor), 
                                width: 1.5
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                                bottomLeft: Radius.circular(4),
                                bottomRight: Radius.circular(4),
                              ),
                              boxShadow: isSelectedByMe 
                                  ? [BoxShadow(color: appViolet.withOpacity(0.4), blurRadius: 6, offset: const Offset(0, 2))]
                                  : null,
                            ),
                            child: Center(
                              child: isProcessing 
                                  ? SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: isSelectedByMe ? Colors.white : appViolet))
                                  : Text(
                                      seat.number.toString(),
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
                                    ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_selectedSeats.length} place(s)',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_totalPrice.toStringAsFixed(0)} FC',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textDark),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: ElevatedButton(
                onPressed: (_selectedSeats.isEmpty || _isConfirming) ? null : _confirmSelection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: appViolet,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: _selectedSeats.isEmpty ? 0 : 4,
                ),
                child: const Text('CONTINUER', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget personnalisé pour dessiner la scène courbée
class ScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD1C4E9) // Violet très clair
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height)
      ..quadraticBezierTo(size.width / 2, -size.height, size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
