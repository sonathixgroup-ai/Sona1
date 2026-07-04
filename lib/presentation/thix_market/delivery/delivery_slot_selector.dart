import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'delivery_provider.dart';

class DeliverySlotSelector extends StatefulWidget {
  final Function(Map<String, dynamic>)? onSlotSelected;

  const DeliverySlotSelector({super.key, this.onSlotSelected});

  @override
  State<DeliverySlotSelector> createState() => _DeliverySlotSelectorState();
}

class _DeliverySlotSelectorState extends State<DeliverySlotSelector> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  final DateFormat _dayFormat = DateFormat('EEE d MMM');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeliveryProvider>().loadAvailableSlots(date: _selectedDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DeliveryProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            // Sélecteur de date
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 7,
                itemBuilder: (context, index) {
                  final date = DateTime.now().add(Duration(days: index + 1));
                  final isSelected = _selectedDate.year == date.year &&
                      _selectedDate.month == date.month &&
                      _selectedDate.day == date.day;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedDate = date);
                      provider.loadAvailableSlots(date: date);
                    },
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFE5592F) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? const Color(0xFFE5592F) : Colors.grey[300]!),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _dayFormat.format(date),
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('dd/MM').format(date),
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? Colors.white70 : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // Créneaux disponibles
            Expanded(
              child: provider.isLoadingSlots
                  ? const Center(child: CircularProgressIndicator())
                  : provider.availableSlots.isEmpty
                      ? const Center(child: Text('Aucun créneau disponible pour cette date'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: provider.availableSlots.length,
                          itemBuilder: (context, index) {
                            final slot = provider.availableSlots[index];
                            final isSelected = provider.selectedSlot?['id'] == slot['id'];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: isSelected ? const Color(0xFFE5592F) : Colors.grey[200]!, width: isSelected ? 2 : 1),
                              ),
                              child: RadioListTile<Map<String, dynamic>>(
                                value: slot,
                                groupValue: provider.selectedSlot,
                                onChanged: (value) {
                                  provider.selectSlot(value!);
                                  widget.onSlotSelected?.call(value);
                                },
                                title: Text('${slot['start_time']} - ${slot['end_time']}'),
                                subtitle: Text('${slot['available_count']} créneaux disponibles'),
                                activeColor: const Color(0xFFE5592F),
                                contentPadding: EdgeInsets.zero,
                              ),
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }
}
