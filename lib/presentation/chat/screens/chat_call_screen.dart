// presentation/chat/screens/chat_call_screen.dart
import 'package:flutter/material.dart';
import '../audio_video/outgoing_call_screen.dart';

class ChatCallScreen extends StatelessWidget {
  final String callId;
  final String callName;
  final List<dynamic> participants;
  final bool isVideoCall;

  const ChatCallScreen({
    super.key,
    this.callId = '',
    this.callName = 'Appel',
    this.participants = const [],
    this.isVideoCall = false,
  });

  @override
  Widget build(BuildContext context) {
    return OutgoingCallScreen(
      calleeName: callName,
      calleeAvatarUrl: null,
      isVideoCall: isVideoCall,
      onCancel: () => Navigator.pop(context),
    );
  }
}
