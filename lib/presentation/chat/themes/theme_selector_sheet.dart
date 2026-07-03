// lib/presentation/chat/themes/theme_selector_sheet.dart
import 'package:flutter/material.dart';

class ThemeSelectorSheet extends StatefulWidget {
  const ThemeSelectorSheet({super.key});

  @override
  State<ThemeSelectorSheet> createState() => _ThemeSelectorSheetState();
}

class _ThemeSelectorSheetState extends State<ThemeSelectorSheet> {
  String _selectedTheme = 'classic';

  final List<Map<String, dynamic>> _themes = [
    {'name': 'Classique', 'value': 'classic', 'color': Color(0xFF0B1B3D)},
    {'name': 'Doré', 'value': 'gold', 'color': Color(0xFFD4AF37)},
    {'name': 'Sombre', 'value': 'dark', 'color': Colors.black},
    {'name': 'Clair', 'value': 'light', 'color': Colors.white},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choisir un thème'),
      ),
      body: ListView.builder(
        itemCount: _themes.length,
        itemBuilder: (context, index) {
          final theme = _themes[index];
          final isSelected = _selectedTheme == theme['value'];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: theme['color'],
            ),
            title: Text(theme['name']),
            trailing: isSelected
                ? const Icon(Icons.check_circle, color: Colors.green)
                : const Icon(Icons.circle_outlined),
            onTap: () {
              setState(() => _selectedTheme = theme['value']);
              // Appliquer le thème (par exemple via un ThemeProvider)
            },
          );
        },
      ),
    );
  }
}
