// Route: lib/presentation/chat/call/providers/call_provider.dart
// PRODUCTION - CallNotifier Riverpod - State machine - Anti-crash
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../models/chat/call_status.dart';
import '../../../../services/chat/call_service.dart';
import '../../../../services/chat/call_signaling_service.dart';

// État immuable pour le Call
class CallState {
  final CallStatus status;
  final CallType type;
  final int? remoteUid;
  final String? inviteId;
  final String? channelName;
  final bool muted;
  final bool videoOff;
  final bool speakerOn;
  final bool isFrontCam;
  final bool isConnecting;
  final Duration duration;

  const CallState({
    this.status = CallStatus.ringing,
    this.type = CallType.audio,
    this.remoteUid,
    this.inviteId,
    this.channelName,
    this.muted = false,
    this.videoOff = false,
    this.speakerOn = true,
    this.isFrontCam = true,
    this.isConnecting = true,
    this.duration = Duration.zero,
  });

  CallState copyWith({
    CallStatus? status,
    CallType? type,
    int? remoteUid,
    String? inviteId,
    String? channelName,
    bool? muted,
    bool? videoOff,
    bool? speakerOn,
    bool? isFrontCam,
    bool? isConnecting,
    Duration? duration,
  }) {
    return CallState(
      status: status ?? this.status,
      type: type ?? this.type,
      remoteUid: remoteUid ?? this.remoteUid,
      inviteId: inviteId ?? this.inviteId,
      channelName: channelName ?? this.channelName,
      muted: muted ?? this.muted,
      videoOff: videoOff ?? this.videoOff,
      speakerOn: speakerOn ?? this.speakerOn,
      isFrontCam: isFrontCam ?? this.isFrontCam,
      isConnecting: isConnecting ?? this.isConnecting,
      duration: duration ?? this.duration,
    );
  }

  bool get isVideo => type == CallType.video;
  bool get isOngoing => status == CallStatus.ongoing;
  bool get isRinging => status == CallStatus.ringing;
}

class CallNotifier extends AutoDisposeNotifier<CallState> {
  final CallService _call = CallService();
  final CallSignalingService _signal = CallSignalingService();

  Timer? _callTimer;
  StreamSubscription? _statusSub;

  CallService get callService => _call;

  @override
  CallState build() {
    ref.onDispose(() {
      _callTimer?.cancel();
      _statusSub?.cancel();
      _call.dispose();
      _signal.dispose();
    });
    return const CallState();
  }

