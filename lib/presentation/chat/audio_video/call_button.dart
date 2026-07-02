// lib/presentation/chat/audio_video/call_button.dart
// Bouton pour initier un appel (audio ou vidéo)

import 'package:flutter/material.dart';

class CallButton extends StatelessWidget {
  final VoidCallback onAudioCall;
  final VoidCallback onVideoCall;

  const CallButton({
    Key? key,
    required this.onAudioCall,
    required this.onVideoCall,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.call, color: Colors.green),
          onPressed: onAudioCall,
          tooltip: 'Appel audio',
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.videocam, color: Colors.blue),
          onPressed: onVideoCall,
          tooltip: 'Appel vidéo',
        ),
      ],
    );
  }
}
