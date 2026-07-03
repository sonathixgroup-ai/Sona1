// lib/presentation/chat/offline/offline_settings.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineSettings extends StatefulWidget {
  const OfflineSettings({super.key});

  @override
  State<OfflineSettings> createState() => _OfflineSettingsState();
}

class _OfflineSettingsState extends State<OfflineSettings> {
  bool _autoDownload = false;
  int _maxCacheSize = 100; // Mo
  bool _compressMedia = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoDownload = prefs.getBool('offline_auto_download') ?? false;
      _maxCacheSize = prefs.getInt('offline_max_cache') ?? 100;
      _compressMedia = prefs.getBool('offline_compress') ?? true;
    });
  }

  Future<void> _saveAutoDownload(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('offline_auto_download', value);
    setState(() => _autoDownload = value);
  }

  Future<void> _saveCompressMedia(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('offline_compress', value);
    setState(() => _compressMedia = value);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SwitchListTile(
          title: const Text('Téléchargement automatique'),
          subtitle: const Text('Télécharger les messages en arrière-plan'),
          value: _autoDownload,
          onChanged: _saveAutoDownload,
        ),
        SwitchListTile(
          title: const Text('Compresser les médias'),
          subtitle: const Text('Réduire la qualité pour économiser l\'espace'),
          value: _compressMedia,
          onChanged: _saveCompressMedia,
        ),
        ListTile(
          title: const Text('Taille maximale du cache'),
          subtitle: Text('$_maxCacheSize Mo'),
          trailing: Slider(
            value: _maxCacheSize.toDouble(),
            min: 50,
            max: 500,
            divisions: 9,
            label: '$_maxCacheSize Mo',
            onChanged: (value) async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setInt('offline_max_cache', value.toInt());
              setState(() => _maxCacheSize = value.toInt());
            },
          ),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.delete_outline),
          title: const Text('Vider le cache'),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cache vidé')),
            );
          },
        ),
      ],
    );
  }
}
