// lib/presentation/chat/group_admin/do_not_disturb_settings.dart
import 'package:flutter/material.dart';

class DoNotDisturbSettings extends StatefulWidget {
  final bool isEnabled;
  final DateTime? until;
  final Function(bool enabled, DateTime? until) onSave;

  const DoNotDisturbSettings({
    Key? key,
    required this.isEnabled,
    this.until,
    required this.onSave,
  }) : super(key: key);

  @override
  State<DoNotDisturbSettings> createState() => _DoNotDisturbSettingsState();
}

class _DoNotDisturbSettingsState extends State<DoNotDisturbSettings> {
  late bool _enabled;
  DateTime? _until;
  int? _selectedPreset; // suivi de la durée prédéfinie sélectionnée
  final List<int> _presetHours = [1, 2, 4, 8, 24];

  @override
  void initState() {
    super.initState();
    _enabled = widget.isEnabled;
    _until = widget.until;
    // Si une durée prédéfinie correspond à _until (à peu près), on la sélectionne
    if (_until != null) {
      final diff = _until!.difference(DateTime.now()).inHours;
      _selectedPreset = _presetHours.contains(diff) ? diff : null;
    }
  }

  Future<void> _selectDateTime() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _until ?? DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_until ?? DateTime.now()),
      );
      if (time != null) {
        setState(() {
          _until = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
          _selectedPreset = null; // désélectionne le preset quand on choisit manuellement
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ne pas déranger')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Activer Ne pas déranger'),
            subtitle: const Text('Vous ne recevrez pas de notifications de ce groupe'),
            value: _enabled,
            onChanged: (val) => setState(() => _enabled = val),
          ),
          if (_enabled) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('Durée prédéfinie',
                  style: Theme.of(context).textTheme.titleSmall),
            ),
            Wrap(
              spacing: 8,
              children: _presetHours.map((h) {
                final isSelected = _selectedPreset == h;
                return ChoiceChip(
                  label: Text('$h h'),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedPreset = h;
                        _until = DateTime.now().add(Duration(hours: h));
                      });
                    } else {
                      setState(() {
                        _selectedPreset = null;
                        _until = null;
                      });
                    }
                  },
                );
              }).toList(),
            ),
            ListTile(
              title: const Text('Personnalisé'),
              subtitle: Text(_until != null
                  ? 'Jusqu\'au ${_formatDateTime(_until!)}'
                  : 'Aucune limite'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selectDateTime,
            ),
          ],
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () => widget.onSave(_enabled, _enabled ? _until : null),
              child: const Text('Enregistrer'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
