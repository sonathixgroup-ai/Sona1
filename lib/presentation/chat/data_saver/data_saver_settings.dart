// lib/presentation/chat/data_saver/data_saver_settings.dart
// Écran de paramètres pour le mode économie de données

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DataSaverSettings extends StatefulWidget {
  const DataSaverSettings({Key? key}) : super(key: key);

  @override
  State<DataSaverSettings> createState() => _DataSaverSettingsState();
}

class _DataSaverSettingsState extends State<DataSaverSettings> {
  bool _isEnabled = false;
  int _maxImageKB = 500;
  int _maxVideoMB = 10;
  bool _compressAutomatically = true;

  static const String _keyEnabled = 'data_saver_enabled';
  static const String _keyMaxImageKB = 'data_saver_max_image_kb';
  static const String _keyMaxVideoMB = 'data_saver_max_video_mb';
  static const String _keyCompressAuto = 'data_saver_compress_auto';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isEnabled = prefs.getBool(_keyEnabled) ?? false;
      _maxImageKB = prefs.getInt(_keyMaxImageKB) ?? 500;
      _maxVideoMB = prefs.getInt(_keyMaxVideoMB) ?? 10;
      _compressAutomatically = prefs.getBool(_keyCompressAuto) ?? true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, _isEnabled);
    await prefs.setInt(_keyMaxImageKB, _maxImageKB);
    await prefs.setInt(_keyMaxVideoMB, _maxVideoMB);
    await prefs.setBool(_keyCompressAuto, _compressAutomatically);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Paramètres sauvegardés')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Économie de données')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Activer le mode économie de données'),
            subtitle: const Text('Réduire la consommation des médias (WiFi uniquement, compression)'),
            value: _isEnabled,
            onChanged: (val) => setState(() => _isEnabled = val),
          ),
          if (_isEnabled) ...[
            const Divider(),
            ListTile(
              title: const Text('Taille max image (Ko)'),
              subtitle: Slider(
                value: _maxImageKB.toDouble(),
                min: 50,
                max: 2000,
                divisions: 39,
                label: '$_maxImageKB Ko',
                onChanged: (val) => setState(() => _maxImageKB = val.toInt()),
              ),
            ),
            ListTile(
              title: const Text('Taille max vidéo (Mo)'),
              subtitle: Slider(
                value: _maxVideoMB.toDouble(),
                min: 1,
                max: 50,
                divisions: 49,
                label: '$_maxVideoMB Mo',
                onChanged: (val) => setState(() => _maxVideoMB = val.toInt()),
              ),
            ),
            SwitchListTile(
              title: const Text('Compression automatique'),
              subtitle: const Text('Réduire qualité avant envoi'),
              value: _compressAutomatically,
              onChanged: (val) => setState(() => _compressAutomatically = val),
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
