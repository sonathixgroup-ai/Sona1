// lib/presentation/thix_event/widgets/share_button.dart
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../models/event_model.dart';

class ShareButton extends StatelessWidget {
  final Event event;
  final bool isIconOnly;
  final double size;

  const ShareButton({
    super.key,
    required this.event,
    this.isIconOnly = true,
    this.size = 18,
  });

  @override
  Widget build(BuildContext context) {
    if (isIconOnly) {
      return IconButton(
        icon: Icon(Icons.share, size: size, color: Colors.grey[600]),
        onPressed: () => _shareEvent(context),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      );
    }

    return ElevatedButton.icon(
      onPressed: () => _shareEvent(context),
      icon: Icon(Icons.share, size: size, color: const Color(0xFFD4AF37)),
      label: const Text('Partager', style: TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFD4AF37),
        elevation: 0,
        side: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Future<void> _shareEvent(BuildContext context) async {
    final message = '''
🎫 ${event.title}

📅 ${event.formattedDate}
📍 ${event.location}
💰 ${event.formattedPrice}

${event.description}

Réservez sur THIX ÉVÉNEMENT !
    ''';

    await Share.share(message);
  }
}
