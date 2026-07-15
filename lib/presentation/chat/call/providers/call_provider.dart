// Route: lib/presentation/chat/call/providers/call_provider.dart
import 'package:flutter/foundation.dart';
import '../../../../models/chat/call_status.dart';
import '../../../../services/chat/call_service.dart';
import '../../../../services/chat/call_signaling_service.dart';

class CallProvider extends ChangeNotifier {
  final _call = CallService();
  final _signal = CallSignalingService();

  CallStatus status = CallStatus.ringing;
  CallType type = CallType.audio;
  int? remoteUid;
  bool muted = false;
  bool videoOff = false;
  bool speakerOn = true;
  String? inviteId;

  bool get isVideo => type == CallType.video;

  Future<void> start({
    required String channel,
    required String calleeId,
    required CallType callType,
  }) async {
    type = callType;
    status = CallStatus.ringing;
    notifyListeners();

    inviteId = await _signal.create(
      channel: channel,
      calleeId: calleeId,
      type: callType.name,
    );

    await _call.join(
      channel: channel,
      type: callType,
      uid: 0,
      onJoin: (uid) {
        remoteUid = uid;
        status = CallStatus.ongoing;
        notifyListeners();
      },
      onLeave: () => end(),
    );
  }

  Future<void> accept({
    required String channel,
    required String inviteId,
    required CallType callType,
  }) async {
    this.inviteId = inviteId;
    type = callType;
    status = CallStatus.ongoing;
    notifyListeners();

    await _signal.update(inviteId, 'accepted');

    await _call.join(
      channel: channel,
      type: callType,
      uid: 0,
      onJoin: (uid) {
        remoteUid = uid;
        notifyListeners();
      },
      onLeave: () => end(),
    );
  }

  Future<void> toggleMute() async {
    muted = !muted;
    await _call.mute(muted);
    notifyListeners();
  }

  Future<void> toggleVideo() async {
    videoOff = !videoOff;
    await _call.videoOff(videoOff);
    notifyListeners();
  }

  Future<void> toggleSpeaker() async {
    speakerOn = !speakerOn;
    await _call.speaker(speakerOn);
    notifyListeners();
  }

  Future<void> switchCam() => _call.switchCam();

  Future<void> end() async {
    if (inviteId != null) {
      await _signal.update(inviteId!, 'ended');
    }
    await _call.leave();
    status = CallStatus.ended;
    notifyListeners();
  }

  @override
  void dispose() {
    _call.dispose();
    _signal.dispose();
    super.dispose();
  }
}
