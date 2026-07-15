// Route: lib/presentation/chat/call/call_page.dart
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:provider/provider.dart';
import '../../../../models/chat/call_status.dart';
import 'providers/call_provider.dart';
import 'widgets/call_controls.dart';

class CallPage extends StatefulWidget {
  final String channel;
  final String name;
  final CallType type;
  final String? inviteId;
  final bool isCaller;

  const CallPage({
    super.key,
    required this.channel,
    required this.name,
    required this.type,
    this.inviteId,
    this.isCaller = true,
  });

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  @override
  void initState() {
    super.initState();
    final p = context.read<CallProvider>();
    if (widget.isCaller == false && widget.inviteId != null) {
      p.accept(
        channel: widget.channel,
        inviteId: widget.inviteId!,
        callType: widget.type,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CallProvider>(
      builder: (_, prov, __) {
        return Scaffold(
          backgroundColor: const Color(0xFF0A1F44),
          body: Stack(
            children: [
              if (prov.isVideo) _videoView(prov),
              if (!prov.isVideo) _audioView(),

              if (prov.isVideo && prov.remoteUid == null)
                Center(
                  child: Text(
                    'Appel de ${widget.name}...',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),

              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: CallControls(
                  isVideo: prov.isVideo,
                  muted: prov.muted,
                  videoOff: prov.videoOff,
                  onMute: prov.toggleMute,
                  onVideo: prov.toggleVideo,
                  onSwitch: prov.switchCam,
                  onEnd: () async {
                    await prov.end();
                    if (mounted) Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _audioView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person, size: 90, color: Colors.white24),
          const SizedBox(height: 12),
          Text(widget.name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('Appel audio',
              style: TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _videoView(CallProvider prov) {
    final call = prov.remoteUid != null
        ? AgoraVideoView(
            controller: VideoViewController.remote(
              rtcConnection:
                  RtcConnection(channelId: widget.channel),
              canvas: VideoCanvas(uid: prov.remoteUid),
            ),
          )
        : Container(color: const Color(0xFF123B7A));

    return Stack(
      children: [
        SizedBox.expand(child: call),
        if (!prov.videoOff)
          Positioned(
            top: 50,
            right: 16,
            width: 110,
            height: 160,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AgoraVideoView(
                controller: VideoViewController(
                  rtcConnection:
                      RtcConnection(channelId: widget.channel),
                  canvas: const VideoCanvas(uid: 0),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
