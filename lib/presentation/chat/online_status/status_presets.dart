// lib/presentation/chat/online_status/status_presets.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StatusPresets extends StatefulWidget {
  const StatusPresets({super.key});

  @override
  State<StatusPresets> createState() => _StatusPresetsState();
}

class _StatusPresetsState extends State<StatusPresets> {
  List<Map<String, String>> _presets = [];
  final TextEditingController _newPresetController = TextEditingController();

  final List<Map<String, String>> _defaultPresets = const [
    {'text': 'En réunion', 'emoji': '💼'},
    {'text': 'En déplacement', 'emoji': '✈️'},
    {'text': 'En vacances', 'emoji': '🏖️'},
    {'text': 'Télétravail', 'emoji': '🏠'},
    {'text': 'Ne pas déranger', 'emoji': '🔕'},
    {'text': 'Disponible', 'emoji': '✅'},
    {'text': 'En pause', 'emoji': '☕'},
    {'text': 'En ligne', 'emoji': '💻'},
  ];

  @override
  void initState() {
    super.initState();
    _loadPresets();
  }

  Future<void> _loadPresets() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('status_presets');
    if (saved != null && saved.isNotEmpty) {
      setState(() {
        _presets = saved.map((e) => jsonDecode(e) as Map<String, String>).toList();
      });
    } else {
      setState(() {
        _presets = List.from(_defaultPresets);
      });
    }
  }

  Future<void> _savePresets() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = _presets.map((e) => jsonEncode(e)).toList();
    await prefs.setStringList('status_presets', encoded);
  }

  void _addPreset() {
    final text = _newPresetController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _presets.add({
        'text': text,
        'emoji': '📝',
      });
      _newPresetController.clear();
    });
    _savePresets();
  }

  void _removePreset(int index) {
    setState(() {
      _presets.removeAt(index);
    });
    _savePresets();
  }

  void _editPreset(int index) {
    final preset = _presets[index];
    final controller = TextEditingController(text: preset['text']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le statut'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Texte du statut'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _presets[index] = {
                  ...preset,
                  'text': controller.text.trim(),
                };
              });
              _savePresets();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
            ),
            child: const Text('Modifier'),
          ),
        ],
      ),
    );
  }

  void _usePreset(Map<String, String> preset) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_status', '${preset['emoji']} ${preset['text']}');
    if (mounted) {
      Navigator.pop(context, preset);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Statut mis à jour'), duration: Duration(seconds: 1)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statuts prédéfinis'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Nouveau statut
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newPresetController,
                    decoration: const InputDecoration(
                      hintText: 'Nouveau statut...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Color(0xFFD4AF37)),
                  onPressed: _addPreset,
                ),
              ],
            ),
          ),
          // Liste des statuts
          Expanded(
            child: ListView.builder(
              itemCount: _presets.length,
              itemBuilder: (context, index) {
                final preset = _presets[index];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 2),
                    ],
                  ),
                  child: Row(
                    children: [
                      Text(preset['emoji'] ?? '📝', style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          preset['text'] ?? '',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Color(0xFFD4AF37)),
                        onPressed: () => _usePreset(preset),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () => _editPreset(index),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                        onPressed: () => _removePreset(index),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
