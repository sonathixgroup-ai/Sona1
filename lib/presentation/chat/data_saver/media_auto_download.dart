// lib/presentation/chat/data_saver/media_auto_download.dart
// Paramètres de téléchargement automatique des médias (WiFi / données mobiles)

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AutoDownloadPolicy {
  always,      // toujours
  wifiOnly,    // WiFi uniquement
  never,       // jamais
}

class MediaAutoDownloadSettings extends StatefulWidget {
  const MediaAutoDownloadSettings({Key? key}) : super(key: key);

  @override
  State<MediaAutoDownloadSettings> createState() => _MediaAutoDownloadSettingsState();
}

class _MediaAutoDownloadSettingsState extends State<MediaAutoDownloadSettings> {
  AutoDownloadPolicy _images = AutoDownloadPolicy.wifiOnly;
  AutoDownloadPolicy _videos = AutoDownloadPolicy.wifiOnly;
  AutoDownloadPolicy _audio = AutoDownloadPolicy.always;

  static const String _keyImages = 'auto_download_images';
  static const String _keyVideos = 'auto_download_videos';
  static const String _keyAudio = 'auto_download_audio';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _images = AutoDownloadPolicy.values[prefs.getInt(_keyImages) ?? 1];
      _videos = AutoDownloadPolicy.values[prefs.getInt(_keyVideos) ?? 1];
      _audio = AutoDownloadPolicy.values[prefs.getInt(_keyAudio) ?? 0];
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyImages, _images.index);
    await prefs.setInt(_keyVideos, _videos.index);
    await prefs.setInt(_keyAudio, _audio.index);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Préférences enregistrées')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Téléchargement automatique')),
      body: ListView(
        children: [
          _buildPolicyTile('Images', _images, (val) => setState(() => _images = val)),
          _buildPolicyTile('Vidéos', _videos, (val) => setState(() => _videos = val)),
          _buildPolicyTile('Messages audio', _audio, (val) => setState(() => _audio = val)),
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

  Widget _buildPolicyTile(String title, AutoDownloadPolicy current, ValueChanged<AutoDownloadPolicy> onChanged) {
    return ListTile(
      title: Text(title),
      subtitle: Text(_policyString(current)),
      trailing: PopupMenuButton<AutoDownloadPolicy>(
        initialValue: current,
        onSelected: onChanged,
        itemBuilder: (context) => [
          const PopupMenuItem(value: AutoDownloadPolicy.always, child: Text('Toujours')),
          const PopupMenuItem(value: AutoDownloadPolicy.wifiOnly, child: Text('WiFi uniquement')),
          const PopupMenuItem(value: AutoDownloadPolicy.never, child: Text('Jamais')),
        ],
      ),
    );
  }

  String _policyString(AutoDownloadPolicy policy) {
    switch (policy) {
      case AutoDownloadPolicy.always: return 'Toujours télécharger';
      case AutoDownloadPolicy.wifiOnly: return 'Seulement en WiFi';
      case AutoDownloadPolicy.never: return 'Jamais (manuel)';
    }
  }
}
