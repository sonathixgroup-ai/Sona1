// lib/presentation/chat/online_status/availability_schedule.dart
// Planification des horaires de disponibilité en ligne

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AvailabilitySchedule extends StatefulWidget {
  const AvailabilitySchedule({Key? key}) : super(key: key);

  @override
  State<AvailabilitySchedule> createState() => _AvailabilityScheduleState();
}

class _AvailabilityScheduleState extends State<AvailabilitySchedule> {
  bool _isScheduleEnabled = false;
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 20, minute: 0);
  final Set<int> _activeDays = {1, 2, 3, 4, 5}; // Lun-Ven par défaut

  static const String _keyEnabled = 'availability_schedule_enabled';
  static const String _keyStartHour = 'availability_start_hour';
  static const String _keyStartMinute = 'availability_start_minute';
  static const String _keyEndHour = 'availability_end_hour';
  static const String _keyEndMinute = 'availability_end_minute';
  static const String _keyDays = 'availability_days';

  final _dayLabels = const ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _isScheduleEnabled = prefs.getBool(_keyEnabled) ?? false;
      _startTime = TimeOfDay(
        hour: prefs.getInt(_keyStartHour) ?? 8,
        minute: prefs.getInt(_keyStartMinute) ?? 0,
      );
      _endTime = TimeOfDay(
        hour: prefs.getInt(_keyEndHour) ?? 20,
        minute: prefs.getInt(_keyEndMinute) ?? 0,
      );
      final days = prefs.getStringList(_keyDays);
      if (days != null) {
        _activeDays
          ..clear()
          ..addAll(days.map(int.parse));
      }
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, _isScheduleEnabled);
    await prefs.setInt(_keyStartHour, _startTime.hour);
    await prefs.setInt(_keyStartMinute, _startTime.minute);
    await prefs.setInt(_keyEndHour, _endTime.hour);
    await prefs.setInt(_keyEndMinute, _endTime.minute);
    await prefs.setStringList(_keyDays, _activeDays.map((d) => d.toString()).toList());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Horaires enregistrés')),
      );
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() => isStart ? _startTime = picked : _endTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Horaires de disponibilité')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Activer les horaires programmés'),
            subtitle: const Text('Statut "hors ligne" automatique en dehors des heures définies'),
            value: _isScheduleEnabled,
            onChanged: (val) => setState(() => _isScheduleEnabled = val),
          ),
          if (_isScheduleEnabled) ...[
            const Divider(),
            ListTile(
              title: const Text('Heure de début'),
              trailing: Text(_startTime.format(context)),
              onTap: () => _pickTime(true),
            ),
            ListTile(
              title: const Text('Heure de fin'),
              trailing: Text(_endTime.format(context)),
              onTap: () => _pickTime(false),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text('Jours actifs', style: TextStyle(fontWeight: FontWeight.w500)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Wrap(
                spacing: 8,
                children: List.generate(7, (index) {
                  final day = index + 1;
                  final selected = _activeDays.contains(day);
                  return FilterChip(
                    label: Text(_dayLabels[index]),
                    selected: selected,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _activeDays.add(day);
                        } else {
                          _activeDays.remove(day);
                        }
                      });
                    },
                  );
                }),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _saveSettings,
              child: const Text('Enregistrer'),
            ),
          ),
        ],
      ),
    );
  }
}
