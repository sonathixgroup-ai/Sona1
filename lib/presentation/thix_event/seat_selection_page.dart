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
  
  // Charte Graphique THIX
  static const Color appViolet = Color(0xFF6B3CE2);
  static const Color textDark = Color(0xFF1E1B4B);
  static const Color availableSeatColor = Color(0xFFF3F4F6); // Gris très clair
  static const Color reservedByOtherColor = Color(0xFFF59E0B); // Orange
  static const Color soldColor = Color(0xFFEF4444); // Rouge

  List<EventSeat> _seats = [];
  List<EventSeat> _selectedSeats = [];
  final Set<String> _processingSeats = {}; 
  
  // 🟢 OPTIMISATION PRODUCTION : Mise en cache du plan pour éviter de recalculer à chaque frame
  Map<String, List<EventSeat>> _groupedSeats = {};
  List<String> _sortedRows = [];
  
  bool _isLoading = true;
  bool _isConfirming = false;
  int _availableSeats = 0;
  String? _error;

  // Limite stricte de sécurité
  int get _maxAllowedSeats {
    int maxLimit = 5; // Limite globale du système
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

  // Libère toutes les places sécurisées si l'utilisateur quitte la page sans payer
  Future<void> _releaseTemporaryReservations() async {
    if (_selectedSeats.isNotEmpty) {
      final seatIds = _selectedSeats.map((s) => s.id).toList();
      await _seatService.releaseSeats(widget.eventId, seatIds);
    }
  }

  Future<void> _loadSeatMap() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final seats = await _seatService.getSeatMap(widget.eventId);
      final available = await _seatService.getAvailableSeatsCount(widget.eventId);
      
      // 🟢 OPTIMISATION : On groupe et on trie UNE SEULE FOIS ici
      _groupAndSortSeats(seats);

      if (mounted) {
        setState(() {
          _seats = seats;
          _availableSeats = available;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Impossible de charger le plan des places. Veuillez vérifier votre connexion.';
          _isLoading = false;
        });
      }
    }
  }

  // Fonction dédiée au calcul du layout
  void _groupAndSortSeats(List<EventSeat> seats) {
    _groupedSeats.clear();
    for (var seat in seats) {
      _groupedSeats.putIfAbsent(seat.row, () => []).add(seat);
    }
    _sortedRows = _groupedSeats.keys.toList()..sort();
  }

  // SÉCURITÉ : Verrouillage/Déverrouillage immédiat en base de données
  Future<void> _onSeatSelected(EventSeat seat) async {
    if (_processingSeats.contains(seat.id)) return; // Anti-spam clic

    setState(() => _processingSeats.add(seat.id));

    try {
      // Vérification par ID pour plus de sécurité
      final isAlreadySelected = _selectedSeats.any((s) => s.id == seat.id);

      if (isAlreadySelected) {
        // --- DÉVERROUILLER LA PLACE ---
        final released = await _seatService.releaseSeats(widget.eventId, [seat.id]);
        if (released && mounted) {
          setState(() {
            _selectedSeats.removeWhere((s) => s.id == seat.id);
            _availableSeats += 1;
          });
        }
      } else {
        // --- VÉRIFIER LA LIMITE ---
        if (_selectedSeats.length >= _maxAllowedSeats) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Limite atteinte : $_maxAllowedSeats place(s) maximum.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return; // Sortie anticipée
        }

        // --- VERROUILLER LA PLACE ---
        final reserved = await _seatService.reserveSeats(widget.eventId, [seat.id]);
        if (reserved && mounted) {
          setState(() {
            _selectedSeats.add(seat);
            _availableSeats -= 1;
          });
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Trop tard ! Cette place vient d\'être prise.'),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
              ),
            );
            _loadSeatMap(); // Rafraîchissement silencieux
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur de réseau. Veuillez réessayer.'), backgroundColor: Colors.red),
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
    if (_selectedSeats.isEmpty) return;

    // Blocage du bouton pendant la transition
    setState(() => _isConfirming = true);

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
      // Débloque et recharge à la fermeture de la page de réservation
      if (mounted) {
        setState(() => _isConfirming = false);
        _loadSeatMap();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: const BoxDecoration(color: Color(0xFFF8F7FF), shape: BoxShape.circle),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: textDark, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: const Text('Choisissez vos places', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textDark)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: appViolet.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_selectedSeats.length} / $_maxAllowedSeats',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: appViolet),
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
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.red),
            ),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.5)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadSeatMap,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Réessayer', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: appViolet,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ],
        ),
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
        border: Border.all(color: const Color(0xFFEEE9FF), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: appViolet.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.event_seat_rounded, color: appViolet, size: 16),
              ),
              const SizedBox(width: 12),
              const Text('Places disponibles', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textDark)),
            ],
          ),
          Text(
            '$_availableSeats',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: appViolet),
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
          width: 14, height: 14,
          decoration: BoxDecoration(
            color: isFilled ? color : Colors.transparent,
            border: Border.all(color: isFilled ? color : Colors.grey.shade400, width: 1.5),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: textDark, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildSeatMap() {
    if (_seats.isEmpty) {
      return const Center(child: Text('Aucune place n\'a été configurée pour cet événement.', style: TextStyle(color: Colors.grey)));
    }

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 3.0,
      boundaryMargin: const EdgeInsets.all(40), // Permet un meilleur panning
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 20, bottom: 60, left: 16, right: 16),
        child: Column(
          children: [
            // Dessin de la Scène courbée
            CustomPaint(size: const Size(250, 40), painter: ScenePainter()),
            const SizedBox(height: 12),
            const Text('SCÈNE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 5, color: Colors.grey)),
            const SizedBox(height: 40),
            
            // Grille des sièges générée via le cache (_sortedRows et _groupedSeats)
            for (var row in _sortedRows)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 24,
                      child: Text(row, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textDark)),
                    ),
                    const SizedBox(width: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: _groupedSeats[row]!.map((seat) {
                        final isSelectedByMe = _selectedSeats.any((s) => s.id == seat.id);
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
                          textColor = textDark;
                        }
                        
                        return GestureDetector(
                          onTap: (isAvailable || isSelectedByMe) && !_isConfirming ? () => _onSeatSelected(seat) : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 38, height: 38,
                            decoration: BoxDecoration(
                              color: seatColor,
                              border: Border.all(
                                color: isSelectedByMe ? appViolet : (isAvailable ? Colors.grey.shade300 : seatColor), 
                                width: 1.5
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8), topRight: Radius.circular(8),
                                bottomLeft: Radius.circular(4), bottomRight: Radius.circular(4),
                              ),
                              boxShadow: isSelectedByMe 
                                  ? [BoxShadow(color: appViolet.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))]
                                  : null,
                            ),
                            child: Center(
                              child: isProcessing 
                                  ? SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2, color: isSelectedByMe ? Colors.white : appViolet))
                                  : Text(
                                      seat.number.toString(),
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textColor),
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
    // 🟢 OPTIMISATION : Devise dynamique tirée de l'événement
    final String currency = widget.event?.priceCurrency ?? 'FC';
    
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
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
                    style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_totalPrice.toStringAsFixed(0)} $currency', // Utilisation dynamique
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textDark),
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
                  disabledBackgroundColor: appViolet.withOpacity(0.3), // Rendu du désactivé plus premium
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 0,
                ),
                child: _isConfirming 
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('CONTINUER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFEEE9FF) // Violet très clair THIX
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
