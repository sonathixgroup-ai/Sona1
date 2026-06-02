import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:thix_id/services/call_service.dart';
import 'package:thix_id/theme.dart';

class ThixCallSheet extends StatefulWidget {
  final String callId;
  final String otherUserId;
  final String kind;
  final bool isCaller;
  final CallService calls;

  const ThixCallSheet({
    super.key,
    required this.callId,
    required this.otherUserId,
    required this.kind,
    required this.isCaller,
    required this.calls,
  });

  @override
  State<ThixCallSheet> createState() => _ThixCallSheetState();
}

class _ThixCallSheetState extends State<ThixCallSheet> {
  RtcEngine? _engine;
  int? _remoteUid;
  bool _joined = false;
  bool _ending = false;
  bool _micOn = true;
  bool _camOn = true;
  DateTime? _startedAt;
  bool _isLoadingMedia = false;
  String _errorMsg = '';

  bool get _isVideo => widget.kind == 'video';
  String get _channelName => 'thix_call_${widget.callId}';
  int get _uid => widget.calls.agoraUidFor(widget.calls.getCurrentUserId() ?? '');

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _disposeAgora();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _init() async {
    try {
      setState(() {
        _isLoadingMedia = true;
        _errorMsg = '';
      });

      if (!kIsWeb) {
        final micGranted = await _requestPermission(Permission.microphone, 'microphone');
        if (!micGranted) throw Exception('Permission microphone refusée');
        if (_isVideo) {
          final camGranted = await _requestPermission(Permission.camera, 'caméra');
          if (!camGranted) throw Exception('Permission caméra refusée');
        }
      }

      await _initAgora();
    } catch (e) {
      debugPrint('ThixCallSheet: init failed $e');
      setState(() {
        _errorMsg = e.toString();
        _isLoadingMedia = false;
      });
      _snack('Erreur: $e');
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) context.pop();
      });
    } finally {
      if (mounted) setState(() => _isLoadingMedia = false);
    }
  }

  Future<bool> _requestPermission(Permission permission, String name) async {
    final status = await permission.status;
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) {
      _snack('Permission $name définitivement refusée');
      await openAppSettings();
      return false;
    }
    final result = await permission.request();
    return result.isGranted;
  }

  Future<void> _initAgora() async {
    // Token temporaire (pour test, en production utilise un vrai token via backend)
    const appId = '96ed392d17c74fe684bbb9d4a031ad12';
    const token = ''; // Token vide fonctionne 24h avec cet App ID
    
    // Créer et initialiser le moteur
    _engine = createAgoraRtcEngine();
    await _engine!.initialize(RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    // Écouter les événements
    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint('Agora: join success');
          if (!mounted) return;
          setState(() {
            _joined = true;
            _startedAt ??= DateTime.now();
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint('Agora: user joined $remoteUid');
          if (!mounted) return;
          setState(() => _remoteUid = remoteUid);
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          debugPrint('Agora: user offline $remoteUid');
          if (!mounted) return;
          _end(reason: 'user_left');
        },
        onError: (int errCode, String errMsg) {
          debugPrint('Agora: error $errCode: $errMsg');
          if (errCode != 0 && mounted) {
            _snack('Erreur Agora: $errMsg');
          }
        },
      ),
    );

    // Activer audio et vidéo
    await _engine!.enableAudio();
    if (_isVideo) {
      await _engine!.enableVideo();
      await _engine!.startPreview();
    }

    // Rejoindre le channel
    await _engine!.joinChannel(
      token: token,
      channelId: _channelName,
      uid: _uid,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );
  }

  Future<void> _disposeAgora() async {
    try {
      await _engine?.leaveChannel();
    } catch (_) {}
    try {
      await _engine?.release();
    } catch (_) {}
    _engine = null;
  }

  Future<void> _toggleMic() async {
    if (_engine == null) return;
    final enabled = !_micOn;
    await _engine!.muteLocalAudioStream(!enabled);
    if (mounted) setState(() => _micOn = enabled);
  }

  Future<void> _toggleCam() async {
    if (_engine == null || !_isVideo) return;
    final enabled = !_camOn;
    await _engine!.muteLocalVideoStream(!enabled);
    if (mounted) setState(() => _camOn = enabled);
  }

  Future<void> _end({required String reason}) async {
    if (_ending) return;
    setState(() => _ending = true);

    final started = _startedAt;
    try {
      if (started != null) {
        await widget.calls.completeCall(
          callId: widget.callId,
          startedAt: started,
          endedAt: DateTime.now(),
        );
      } else {
        await widget.calls.setCallStatus(
          callId: widget.callId,
          status: 'declined',
        );
      }
    } catch (e) {
      debugPrint('ThixCallSheet: end error $e');
    }

    await _disposeAgora();
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.92,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
          border: Border(top: BorderSide(color: scheme.outlineVariant.withAlpha(153))),
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isVideo ? 'Appel vidéo' : 'Appel audio',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _errorMsg.isNotEmpty
                              ? _errorMsg
                              : (_joined ? 'Connecté' : 'Connexion…'),
                          style: TextStyle(color: scheme.onSurface.withOpacity(0.6), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _ending ? null : () => _end(reason: 'closed'),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            // Video / Audio body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    color: Colors.black26,
                    child: _isLoadingMedia
                        ? const Center(child: CircularProgressIndicator())
                        : _isVideo && _remoteUid != null && _engine != null
                            ? Stack(
                                children: [
                                  // Remote video
                                  AgoraVideoView(
                                    controller: VideoViewController.remote(
                                      rtcEngine: _engine!,
                                      canvas: VideoCanvas(uid: _remoteUid),
                                      connection: RtcConnection(channelId: _channelName),
                                    ),
                                  ),
                                  // Local video (pip)
                                  Positioned(
                                    bottom: 16,
                                    right: 16,
                                    child: SizedBox(
                                      width: 100,
                                      height: 140,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: AgoraVideoView(
                                          controller: VideoViewController(
                                            rtcEngine: _engine!,
                                            canvas: const VideoCanvas(uid: 0),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Center(
                                child: Icon(
                                  Icons.phone_in_talk_rounded,
                                  size: 80,
                                  color: scheme.primary.withOpacity(0.65),
                                ),
                              ),
                  ),
                ),
              ),
            ),
            // Controls
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ControlButton(
                    icon: _micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
                    label: _micOn ? 'Micro' : 'Muet',
                    onTap: _ending ? null : _toggleMic,
                  ),
                  if (_isVideo) const SizedBox(width: 12),
                  if (_isVideo)
                    _ControlButton(
                      icon: _camOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                      label: _camOn ? 'Cam' : 'Cam off',
                      onTap: _ending ? null : _toggleCam,
                    ),
                  const SizedBox(width: 12),
                  _HangupButton(
                    onTap: _ending ? null : () => _end(reason: 'hangup'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Future<void> Function()? onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: Material(
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: BorderSide(color: scheme.outlineVariant.withAlpha(204)),
        ),
        child: InkWell(
          onTap: onTap == null ? null : () => unawaited(onTap!.call()),
          borderRadius: BorderRadius.circular(30),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: scheme.onSurface),
                const SizedBox(width: 8),
                Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HangupButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _HangupButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: FilledButton.icon(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: scheme.error,
          foregroundColor: scheme.onError,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        icon: const Icon(Icons.call_end_rounded, size: 18),
        label: const Text('Raccrocher', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
      ),
    );
  }
}
