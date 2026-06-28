/// Call model for THIX CHAT
class Call {
  final String id;
  final String conversationId;
  final String initiatorId;
  final String initiatorName;
  final String? initiatorAvatar;
  final List<String> participantIds;
  final CallType type;
  final CallStatus status;
  final DateTime startTime;
  final DateTime? endTime;
  final Duration duration;
  final bool isRecorded;
  final String? recordingUrl;
  final bool isScreenShared;
  final String? screenSharerId;
  final List<CallParticipant> participants;
  final CallQuality quality;
  final bool isMissed;
  final String? missedReason;

  const Call({
    required this.id,
    required this.conversationId,
    required this.initiatorId,
    required this.initiatorName,
    this.initiatorAvatar,
    this.participantIds = const [],
    required this.type,
    required this.status,
    required this.startTime,
    this.endTime,
    this.duration = const Duration(),
    this.isRecorded = false,
    this.recordingUrl,
    this.isScreenShared = false,
    this.screenSharerId,
    this.participants = const [],
    this.quality = CallQuality.hd,
    this.isMissed = false,
    this.missedReason,
  });
}

enum CallType { audioOneToOne, videoOneToOne, audioGroup, videoGroup, emergency }
enum CallStatus { incoming, ringing, connecting, active, ending, ended, failed, cancelled, missed }
enum CallQuality { low, medium, hd, fullHd }

class CallParticipant {
  final String userId;
  final String userName;
  final String? avatarUrl;
  final bool isAudioOn;
  final bool isVideoOn;
  final bool isScreenSharing;
  final DateTime joinedAt;
  final DateTime? leftAt;
  final CallParticipantRole role;

  const CallParticipant({
    required this.userId,
    required this.userName,
    this.avatarUrl,
    this.isAudioOn = true,
    this.isVideoOn = true,
    this.isScreenSharing = false,
    required this.joinedAt,
    this.leftAt,
    this.role = CallParticipantRole.participant,
  });
}

enum CallParticipantRole { host, moderator, participant }
