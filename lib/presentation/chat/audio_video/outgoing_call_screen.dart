// lib/presentation/chat/audio_video/outgoing_call_screen.dart
// Écran lors d'un appel sortant (en attente de réponse)

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class OutgoingCallScreen extends StatelessWidget {
  final String calleeName;
  final String? calleeAvatarUrl;
  final bool isVideoCall;
  final VoidCallback onCancel;

  const OutgoingCallScreen({
    Key? key,
    required this.calleeName,
    this.calleeAvatarUrl,
    required this.isVideoCall,
    required this.onCancel,
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
              backgroundImage: calleeAvatarUrl != null
                  ? CachedNetworkImageProvider(calleeAvatarUrl!)
                  : const AssetImage('assets/default_avatar.png') as ImageProvider,
            ),
            const SizedBox(height: 24),
            Text(
              calleeName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              isVideoCall ? 'Appel vidéo en cours...' : 'Appel audio en cours...',
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 48),
            FloatingActionButton(
              heroTag: 'cancel',
              backgroundColor: Colors.red,
              onPressed: onCancel,
              child: const Icon(Icons.call_end),
            ),
          ],
        ),
      ),
    );
  }
}
