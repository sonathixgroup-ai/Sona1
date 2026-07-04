import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LiveStreamService {
  final SupabaseClient _supabase = Supabase.instance.client;

  late RtcEngine _engine;

  bool _isHost = false;
  bool _isJoined = false;
  bool _isMuted = false;
  bool _isVideoEnabled = true;

  int _remoteUid = 0;
  String? _currentChannel;

  // =========================
  // INIT ENGINE
  // =========================
  Future<void> initEngine({required bool isHost}) async {
    await [
      Permission.microphone,
      Permission.camera,
    ].request();

    _isHost = isHost;

    // ✅ Agora 6.5.1 correct init
    _engine = createAgoraRtcEngine();

    await _engine.initialize(
      const RtcEngineContext(
        appId: 'YOUR_AGORA_APP_ID',
        channelProfile:
            ChannelProfileType.channelProfileLiveBroadcasting,
      ),
    );

    await _engine.enableVideo();

    _engine.registerEventHandler(
      RtcEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          _isJoined = true;
        },

        onUserJoined: (RtcConnection connection, int uid, int elapsed) {
          _remoteUid = uid;
        },

        onUserOffline: (
          RtcConnection connection,
          int uid,
          UserOfflineReasonType reason,
        ) {
          _remoteUid = 0;
        },

        onError: (ErrorCodeType err, String msg) {
          print("Agora error: $err - $msg");
        },
      ),
    );

    // set role
    if (_isHost) {
      await _engine.setClientRole(
        role: ClientRoleType.clientRoleBroadcaster,
      );
    } else {
      await _engine.setClientRole(
        role: ClientRoleType.clientRoleAudience,
      );
    }
  }

  // =========================
  // JOIN CHANNEL
  // =========================
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

  // =========================
  // LEAVE CHANNEL
  // =========================
  Future<void> leaveChannel() async {
    await _engine.leaveChannel();

    _isJoined = false;
    _remoteUid = 0;
    _currentChannel = null;
  }

  // =========================
  // MUTING
  // =========================
  Future<void> toggleMute() async {
    _isMuted = !_isMuted;

    await _engine.muteLocalAudioStream(_isMuted);
  }

  // =========================
  // VIDEO CONTROL
  // =========================
  Future<void> toggleVideo() async {
    _isVideoEnabled = !_isVideoEnabled;

    if (_isVideoEnabled) {
      await _engine.enableVideo();
    } else {
      await _engine.disableVideo();
    }
  }

  Future<void> switchCamera() async {
    await _engine.switchCamera();
  }

  // =========================
  // SUPABASE LIVE SESSION
  // =========================
  Future<Map<String, dynamic>> createLiveSession({
    required String shopId,
    required String title,
    List<String>? productIds,
  }) async {
    final channelName =
        'live_${DateTime.now().millisecondsSinceEpoch}';

    final liveData = {
      'shop_id': shopId,
      'title': title,
      'channel_name': channelName,
      'products': productIds ?? [],
      'status': 'scheduled',
      'created_at': DateTime.now().toIso8601String(),
    };

    final res = await _supabase
        .from('lives')
        .insert(liveData)
        .select()
        .single();

    return res;
  }

  // =========================
  // START LIVE
  // =========================
  Future<void> startLive(String liveId) async {
    await _supabase.from('lives').update({
      'status': 'live',
      'started_at': DateTime.now().toIso8601String(),
    }).eq('id', liveId);
  }

  // =========================
  // END LIVE
  // =========================
  Future<void> endLive(String liveId) async {
    await _supabase.from('lives').update({
      'status': 'ended',
      'ended_at': DateTime.now().toIso8601String(),
    }).eq('id', liveId);

    await leaveChannel();
  }

  // =========================
  // VIEWERS
  // =========================
  Future<void> incrementViewers(String liveId) async {
    await _supabase.rpc('increment_live_viewers', params: {
      'live_id': liveId,
    });
  }

  // =========================
  // CHAT
  // =========================
  Future<void> sendMessage({
    required String liveId,
    required String message,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase.from('live_messages').insert({
      'live_id': liveId,
      'user_id': userId,
      'message': message,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // =========================
  // DISPOSE
  // =========================
  Future<void> dispose() async {
    await _engine.leaveChannel();
    await _engine.release(); // ✅ correct Agora 6.x
  }
}
