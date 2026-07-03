// lib/presentation/chat/online_status/availability_schedule.dart
import 'package:flutter/material.dart';

class AvailabilitySchedule extends StatefulWidget {
  const AvailabilitySchedule({super.key});

  @override
  State<AvailabilitySchedule> createState() => _AvailabilityScheduleState();
}

class _AvailabilityScheduleState extends State<AvailabilitySchedule> {
  bool _isEnabled = false;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 18, minute: 0);
  List<int> _selectedDays = [1, 2, 3, 4, 5]; // Lundi à Vendredi

  final List<String> _weekDays = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planification de disponibilité'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              // TODO: Enregistrer les paramètres
              Navigator.pop(context);
            },
            child: const Text('Enregistrer', style: TextStyle(color: Color(0xFFD4AF37))),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Activer la planification'),
              subtitle: const Text('Changer automatiquement de statut selon l\'horaire'),
              value: _isEnabled,
              onChanged: (value) => setState(() => _isEnabled = value),
              activeColor: const Color(0xFFD4AF37),
            ),
            if (_isEnabled) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: _startTime,
                        );
                        if (time != null) setState(() => _startTime = time);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time, size: 16, color: Color(0xFFD4AF37)),
                            const SizedBox(width: 8),
                            Text(_startTime.format(context)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('-'),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: _endTime,
                        );
                        if (time != null) setState(() => _endTime = time);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time, size: 16, color: Color(0xFFD4AF37)),
                            const SizedBox(width: 8),
                            Text(_endTime.format(context)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Jours actifs', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (index) {
                  final isSelected = _selectedDays.contains(index);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedDays.remove(index);
                        } else {
                          _selectedDays.add(index);
                        }
                      });
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFD4AF37) : Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _weekDays[index],
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.white : Colors.grey[600],
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
