// lib/presentation/chat/audio_video/incoming_call_screen.dart
// Écran affiché lors d'un appel entrant (avec accept/refuser)

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class IncomingCallScreen extends StatelessWidget {
  final String callerName;
  final String? callerAvatarUrl;
  final bool isVideoCall;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const IncomingCallScreen({
    Key? key,
    required this.callerName,
    this.callerAvatarUrl,
    required this.isVideoCall,
    required this.onAccept,
    required this.onDecline,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: callerAvatarUrl != null
                  ? CachedNetworkImageProvider(callerAvatarUrl!)
                  : const AssetImage('assets/default_avatar.png') as ImageProvider,
            ),
            const SizedBox(height: 24),
            Text(
              callerName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              isVideoCall ? 'Appel vidéo entrant...' : 'Appel audio entrant...',
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FloatingActionButton(
                  heroTag: 'decline',
                  backgroundColor: Colors.red,
                  onPressed: onDecline,
                  child: const Icon(Icons.call_end),
                ),
                FloatingActionButton(
                  heroTag: 'accept',
                  backgroundColor: Colors.green,
                  onPressed: onAccept,
                  child: Icon(isVideoCall ? Icons.videocam : Icons.call),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
