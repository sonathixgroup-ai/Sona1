// lib/presentation/chat/themes/chat_wallpaper_picker.dart
import 'package:flutter/material.dart';

class ChatWallpaperPicker extends StatefulWidget {
  const ChatWallpaperPicker({super.key});

  @override
  State<ChatWallpaperPicker> createState() => _ChatWallpaperPickerState();
}

class _ChatWallpaperPickerState extends State<ChatWallpaperPicker> {
  String? _selectedWallpaper;

  // Liste des fonds d'écran disponibles (couleurs ou assets)
  final List<Map<String, dynamic>> _wallpapers = [
    {'name': 'Défaut', 'color': Colors.white, 'asset': null},
    {'name': 'Nuit', 'color': const Color(0xFF1A1A2E), 'asset': null},
    {'name': 'Nature', 'color': null, 'asset': 'assets/wallpapers/nature.jpg'},
    {'name': 'Abstrait', 'color': null, 'asset': 'assets/wallpapers/abstract.jpg'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fond d\'écran')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _wallpapers.length,
        itemBuilder: (context, index) {
          final wallpaper = _wallpapers[index];
          final isSelected = _selectedWallpaper == wallpaper['name'];
          return GestureDetector(
            onTap: () => setState(() => _selectedWallpaper = wallpaper['name']),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? const Color(0xFFD4AF37) : Colors.grey.shade300,
                  width: isSelected ? 3 : 1,
                ),
                image: wallpaper['asset'] != null
                    ? DecorationImage(
                        image: AssetImage(wallpaper['asset']),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: wallpaper['color'] as Color?,
              ),
              child: Center(
                child: Text(
                  wallpaper['name'],
                  style: TextStyle(
                    color: wallpaper['color'] != null
                        ? (wallpaper['color'] == Colors.white ? Colors.black : Colors.white)
                        : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
