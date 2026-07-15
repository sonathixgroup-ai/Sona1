// Route: lib/presentation/chat/call/providers/call_provider.dart
// PRODUCTION - CallProvider complet - State machine - Anti-crash
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../models/chat/call_status.dart';
import '../../../../services/chat/call_service.dart';
import '../../../../services/chat/call_signaling_service.dart';

class CallProvider extends ChangeNotifier {
  final CallService _call = CallService();
  final CallSignalingService _signal = CallSignalingService();

  // State
  CallStatus status = CallStatus.ringing;
  CallType type = CallType.audio;
  int? remoteUid;
  String? inviteId;
  String? channelName;

  // Controls
  bool muted = false;
  bool videoOff = false;
  bool speakerOn = true;
  bool isFrontCam = true;
  bool isConnecting = true;

  // Timer
  Timer? _callTimer;
  Duration duration = Duration.zero;

  // Sub
  StreamSubscription? _statusSub;
  bool _disposed = false;

  bool get isVideo => type == CallType.video;
  bool get isOngoing => status == CallStatus.ongoing;
  bool get isRinging => status == CallStatus.ringing;

  // ============================================================
  // START - Caller lance l'appel
  // ============================================================
  Future<void> start({
    required String channel,
    required String calleeId,
    required CallType callType,
  }) async {
    try {
      channelName = channel;
      type = callType;
      status = CallStatus.ringing;
      isConnecting = true;
      remoteUid = null;
      muted = false;
      videoOff = callType == CallType.audio ? true : false;
      speakerOn = callType == CallType.video;
      duration = Duration.zero;
      _safeNotify();

      // 1. Créer invite en DB
      inviteId = await _signal.create(
        channel: channel,
        calleeId: calleeId,
        type: callType.name,
      );

      // 2. Ecouter changement status (rejected/ended par callee)
      _listenStatusChange(inviteId!);

      // 3. Join Agora
      await _call.join(
        channel: channel,
        type: callType,
        uid: 0,
        onJoin: (uid) {
          remoteUid = uid;
          status = CallStatus.ongoing;
          isConnecting = false;
          _startTimer();
          _safeNotify();
        },
        onLeave: () {
          // Remote a quitté
          end(silent: false);
        },
      );
    } catch (e) {
      debugPrint('❌ CallProvider.start error: $e');
      status = CallStatus.ended;
      _safeNotify();
      rethrow;
    }
  }

  // ============================================================
  // ACCEPT - Callee accepte
  // ============================================================
  Future<void> accept({
    required String channel,
    required String inviteId,
    required CallType callType,
  }) async {
    try {
      this.inviteId = inviteId;
      channelName = channel;
      type = callType;
      status = CallStatus.accepted;
      isConnecting = true;
      _safeNotify();

      await _signal.update(inviteId, 'accepted');
      _listenStatusChange(inviteId);

      await _call.join(
        channel: channel,
        type: callType,
        uid: 0,
        onJoin: (uid) {
          remoteUid = uid;
          status = CallStatus.ongoing;
          isConnecting = false;
          _startTimer();
          _safeNotify();
        },
        onLeave: () => end(silent: false),
      );
    } catch (e) {
      debugPrint('❌ CallProvider.accept error: $e');
      status = CallStatus.ended;
      _safeNotify();
    }
  }

  // ============================================================
  // REJECT / MISS / BUSY
  // ============================================================
  Future<void> reject() async {
    try {
      if (inviteId != null) {
        await _signal.update(inviteId!, 'rejected');
      }
    } finally {
      await _cleanup();
      status = CallStatus.rejected;
      _safeNotify();
    }
  }

  Future<void> markMissed() async {
    try {
      if (inviteId != null) await _signal.update(inviteId!, 'missed');
    } finally {
      await _cleanup();
      status = CallStatus.missed;
      _safeNotify();
    }
  }

  // ============================================================
  // CONTROLS
  // ============================================================
  Future<void> toggleMute() async {
    muted = !muted;
    try {
      await _call.mute(muted);
    } catch (e) {
      debugPrint('mute err $e');
      muted = !muted;
    }
    _safeNotify();
  }

  Future<void> toggleVideo() async {
    // Audio call ne peut pas activer video comme ça, on garde la logique
    if (type == CallType.audio) return;
    videoOff = !videoOff;
    try {
      await _call.videoOff(videoOff);
    } catch (e) {
      videoOff = !videoOff;
      debugPrint('videoOff err $e');
    }
    _safeNotify();
  }

  Future<void> toggleSpeaker() async {
    speakerOn = !speakerOn;
    try {
      await _call.speaker(speakerOn);
    } catch (e) {
      speakerOn = !speakerOn;
      debugPrint('speaker err $e');
    }
    _safeNotify();
  }

  Future<void> switchCam() async {
    try {
      await _call.switchCam();
      isFrontCam = !isFrontCam;
      _safeNotify();
    } catch (e) {
      debugPrint('switchCam err $e');
    }
  }

  // ============================================================
  // END
  // ============================================================
  Future<void> end({bool silent = false}) async {
    try {
      _callTimer?.cancel();
      if (!silent && inviteId != null) {
        await _signal.update(inviteId!, 'ended');
      }
      await _call.leave();
    } catch (e) {
      debugPrint('end err $e');
    } finally {
      await _cleanup();
      status = CallStatus.ended;
      duration = Duration.zero;
      _safeNotify();
    }
  }

  // ============================================================
  // TIMER + LISTEN
  // ============================================================
  void _startTimer() {
    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      duration += const Duration(seconds: 1);
      _safeNotify();
    });
  }

  void _listenStatusChange(String id) {
    _statusSub?.cancel();
    _statusSub = Supabase.instance.client
        .from('call_invites')
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .listen((list) {
          if (list.isEmpty) return;
          final row = list.first;
          final s = row['status'] as String?;
          if (s == 'ended' || s == 'rejected' || s == 'missed') {
            // L'autre a raccroché
            end(silent: true);
          }
        });
  }

  Future<void> _cleanup() async {
    _callTimer?.cancel();
    _statusSub?.cancel();
    _statusSub = null;
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _callTimer?.cancel();
    _statusSub?.cancel();
    _call.dispose();
    _signal.dispose();
    super.dispose();
  }
}