  // Génération d'un UID stable basé sur l'ID Supabase de l'utilisateur
  int _agoraUid() {
    final id = Supabase.instance.client.auth.currentUser?.id ?? '';
    var hash = 0x811c9dc5;
    for (final c in id.codeUnits) {
      hash ^= c;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    final uid = hash & 0x7fffffff;
    return uid == 0 ? 1 : uid;
  }

  // ============================================================
  // START - Caller lance l'appel
  // ============================================================
  Future<void> start({
    required String channel,
    required String calleeId,
    required CallType callType,
  }) async {
    try {
      state = state.copyWith(
        channelName: channel,
        type: callType,
        status: CallStatus.ringing,
        isConnecting: true,
        remoteUid: null,
        muted: false,
        videoOff: callType == CallType.audio,
        speakerOn: callType == CallType.video,
        duration: Duration.zero,
      );

      // 1. Créer invite en DB
      final inviteId = await _signal.create(
        channel: channel,
        calleeId: calleeId,
        type: callType.name,
      );
      state = state.copyWith(inviteId: inviteId);

      // 2. Ecouter changement status (rejected/ended par callee)
      _listenStatusChange(inviteId);

      // 3. Join Agora avec UID stable
      await _call.join(
        channel: channel,
        type: callType,
        uid: _agoraUid(),
        onJoin: (uid) {
          state = state.copyWith(
            remoteUid: uid,
            status: CallStatus.ongoing,
            isConnecting: false,
          );
          _startTimer();
        },
        onLeave: () {
          end(silent: false);
        },
        onError: (reason) {
          debugPrint('Agora join error: $reason');
          state = state.copyWith(status: CallStatus.ended);
        },
      );
    } catch (e) {
      debugPrint('❌ CallNotifier.start error: $e');
      state = state.copyWith(status: CallStatus.ended);
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
      state = state.copyWith(
        inviteId: inviteId,
        channelName: channel,
        type: callType,
        status: CallStatus.accepted,
        isConnecting: true,
      );

      await _signal.update(inviteId, 'accepted');
      _listenStatusChange(inviteId);

      // Join Agora avec UID stable
      await _call.join(
        channel: channel,
        type: callType,
        uid: _agoraUid(),
        onJoin: (uid) {
          state = state.copyWith(
            remoteUid: uid,
            status: CallStatus.ongoing,
            isConnecting: false,
          );
          _startTimer();
        },
        onLeave: () => end(silent: false),
        onError: (reason) {
          debugPrint('Agora join error: $reason');
          state = state.copyWith(status: CallStatus.ended);
        },
      );
    } catch (e) {
      debugPrint('❌ CallNotifier.accept error: $e');
      state = state.copyWith(status: CallStatus.ended);
    }
  }

  // ============================================================
  // REJECT / MISS / BUSY
  // ============================================================
  Future<void> reject() async {
    try {
      if (state.inviteId != null) {
        await _signal.update(state.inviteId!, 'rejected');
      }
    } finally {
      await _cleanup();
      state = state.copyWith(status: CallStatus.rejected);
    }
  }

  Future<void> markMissed() async {
    try {
      if (state.inviteId != null) {
        await _signal.update(state.inviteId!, 'missed');
      }
    } finally {
      await _cleanup();
      state = state.copyWith(status: CallStatus.missed);
    }
  }

  // ============================================================
  // CONTROLS
  // ============================================================
  Future<void> toggleMute() async {
    final newMuted = !state.muted;
    state = state.copyWith(muted: newMuted);
    try {
      await _call.mute(newMuted);
    } catch (e) {
      debugPrint('mute err $e');
      state = state.copyWith(muted: !newMuted);
    }
  }

  Future<void> toggleVideo() async {
    if (state.type == CallType.audio) return;
    final newVideoOff = !state.videoOff;
    state = state.copyWith(videoOff: newVideoOff);
    try {
      await _call.videoOff(newVideoOff);
    } catch (e) {
      state = state.copyWith(videoOff: !newVideoOff);
      debugPrint('videoOff err $e');
    }
  }

  Future<void> toggleSpeaker() async {
    final newSpeakerOn = !state.speakerOn;
    state = state.copyWith(speakerOn: newSpeakerOn);
    try {
      await _call.speaker(newSpeakerOn);
    } catch (e) {
      state = state.copyWith(speakerOn: !newSpeakerOn);
      debugPrint('speaker err $e');
    }
  }

  Future<void> switchCam() async {
    try {
      await _call.switchCam();
      state = state.copyWith(isFrontCam: !state.isFrontCam);
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
      if (!silent && state.inviteId != null) {
        await _signal.update(state.inviteId!, 'ended');
      }
      await _call.leave();
    } catch (e) {
      debugPrint('end err $e');
    } finally {
      await _cleanup();
      state = state.copyWith(
        status: CallStatus.ended,
        duration: Duration.zero,
      );
    }
  }

  // ============================================================
  // TIMER + LISTEN
  // ============================================================
  void _startTimer() {
    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(duration: state.duration + const Duration(seconds: 1));
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
            end(silent: true);
          }
        });
  }

  Future<void> _cleanup() async {
    _callTimer?.cancel();
    _statusSub?.cancel();
    _statusSub = null;
  }
}

// Déclaration du Provider Riverpod
final callProvider = AutoDisposeNotifierProvider<CallNotifier, CallState>(
  CallNotifier.new,
);
