// lib/presentation/chat/themes/notification_sounds_settings.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSoundsSettings extends StatefulWidget {
  const NotificationSoundsSettings({super.key});

  @override
  State<NotificationSoundsSettings> createState() => _NotificationSoundsSettingsState();
}

class _NotificationSoundsSettingsState extends State<NotificationSoundsSettings> {
  String _selectedSound = 'default';
  double _volume = 0.8;
  bool _vibrate = true;
  bool _soundEnabled = true;

  final List<Map<String, dynamic>> _sounds = [
    {'name': 'Défaut', 'value': 'default', 'icon': Icons.notifications},
    {'name': 'Doux', 'value': 'soft', 'icon': Icons.volume_down},
    {'name': 'Énergique', 'value': 'energetic', 'icon': Icons.volume_up},
    {'name': 'Classique', 'value': 'classic', 'icon': Icons.music_note},
    {'name': 'Silencieux', 'value': 'silent', 'icon': Icons.volume_off},
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedSound = prefs.getString('notification_sound') ?? 'default';
      _volume = prefs.getDouble('notification_volume') ?? 0.8;
      _vibrate = prefs.getBool('notification_vibrate') ?? true;
      _soundEnabled = prefs.getBool('notification_sound_enabled') ?? true;
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    } else {
      await prefs.setString(key, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sons de notification'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        children: [
          // Activer/Désactiver les sons
          Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SwitchListTile(
              title: const Text('Activer les sons', style: TextStyle(fontSize: 13)),
              value: _soundEnabled,
              onChanged: (value) {
                setState(() => _soundEnabled = value);
                _saveSetting('notification_sound_enabled', value);
              },
              activeColor: const Color(0xFFD4AF37),
            ),
          ),

          if (_soundEnabled) ...[
            // Sélection du son
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Son de notification',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  ..._sounds.map((sound) {
                    final isSelected = _selectedSound == sound['value'];
                    return RadioListTile<String>(
                      value: sound['value'],
                      groupValue: _selectedSound,
                      onChanged: (value) {
                        setState(() => _selectedSound = value!);
                        _saveSetting('notification_sound', value);
                      },
                      title: Text(sound['name'], style: const TextStyle(fontSize: 12)),
                      secondary: Icon(sound['icon'], size: 20, color: isSelected ? const Color(0xFFD4AF37) : Colors.grey),
                      activeColor: const Color(0xFFD4AF37),
                      contentPadding: EdgeInsets.zero,
                    );
                  }),
                ],
              ),
            ),

            // Volume
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Volume',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.volume_down, size: 16, color: Colors.grey),
                      Expanded(
                        child: Slider(
                          value: _volume,
                          min: 0,
                          max: 1,
                          divisions: 10,
                          onChanged: (value) {
                            setState(() => _volume = value);
                            _saveSetting('notification_volume', value);
                          },
                          activeColor: const Color(0xFFD4AF37),
                        ),
                      ),
                      const Icon(Icons.volume_up, size: 16, color: const Color(0xFFD4AF37)),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // Vibration (indépendant du son)
          Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SwitchListTile(
              title: const Text('Vibration', style: TextStyle(fontSize: 13)),
              subtitle: const Text('Vibrer lors des notifications', style: TextStyle(fontSize: 10)),
              value: _vibrate,
              onChanged: (value) {
                setState(() => _vibrate = value);
                _saveSetting('notification_vibrate', value);
              },
              activeColor: const Color(0xFFD4AF37),
            ),
          ),
        ],
      ),
    );
  }
}
