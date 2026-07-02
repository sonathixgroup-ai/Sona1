// lib/presentation/chat/archive/advanced_search_sheet.dart
// Feuille modale pour recherche avancée (texte, date, type, contact)

import 'package:flutter/material.dart';

class AdvancedSearchSheet extends StatefulWidget {
  final Function(SearchFilters) onSearch;

  const AdvancedSearchSheet({Key? key, required this.onSearch}) : super(key: key);

  @override
  State<AdvancedSearchSheet> createState() => _AdvancedSearchSheetState();
}

class _AdvancedSearchSheetState extends State<AdvancedSearchSheet> {
  final TextEditingController _textController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String? _contactName;
  String? _messageType; // text, image, video, audio

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recherche avancée', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: _textController,
            decoration: const InputDecoration(
              hintText: 'Mot(s) clé(s)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ListTile(
                  title: const Text('Du'),
                  subtitle: Text(_startDate != null ? _formatDate(_startDate!) : 'Aucune'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) setState(() => _startDate = date);
                  },
                ),
              ),
              Expanded(
                child: ListTile(
                  title: const Text('Au'),
                  subtitle: Text(_endDate != null ? _formatDate(_endDate!) : 'Aucune'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) setState(() => _endDate = date);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _messageType,
            decoration: const InputDecoration(labelText: 'Type de message'),
            items: const [
              DropdownMenuItem(value: null, child: Text('Tous')),
              DropdownMenuItem(value: 'text', child: Text('Texte')),
              DropdownMenuItem(value: 'image', child: Text('Image')),
              DropdownMenuItem(value: 'video', child: Text('Vidéo')),
              DropdownMenuItem(value: 'audio', child: Text('Audio')),
            ],
            onChanged: (val) => setState(() => _messageType = val),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  final filters = SearchFilters(
                    text: _textController.text.trim(),
                    startDate: _startDate,
                    endDate: _endDate,
                    contactName: _contactName,
                    messageType: _messageType,
                  );
                  widget.onSearch(filters);
                  Navigator.pop(context);
                },
                child: const Text('Rechercher'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
