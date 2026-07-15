// Route: lib/presentation/chat/call/call_page.dart
// PRODUCTION - CallPage Audio + Video - Timer - Controls - PIP
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:provider/provider.dart';
import '../../../../models/chat/call_status.dart';
import 'providers/call_provider.dart';
import 'widgets/call_controls.dart';
import 'widgets/call_avatar.dart';

class CallPage extends StatefulWidget {
  final String channel;
  final String name;
  final String? avatarUrl;
  final CallType type;
  final String? inviteId;
  final bool isCaller;

  const CallPage({
    super.key,
    required this.channel,
    required this.name,
    this.avatarUrl,
    required this.type,
    this.inviteId,
    this.isCaller = true,
  });

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> with WidgetsBindingObserver {
  Timer? _timer;
  int _seconds = 0;
  bool _isConnecting = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final p = context.read<CallProvider>();

    if (widget.isCaller == false && widget.inviteId!= null) {
      p.accept(
        channel: widget.channel,
        inviteId: widget.inviteId!,
        callType: widget.type,
      );
    }

    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final prov = context.read<CallProvider>();
      if (prov.status == CallStatus.ongoing) {
        if (_isConnecting) setState(() => _isConnecting = false);
        setState(() => _seconds++);
      }
    });
  }

  String _formatTime(int s) {
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2,'0')}:${m.toString().padLeft(2,'0')}:${sec.toString().padLeft(2,'0')}';
    }
    return '${m.toString().padLeft(2,'0')}:${sec.toString().padLeft(2,'0')}';
  }

  Future<void> _handleEnd() async {
    final prov = context.read<CallProvider>();
    await prov.end();
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Optionnel: mettre en background audio
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CallProvider>(
      builder: (_, prov, __) {
        final isVideo = prov.isVideo;
        final statusText = _getStatusText(prov);

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (!didPop) await _handleEnd();
          },
          child: Scaffold(
            backgroundColor: const Color(0xFF0A1F44),
            body: Stack(
              children: [
                // VIDEO BACKGROUND
                if (isVideo) _buildVideoLayout(prov),

                // AUDIO BACKGROUND
                if (!isVideo) _buildAudioLayout(statusText, prov),

                // TOP BAR
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Container(
                      height: 70,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.55),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                color: Colors.white70, size: 20),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(widget.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800)),
                                const SizedBox(height: 2),
                                Text(statusText,
                                    style: TextStyle(
                                        color: prov.status == CallStatus.ongoing
                                           ? const Color(0xFF1FA971)
                                            : Colors.white60,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          if (isVideo)
                            IconButton(
                              icon: const Icon(Icons.flip_camera_ios_rounded,
                                  color: Colors.white70),
                              onPressed: prov.switchCam,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                // REMOTE NOT YET JOINED OVERLAY FOR VIDEO
                if (isVideo && prov.remoteUid == null)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white)),
                          const SizedBox(width: 10),
                          Text('Appel de ${widget.name}...',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),

                // CONTROLS
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.only(
                        top: 18, bottom: 34, left: 16, right: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.85),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (prov.status == CallStatus.ongoing)
                          Text(_formatTime(_seconds),
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.1)),
                        const SizedBox(height: 14),
                        CallControls(
                          isVideo: isVideo,
                          muted: prov.muted,
                          videoOff: prov.videoOff,
                          speakerOn: prov.speakerOn,
                          onMute: prov.toggleMute,
                          onVideo: prov.toggleVideo,
                          onSwitch: prov.switchCam,
                          onSpeaker: prov.toggleSpeaker,
                          onEnd: _handleEnd,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getStatusText(CallProvider p) {
    switch (p.status) {
      case CallStatus.ringing:
        return widget.isCaller? 'Appel en cours...' : 'Connexion...';
      case CallStatus.ongoing:
        return p.remoteUid == null? 'Sonnerie...' : 'En cours';
      case CallStatus.ended:
        return 'Terminé';
      default:
        return p.status.name;
    }
  }

  Widget _buildAudioLayout(String status, CallProvider prov) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 90),
          CallAvatar(
            name: widget.name,
            imageUrl: widget.avatarUrl,
            size: 130,
            isVideo: false,
          ),
          const SizedBox(height: 20),
          Text(widget.name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4)),
          const SizedBox(height: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(status,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 18),
          if (prov.status == CallStatus.ongoing && prov.remoteUid!= null)
            Text(_formatTime(_seconds),
                style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2)),
        ],
      ),
    );
  }

  Widget _buildVideoLayout(CallProvider prov) {
    Widget remoteView;
    if (prov.remoteUid!= null) {
      remoteView = AgoraVideoView(
        controller: VideoViewController.remote(
          rtcConnection: RtcConnection(channelId: widget.channel),
          canvas: VideoCanvas(
            uid: prov.remoteUid,
            renderMode: RenderModeType.renderModeHidden,
          ),
        ),
      );
    } else {
      remoteView = Container(
        color: const Color(0xFF0A1F44),
        child: Center(
          child: CallAvatar(
            name: widget.name,
            imageUrl: widget.avatarUrl,
            size: 110,
            isVideo: true,
          ),
        ),
      );
    }

    return Stack(
      children: [
        SizedBox.expand(child: remoteView),

        // Local PIP
        if (!prov.videoOff)
          Positioned(
            top: 90,
            right: 16,
            width: 112,
            height: 168,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white24, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.45),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  children: [
                    AgoraVideoView(
                      controller: VideoViewController(
                        rtcConnection:
                            RtcConnection(channelId: widget.channel),
                        canvas: const VideoCanvas(
                          uid: 0,
                          renderMode: RenderModeType.renderModeHidden,
                          mirrorMode: VideoMirrorModeType.videoMirrorModeEnabled,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Vous',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        if (prov.videoOff)
          Positioned(
            top: 90,
            right: 16,
            width: 112,
            height: 168,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Icon(Icons.videocam_off_rounded,
                    color: Colors.white38, size: 28),
              ),
            ),
          ),
      ],
    );
  }
}
