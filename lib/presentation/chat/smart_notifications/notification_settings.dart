// lib/presentation/chat/smart_notifications/notification_settings.dart
// Paramètres de notifications intelligentes (par conversation, priorité, heures silencieuses)

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettings extends StatefulWidget {
  const NotificationSettings({Key? key}) : super(key: key);

  @override
  State<NotificationSettings> createState() => _NotificationSettingsState();
}

class _NotificationSettingsState extends State<NotificationSettings> {
  bool _globalEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  String _priorityMode = 'all'; // all, mentions_only, none
  TimeOfDay? _quietStart;
  TimeOfDay? _quietEnd;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _globalEnabled = prefs.getBool('notif_global') ?? true;
      _soundEnabled = prefs.getBool('notif_sound') ?? true;
      _vibrationEnabled = prefs.getBool('notif_vibration') ?? true;
      _priorityMode = prefs.getString('notif_priority_mode') ?? 'all';
      final start = prefs.getString('notif_quiet_start');
      final end = prefs.getString('notif_quiet_end');
      if (start != null) _quietStart = TimeOfDay(hour: int.parse(start.split(':')[0]), minute: int.parse(start.split(':')[1]));
      if (end != null) _quietEnd = TimeOfDay(hour: int.parse(end.split(':')[0]), minute: int.parse(end.split(':')[1]));
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_global', _globalEnabled);
    await prefs.setBool('notif_sound', _soundEnabled);
    await prefs.setBool('notif_vibration', _vibrationEnabled);
    await prefs.setString('notif_priority_mode', _priorityMode);
    if (_quietStart != null) await prefs.setString('notif_quiet_start', '${_quietStart!.hour}:${_quietStart!.minute}');
    if (_quietEnd != null) await prefs.setString('notif_quiet_end', '${_quietEnd!.hour}:${_quietEnd!.minute}');
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paramètres sauvegardés')));
  }

  Future<void> _selectTime(String type) async {
    final current = type == 'start' ? _quietStart : _quietEnd;
    final time = await showTimePicker(
      context: context,
      initialTime: current ?? const TimeOfDay(hour: 22, minute: 0),
    );
    if (time != null) {
      setState(() {
        if (type == 'start') _quietStart = time;
        else _quietEnd = time;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Activer les notifications'),
            value: _globalEnabled,
            onChanged: (val) => setState(() => _globalEnabled = val),
          ),
          if (_globalEnabled) ...[
            SwitchListTile(
              title: const Text('Son'),
              value: _soundEnabled,
              onChanged: (val) => setState(() => _soundEnabled = val),
            ),
            SwitchListTile(
              title: const Text('Vibration'),
              value: _vibrationEnabled,
              onChanged: (val) => setState(() => _vibrationEnabled = val),
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Mode priorité', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            RadioListTile<String>(
              title: const Text('Tous les messages'),
              value: 'all',
              groupValue: _priorityMode,
              onChanged: (val) => setState(() => _priorityMode = val!),
            ),
            RadioListTile<String>(
              title: const Text('Uniquement les mentions'),
              value: 'mentions_only',
              groupValue: _priorityMode,
              onChanged: (val) => setState(() => _priorityMode = val!),
            ),
            RadioListTile<String>(
              title: const Text('Aucun'),
              value: 'none',
              groupValue: _priorityMode,
              onChanged: (val) => setState(() => _priorityMode = val!),
            ),
            const Divider(),
            ListTile(
              title: const Text('Heures silencieuses'),
              subtitle: Text(_quietStart != null && _quietEnd != null
                  ? '${_quietStart!.format(context)} - ${_quietEnd!.format(context)}'
                  : 'Désactivé'),
              trailing: const Icon(Icons.bedtime),
              onTap: () => _selectTime('start'),
            ),
            if (_quietStart != null)
              ListTile(
                title: const Text('Heure de fin'),
                subtitle: Text(_quietEnd?.format(context) ?? 'Non défini'),
                trailing: const Icon(Icons.wb_sunny),
                onTap: () => _selectTime('end'),
              ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _saveSettings,
                child: const Text('Enregistrer'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
