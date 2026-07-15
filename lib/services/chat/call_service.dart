// Route: lib/services/chat/call_service.dart
// PRODUCTION - Agora Service - Anti-crash - Audio Pro Config
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../models/chat/call_status.dart';
import 'call_token_service.dart';

class CallService {
  static final CallService _instance = CallService._internal();
  factory CallService() => _instance;
  CallService._internal();

  RtcEngine? _engine;
  bool _joined = false;
  bool _isInitializing = false;
  final _tokenService = CallTokenService();
  String? _currentChannel;
  CallType? _currentType;

  RtcEngine? get engine => _engine;
  bool get isJoined => _joined;
  String? get currentChannel => _currentChannel;

  // ============================================================
  // INIT ENGINE - Avec config audio pro
  // ============================================================
  Future<void> initEngine(String appId) async {
    if (_isInitializing) return;
    if (_engine != null) return;

    _isInitializing = true;
    try {
      _engine = createAgoraRtcEngine();

      await _engine!.initialize(
        RtcEngineContext(
          appId: appId,
          channelProfile:
              ChannelProfileType.channelProfileCommunication,
          audioScenario: AudioScenarioType.audioScenarioDefault,
        ),
      );

      // Audio config pro
      await _engine!.enableAudio();
      await _engine!.setAudioProfile(
        profile: AudioProfileType.audioProfileMusicHighQuality,
        scenario: AudioScenarioType.audioScenarioGameStreaming,
      );
      await _engine!.enableAudioVolumeIndication(
        interval: 200,
        smooth: 3,
        reportVad: true,
      );

      // Video config
      await _engine!.enableVideo();
      await _engine!.setVideoEncoderConfiguration(
        const VideoEncoderConfiguration(
          dimensions: VideoDimensions(width: 640, height: 480),
          frameRate: 15,
          bitrate: 0,
          orientationMode: OrientationMode.orientationModeAdaptive,
        ),
      );

      // Echo & Noise
      await _engine!.setDefaultAudioRoutetoSpeakerphone(true);
      await _engine!.enableLocalAudio(true);

      debugPrint('✅ Agora engine initialized');
    } catch (e) {
      debugPrint('❌ Agora init error: $e');
      _engine = null;
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  // ============================================================
  // JOIN - Avec permission + token refresh + events
  // ============================================================
  Future<void> join({
    required String channel,
    required CallType type,
    required int uid,
    required Function(int remoteUid) onJoin,
    required Function() onLeave,
    Function(String reason)? onError,
  }) async {
    try {
      _currentChannel = channel;
      _currentType = type;

      // 1. Permissions
      final mic = await Permission.microphone.request();
      if (!mic.isGranted) {
        throw Exception('Microphone permission denied');
      }
      if (type == CallType.video) {
        final cam = await Permission.camera.request();
        if (!cam.isGranted) {
          throw Exception('Camera permission denied');
        }
      }

      // 2. Token
      final cred = await _tokenService.getToken(
        channel: channel,
        uid: uid,
      );
      final token = cred['token']!;
      final appId = cred['appId']!;

      // 3. Init si besoin
      if (_engine == null) {
        await initEngine(appId);
      }

      if (_engine == null) {
        throw Exception('Engine not initialized');
      }

      // 4. Event handlers - PROD complet
      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (conn, elapsed) {
            _joined = true;
            debugPrint('✅ Joined channel ${conn.channelId} uid ${conn.localUid}');
          },

          onUserJoined: (conn, remoteUid, elapsed) {
            debugPrint('👤 Remote $remoteUid joined');
            onJoin(remoteUid);
          },

          onUserOffline: (conn, remoteUid, reason) {
            debugPrint('👋 Remote $remoteUid offline reason $reason');
            onLeave();
          },

          onLeaveChannel: (conn, stats) {
            _joined = false;
            debugPrint('🚪 Left channel');
          },

          onError: (err, msg) {
            debugPrint('❌ Agora error $err : $msg');
            onError?.call('Agora $err: $msg');
          },

          onTokenPrivilegeWillExpire: (conn, token) async {
            debugPrint('⚠️ Token will expire, refreshing...');
            try {
              final newCred = await _tokenService.getToken(
                channel: channel,
                uid: uid,
              );
              await _engine!.renewToken(newCred['token']!);
            } catch (e) {
              debugPrint('Token refresh failed $e');
            }
          },

          onConnectionStateChanged: (conn, state, reason) {
            debugPrint('🔌 Connection state $state reason $reason');
            if (state == ConnectionStateType.connectionStateFailed) {
              onError?.call('Connection failed: $reason');
            }
          },

          onNetworkQuality: (conn, remoteUid, tx, rx) {
            // Optionnel: log qualité réseau
          },
        ),
      );

      // 5. Media options
      final options = ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
        autoSubscribeAudio: true,
        autoSubscribeVideo: type == CallType.video,
        publishCameraTrack: type == CallType.video,
        publishMicrophoneTrack: true,
        publishScreenTrack: false,
      );

      await _engine!.joinChannel(
        token: token,
        channelId: channel,
        uid: uid == 0 ? 0 : uid,
        options: options,
      );

      // 6. Config finale selon type
      if (type == CallType.audio) {
        await _engine!.disableVideo();
        await _engine!.muteLocalVideoStream(true);
        await _engine!.setEnableSpeakerphone(true);
      } else {
        await _engine!.enableVideo();
        await _engine!.muteLocalVideoStream(false);
        await _engine!.startPreview();
        await _engine!.setEnableSpeakerphone(true);
      }
    } catch (e) {
      debugPrint('❌ CallService.join error: $e');
      _joined = false;
      onError?.call(e.toString());
      rethrow;
    }
  }

  // ============================================================
  // LEAVE - Safe
  // ============================================================
  Future<void> leave() async {
    try {
      if (_joined && _engine != null) {
        await _engine!.stopPreview();
        await _engine!.leaveChannel();
        _joined = false;
        debugPrint('✅ Left channel $_currentChannel');
      }
      _currentChannel = null;
      _currentType = null;
    } catch (e) {
      debugPrint('⚠️ leave error $e');
      _joined = false;
    }
  }

  // ============================================================
  // CONTROLS - Safe avec try/catch
  // ============================================================
  Future<void> mute(bool muted) async {
    try {
      await _engine?.muteLocalAudioStream(muted);
      await _engine?.enableLocalAudio(!muted);
    } catch (e) {
      debugPrint('mute err $e');
    }
  }

  Future<void> videoOff(bool off) async {
    try {
      await _engine?.muteLocalVideoStream(off);
      await _engine?.enableLocalVideo(!off);
      if (off) {
        await _engine?.stopPreview();
      } else {
        await _engine?.startPreview();
      }
    } catch (e) {
      debugPrint('videoOff err $e');
    }
  }

  Future<void> switchCam() async {
    try {
      await _engine?.switchCamera();
    } catch (e) {
      debugPrint('switchCam err $e');
    }
  }

  Future<void> speaker(bool enable) async {
    try {
      await _engine?.setEnableSpeakerphone(enable);
      await _engine?.setDefaultAudioRoutetoSpeakerphone(enable);
    } catch (e) {
      debugPrint('speaker err $e');
    }
  }

  Future<void> setVolume(int volume) async {
    // 0..400
    try {
      await _engine?.adjustRecordingSignalVolume(volume);
    } catch (e) {
      debugPrint('volume err $e');
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================
  void dispose() {
    try {
      _engine?.release();
    } catch (_) {}
    _engine = null;
    _joined = false;
    _currentChannel = null;
    _currentType = null;
    _isInitializing = false;
    debugPrint('🧹 CallService disposed');
  }
}
