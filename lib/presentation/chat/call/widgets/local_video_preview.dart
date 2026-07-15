// Route: lib/presentation/chat/call/widgets/local_video_preview.dart
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

class LocalVideoPreview extends StatelessWidget {
  final String channel;
  const LocalVideoPreview({super.key, required this.channel});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 110,
        height: 160,
        child: AgoraVideoView(
          controller: VideoViewController(
            rtcConnection: RtcConnection(channelId: channel),
            canvas: const VideoCanvas(uid: 0),
          ),
        ),
      ),
    );
  }
}
