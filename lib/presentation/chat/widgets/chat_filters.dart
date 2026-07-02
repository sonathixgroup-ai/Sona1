// lib/presentation/chat/widgets/chat_filters.dart
import 'package:flutter/material.dart';

class ChatFilters extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onFilterSelected;

  const ChatFilters({
    Key? key,
    required this.selectedFilter,
    required this.onFilterSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const filters = ['Tous', 'Équipes', 'Appels', 'Favoris', 'Rendez-vous'];
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Text(filter),
              selected: selectedFilter == filter,
              onSelected: (_) => onFilterSelected(filter),
              labelStyle: const TextStyle(fontSize: 12),
              selectedColor: Colors.blue.shade100,
            ),
          );
        },
      ),
    );
  }
}
