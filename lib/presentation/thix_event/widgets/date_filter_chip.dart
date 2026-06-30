// lib/presentation/thix_event/widgets/date_filter_chip.dart
import 'package:flutter/material.dart';

class DateFilterChip extends StatelessWidget {
  final String label;
  final String value;
  final bool isSelected;
  final VoidCallback onTap;

  const DateFilterChip({
    super.key,
    required this.label,
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD4AF37).withOpacity(0.15) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? const Color(0xFFD4AF37) : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? const Color(0xFFD4AF37) : Colors.grey[700],
          ),
        ),
      ),
    );
  }
}

class DateFilterRow extends StatefulWidget {
  final Function(String) onFilterChanged;
  final String initialFilter;

  const DateFilterRow({
    super.key,
    required this.onFilterChanged,
    this.initialFilter = 'all',
  });

  @override
  State<DateFilterRow> createState() => _DateFilterRowState();
}

class _DateFilterRowState extends State<DateFilterRow> {
  late String _selectedFilter;

  final List<Map<String, String>> _filters = [
    {'value': 'today', 'label': "Aujourd'hui"},
    {'value': 'week', 'label': 'Cette semaine'},
    {'value': 'month', 'label': 'Ce mois'},
    {'value': 'all', 'label': 'Tous'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: _filters.map((filter) {
          final isSelected = _selectedFilter == filter['value'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text(filter['label']!, style: const TextStyle(fontSize: 12)),
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedFilter = filter['value']!);
                  widget.onFilterChanged(filter['value']!);
                }
              },
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFFD4AF37).withOpacity(0.15),
              side: BorderSide(color: isSelected ? const Color(0xFFD4AF37) : Colors.grey[300]!),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
          );
        }).toList(),
      ),
    );
  }
}
