// lib/presentation/chat/audio_video/call_notification_widget.dart
// Widget de notification flottante (toast/banner) pour appel entrant

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CallNotificationWidget extends StatelessWidget {
  final String callerName;
  final String? callerAvatarUrl;
  final bool isVideoCall;
  final VoidCallback onAnswer;
  final VoidCallback onDecline;

  const CallNotificationWidget({
    Key? key,
    required this.callerName,
    this.callerAvatarUrl,
    required this.isVideoCall,
    required this.onAnswer,
    required this.onDecline,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Material(
        elevation: 4,
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: callerAvatarUrl != null
                    ? CachedNetworkImageProvider(callerAvatarUrl!)
                    : const AssetImage('assets/default_avatar.png') as ImageProvider,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(callerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      isVideoCall ? 'Appel vidéo entrant' : 'Appel audio entrant',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.call_end, color: Colors.red),
                onPressed: onDecline,
              ),
              IconButton(
                icon: Icon(isVideoCall ? Icons.videocam : Icons.call, color: Colors.green),
                onPressed: onAnswer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
