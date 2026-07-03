// lib/presentation/chat/archive/advanced_search_sheet.dart
import 'package:flutter/material.dart';
import 'search_filters.dart';

class AdvancedSearchSheet extends StatefulWidget {
  final Function(SearchFilters) onSearch;

  const AdvancedSearchSheet({super.key, required this.onSearch});

  @override
  State<AdvancedSearchSheet> createState() => _AdvancedSearchSheetState();
}

class _AdvancedSearchSheetState extends State<AdvancedSearchSheet> {
  final TextEditingController _queryController = TextEditingController();
  String _selectedType = 'all';
  String _selectedDateRange = 'anytime';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _hasMedia = false;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Recherche avancée',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _queryController,
            decoration: const InputDecoration(
              hintText: 'Rechercher...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedType,
            decoration: const InputDecoration(
              labelText: 'Type de conversation',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('Tous les types')),
              DropdownMenuItem(value: 'private', child: Text('Privé')),
              DropdownMenuItem(value: 'group', child: Text('Groupe')),
            ],
            onChanged: (value) => setState(() => _selectedType = value!),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedDateRange,
            decoration: const InputDecoration(
              labelText: 'Période',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'anytime', child: Text('À tout moment')),
              DropdownMenuItem(value: 'today', child: Text("Aujourd'hui")),
              DropdownMenuItem(value: 'week', child: Text('Cette semaine')),
              DropdownMenuItem(value: 'month', child: Text('Ce mois')),
            ],
            onChanged: (value) => setState(() => _selectedDateRange = value!),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) setState(() => _startDate = date);
                  },
                  child: Text(_startDate != null
                      ? 'Du ${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                      : 'Date de début'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) setState(() => _endDate = date);
                  },
                  child: Text(_endDate != null
                      ? 'Au ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                      : 'Date de fin'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            title: const Text('Avec médias uniquement'),
            value: _hasMedia,
            onChanged: (value) => setState(() => _hasMedia = value ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final filters = SearchFilters(
                  query: _queryController.text.trim(),
                  type: _selectedType == 'all' ? null : _selectedType,
                  dateRange: _selectedDateRange == 'anytime' ? null : _selectedDateRange,
                  startDate: _startDate,
                  endDate: _endDate,
                  hasMedia: _hasMedia,
                );
                widget.onSearch(filters);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.white,
              ),
              child: const Text('Rechercher'),
            ),
          ),
        ],
      ),
    );
  }
}
