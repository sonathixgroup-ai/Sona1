// Route: lib/services/chat/call_service.dart
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../models/chat/call_status.dart';
import 'call_token_service.dart';

class CallService {
  static final CallService _i = CallService._();
  factory CallService() => _i;
  CallService._();

  RtcEngine? _engine;
  bool _joined = false;
  final _tokenSvc = CallTokenService();

  RtcEngine? get engine => _engine;
  bool get isJoined => _joined;

  Future<void> initEngine(String appId) async {
    _engine = createAgoraRtcEngine();
    await _engine!.initialize(
      RtcEngineContext(
        appId: appId,
        channelProfile:
            ChannelProfileType.channelProfileCommunication,
      ),
    );
    await _engine!.enableAudio();
    await _engine!.enableVideo();
  }

  Future<void> join({
    required String channel,
    required CallType type,
    required int uid,
    required Function(int remoteUid) onJoin,
    required Function() onLeave,
  }) async {
    await [Permission.mic, Permission.camera].request();

    final cred = await _tokenSvc.getToken(
      channel: channel,
      uid: uid,
    );

    if (_engine == null) {
      await initEngine(cred['appId']!);
    }

    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (c, _) => _joined = true,
        onUserJoined: (c, rUid, _) => onJoin(rUid),
        onUserOffline: (c, _, _) => onLeave(),
      ),
    );

    await _engine!.joinChannel(
      token: cred['token']!,
      channelId: channel,
      uid: uid,
      options: ChannelMediaOptions(
        clientRoleType:
            ClientRoleType.clientRoleBroadcaster,
        autoSubscribeAudio: true,
        autoSubscribeVideo: type == CallType.video,
      ),
    );

    if (type == CallType.audio) {
      await _engine!.disableVideo();
    } else {
      await _engine!.enableVideo();
    }
  }

  Future<void> leave() async {
    if (_joined) {
      await _engine?.leaveChannel();
      _joined = false;
    }
  }

  Future<void> mute(bool v) =>
      _engine!.muteLocalAudioStream(v);

  Future<void> videoOff(bool v) =>
      _engine!.muteLocalVideoStream(v);

  Future<void> switchCam() =>
      _engine!.switchCamera();

  Future<void> speaker(bool v) =>
      _engine!.setEnableSpeakerphone(v);

  void dispose() {
    _engine?.release();
    _engine = null;
  }
}
