// presentation/chat/screens/chat_incoming_call_screen.dart
import 'package:flutter/material.dart';
import '../audio_video/incoming_call_screen.dart';

class ChatIncomingCallScreen extends StatelessWidget {
  final String callerName;
  final String? callerAvatarUrl;
  final bool isVideoCall;

  const ChatIncomingCallScreen({
    super.key,
    this.callerName = 'Appel entrant',
    this.callerAvatarUrl,
    this.isVideoCall = false,
  });

  @override
  Widget build(BuildContext context) {
    return IncomingCallScreen(
      callerName: callerName,
      callerAvatarUrl: callerAvatarUrl,
      isVideoCall: isVideoCall,
      onAccept: () => Navigator.pop(context, 'accept'),
      onDecline: () => Navigator.pop(context, 'decline'),
    );
  }
}
