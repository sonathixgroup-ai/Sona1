// lib/presentation/chat/scheduled/recurring_schedule.dart
// Configuration de récurrence pour les messages programmés (quotidien, hebdomadaire, etc.)

import 'package:flutter/material.dart';

enum RecurrenceType {
  none,
  daily,
  weekly,
  monthly,
}

class RecurringSchedule extends StatefulWidget {
  final Function(RecurrenceType type, int? intervalDays) onRecurrenceSelected;

  const RecurringSchedule({Key? key, required this.onRecurrenceSelected}) : super(key: key);

  @override
  State<RecurringSchedule> createState() => _RecurringScheduleState();
}

class _RecurringScheduleState extends State<RecurringSchedule> {
  RecurrenceType _selectedType = RecurrenceType.none;
  int _customIntervalDays = 1;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Répétition', style: TextStyle(fontWeight: FontWeight.bold)),
        RadioListTile<RecurrenceType>(
          title: const Text('Aucune'),
          value: RecurrenceType.none,
          groupValue: _selectedType,
          onChanged: (val) => _updateType(val!),
        ),
        RadioListTile<RecurrenceType>(
          title: const Text('Quotidienne'),
          value: RecurrenceType.daily,
          groupValue: _selectedType,
          onChanged: (val) => _updateType(val!),
        ),
        RadioListTile<RecurrenceType>(
          title: const Text('Hebdomadaire'),
          value: RecurrenceType.weekly,
          groupValue: _selectedType,
          onChanged: (val) => _updateType(val!),
        ),
        RadioListTile<RecurrenceType>(
          title: const Text('Mensuelle'),
          value: RecurrenceType.monthly,
          groupValue: _selectedType,
          onChanged: (val) => _updateType(val!),
        ),
        if (_selectedType == RecurrenceType.none) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Intervalle personnalisé (jours) : '),
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Ex: 3',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) {
                    _customIntervalDays = int.tryParse(val) ?? 1;
                    widget.onRecurrenceSelected(RecurrenceType.none, _customIntervalDays);
                  },
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            widget.onRecurrenceSelected(_selectedType, 
                _selectedType != RecurrenceType.none ? null : _customIntervalDays);
            Navigator.pop(context);
          },
          child: const Text('Appliquer'),
        ),
      ],
    );
  }

  void _updateType(RecurrenceType type) {
    setState(() => _selectedType = type);
    widget.onRecurrenceSelected(type, null);
  }
}
