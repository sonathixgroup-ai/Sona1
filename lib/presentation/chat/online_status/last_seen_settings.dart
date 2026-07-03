// lib/presentation/chat/online_status/last_seen_settings.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LastSeenSettings extends StatefulWidget {
  const LastSeenSettings({super.key});

  @override
  State<LastSeenSettings> createState() => _LastSeenSettingsState();
}

class _LastSeenSettingsState extends State<LastSeenSettings> {
  String _visibility = 'everyone'; // everyone, contacts, nobody

  @override
  void initState() {
    super.initState();
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _visibility = prefs.getString('last_seen_visibility') ?? 'everyone';
    });
  }

  Future<void> _savePreference(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_seen_visibility', value);
    setState(() => _visibility = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Visibilité du dernier vu')),
      body: ListView(
        children: [
          RadioListTile<String>(
            title: const Text('Tout le monde'),
            value: 'everyone',
            groupValue: _visibility,
            onChanged: (value) => _savePreference(value!),
          ),
          RadioListTile<String>(
            title: const Text('Mes contacts'),
            value: 'contacts',
            groupValue: _visibility,
            onChanged: (value) => _savePreference(value!),
          ),
          RadioListTile<String>(
            title: const Text('Personne'),
            value: 'nobody',
            groupValue: _visibility,
            onChanged: (value) => _savePreference(value!),
          ),
        ],
      ),
    );
  }
}
