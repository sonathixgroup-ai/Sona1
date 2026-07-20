// lib/presentation/thix_event/widgets/seat_map_widget.dart
import 'package:flutter/material.dart';
import '../../../models/event_seat.dart';

class _ThixColors {
  static const Color primary = Color(0xFF6B3CE2); // Violet THIX pour la sélection
  static const Color darkText = Color(0xFF1E1B4B);
  static const Color mutedText = Color(0xFF8B8BA7);
  
  // Couleurs de statuts modernes (en phase avec la légende)
  static const Color seatAvailable = Color(0xFF10B981); // Vert émeraude
  static const Color seatReserved = Color(0xFFF59E0B);  // Orange
  static const Color seatSold = Color(0xFFEF4444);      // Rouge
}

class SeatMapWidget extends StatelessWidget {
  final List<EventSeat> seats;
  final List<EventSeat> selectedSeats;
  final Function(EventSeat) onSeatTap;

  const SeatMapWidget({
    super.key,
    required this.seats,
    required this.selectedSeats,
    required this.onSeatTap,
  });

  @override
  Widget build(BuildContext context) {
    // Grouper les places par rangée de manière dynamique
    final Map<String, List<EventSeat>> rows = {};
    for (var seat in seats) {
      rows.putIfAbsent(seat.row, () => []).add(seat);
    }

    // Trier les rangées alphabétiquement/numériquement
    final sortedRows = rows.keys.toList()..sort();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 🎭 SCÈNE (Design modernisé)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            margin: const EdgeInsets.only(bottom: 28),
            decoration: BoxDecoration(
              color: _ThixColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _ThixColors.primary.withOpacity(0.2), width: 1.5),
            ),
            child: const Center(
              child: Text(
                'SCÈNE', 
                style: TextStyle(
                  fontSize: 12, 
                  fontWeight: FontWeight.w900, 
                  letterSpacing: 3, 
                  color: _ThixColors.primary,
                ),
              ),
            ),
          ),
          
          // 💺 PLAN DES PLACES DYNAMIQUE
          for (var row in sortedRows)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 32,
                    child: Text(
                      row,
                      style: const TextStyle(
                        fontSize: 14, 
                        fontWeight: FontWeight.w900, 
                        color: _ThixColors.darkText,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: rows[row]!.map((seat) {
                        final isSelected = selectedSeats.contains(seat);
                        final isAvailable = seat.isAvailable;
                        final isReserved = seat.isReserved;
                        final isSold = seat.isSold;
                        
                        // Attribution des couleurs dynamiques selon l'état du siège
                        Color seatColor;
                        if (isSelected) {
                          seatColor = _ThixColors.primary; // 🟣 Violet THIX pour la sélection
                        } else if (isSold) {
                          seatColor = _ThixColors.seatSold; // 🔴 Rouge (vendu)
                        } else if (isReserved) {
                          seatColor = _ThixColors.seatReserved; // 🟠 Orange (réservé temporairement)
                        } else {
                          seatColor = _ThixColors.seatAvailable; // 🟢 Vert (disponible)
                        }
                        
                        return GestureDetector(
                          onTap: isAvailable || isSelected ? () => onSeatTap(seat) : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: seatColor.withOpacity(isSelected ? 0.25 : 0.12),
                              border: Border.all(color: seatColor, width: isSelected ? 2.5 : 1.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                seat.number.toString(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: seatColor,
                                ),
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
            
          // 🚪 COULOIR CENTRAL OPTIONNEL
          Container(
            margin: const EdgeInsets.symmetric(vertical: 20),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'COULOIR CENTRAL', 
                style: TextStyle(
                  fontSize: 10, 
                  fontWeight: FontWeight.w700, 
                  letterSpacing: 1.5, 
                  color: _ThixColors.mutedText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
