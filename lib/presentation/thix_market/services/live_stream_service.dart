import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class LiveStreamService {
  final SupabaseClient _supabase = Supabase.instance.client;

  late RtcEngine _engine;

  bool _isHost = false;
  bool _isJoined = false;
  bool _isMuted = false;
  bool _isVideoEnabled = true;

  int _remoteUid = 0;
  String? _currentChannel;

  Future<void> initEngine({required bool isHost}) async {
    await [
      Permission.microphone,
      Permission.camera,
    ].request();

    // ✅ Agora 6.5.1
    _engine = createAgoraRtcEngine();

    await _engine.initialize(
      RtcEngineContext(
        appId: 'YOUR_AGORA_APP_ID',
        channelProfile:
            ChannelProfileType.channelProfileLiveBroadcasting,
      ),
    );

    // Active vidéo
    await _engine.enableVideo();

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess:
            (RtcConnection connection, int elapsed) {
          _isJoined = true;
        },

        onUserJoined:
            (RtcConnection connection, int remoteUid, int elapsed) {
          _remoteUid = remoteUid;
        },

        onUserOffline: (
          RtcConnection connection,
          int remoteUid,
          UserOfflineReasonType reason,
        ) {
          _remoteUid = 0;
        },

        onError: (ErrorCodeType err, String msg) {
          print("Agora error: $err - $msg");
        },
      ),
    );

    _isHost = isHost;

    if (isHost) {
      await _engine.setClientRole(
        role: ClientRoleType.clientRoleBroadcaster,
      );
    } else {
      await _engine.setClientRole(
        role: ClientRoleType.clientRoleAudience,
      );
    }
  }

  Future<void> joinChannel({
    required String channelName,
    required String token,
  }) async {
    _currentChannel = channelName;

    await _engine.joinChannel(
      token: token,
      channelId: channelName,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  Future<void> leaveChannel() async {
    await _engine.leaveChannel();

    _isJoined = false;
    _remoteUid = 0;
    _currentChannel = null;
  }

  Future<void> toggleMute() async {
    _isMuted = !_isMuted;

    await _engine.muteLocalAudioStream(_isMuted);
  }

  Future<void> switchCamera() async {
    await _engine.switchCamera();
  }

  Future<void> toggleVideo() async {
    _isVideoEnabled = !_isVideoEnabled;

    if (_isVideoEnabled) {
      await _engine.enableVideo();
    } else {
      await _engine.disableVideo();
    }
  }

  Future<void> dispose() async {
    await _engine.leaveChannel();

    // ✅ Agora 6.5.1
    await _engine.release();
  }
}
