// lib/presentation/chat/scheduled/schedule_picker_sheet.dart
// Feuille modale pour choisir une date/heure d'envoi programmé

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SchedulePickerSheet extends StatefulWidget {
  final Function(DateTime scheduledTime) onScheduleSelected;

  const SchedulePickerSheet({Key? key, required this.onScheduleSelected}) : super(key: key);

  @override
  State<SchedulePickerSheet> createState() => _SchedulePickerSheetState();
}

class _SchedulePickerSheetState extends State<SchedulePickerSheet> {
  DateTime _selectedDateTime = DateTime.now().add(const Duration(hours: 1));
  bool _isRecurring = false;

  Future<void> _selectDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );
      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Programmer un message', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Date et heure'),
            subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(_selectedDateTime)),
            trailing: const Icon(Icons.calendar_today),
            onTap: _selectDateTime,
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            title: const Text('Récurrent (chaque jour à cette heure)'),
            value: _isRecurring,
            onChanged: (val) => setState(() => _isRecurring = val ?? false),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  widget.onScheduleSelected(_selectedDateTime);
                  Navigator.pop(context);
                },
                child: const Text('Programmer'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
