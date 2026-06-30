// lib/presentation/thix_event/widgets/seat_map_widget.dart
import 'package:flutter/material.dart';
import '../../../models/event_seat.dart';

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
    // Grouper les places par rangée
    final Map<String, List<EventSeat>> rows = {};
    for (var seat in seats) {
      rows.putIfAbsent(seat.row, () => []).add(seat);
    }

    // Trier les rangées
    final sortedRows = rows.keys.toList()..sort();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Scène
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
          // Plan des places
          for (var row in sortedRows)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 30,
                    child: Text(
                      row,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: rows[row]!.map((seat) {
                        final isSelected = selectedSeats.contains(seat);
                        final isAvailable = seat.isAvailable;
                        final isReserved = seat.isReserved;
                        final isSold = seat.isSold;
                        
                        Color seatColor;
                        if (isSelected) seatColor = const Color(0xFFD4AF37);
                        else if (isSold) seatColor = Colors.red;
                        else if (isReserved) seatColor = Colors.orange;
                        else seatColor = Colors.green;
                        
                        return GestureDetector(
                          onTap: isAvailable || isSelected ? () => onSeatTap(seat) : null,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: seatColor.withOpacity(0.15),
                              border: Border.all(color: seatColor, width: 1.5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                seat.number.toString(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
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
          // Couloir central (optionnel)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 16),
            height: 20,
            color: Colors.grey[200],
            child: const Center(
              child: Text('COULOIR', style: TextStyle(fontSize: 10, color: Colors.grey)),
            ),
          ),
        ],
      ),
    );
  }
}
