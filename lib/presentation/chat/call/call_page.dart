// Route: lib/presentation/chat/call/call_page.dart
// PRODUCTION - CallPage Audio + Video - Riverpod - Sans double timer - Anti-crash
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../../../../models/chat/call_status.dart';
import 'providers/call_provider.dart';
import 'widgets/call_avatar.dart';

class CallPage extends ConsumerStatefulWidget {
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
  ConsumerState<CallPage> createState() => _CallPageState();
}

class _CallPageState extends ConsumerState<CallPage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialisation post-frame pour éviter les modifications d'état pendant le build initial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.isCaller && widget.inviteId != null) {
        ref.read(callProvider.notifier).accept(
              channel: widget.channel,
              inviteId: widget.inviteId!,
              callType: widget.type,
            );
      }
    });
  }

  String _formatDuration(Duration duration) {
    final s = duration.inSeconds;
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  Future<void> _handleEnd() async {
    await ref.read(callProvider.notifier).end();
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Optionnel: gestion du passage en arrière-plan
    }
  }

  @override
  Widget build(BuildContext context) {
    final provState = ref.watch(callProvider);
    final provNotifier = ref.read(callProvider.notifier);
    final isVideo = provState.isVideo;
    final statusText = _getStatusText(provState);

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
            if (isVideo) _buildVideoLayout(provState, provNotifier),

            // AUDIO BACKGROUND
            if (!isVideo) _buildAudioLayout(statusText, provState),

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
                        onPressed: _handleEnd,
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
                                    color: provState.status == CallStatus.ongoing
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
                          onPressed: provNotifier.switchCam,
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // REMOTE NOT YET JOINED OVERLAY FOR VIDEO
            if (isVideo && provState.remoteUid == null)
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
                    if (provState.status == CallStatus.ongoing)
                      Text(_formatDuration(provState.duration),
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.1)),
                    const SizedBox(height: 14),
                    CallControls(
                      isVideo: isVideo,
                      muted: provState.muted,
                      videoOff: provState.videoOff,
                      speakerOn: provState.speakerOn,
                      onMute: provNotifier.toggleMute,
                      onVideo: provNotifier.toggleVideo,
                      onSwitch: provNotifier.switchCam,
                      onSpeaker: provNotifier.toggleSpeaker,
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
  }

  String _getStatusText(CallState p) {
    switch (p.status) {
      case CallStatus.ringing:
        return widget.isCaller ? 'Appel en cours...' : 'Connexion...';
      case CallStatus.ongoing:
        return p.remoteUid == null ? 'Sonnerie...' : 'En cours';
      case CallStatus.ended:
        return 'Terminé';
      default:
        return p.status.name;
    }
  }

  Widget _buildAudioLayout(String status, CallState prov) {
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          if (prov.status == CallStatus.ongoing && prov.remoteUid != null)
            Text(_formatDuration(prov.duration),
                style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2)),
        ],
      ),
    );
  }

  Widget _buildVideoLayout(CallState prov, CallNotifier notifier) {
    Widget remoteView;
    if (prov.remoteUid != null) {
      remoteView = AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: notifier.callService.engine, // Utilise l'instance active du service
          connection: RtcConnection(channelId: widget.channel),
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
                        rtcEngine: notifier.callService.engine, // Utilise l'instance active
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

// ============================================================================
// COMPOSANT DES BOUTONS D'APPEL
// ============================================================================
class CallControls extends StatelessWidget {
  final bool isVideo;
  final bool muted;
  final bool videoOff;
  final bool speakerOn;
  final VoidCallback onMute;
  final VoidCallback onVideo;
  final VoidCallback onSwitch;
  final VoidCallback onSpeaker;
  final VoidCallback onEnd;

  const CallControls({
    super.key,
    required this.isVideo,
    required this.muted,
    required this.videoOff,
    required this.speakerOn,
    required this.onMute,
    required this.onVideo,
    required this.onSwitch,
    required this.onSpeaker,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildButton(
          icon: muted ? Icons.mic_off : Icons.mic,
          color: muted ? Colors.white : Colors.white24,
          iconColor: muted ? Colors.black : Colors.white,
          onTap: onMute,
        ),
        if (isVideo)
          _buildButton(
            icon: videoOff ? Icons.videocam_off : Icons.videocam,
            color: videoOff ? Colors.white : Colors.white24,
            iconColor: videoOff ? Colors.black : Colors.white,
            onTap: onVideo,
          ),
        _buildButton(
          icon: speakerOn ? Icons.volume_up : Icons.volume_down,
          color: speakerOn ? Colors.white : Colors.white24,
          iconColor: speakerOn ? Colors.black : Colors.white,
          onTap: onSpeaker,
        ),
        _buildButton(
          icon: Icons.call_end,
          color: Colors.redAccent,
          iconColor: Colors.white,
          onTap: onEnd,
          isEndButton: true,
        ),
      ],
    );
  }

  Widget _buildButton({
    required IconData icon,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
    bool isEndButton = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isEndButton ? 18 : 14),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: isEndButton ? 32 : 28,
        ),
      ),
    );
  }
}
